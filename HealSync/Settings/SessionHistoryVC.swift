//
//  TherapyHistoryVC.swift
//  HealSync
//
//  Created by Arfa on 24/03/2026.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

// MARK: - SessionHistoryVC

class SessionHistoryVC: UIViewController {

    // MARK: - Role
    enum UserRole { case therapist, patient }

    // MARK: - Properties
    private let role: UserRole
    private let db = Firestore.firestore()
    private var sessions: [[String: Any]] = []
    private var listener: ListenerRegistration?

    // MARK: - UI
    private let bgColor = UIColor(hex: "#D1F0F8")

    // MARK: - Custom Nav Bar
    private let navBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#D1F0F8")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backBtn = CustomBackButton()

    private let navTitleLbl: UILabel = {
        let l = UILabel()
        l.text = "Session History"
        l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let navDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#C8EDF5")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let countLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .systemGray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle  = .none
        tv.showsVerticalScrollIndicator = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyView: UIView = {
        let v = UIView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let emptyIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .light)
        let iv = UIImageView(image: UIImage(systemName: "clock.arrow.circlepath", withConfiguration: config))
        iv.tintColor = UIColor(hex: "#4FC3D8").withAlphaComponent(0.6)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No completed sessions yet"
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let emptySubLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Your completed sessions will appear here"
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Init
    init(role: UserRole) {
        self.role = role
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupNavBar()
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchHistory()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        listener?.remove()
        listener = nil
    }

    deinit { listener?.remove() }

    // MARK: - Nav Bar
    private func setupNavBar() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        [backBtn, navTitleLbl, navDivider].forEach { navBar.addSubview($0) }
        view.addSubview(navBar)

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -50),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 52),

            backBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 14),
            backBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            backBtn.widthAnchor.constraint(equalToConstant: 32),
            backBtn.heightAnchor.constraint(equalToConstant: 32),

            navTitleLbl.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 60),
            navTitleLbl.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),

            navDivider.leadingAnchor.constraint(equalTo: navBar.leadingAnchor),
            navDivider.trailingAnchor.constraint(equalTo: navBar.trailingAnchor),
            navDivider.bottomAnchor.constraint(equalTo: navBar.bottomAnchor),
            navDivider.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Layout
    private func setupLayout() {
        emptyView.addSubview(emptyIcon)
        emptyView.addSubview(emptyLabel)
        emptyView.addSubview(emptySubLabel)

        [countLabel, tableView, emptyView, activityIndicator].forEach {
            view.addSubview($0)
        }

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(SessionHistoryCell.self, forCellReuseIdentifier: SessionHistoryCell.reuseID)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)

        NSLayoutConstraint.activate([
            // countLabel sits in the nav bar, trailing side
            countLabel.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Table starts below the nav bar
            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyIcon.topAnchor.constraint(equalTo: emptyView.topAnchor),
            emptyIcon.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 60),
            emptyIcon.heightAnchor.constraint(equalToConstant: 60),

            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 14),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),

            emptySubLabel.topAnchor.constraint(equalTo: emptyLabel.bottomAnchor, constant: 6),
            emptySubLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptySubLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 30),
            emptySubLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -30),
            emptySubLabel.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Fetch
    private func fetchHistory() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listener?.remove()
        activityIndicator.startAnimating()

        let collection: String
        switch role {
        case .therapist: collection = "bookedSessions"
        case .patient:   collection = "mySessions"
        }

        listener = db.collection("users")
            .document(uid)
            .collection(collection)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()

                if let error = error {
                    print("SessionHistoryVC fetch error:", error.localizedDescription)
                    return
                }

                let now = Date()
                self.sessions = (snapshot?.documents.map { $0.data() } ?? [])
                    .filter { session in
                        guard (session["status"] as? String) == "confirmed" else { return false }
                        guard let ts       = session["sessionDateTime"] as? Timestamp else { return false }
                        let duration       = session["duration"] as? Int ?? 45
                        let sessionStart   = ts.dateValue()
                        let sessionEnd     = sessionStart.addingTimeInterval(TimeInterval(duration * 60))
                        return sessionEnd <= now
                    }
                    .sorted {
                        let a = ($0["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantPast
                        let b = ($1["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantPast
                        return a > b
                    }

                DispatchQueue.main.async {
                    let count = self.sessions.count
                    self.countLabel.text    = count > 0 ? "\(count) completed" : ""
                    self.emptyView.isHidden = !self.sessions.isEmpty
                    self.tableView.isHidden = self.sessions.isEmpty
                    self.tableView.reloadData()
                }
            }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SessionHistoryVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SessionHistoryCell.reuseID, for: indexPath) as! SessionHistoryCell
        cell.configure(with: sessions[indexPath.row], role: role)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        200
    }
}

// MARK: - SessionHistoryCell
class SessionHistoryCell: UITableViewCell {
    static let reuseID = "SessionHistoryCell"

