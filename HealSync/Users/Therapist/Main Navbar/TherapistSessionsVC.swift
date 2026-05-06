//
//  TherapistSessionsVC.swift
//  HealSync
//
//  Created by Arfa on 13/03/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class TherapistSessionsVC: UIViewController {

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var sessions:          [[String: Any]] = []
    private var sessionsListener:  ListenerRegistration?
    private var countdownTimer:    Timer?
    private let currentTherapistId   = Auth.auth().currentUser?.uid ?? ""
    private var currentTherapistName = ""

    // MARK: - UI
    private let bgColor = UIColor(hex: "#D1F0F8")

    private let headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Upcoming Sessions"
        lbl.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        lbl.textColor = .black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
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
        let iv = UIImageView(image: UIImage(systemName: "calendar.badge.clock", withConfiguration: config))
        iv.tintColor = UIColor(hex: "#4FC3D8").withAlphaComponent(0.6)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No upcoming sessions"
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let emptySubLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Your confirmed sessions will appear here"
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // Restart listener every time the tab becomes visible
        // so new bookings and cancellations always reflect immediately
        fetchSessions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        sessionsListener?.remove()
        sessionsListener = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    deinit {
        sessionsListener?.remove()
        countdownTimer?.invalidate()
    }

    // MARK: - Layout
    private func setupLayout() {
        [headerLabel, countLabel, tableView, emptyView, activityIndicator].forEach {
            view.addSubview($0)
        }

        emptyView.addSubview(emptyIcon)
        emptyView.addSubview(emptyLabel)
        emptyView.addSubview(emptySubLabel)

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(UpcomingSessionCell.self, forCellReuseIdentifier: UpcomingSessionCell.reuseID)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            countLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            countLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            tableView.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 16),
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

    // MARK: - Countdown Timer
    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Refresh visible cells' countdown labels without full reload
            self.tableView.visibleCells
                .compactMap { $0 as? UpcomingSessionCell }
                .forEach { $0.refreshCountdown() }
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
    }

    // MARK: - Fetch
    private func fetchSessions() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // Always tear down existing listener before creating a fresh one
        sessionsListener?.remove()
        sessionsListener = nil
        activityIndicator.startAnimating()

        sessionsListener = db.collection("users").document(uid)
            .collection("bookedSessions")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()

                if let error = error {
                    print("❌ Sessions error: \(error.localizedDescription)"); return
                }

                let now = Date()
                // Only show confirmed + future sessions — filter fully in-memory

                self.sessions = (snapshot?.documents.map { $0.data() } ?? [])
                    .filter { session in
                        let status   = session["status"]          as? String ?? ""
                        let dt       = (session["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantPast
                        let duration = session["duration"]         as? Int    ?? 45
                        let endTime  = dt.addingTimeInterval(TimeInterval(duration * 60))
                        return status == "confirmed" && endTime > now   // ← keep until session ends
                    }
                    .sorted {
                        let a = ($0["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantFuture
                        let b = ($1["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantFuture
                        return a < b
                    }

                DispatchQueue.main.async {
                    let count = self.sessions.count
                    self.countLabel.text    = "\(count) session\(count == 1 ? "" : "s") scheduled"
                    self.emptyView.isHidden = !self.sessions.isEmpty
                    self.tableView.isHidden = self.sessions.isEmpty
                    self.tableView.reloadData()
                    self.startCountdownTimer()
                }
            }
    }
    // MARK: - Start Session routing

    private func handleStartSession(_ session: [String: Any]) {
        guard let patientId      = session["patientId"]     as? String,
              let bookingId      = session["bookingId"]      as? String,
              let patientName    = session["patientName"]    as? String,
              let sessionType    = session["sessionType"]    as? String else { return }

        switch sessionType {

        case "Chat":
            ChatService.shared.getOrCreateSessionChat(
                bookingId:     bookingId,
                patientId:     patientId,
                patientName:   patientName,
                therapistId:   currentTherapistId,
                therapistName: currentTherapistName
            ) { [weak self] chatId in
                DispatchQueue.main.async {
                    let vc = ChatVC(
                        chatId:          chatId,
                        otherUserId:     patientId,
                        otherName:       patientName,
                        chatType:        .session,
                        currentUserName:  self!.currentTherapistName
                    
                    )
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }

        case "Audio":
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }         
                let vc = AudioCallVC()
                vc.bookingId      = bookingId
                vc.therapistId    = self.currentTherapistId
                vc.therapistName  = self.currentTherapistName
                vc.patientId      = patientId
                vc.patientName    = patientName
                vc.isTherapist    = true
                vc.modalPresentationStyle = .fullScreen
                vc.modalTransitionStyle   = .crossDissolve
                self.present(vc, animated: true)
            }

        case "Video":
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let vc = VideoCallVC()
                vc.bookingId      = bookingId
                vc.therapistId    = self.currentTherapistId
                vc.therapistName  = self.currentTherapistName
                vc.patientId      = patientId
                vc.patientName    = patientName
                vc.isTherapist    = true   
                vc.modalPresentationStyle = .fullScreen
                vc.modalTransitionStyle   = .crossDissolve
                self.present(vc, animated: true)
            }

        default:
            break
        }
    }

    private func showSessionAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension TherapistSessionsVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UpcomingSessionCell.reuseID, for: indexPath) as! UpcomingSessionCell
        let session = sessions[indexPath.row]
        cell.configure(with: session, isFirst: indexPath.row == 0)
        cell.onStartSession = { [weak self] in
            self?.handleStartSession(session)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 210 }
}

