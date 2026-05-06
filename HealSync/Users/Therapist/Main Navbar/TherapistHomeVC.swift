//
//  TherapistHomeVC.swift
//  HealSync
//
//  Created by Arfa on 13/03/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class TherapistHomeVC: UIViewController {

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var notificationsListener: ListenerRegistration?

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var greetingLabel = TitleLabel(text: "Greetings", fontSize: 20)
    private let notificationBadge = UILabel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#D1F0F8")
        setupScrollView()
        setupContent()
        fetchUpcomingSession()

        // Fetch therapist name for greeting
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self = self, let data = snapshot?.data(),
                  let fullName = data["fullName"] as? String else { return }
            DispatchQueue.main.async {
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
                self.greetingLabel.text = "Greetings, \(firstName)!"
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchUpcomingSession()
        listenForNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore nav bar for any pushed VC (e.g. NotificationsVC) so back button is visible
        navigationController?.setNavigationBarHidden(true, animated: animated)
        notificationsListener?.remove()
    }

    // MARK: - Scroll View Setup
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 30

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: -50),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 25),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -25),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -50)
        ])
    }

    // MARK: - Content Setup
    private func setupContent() {
        contentStack.addArrangedSubview(createGreetingCard())

        // Placeholder for upcoming session card (replaced dynamically)
        let placeholder = UIView()
        placeholder.tag = 999
        contentStack.insertArrangedSubview(placeholder, at: 1)

        contentStack.addArrangedSubview(createQuickActionsCard())
    }

    // MARK: - Fetch Upcoming Sessions
    private var sessionsListener: ListenerRegistration?

    private func fetchUpcomingSession() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        sessionsListener?.remove()

        sessionsListener = db.collection("users")
            .document(uid)
            .collection("bookedSessions")
            .whereField("status", isEqualTo: "confirmed")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Session fetch error: \(error.localizedDescription)")
                }


                let now = Date()
                let upcoming = (snapshot?.documents ?? [])
                    .map { $0.data() }
                    .filter { session in
                        guard let ts = session["sessionDateTime"] as? Timestamp else { return false }
                        return ts.dateValue() > now
                    }
                    .sorted {
                        let a = ($0["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantFuture
                        let b = ($1["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantFuture
                        return a < b
                    }
                    .prefix(2)
                    .map { $0 }


                DispatchQueue.main.async {
                    if let index = self.contentStack.arrangedSubviews.firstIndex(where: { $0.tag == 999 }) {
                        let old = self.contentStack.arrangedSubviews[index]
                        self.contentStack.removeArrangedSubview(old)
                        old.removeFromSuperview()
                    }
                    let card = upcoming.isEmpty
                        ? self.createNoSessionCard()
                        : self.createUpcomingSessionCard(sessions: upcoming)
                    card.tag = 999
                    self.contentStack.insertArrangedSubview(card, at: 1)
                }
            }
    }

    // MARK: - Notifications Listener
    private func listenForNotifications() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        notificationsListener = db.collection("users").document(uid)
            .collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, _ in
                DispatchQueue.main.async {
                    let count = snapshot?.documents.count ?? 0
                    if count == 0 {
                        self?.notificationBadge.isHidden = true
                    } else {
                        self?.notificationBadge.isHidden = false
                        self?.notificationBadge.text = count > 99 ? "99+" : "\(count)"
                        self?.notificationBadge.font = .systemFont(ofSize: count > 99 ? 8 : 10, weight: .semibold)
                    }
                }
            }
    }

    // MARK: - Greeting Card
    private func createGreetingCard() -> UIView {
        let card = BaseContainer(opacity: 0.9)

        greetingLabel.textAlignment = .left

        let subtitle = SubtitleLabel(
            text: "Your practice. Your impact.\nPowered by HealSync",
            noOfLines: 2,
            fontSize: 14
        )
        subtitle.textAlignment = .left

        let bell = UIButton(type: .system)
        bell.setImage(UIImage(systemName: "bell"), for: .normal)
        bell.tintColor = .gray
        bell.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [greetingLabel, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 5

        let hStack = UIStackView(arrangedSubviews: [textStack, bell])
        hStack.axis = .horizontal
        hStack.alignment = .top
        hStack.distribution = .equalSpacing
        hStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -30)
        ])

        // Notification badge
        notificationBadge.backgroundColor = .systemRed
        notificationBadge.textColor = .white
        notificationBadge.font = .systemFont(ofSize: 10, weight: .semibold)
        notificationBadge.textAlignment = .center
        notificationBadge.layer.cornerRadius = 10
        notificationBadge.clipsToBounds = true
        notificationBadge.isHidden = true
        notificationBadge.minimumScaleFactor = 0.5
        notificationBadge.adjustsFontSizeToFitWidth = true
        notificationBadge.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(notificationBadge)

        NSLayoutConstraint.activate([
            notificationBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            notificationBadge.heightAnchor.constraint(equalToConstant: 20),
            notificationBadge.topAnchor.constraint(equalTo: bell.topAnchor, constant: -5),
            notificationBadge.trailingAnchor.constraint(equalTo: bell.trailingAnchor, constant: 5)
        ])

        return card
    }

    // MARK: - Upcoming Session Card (with sessions)
    private func createUpcomingSessionCard(sessions: [[String: Any]]) -> UIView {
        let card = BaseContainer(opacity: 0.9)

        let title = TitleLabel(text: "Your Upcoming Session", fontSize: 21)
        title.textAlignment = .left

        let sessionRowsStack = UIStackView()
        sessionRowsStack.axis = .vertical
        sessionRowsStack.spacing = 12
        sessionRowsStack.translatesAutoresizingMaskIntoConstraints = false

        for session in sessions {
            let row = makeSessionRow(session: session)
            sessionRowsStack.addArrangedSubview(row)
        }

        let mainStack = UIStackView(arrangedSubviews: [title, sessionRowsStack])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -24)
        ])

        return card
    }

    private func makeSessionRow(session: [String: Any]) -> UIView {
        let patientName  = session["patientName"]  as? String ?? "Patient"
        let slot         = session["slot"]         as? String ?? "--"
        let sessionType  = session["sessionType"]  as? String ?? ""

        // Determine "Today" / "Tomorrow" / date label
        var dayLabel = "--"
        if let ts = session["sessionDateTime"] as? Timestamp {
            let date = ts.dateValue()
            let cal  = Calendar.current
            if cal.isDateInToday(date)     { dayLabel = "Today" }
            else if cal.isDateInTomorrow(date) { dayLabel = "Tomorrow" }
            else {
                let f = DateFormatter(); f.dateFormat = "dd MMM"
                dayLabel = f.string(from: date)
            }
        }

        let leftLabel = UILabel()
        leftLabel.text = "\(slot)  –  \(patientName)"
        leftLabel.font = .systemFont(ofSize: 15)
        leftLabel.textColor = UIColor(hex: "#1A3A45")

        let tagLabel = UILabel()
        tagLabel.text = sessionType.isEmpty ? dayLabel : "\(sessionType)  ·  \(dayLabel)"
        tagLabel.font = .systemFont(ofSize: 13)
        tagLabel.textColor = .systemGray

        let row = UIStackView(arrangedSubviews: [leftLabel, tagLabel])
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        return row
    }

    // MARK: - No Session Card
    private func createNoSessionCard() -> UIView {
        let card = BaseContainer(opacity: 0.9)

        let title    = TitleLabel(text: "No Upcoming Sessions", fontSize: 21)
        let subtitle = SubtitleLabel(
            text: "You have no sessions scheduled.\nYour availability is live for patients to book.",
            noOfLines: 3,
            fontSize: 15
        )

        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -30)
        ])

        return card
    }

    // MARK: - Quick Actions Card
    private func createQuickActionsCard() -> UIView {
        let card = BaseContainer(opacity: 0.9)

        let title = TitleLabel(text: "Quick Actions", fontSize: 21)
        title.textAlignment = .left

        let scheduleBtn = makeOutlineButton(title: " Manage Schedule", icon: "calendar.badge.clock")
        scheduleBtn.addTarget(self, action: #selector(manageScheduleTapped), for: .touchUpInside)

        let historyBtn = makeOutlineButton(title: "Session History", icon: "clock.arrow.circlepath")
        historyBtn.addTarget(self, action: #selector(sessionHistoryTapped), for: .touchUpInside)

        let btnStack = UIStackView(arrangedSubviews: [scheduleBtn, historyBtn])
        btnStack.axis = .vertical
        btnStack.spacing = 15

        let mainStack = UIStackView(arrangedSubviews: [title, btnStack])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
        ])

        return card
    }

    private func makeOutlineButton(title: String, icon: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.baseForegroundColor = UIColor(hex: "#1A3A45")
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 13, weight: .semibold); return a
        }
        let btn = UIButton(configuration: config)
        btn.backgroundColor = UIColor(hex: "#74D6EA")
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        return btn
    }

    // MARK: - Actions
    @objc private func openNotifications() {
        let vc = NotificationsVC()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func manageScheduleTapped() {
        let vc = TherapistSchedulingVC()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func sessionHistoryTapped() {
        let vc = SessionHistoryVC(role: .therapist)
        navigationController?.pushViewController(vc, animated: true)
    }
}