    // MARK: - UI
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor    = .white.withAlphaComponent(0.9)
        v.layer.cornerRadius  = 20
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset  = CGSize(width: 0, height: 3)
        v.layer.shadowRadius  = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let completedBanner: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor(hex: "#4FC3D8").withAlphaComponent(0.12)
        v.layer.cornerRadius  = 20
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let completedBadge: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor(hex: "#4FC3D8").withAlphaComponent(0.18)
        v.layer.cornerRadius  = 10
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let completedIcon: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: config))
        iv.tintColor = UIColor(hex: "#4FC3D8")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let completedLabel: UILabel = {
        let lbl = UILabel()
        lbl.text      = "Completed"
        lbl.font      = UIFont.systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = UIColor(hex: "#4FC3D8")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font      = UIFont.systemFont(ofSize: 17, weight: .bold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#D6EEF5")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let personRow = SessionHistoryCell.makeInfoRow(icon: "person.fill")
    private let dateRow   = SessionHistoryCell.makeInfoRow(icon: "calendar")
    private let timeRow   = SessionHistoryCell.makeInfoRow(icon: "clock")
    private let typeRow   = SessionHistoryCell.makeInfoRow(icon: "video.fill")

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        buildLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildLayout() {
        completedBadge.addSubview(completedIcon)
        completedBadge.addSubview(completedLabel)
        completedBanner.addSubview(completedBadge)
        completedBanner.addSubview(titleLabel)

        let infoStack = UIStackView(arrangedSubviews: [personRow, dateRow, timeRow, typeRow])
        infoStack.axis    = .vertical
        infoStack.spacing = 10
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        [completedBanner, divider, infoStack].forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            completedBanner.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 5),
            completedBanner.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -70),

            completedBadge.topAnchor.constraint(equalTo: completedBanner.topAnchor, constant: 14),
            completedBadge.centerXAnchor.constraint(equalTo: completedBanner.centerXAnchor),
            completedBadge.heightAnchor.constraint(equalToConstant: 22),

            completedIcon.leadingAnchor.constraint(equalTo: completedBadge.leadingAnchor, constant: 8),
            completedIcon.centerYAnchor.constraint(equalTo: completedBadge.centerYAnchor),
            completedIcon.widthAnchor.constraint(equalToConstant: 13),
            completedIcon.heightAnchor.constraint(equalToConstant: 13),

            completedLabel.leadingAnchor.constraint(equalTo: completedIcon.trailingAnchor, constant: 4),
            completedLabel.trailingAnchor.constraint(equalTo: completedBadge.trailingAnchor, constant: -8),
            completedLabel.centerYAnchor.constraint(equalTo: completedBadge.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.bottomAnchor.constraint(equalTo: completedBanner.bottomAnchor, constant: -14),

            divider.topAnchor.constraint(equalTo: completedBanner.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 1),

            infoStack.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14),
            infoStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            infoStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18)
        ])
    }

    private static func makeInfoRow(icon: String) -> UIStackView {
        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor   = UIColor(hex: "#4FC3D8")
        img.contentMode = .scaleAspectFit
        img.widthAnchor.constraint(equalToConstant: 16).isActive  = true
        img.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let lbl = UILabel()
        lbl.font      = UIFont.systemFont(ofSize: 16, weight: .medium)
        lbl.textColor = UIColor(hex: "#1A3A45")

        let row = UIStackView(arrangedSubviews: [img, lbl])
        row.axis      = .horizontal
        row.spacing   = 10
        row.alignment = .center
        return row
    }

    private func rowLabel(_ row: UIStackView) -> UILabel? {
        row.arrangedSubviews.compactMap { $0 as? UILabel }.first
    }

    private func rowIcon(_ row: UIStackView) -> UIImageView? {
        row.arrangedSubviews.compactMap { $0 as? UIImageView }.first
    }

    // MARK: - Configure
    func configure(with session: [String: Any], role: SessionHistoryVC.UserRole) {
        let type     = session["sessionType"] as? String ?? "Video"
        let duration = session["duration"]    as? Int    ?? 45

        switch role {
        case .patient:
            let name = session["therapistName"] as? String ?? "Therapist"
            rowLabel(personRow)?.text = "Dr. \(name)"
            rowIcon(personRow)?.image = UIImage(systemName: "stethoscope")
            titleLabel.text = "Past Session"
        case .therapist:
            let name = session["patientName"] as? String ?? "Patient"
            rowLabel(personRow)?.text = name
            rowIcon(personRow)?.image = UIImage(systemName: "person.fill")
            titleLabel.text = "Completed Session"
        }

        rowLabel(typeRow)?.text = "\(type)  •  \(duration) min"
        switch type {
        case "Audio": rowIcon(typeRow)?.image = UIImage(systemName: "phone.fill")
        case "Chat":  rowIcon(typeRow)?.image = UIImage(systemName: "bubble.left.fill")
        default:      rowIcon(typeRow)?.image = UIImage(systemName: "video.fill")
        }

        if let ts = session["sessionDateTime"] as? Timestamp {
            let date = ts.dateValue()
            let df   = DateFormatter()

            df.dateFormat = "dd MMM, yyyy"
            rowLabel(dateRow)?.text = df.string(from: date)

            df.dateFormat = "h:mm a"
            let start = df.string(from: date)
            let end   = df.string(from: date.addingTimeInterval(TimeInterval(duration * 60)))
            rowLabel(timeRow)?.text = "\(start) – \(end)"
        }
    }
}
