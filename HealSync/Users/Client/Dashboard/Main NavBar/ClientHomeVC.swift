//
//  UserDashboardVC.swift
//  HealSync
//
//  Created by Arfa on 10/02/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ClientHomeVC: UIViewController {
    
    private enum AssociatedKeys {
        static var sessionData: UInt8 = 0
    }
    
    private var therapists: [Therapist] = []
    private var therapistStackView = UIStackView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var greetingLabel = TitleLabel(text: "Greetings", fontSize: 20)
    private let notificationBadge = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#D1F0F8")
        setupScrollView()
        setupContent()
        fetchUpcomingSession()
        
        // Fetch patient info
        ClientService.shared.fetchCurrentUser { [weak self] user in
            guard let self = self, let user = user else { return }
            DispatchQueue.main.async {
                let firstName = user.fullName.components(separatedBy: " ").first ?? user.fullName
                self.greetingLabel.text = "Greetings, \(firstName)!"
            }
        }
        
        // Fetch therapists
        TherapistService.shared.fetchSuggestedTherapists { [weak self] therapists in
            self?.therapists = therapists
            DispatchQueue.main.async {
                self?.configureTherapistCards()
            }
        }
    }
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchUpcomingSession()
        checkNotifications()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func fetchUpcomingSession() {
        let db = Firestore.firestore()
        guard let patientId = Auth.auth().currentUser?.uid else { return }
     
        db.collection("users")
            .document(patientId)
            .collection("mySessions")
            .whereField("status", isEqualTo: "confirmed")
            .order(by: "sessionDateTime")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
     
                // Filter in-memory so we can use duration to compute end time
                let now = Date()
                let upcomingSession = snapshot?.documents
                    .map { $0.data() }
                    .filter { session in
                        let dt       = (session["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantPast
                        let duration = session["duration"] as? Int ?? 45
                        let endTime  = dt.addingTimeInterval(TimeInterval(duration * 60))
                        return endTime > now   // visible until session finishes
                    }
                    .sorted {
                        let a = ($0["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantFuture
                        let b = ($1["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantFuture
                        return a < b
                    }
                    .first
     
                DispatchQueue.main.async {
                    // Remove old card
                    if let index = self.contentStack.arrangedSubviews.firstIndex(where: { $0.tag == 999 }) {
                        let old = self.contentStack.arrangedSubviews[index]
                        self.contentStack.removeArrangedSubview(old)
                        old.removeFromSuperview()
                    }
     
                    let card: UIView
                    if let session = upcomingSession {
                        card = self.createUpcomingSessionCard(with: session)
                    } else {
                        card = self.createNoUpcomingSessionCard()
                    }
                    card.tag = 999
                    self.contentStack.insertArrangedSubview(card, at: 1)
                }
            }
    }
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        contentStack.axis = .vertical
        contentStack.spacing = 30

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor , constant: -50),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 25),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -25),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -50)
        ])
    }

    private func setupContent() {
        contentStack.addArrangedSubview(createGreetingCard(title: greetingLabel))

        let placeholder = UIView()
        placeholder.tag = 999
        contentStack.insertArrangedSubview(placeholder, at: 1)

        contentStack.addArrangedSubview(createSuggestedTherapists())
        contentStack.addArrangedSubview(createViewMore())
    }

    private func createGreetingCard(title: TitleLabel) -> UIView {
        
        let card = BaseContainer(opacity: 0.9)
        let title = title
        title.textAlignment = .left
        
        let subtitle = SubtitleLabel(text: "Take a deep breath. You’re doing better than you think", noOfLines: 2, fontSize: 14)
        subtitle.textAlignment = .left

        let bell = UIButton(type: .system)
        bell.setImage(UIImage(systemName: "bell"), for: .normal)
        bell.tintColor = .gray
        bell.addTarget(self, action: #selector(openNotifications), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 5

        let hStack = UIStackView(arrangedSubviews: [stack, bell])
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
        // Configure the badge
        notificationBadge.backgroundColor = .systemRed
        notificationBadge.textColor = .white
        notificationBadge.font = .systemFont(ofSize: 10, weight: .semibold)
        notificationBadge.textAlignment = .center
        notificationBadge.layer.cornerRadius = 10
        notificationBadge.clipsToBounds = true
        notificationBadge.isHidden = true  // hidden by default
        notificationBadge.translatesAutoresizingMaskIntoConstraints = false
        

        notificationBadge.minimumScaleFactor = 0.5
        notificationBadge.adjustsFontSizeToFitWidth = true

        card.addSubview(notificationBadge)

        NSLayoutConstraint.activate([
            notificationBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            notificationBadge.heightAnchor.constraint(equalToConstant: 20),
            notificationBadge.topAnchor.constraint(equalTo: bell.topAnchor, constant: -5),
            notificationBadge.trailingAnchor.constraint(equalTo: bell.trailingAnchor, constant: 5)
        ])
        
        return card
    }
    @objc private func openNotifications() {
        let vc = NotificationsVC()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
  
    func checkNotifications() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .addSnapshotListener { snapshot, _ in
                DispatchQueue.main.async {
                    let unreadCount = snapshot?.documents.count ?? 0
                    
                    if unreadCount == 0 {
                        self.notificationBadge.isHidden = true
                    } else {
                        self.notificationBadge.isHidden = false
                        
                      if unreadCount > 99 {
                          self.notificationBadge.text = "99+"
                          self.notificationBadge.font = .systemFont(ofSize: 8)
                        }
                        else {
                            self.notificationBadge.text = "\(unreadCount)"
                        }
                    }
                }
            }
    }
    
    private func updateUpcomingSessionCard(with session: [String: Any]) {

        if let index = contentStack.arrangedSubviews.firstIndex(where: { $0.tag == 999 }) {
            let oldCard = contentStack.arrangedSubviews[index]
            contentStack.removeArrangedSubview(oldCard)
            oldCard.removeFromSuperview()
        }

        let card = createUpcomingSessionCard(with: session)
        card.tag = 999
        contentStack.insertArrangedSubview(card, at: 1)
    }
    private func createNoUpcomingSessionCard() -> UIView {
        let card = BaseContainer(opacity: 0.9)

        let title = TitleLabel(text: "No Upcoming Sessions", fontSize: 21)
        let subtitle = SubtitleLabel(text: "You don’t have any upcoming sessions yet. Book one now", noOfLines: 3, fontSize: 16)

        let bookButton = PrimaryButton(title: "Book a Session")
        bookButton.addTarget(self, action: #selector(navigateToTherapist), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, subtitle, bookButton])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(20, after: subtitle)
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 50),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -50),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -30)
        ])

        return card
    }

    private func createUpcomingSessionCard(with session: [String: Any]) -> UIView {
        let card = BaseContainer(opacity: 0.9)
     
        // ── Header ────────────────────────────────────────────────────
        let title = TitleLabel(text: "Your Upcoming Session", fontSize: 21)
     
        // Use `date` + `slot` for display (they exist and are already formatted)
        let therapistName = session["therapistName"] as? String ?? ""
        let slot          = session["slot"]          as? String ?? ""
        let duration      = session["duration"]      as? Int    ?? 45
     
        var dateStr = ""
        if let ts = session["date"] as? Timestamp {
            let df = DateFormatter()
            df.dateFormat = "dd MMM yyyy"
            dateStr = df.string(from: ts.dateValue())
        }
     
        let subtitleText = "\(dateStr) at \(slot) with\nDr. \(therapistName)  •  \(duration) min"
        let subtitle = SubtitleLabel(text: subtitleText, noOfLines: 3, fontSize: 16)
     
        // ── Join button — enabled only within 10 min of start until end ──
        let joinButton = PrimaryButton(title: "JOIN NOW")
     
        var canJoin = false
        if let ts = session["sessionDateTime"] as? Timestamp {
            let start        = ts.dateValue()
            let end          = start.addingTimeInterval(TimeInterval(duration * 60))
            let minutesUntil = start.timeIntervalSinceNow / 60
            canJoin = minutesUntil <= 10 && Date() < end
        }
     
        joinButton.isEnabled = canJoin
        joinButton.alpha     = canJoin ? 1.0 : 0.8
        title.text = canJoin ? "Your Ongoing Session" : "Your Upcoming Session"
     
        objc_setAssociatedObject(joinButton, &AssociatedKeys.sessionData, session,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        joinButton.addTarget(self, action: #selector(homeJoinTapped(_:)), for: .touchUpInside)
     
        // ── Layout ────────────────────────────────────────────────────
        let headerStack = UIStackView(arrangedSubviews: [title, subtitle])
        headerStack.axis    = .vertical
        headerStack.spacing = 10
     
        let stack = UIStackView(arrangedSubviews: [headerStack, joinButton])
        stack.axis    = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
     
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 50),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -50),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -30)
        ])
     
        return card
    }
    @objc private func homeJoinTapped(_ sender: UIButton) {
        guard
            let session       = objc_getAssociatedObject(sender, &AssociatedKeys.sessionData) as? [String: Any],
            let patientId     = Auth.auth().currentUser?.uid,
            let bookingId     = session["bookingId"]     as? String,
            let therapistId   = session["therapistId"]   as? String,
            let therapistName = session["therapistName"] as? String,
            let patientName   = session["patientName"]   as? String,
            let sessionType   = session["sessionType"]   as? String
        else { return }
     
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
            let vc = AudioCallVC()
            vc.bookingId     = bookingId
            vc.therapistId   = therapistId
            vc.therapistName = therapistName
            vc.patientId     = patientId
            vc.patientName   = patientName
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle   = .crossDissolve
            present(vc, animated: true)
     
        case "Video":
            let vc = VideoCallVC()
            vc.bookingId     = bookingId
            vc.therapistId   = therapistId
            vc.therapistName = therapistName
            vc.patientId     = patientId
            vc.patientName   = patientName
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle   = .crossDissolve
            present(vc, animated: true)
     
        default:
            break
        }
    }
     

    private func createSuggestedTherapists() -> UIView {
        
        let container = UIView()
        
        let title = TitleLabel(text: "Suggested Therapist", fontSize: 18)
        title.textAlignment = .left
        
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        
        therapistStackView.axis = .horizontal
        therapistStackView.spacing = 20
        
        scrollView.addSubview(therapistStackView)
        therapistStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            therapistStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            therapistStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            therapistStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            therapistStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            therapistStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        let mainStack = UIStackView(arrangedSubviews: [title, scrollView])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        return container
    }
    private func configureTherapistCards() {
        
        therapistStackView.arrangedSubviews.forEach {
            therapistStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        for therapist in therapists {
            
            let card = BaseContainer(opacity: 0.9, shadow: false)
            
            let name = TitleLabel(text: "Dr. \(therapist.fullName)", fontSize: 16)
            
            let specialty = SubtitleLabel(
                text: therapist.specialization,
                noOfLines: 2,
                fontSize: 12
            )
            
            let button = PrimaryButton(title: "View Profile", fontSize: 12)
            button.addTarget(self,
                             action: #selector(viewProfileTapped(_:)),
                             for: .touchUpInside)
            button.tag = therapists.firstIndex(where: { $0.uid == therapist.uid }) ?? 0
            
            let vStack = UIStackView(arrangedSubviews: [name, specialty, button])
            vStack.spacing = 12
            vStack.axis = .vertical
            vStack.translatesAutoresizingMaskIntoConstraints = false
            
            card.addSubview(vStack)
            
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
                card.widthAnchor.constraint(equalToConstant: 180),

            ])
            
            therapistStackView.addArrangedSubview(card)
        }
    }
    @objc private func viewProfileTapped(_ sender: UIButton) {
        let therapist = therapists[sender.tag]
        let profileVC = TherapistProfileVC(therapist: therapist)
        profileVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(profileVC, animated: true)
    }
    private func createViewMore() -> UIView {
        let label = Hyperlink(fullText: "View More", linkText: "View More")
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .right
        label.onLinkTap = { [weak self] in
            self?.navigateToTherapist()
        }
        return label
    }
    
    @objc private func navigateToTherapist() {
        tabBarController?.selectedIndex = 2
    }
    
}