// MARK: - UpcomingSessionCell
class UpcomingSessionCell: UITableViewCell {
    static let reuseID = "UpcomingSessionCell"

    var onStartSession: (() -> Void)?
    private var sessionDate: Date?
    private var sessionDuration: Int = 45

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.9)
        v.layer.cornerRadius = 20
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset  = CGSize(width: 0, height: 3)
        v.layer.shadowRadius  = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
        return lbl
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#D6EEF5")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Info rows
    private let nameRow = UpcomingSessionCell.makeInfoRow(icon: "person.fill")
    private let dateRow = UpcomingSessionCell.makeInfoRow(icon: "calendar")
    private let timeRow = UpcomingSessionCell.makeInfoRow(icon: "clock")
    private let typeRow = UpcomingSessionCell.makeInfoRow(icon: "video.fill")

    private let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("START SESSION", for: .normal)
        btn.setTitleColor(UIColor(hex: "#1A5C2A"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        btn.backgroundColor = UIColor(hex: "#A3E8AB")
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()



    private let countdownLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        contentView.addSubview(cardView)

        let infoStack = UIStackView(arrangedSubviews: [nameRow, dateRow, timeRow, typeRow])
        infoStack.axis    = .vertical
        infoStack.spacing = 10
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        let btnStack = UIStackView(arrangedSubviews: [startButton])
        btnStack.axis         = .horizontal
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        [titleLabel, divider, infoStack, btnStack, countdownLabel].forEach { cardView.addSubview($0) }

        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            divider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            divider.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            divider.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            divider.heightAnchor.constraint(equalToConstant: 1),

            infoStack.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14),
            infoStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            btnStack.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 18),
            btnStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            btnStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            btnStack.heightAnchor.constraint(equalToConstant: 44),

            countdownLabel.topAnchor.constraint(equalTo: btnStack.bottomAnchor, constant: 8),
            countdownLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            countdownLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Factory
    private static func makeInfoRow(icon: String) -> UIStackView {
        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = UIColor(hex: "#4FC3D8")
        img.contentMode = .scaleAspectFit
        img.widthAnchor.constraint(equalToConstant: 16).isActive = true
        img.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        lbl.textColor = UIColor(hex: "#1A3A45")

        let row = UIStackView(arrangedSubviews: [img, lbl])
        row.axis = .horizontal
        row.spacing = 10
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
    func configure(with session: [String: Any], isFirst: Bool) {
        titleLabel.text = isFirst ? "Your Next Session" : "Other Upcoming Session"

        let patientName = session["patientName"] as? String ?? "Patient"
        let type        = session["sessionType"] as? String ?? "Video"
        let duration    = session["duration"]    as? Int    ?? 45

        sessionDuration = duration

        rowLabel(nameRow)?.text = patientName
        rowLabel(typeRow)?.text = "\(type)  •  \(duration) min"

        switch type {
        case "Audio": rowIcon(typeRow)?.image = UIImage(systemName: "phone.fill")
        case "Chat":  rowIcon(typeRow)?.image = UIImage(systemName: "bubble.left.fill")
        default:      rowIcon(typeRow)?.image = UIImage(systemName: "video.fill")
        }

        if let ts = session["sessionDateTime"] as? Timestamp {
            let date = ts.dateValue()
            sessionDate = date

            let df = DateFormatter()
            df.dateFormat = "dd MMM , yyyy"
            rowLabel(dateRow)?.text = df.string(from: date)

            df.dateFormat = "h:mm a"
            let start = df.string(from: date)
            let end   = df.string(from: date.addingTimeInterval(TimeInterval(duration * 60)))
            rowLabel(timeRow)?.text = "\(start) - \(end)"
        }

        refreshCountdown()
    }

    // MARK: - Countdown (called by configure + timer every minute)
    func refreshCountdown() {
        guard let date = sessionDate else { return }
        let secondsUntil = date.timeIntervalSinceNow
        let minutesUntil = secondsUntil / 60
        let canStart     = minutesUntil <= 10 && minutesUntil > -TimeInterval(sessionDuration)

        startButton.isEnabled       = canStart
        startButton.alpha           = canStart ? 1.0 : 0.5
        startButton.backgroundColor = canStart ? UIColor(hex: "#A3E8AB") : UIColor(hex: "#D8D8D8")

        if canStart {
            countdownLabel.text      = "Session is ready to start"
            countdownLabel.textColor = UIColor(hex: "#1A5C2A")
        } else if secondsUntil > 0 {
            let totalMinutes = Int(minutesUntil)
            let days  = totalMinutes / (60 * 24)
            let hours = (totalMinutes % (60 * 24)) / 60
            let mins  = totalMinutes % 60

            if days >= 1 {
                countdownLabel.text = "\(days) day\(days > 1 ? "s" : "") : \(hours) hr"
            } else if hours >= 1 {
                countdownLabel.text = "\(hours) hr : \(String(format: "%02d", mins)) min"
            } else {
                countdownLabel.text = "\(mins) min"
            }
            countdownLabel.textColor = .systemGray
        } else {
            countdownLabel.text = ""
        }
    }

    @objc private func startTapped() { onStartSession?() }
}
