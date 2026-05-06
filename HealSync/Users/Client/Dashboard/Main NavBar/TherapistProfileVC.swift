//
//  TherapistProfileVC.swift
//  HealSync
//
//  Created by Arfa on 25/02/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class TherapistProfileVC: UIViewController {

    private var therapist: Therapist

    init(therapist: Therapist) {
        self.therapist = therapist
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Colors
    private let teal       = UIColor(hex: "#4FC3D8")
    private let darkTeal   = UIColor(hex: "#1A7A8A")
    private let bgColor    = UIColor(hex: "#EEF8FB")
    private let cardWhite  = UIColor.white
    private let textDark   = UIColor(hex: "#1A3A45")
    private let textGray   = UIColor(hex: "#5A8A99")

    // MARK: - UI
    private var tagsContainerView: UIView?   // laid out in viewDidLayoutSubviews
    private var therapistListener: ListenerRegistration?
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Hero image — full bleed at top
    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode   = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(hex: "#C3EBF2")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Gradient overlay on hero so text is readable
    private let heroGradient: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Back button floating over hero
    private let backButton = CustomBackButton()

    // Profile name + specialty overlaid on hero bottom
    private let heroNameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let heroSpecLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Main white card that overlaps the hero
    private let mainCard: UIView = {
        let v = UIView()
        v.backgroundColor    = .white
        v.layer.cornerRadius = 28
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset  = CGSize(width: 0, height: -4)
        v.layer.shadowRadius  = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Stats row — experience, sessions, rating
    private let statsCard: UIView = {
        let v = UIView()
        v.backgroundColor  = UIColor(hex: "#EEF8FB")
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Book + Chat buttons
    private let bookButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Book a Session", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        btn.backgroundColor  = UIColor(hex: "#4FC3D8")
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let chatButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "bubble.left.fill"), for: .normal)
        btn.tintColor = UIColor(hex: "#4FC3D8")
        btn.backgroundColor  = UIColor(hex: "#EEF8FB")
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupLayout()
        configure()
        bookButton.addTarget(self, action: #selector(handleBookSession), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        chatButton.addTarget(self, action: #selector(handleChat), for: .touchUpInside)
        bookButton.isEnabled = !therapist.schedule.isEmpty
        bookButton.alpha     = therapist.schedule.isEmpty ? 0.5 : 1.0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        configure()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Apply gradient to hero overlay
        if heroGradient.layer.sublayers == nil || heroGradient.layer.sublayers?.isEmpty == true {
            let grad = CAGradientLayer()
            grad.frame  = heroGradient.bounds
            grad.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor]
            grad.locations = [0.4, 1.0]
            heroGradient.layer.insertSublayer(grad, at: 0)
        }

        // Populate tag chips now that bounds are finalised — no UIScreen.main needed
        if let container = tagsContainerView, container.subviews.isEmpty {
            let availableWidth = container.bounds.width
            guard availableWidth > 0 else { return }

            var xOffset: CGFloat = 0
            var yOffset: CGFloat = 0
            let spacing: CGFloat = 8
            let rowHeight: CGFloat = 32

            for tag in therapist.tags {
                let chip = makeChip(tag)
                let chipWidth = (tag as NSString).size(withAttributes: [
                    .font: UIFont.systemFont(ofSize: 13, weight: .medium)
                ]).width + 24

                if xOffset + chipWidth > availableWidth {
                    xOffset = 0
                    yOffset += rowHeight + spacing
                }
                chip.frame = CGRect(x: xOffset, y: yOffset, width: chipWidth, height: rowHeight)
                container.addSubview(chip)
                xOffset += chipWidth + spacing
            }

            // Update placeholder height to fit wrapped chips
            let totalHeight = yOffset + rowHeight
            for constraint in container.constraints where constraint.firstAttribute == .height {
                constraint.isActive = false
            }
            container.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true
        }
    }

    // MARK: - Configure
        private func configure() {
            therapistListener?.remove()
            therapistListener = Firestore.firestore()
                .collection("users").document(therapist.uid)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self,
                          let _ = snapshot?.data(),
                          let updated = Therapist(document: snapshot!) else { return }
    
                    DispatchQueue.main.async {
                        self.therapist = updated
                        self.heroNameLabel.text = updated.fullName
                        self.heroSpecLabel.text = updated.specialization
    
                        // Reload tags
                        if let container = self.tagsContainerView {
                            container.subviews.forEach { $0.removeFromSuperview() }
                            self.tagsContainerView = container
                            self.view.setNeedsLayout()
                        }
    
                        // Refresh book button state
                        self.bookButton.isEnabled = !updated.schedule.isEmpty
                        self.bookButton.alpha     = updated.schedule.isEmpty ? 0.5 : 1.0
    
                        // Load profile image
                        let urlStr = updated.profileImageURL
                        guard !urlStr.isEmpty, let url = URL(string: urlStr) else { return }
                        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                            if let data = data, let img = UIImage(data: data) {
                                DispatchQueue.main.async { self?.heroImageView.image = img }
                            }
                        }.resume()
                    }
                }
        }
    

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Hero
        contentView.addSubview(heroImageView)
        contentView.addSubview(heroGradient)
        heroGradient.addSubview(heroNameLabel)
        heroGradient.addSubview(heroSpecLabel)

        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 38),
            backButton.heightAnchor.constraint(equalToConstant: 38)
        ])

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalToConstant: 320),

            heroGradient.topAnchor.constraint(equalTo: heroImageView.topAnchor),
            heroGradient.leadingAnchor.constraint(equalTo: heroImageView.leadingAnchor),
            heroGradient.trailingAnchor.constraint(equalTo: heroImageView.trailingAnchor),
            heroGradient.bottomAnchor.constraint(equalTo: heroImageView.bottomAnchor),

    
            heroSpecLabel.bottomAnchor.constraint(equalTo: heroGradient.bottomAnchor, constant: -50),
            heroSpecLabel.leadingAnchor.constraint(equalTo: heroGradient.leadingAnchor, constant: 24),
            heroSpecLabel.trailingAnchor.constraint(equalTo: heroGradient.trailingAnchor, constant: -24),

            heroNameLabel.bottomAnchor.constraint(equalTo: heroSpecLabel.topAnchor, constant: -4),
            heroNameLabel.leadingAnchor.constraint(equalTo: heroGradient.leadingAnchor, constant: 24),
            heroNameLabel.trailingAnchor.constraint(equalTo: heroGradient.trailingAnchor, constant: -24)
        ])

        // Main card overlapping hero by 24pt
        contentView.addSubview(mainCard)
        NSLayoutConstraint.activate([
            mainCard.topAnchor.constraint(equalTo: heroImageView.bottomAnchor, constant: -24),
            mainCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // Build main card content
        buildMainCard()
    }

    private func buildMainCard() {
        let p: CGFloat = 22

        // Stats row
        let statsStack = makeStatsRow()
        mainCard.addSubview(statsStack)
        statsStack.translatesAutoresizingMaskIntoConstraints = false

        // Action buttons
        mainCard.addSubview(bookButton)
        mainCard.addSubview(chatButton)

        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: mainCard.topAnchor, constant: 28),
            statsStack.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: p),
            statsStack.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor, constant: -p),
            statsStack.heightAnchor.constraint(equalToConstant: 72),

            bookButton.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 20),
            bookButton.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: p),
            bookButton.trailingAnchor.constraint(equalTo: chatButton.leadingAnchor, constant: -12),
            bookButton.heightAnchor.constraint(equalToConstant: 50),

            chatButton.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor, constant: -p),
            chatButton.centerYAnchor.constraint(equalTo: bookButton.centerYAnchor),
            chatButton.widthAnchor.constraint(equalToConstant: 50),
            chatButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        var lastView: UIView = bookButton

        // About
        lastView = addSection(title: "About Me",
                              body: therapist.about.isEmpty ? "No information provided." : therapist.about,
                              below: lastView, padding: p)

        // Qualifications
        let qualText = [
            therapist.qualification.isEmpty ? nil : "🎓  \(therapist.qualification)",
            therapist.experience > 0 ? "⏱  \(therapist.experience)+ years of experience" : nil,
            therapist.licenseNo.isEmpty ? nil : "📋  License: \(therapist.licenseNo)"
        ].compactMap { $0 }.joined(separator: "\n")

        lastView = addSection(title: "Qualifications",
                              body: qualText.isEmpty ? "Not provided" : qualText,
                              below: lastView, padding: p)

        // Languages
        if !therapist.languages.isEmpty {
            lastView = addSection(title: "Languages",
                                  body: therapist.languages.joined(separator: "   •   "),
                                  below: lastView, padding: p)
        }

        // Specialties tags
        if !therapist.tags.isEmpty {
            let tagsTitle = makeSectionTitle("Specialties")
            // Placeholder — real chips are added in viewDidLayoutSubviews when bounds are known
            let tagsPlaceholder = UIView()
            tagsPlaceholder.tag = 888
            mainCard.addSubview(tagsTitle)
            mainCard.addSubview(tagsPlaceholder)
            tagsTitle.translatesAutoresizingMaskIntoConstraints     = false
            tagsPlaceholder.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                tagsTitle.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 24),
                tagsTitle.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: p),

                tagsPlaceholder.topAnchor.constraint(equalTo: tagsTitle.bottomAnchor, constant: 12),
                tagsPlaceholder.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: p),
                tagsPlaceholder.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor, constant: -p),
                tagsPlaceholder.bottomAnchor.constraint(equalTo: mainCard.bottomAnchor, constant: -40)
            ])
            tagsContainerView = tagsPlaceholder
        } else {
            lastView.bottomAnchor.constraint(equalTo: mainCard.bottomAnchor, constant: -40).isActive = true
        }
    }

    // MARK: - Stat Row
    private func makeStatsRow() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(hex: "#EEF8FB")
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false

        let items: [(String, String)] = [
            ("\(therapist.experience)+", "Years Exp."),
            (therapist.gender.isEmpty ? "—" : therapist.gender, "Gender"),
            (therapist.verificationStatus == "approved" ? "✓" : "⏳", "Verified")
        ]

        var statViews: [UIView] = []
        for item in items {
            statViews.append(makeStatItem(value: item.0, label: item.1))
        }

        // Add stat views and dividers manually with Auto Layout
        for (i, statView) in statViews.enumerated() {
            statView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(statView)

            NSLayoutConstraint.activate([
                statView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
                statView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            ])

            if i == 0 {
                statView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8).isActive = true
            }
            if i == statViews.count - 1 {
                statView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8).isActive = true
            }

            // Equal widths across all stat items
            if i > 0 {
                statView.widthAnchor.constraint(equalTo: statViews[0].widthAnchor).isActive = true
            }
        }

        // Dividers + spacing between stat views
        for i in 0..<(statViews.count - 1) {
            let div = UIView()
            div.backgroundColor = UIColor(hex: "#C8EDF5")
            div.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(div)

            NSLayoutConstraint.activate([
                div.widthAnchor.constraint(equalToConstant: 1),
                div.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.5),
                div.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                div.leadingAnchor.constraint(equalTo: statViews[i].trailingAnchor, constant: 4),
                statViews[i + 1].leadingAnchor.constraint(equalTo: div.trailingAnchor, constant: 4)
            ])
        }

        return container
    }

    private func makeStatItem(value: String, label: String) -> UIView {
        let vStack = UIStackView()
        vStack.axis      = .vertical
        vStack.alignment = .center
        vStack.spacing   = 2

        let valLbl = UILabel()
        valLbl.text      = value
        valLbl.font      = UIFont.systemFont(ofSize: 20, weight: .bold)
        valLbl.textColor = UIColor(hex: "#1A3A45")
        valLbl.textAlignment = .center
        valLbl.adjustsFontSizeToFitWidth = true
        valLbl.minimumScaleFactor = 0.7

        let nameLbl = UILabel()
        nameLbl.text      = label
        nameLbl.font      = UIFont.systemFont(ofSize: 11, weight: .medium)
        nameLbl.textColor = UIColor(hex: "#5A8A99")
        nameLbl.textAlignment = .center

        vStack.addArrangedSubview(valLbl)
        vStack.addArrangedSubview(nameLbl)
        return vStack
    }

    // MARK: - Section Builder
    @discardableResult
    private func addSection(title: String, body: String, below anchor: UIView, padding: CGFloat) -> UIView {
        let titleLbl = makeSectionTitle(title)
        let bodyLbl  = makeBodyLabel(body)

        mainCard.addSubview(titleLbl)
        mainCard.addSubview(bodyLbl)
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        bodyLbl.translatesAutoresizingMaskIntoConstraints  = false

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: anchor.bottomAnchor, constant: 24),
            titleLbl.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: padding),

            bodyLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 8),
            bodyLbl.leadingAnchor.constraint(equalTo: mainCard.leadingAnchor, constant: padding),
            bodyLbl.trailingAnchor.constraint(equalTo: mainCard.trailingAnchor, constant: -padding)
        ])
        return bodyLbl
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text      = text
        lbl.font      = UIFont.systemFont(ofSize: 17, weight: .bold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        return lbl
    }

    private func makeBodyLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text          = text
        lbl.font          = UIFont.systemFont(ofSize: 15, weight: .regular)
        lbl.textColor     = UIColor(hex: "#3A6070")
        lbl.numberOfLines = 0
        lbl.lineBreakMode = .byWordWrapping
        return lbl
    }


    private func makeChip(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text            = text
        lbl.font            = UIFont.systemFont(ofSize: 13, weight: .medium)
        lbl.textColor       = UIColor(hex: "#1A7A8A")
        lbl.backgroundColor = UIColor(hex: "#D6F0F7")
        lbl.textAlignment   = .center
        lbl.layer.cornerRadius = 10
        lbl.clipsToBounds   = true
        return lbl
    }

    // MARK: - Actions
    @objc private func handleBookSession() {
        let vc = BookingSessionVC(therapist: therapist)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleChat() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snap, _ in
            guard let self = self,
                  let patientName = snap?.data()?["fullName"] as? String else { return }
     
            ChatService.shared.getOrCreateGeneralChat(
                patientId:     uid,
                patientName:   patientName,
                therapistId:   self.therapist.uid,
                therapistName: self.therapist.fullName
            ) { chatId in
                DispatchQueue.main.async {
                    let vc = ChatVC(
                        chatId:          chatId,
                        otherUserId:     self.therapist.uid,
                        otherName:       self.therapist.fullName,
                        chatType:        .general,
                        currentUserName: patientName
                    )
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}

