//
//  ClientSessionsVCViewController.swift
//  HealSync
//
//  Created by Arfa on 10/02/2026.
//


import UIKit
import FirebaseFirestore
import FirebaseAuth

class ClientSessionsVC: UIViewController {

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var sessions: [[String: Any]] = []
    private var sessionsListener: ListenerRegistration?
    private var countdownTimer: Timer?

    // MARK: - UI
    private let bgColor = UIColor(hex: "#D1F0F8")

    private let headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "My Sessions"
        lbl.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textColor = .black
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
        lbl.text = "Book a session with a therapist to get started"
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let bookNowButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Book Now", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        btn.backgroundColor = UIColor(hex: "#4FC3D8")
        btn.layer.cornerRadius = 10
        btn.layer.shadowColor = UIColor(hex: "#4FC3D8").cgColor
        btn.layer.shadowOpacity = 0.35
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowRadius = 4
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
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
    
    @objc private func bookNowTapped() {
           // Switch to the Therapists tab (index 1) in the tab bar
           if let tabBar = tabBarController {
               tabBar.selectedIndex = 2
           }
       }

    // MARK: - Layout
    private func setupLayout() {
        emptyView.addSubview(emptyIcon)
        emptyView.addSubview(emptyLabel)
        emptyView.addSubview(emptySubLabel)
        emptyView.addSubview(bookNowButton)
        bookNowButton.addTarget(self, action: #selector(bookNowTapped), for: .touchUpInside)

        [headerLabel, countLabel, tableView, emptyView, activityIndicator].forEach {
            view.addSubview($0)
        }

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(ClientSessionCell.self, forCellReuseIdentifier: ClientSessionCell.reuseID)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            countLabel.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
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

            bookNowButton.topAnchor.constraint(equalTo: emptySubLabel.bottomAnchor, constant: 24),
            bookNowButton.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            bookNowButton.heightAnchor.constraint(equalToConstant: 48),
            bookNowButton.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor),
            

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Fetch
    func fetchSessions() {
        guard let patientId = Auth.auth().currentUser?.uid else { return }
        sessionsListener?.remove()
        sessionsListener = nil
        activityIndicator.startAnimating()

        sessionsListener = db.collection("users")
            .document(patientId)
            .collection("mySessions")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()

                if let error = error {
                    print("Error fetching sessions:", error.localizedDescription); return
                }

                let now = Date()
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
                    self.countLabel.text    = count > 0 ? "\(count) upcoming" : ""
                    self.emptyView.isHidden = !self.sessions.isEmpty
                    self.tableView.isHidden = self.sessions.isEmpty
                    self.tableView.reloadData()
                    self.startCountdownTimer()
                }
            }
    }

    // MARK: - Countdown Timer
    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.tableView.visibleCells
                .compactMap { $0 as? ClientSessionCell }
                .forEach { $0.refreshCountdown() }
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
    }

    // MARK: - Join Session routing

    private func handleJoinSession(_ session: [String: Any]) {
        guard let patientId      = Auth.auth().currentUser?.uid,
              let bookingId      = session["bookingId"]      as? String,
              let therapistId    = session["therapistId"]    as? String,
              let therapistName  = session["therapistName"]  as? String,
              let patientName    = session["patientName"]    as? String,
              let sessionType    = session["sessionType"]    as? String else { return }

        switch sessionType {

        case "Chat":
            ChatService.shared.getOrCreateSessionChat(
                bookingId:     bookingId,
                patientId:     patientId,
                patientName:   patientName,
                therapistId:   therapistId,
                therapistName: therapistName
            ) { [weak self] chatId in
                DispatchQueue.main.async {
                    let vc = ChatVC(
                        chatId:          chatId,
                        otherUserId:     therapistId,
                        otherName:       therapistName,
                        chatType:        .session,
                        currentUserName: patientName
                    )
                    vc.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }

        case "Audio":
            DispatchQueue.main.async { [weak self] in
                let vc = AudioCallVC()
                vc.bookingId      = bookingId
                vc.therapistId    = therapistId
                vc.therapistName  = therapistName
                vc.patientId      = patientId
                vc.patientName    = patientName
                vc.modalPresentationStyle = .fullScreen
                vc.modalTransitionStyle   = .crossDissolve
                self?.present(vc, animated: true)
            }

        case "Video":
            DispatchQueue.main.async { [weak self] in
                let vc = VideoCallVC()
                vc.bookingId      = bookingId
                vc.therapistId    = therapistId
                vc.therapistName  = therapistName
                vc.patientId      = patientId
                vc.patientName    = patientName
                vc.modalPresentationStyle = .fullScreen
                vc.modalTransitionStyle   = .crossDissolve
                self?.present(vc, animated: true)
            }

        default:
            break
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func cancelSession(for session: [String: Any]) {
        guard let therapistId     = session["therapistId"]      as? String,
              let sessionTimestamp = session["sessionDateTime"]  as? Timestamp,
              let patientId        = Auth.auth().currentUser?.uid else { return }

        let sessionDate    = sessionTimestamp.dateValue()
        let hoursUntil     = sessionDate.timeIntervalSinceNow / 3600

        // ── Feature 2: 24-hour non-refundable policy ──────────────────────
        if hoursUntil < 24 {
            let lockAlert = UIAlertController(
                title: "Cannot Cancel",
                message: hoursUntil <= 0
                    ? "This session has already started or passed."
                    : "Sessions cannot be cancelled within 24 hours of the start time. This session is non-refundable.",
                preferredStyle: .alert
            )
            lockAlert.addAction(UIAlertAction(title: "OK", style: .default))
            present(lockAlert, animated: true)
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH:mm"
        let slotId = formatter.string(from: sessionDate)

        let alert = UIAlertController(
            title: "Cancel Session",
            message: "Are you sure you want to cancel? Since it's more than 24 hours away, a full refund will be initiated.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Keep Session", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cancel & Refund", style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            let therapistRef = self.db.collection("users")
                .document(therapistId).collection("bookedSessions").document(slotId)
            let patientRef = self.db.collection("users")
                .document(patientId).collection("mySessions").document(slotId)

            let batch = self.db.batch()
            batch.updateData([
                "status":      "cancelled",
                "cancelledBy": "patient",
                "cancelledAt": Timestamp(date: Date()),
                "refundStatus": "initiated"
            ], forDocument: patientRef)
            batch.updateData([
                "status":      "cancelled",
                "cancelledBy": "patient",
                "cancelledAt": Timestamp(date: Date())
            ], forDocument: therapistRef)

            batch.commit { error in
                if let error = error { print("Cancel failed:", error.localizedDescription); return }
                notifyUser(userId: patientId,        session: session, type: .cancelled)
                saveTherapistNotification(therapistId: therapistId, session: session, type: .cancelled)
            }
        })
        present(alert, animated: true)
    }

    // ── Feature 4: Reschedule ─────────────────────────────────────────────
    func rescheduleSession(for session: [String: Any]) {
        guard let therapistId     = session["therapistId"]      as? String,
              let sessionTimestamp = session["sessionDateTime"]  as? Timestamp else { return }

        let sessionDate = sessionTimestamp.dateValue()
        let hoursUntil  = sessionDate.timeIntervalSinceNow / 3600

        if hoursUntil < 24 {
            let alert = UIAlertController(
                title: "Cannot Reschedule",
                message: "Sessions can only be rescheduled more than 24 hours before the start time.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let rescheduleCount = session["rescheduleCount"] as? Int ?? 0
        if rescheduleCount >= 2 {
            let alert = UIAlertController(
                title: "Reschedule Limit Reached",
                message: "Sessions can only be rescheduled up to 2 times.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Fetch the therapist object then open BookingSessionVC in reschedule mode
        let db = Firestore.firestore()
        db.collection("users").document(therapistId).getDocument { [weak self] snap, error in
            guard let self = self, let snap = snap else { return }

            guard let therapist = Therapist(document: snap) else { return }

            DispatchQueue.main.async {
                let bookingVC = BookingSessionVC(therapist: therapist)
                bookingVC.rescheduleSession        = session
                bookingVC.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(bookingVC, animated: true)
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ClientSessionsVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ClientSessionCell.reuseID, for: indexPath) as! ClientSessionCell
        let session = sessions[indexPath.row]
        cell.configure(with: session, isFirst: indexPath.row == 0)
        cell.onJoin = { [weak self] in
            self?.handleJoinSession(session)
        }
        cell.onCancel = { [weak self] in
            self?.cancelSession(for: session)
        }
        cell.onReschedule = { [weak self] in
            self?.rescheduleSession(for: session)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        230
    }
}

// MARK: - ClientSessionCell
class ClientSessionCell: UITableViewCell {
    static let reuseID = "ClientSessionCell"

    var onJoin:       (() -> Void)?
    var onCancel:     (() -> Void)?
    var onReschedule: (() -> Void)?
    private var sessionDate:     Date?
    private var sessionDuration: Int = 45

    // MARK: - UI — identical structure to UpcomingSessionCell
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.9)
        v.layer.cornerRadius  = 20
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

    // Info rows — same factory as therapist card
    private let therapistRow = ClientSessionCell.makeInfoRow(icon: "stethoscope")
    private let dateRow      = ClientSessionCell.makeInfoRow(icon: "calendar")
    private let timeRow      = ClientSessionCell.makeInfoRow(icon: "clock")
    private let typeRow      = ClientSessionCell.makeInfoRow(icon: "video.fill")

    private let joinButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("JOIN SESSION", for: .normal)
        btn.setTitleColor(UIColor(hex: "#1A5C2A"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        btn.backgroundColor  = UIColor(hex: "#A3E8AB")
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("CANCEL", for: .normal)
        btn.setTitleColor(UIColor(hex: "#7B1C1C"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        btn.backgroundColor  = UIColor(hex: "#F5C6C6")
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let rescheduleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("RESCHEDULE", for: .normal)
        btn.setTitleColor(UIColor(hex: "#1A3A45"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        btn.backgroundColor  = UIColor(hex: "#CBE9F1")
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

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        contentView.addSubview(cardView)

        let infoStack = UIStackView(arrangedSubviews: [therapistRow, dateRow, timeRow, typeRow])
        infoStack.axis    = .vertical
        infoStack.spacing = 10
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        // Join | Cancel row + Reschedule below
        let topBtnStack = UIStackView(arrangedSubviews: [joinButton, cancelButton])
        topBtnStack.axis         = .horizontal
        topBtnStack.spacing      = 12
        topBtnStack.distribution = .fillEqually
        topBtnStack.translatesAutoresizingMaskIntoConstraints = false

        let btnStack = UIStackView(arrangedSubviews: [topBtnStack, rescheduleButton])
        btnStack.axis    = .vertical
        btnStack.spacing = 8
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        [titleLabel, divider, infoStack, btnStack, countdownLabel].forEach { cardView.addSubview($0) }

        joinButton.addTarget(self,       action: #selector(joinTapped),       for: .touchUpInside)
        cancelButton.addTarget(self,     action: #selector(cancelTapped),     for: .touchUpInside)
        rescheduleButton.addTarget(self, action: #selector(rescheduleTapped), for: .touchUpInside)

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

            topBtnStack.heightAnchor.constraint(equalToConstant: 44),
            rescheduleButton.heightAnchor.constraint(equalToConstant: 40),

            countdownLabel.topAnchor.constraint(equalTo: btnStack.bottomAnchor, constant: 8),
            countdownLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            countdownLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Factory — identical to therapist's makeInfoRow
    private static func makeInfoRow(icon: String) -> UIStackView {
        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor    = UIColor(hex: "#4FC3D8")
        img.contentMode  = .scaleAspectFit
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
    func configure(with session: [String: Any], isFirst: Bool) {
        titleLabel.text = isFirst ? "Your Next Session" : "Other Upcoming Session"

        let therapistName = session["therapistName"] as? String ?? "Therapist"
        let type          = session["sessionType"]   as? String ?? "Video"
        let duration      = session["duration"]      as? Int    ?? 45
        sessionDuration   = duration

        rowLabel(therapistRow)?.text = "Dr. \(therapistName)"
        rowLabel(typeRow)?.text      = "\(type)  •  \(duration) min"

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

    // MARK: - Countdown — identical logic to therapist card
    func refreshCountdown() {
        guard let date = sessionDate else { return }
        let secondsUntil = date.timeIntervalSinceNow
        let minutesUntil = secondsUntil / 60
        let canJoin      = minutesUntil <= 10 && minutesUntil > -TimeInterval(sessionDuration)

        joinButton.isEnabled       = canJoin
        joinButton.alpha           = canJoin ? 1.0 : 0.5
        joinButton.backgroundColor = canJoin ? UIColor(hex: "#A3E8AB") : UIColor(hex: "#D8D8D8")
        
        cancelButton.isEnabled       = !canJoin
        cancelButton.alpha           = canJoin ? 0.4 : 1.0
        cancelButton.backgroundColor = canJoin ? UIColor(hex: "#E0E0E0") : UIColor(hex: "#F5C6C6")

        // Reschedule only allowed > 24hrs before session
        let canReschedule            = secondsUntil > (24 * 3600)
        rescheduleButton.isEnabled   = canReschedule
        rescheduleButton.alpha       = canReschedule ? 1.0 : 0.4
        rescheduleButton.backgroundColor = canReschedule ? UIColor(hex: "#CBE9F1") : UIColor(hex: "#E0E0E0")

        if canJoin {
            countdownLabel.text      = "Session is ready to join"
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

    @objc private func joinTapped()       { onJoin?() }
    @objc private func cancelTapped()     { onCancel?() }
    @objc private func rescheduleTapped() { onReschedule?() }
}
