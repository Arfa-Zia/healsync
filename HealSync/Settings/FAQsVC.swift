//
//  FAQsVC.swift
//  HealSync
//
//  Created by Arfa on 25/03/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

private struct FAQItem {
    let question: String
    let answer:   String
    var isExpanded: Bool = false
}

class FAQsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let bgColor  = UIColor(hex: "#D1F0F8")
    private let darkText = UIColor(hex: "#1A3A45")

    // MARK: - FAQ Data
    private static let clientFAQs: [FAQItem] = [
        FAQItem(question: "What is HealSync?",
                answer: "HealSync is an online mental wellness platform that connects you with licensed therapists for secure, private, and flexible therapy sessions from anywhere."),
        FAQItem(question: "How do I book a session?",
                answer: "Go to the Therapist tab, browse available therapists, select a date and time that works for you, and complete payment — it only takes a few minutes."),
        FAQItem(question: "Is my personal data kept private?",
                answer: "Absolutely. All your information and session data are encrypted and stored in compliance with HIPAA standards. Only you and your therapist can access your session content."),
        FAQItem(question: "Can I cancel or reschedule a session?",
                answer: "Yes. You can cancel or reschedule any upcoming session at least 24 hours in advance from your Sessions tab without any penalty."),
        FAQItem(question: "What payment methods are accepted?",
                answer: "We accept credit/debit cards, mobile wallets (Apple Pay, Google Pay), and secure bank transfers."),
        FAQItem(question: "How do I choose the right therapist?",
                answer: "You can filter therapists by specialty, language, availability, and ratings. Each therapist profile includes their credentials, approach, and a short bio to help you decide."),
        FAQItem(question: "What happens if I miss a session?",
                answer: "If you miss a session without cancelling in advance, the session fee may still apply. We recommend cancelling at least 24 hours before your appointment."),
        FAQItem(question: "Can I switch my therapist?",
                answer: "Yes, you can switch therapists at any time. Your previous session history will remain private and accessible only to you.")
    ]

    private static let therapistFAQs: [FAQItem] = [
        FAQItem(question: "How do I get started as a therapist on HealSync?",
                answer: "After registering, complete your profile by adding your credentials, bio, specialties, and availability. Once reviewed and approved, your profile will be visible to clients."),
        FAQItem(question: "How do I set my availability?",
                answer: "Go to your Profile settings and navigate to 'Edit Schedule'. You can select working days and add up to 6 time slots per day. Changes take effect immediately for new bookings."),
        FAQItem(question: "How and when do I get paid?",
                answer: "Payments are processed automatically after each completed session and transferred to your registered bank account within 3–5 business days."),
        FAQItem(question: "Can I set different rates for different session types?",
                answer: "Yes. In your Pricing & Duration settings you can configure separate prices and session lengths for Video, Audio, and Chat sessions."),
        FAQItem(question: "What happens if a client cancels last minute?",
                answer: "If a client cancels less than 24 hours before the session, a cancellation fee is charged to them and a portion is transferred to you as compensation."),
        FAQItem(question: "How do I manage my upcoming sessions?",
                answer: "Your Sessions tab shows all upcoming, completed, and cancelled appointments. You can view client details and session notes directly from there."),
        FAQItem(question: "Is client data kept confidential?",
                answer: "Absolutely. All client information and session content is encrypted end-to-end. You are bound by HealSync's confidentiality agreement in addition to your own professional obligations."),
        FAQItem(question: "What session formats are supported?",
                answer: "HealSync supports Video, Audio, and Chat sessions. You can enable or disable specific formats from your profile settings based on your preference."),
        FAQItem(question: "How do I handle a client in crisis?",
                answer: "If a client expresses immediate risk, follow your professional emergency protocols. HealSync also provides a resource centre with crisis guidelines in the Help section of your dashboard.")
    ]

    private var faqs: [FAQItem] = []

    // MARK: - UI
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor    = .clear
        tv.separatorStyle     = .none
        tv.rowHeight          = UITableView.automaticDimension
        tv.estimatedRowHeight = 56
        tv.showsVerticalScrollIndicator = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let card: UIView = {
        let v = UIView()
        v.backgroundColor    = .white.withAlphaComponent(0.85)
        v.layer.cornerRadius = 20
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset  = CGSize(width: 0, height: 3)
        v.layer.shadowRadius  = 8
        v.clipsToBounds      = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var cardHeightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupNav()
        setupTableView()
        loadFAQsForCurrentUser()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCardHeight()
    }

    // MARK: - Load FAQs based on user role
    private func loadFAQsForCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // Default to client FAQs if not logged in
            faqs = FAQsVC.clientFAQs
            tableView.reloadData()
            return
        }

        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self = self else { return }
            let role = snapshot?.data()?["role"] as? String ?? "patient"
            DispatchQueue.main.async {
                self.faqs = (role == "therapist") ? FAQsVC.therapistFAQs : FAQsVC.clientFAQs
                self.tableView.reloadData()
                self.updateCardHeight()
            }
        }
    }

    // MARK: - Nav
    private func setupNav() {
        let backBtn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        backBtn.setImage(UIImage(systemName: "arrow.left", withConfiguration: cfg), for: .normal)
        backBtn.tintColor = darkText
        backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backBtn.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = "Frequently Asked Questions"
        titleLbl.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLbl.textColor = .black
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backBtn)
        view.addSubview(titleLbl)

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backBtn.widthAnchor.constraint(equalToConstant: 32),
            backBtn.heightAnchor.constraint(equalToConstant: 32),

            titleLbl.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLbl.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 10),
            titleLbl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(FAQCell.self, forCellReuseIdentifier: FAQCell.reuseID)

        view.addSubview(card)
        card.addSubview(tableView)

        cardHeightConstraint = card.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            card.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            cardHeightConstraint,

            tableView.topAnchor.constraint(equalTo: card.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
    }

    private func updateCardHeight() {
        tableView.layoutIfNeeded()
        cardHeightConstraint.constant = tableView.contentSize.height
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        faqs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FAQCell.reuseID, for: indexPath) as! FAQCell
        cell.configure(with: faqs[indexPath.row])
        return cell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        faqs[indexPath.row].isExpanded.toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        updateCardHeight()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { nil }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
}


// MARK: - FAQCell

private class FAQCell: UITableViewCell {
    static let reuseID = "FAQCell"

    private let questionLbl: UILabel = {
        let lbl = UILabel()
        lbl.font          = UIFont.systemFont(ofSize: 14, weight: .semibold)
        lbl.textColor     = UIColor(hex: "#1A3A45")
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let chevron: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor   = UIColor(hex: "#4FC3D8")
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }()

    private let answerLbl: UILabel = {
        let lbl = UILabel()
        lbl.font          = UIFont.systemFont(ofSize: 13)
        lbl.textColor     = .systemGray
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#EAF5F8")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var answerTopWhenVisible: NSLayoutConstraint!
    private var answerTopWhenHidden:  NSLayoutConstraint!
    private var answerHeightZero: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle    = .none
        backgroundColor   = .clear
        contentView.backgroundColor = .clear

        [questionLbl, chevron, answerLbl, divider].forEach { contentView.addSubview($0) }

        answerTopWhenVisible = answerLbl.topAnchor.constraint(equalTo: questionLbl.bottomAnchor, constant: 8)
        answerTopWhenHidden  = answerLbl.topAnchor.constraint(equalTo: questionLbl.bottomAnchor, constant: 0)
        answerHeightZero     = answerLbl.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            questionLbl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            questionLbl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            questionLbl.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            chevron.centerYAnchor.constraint(equalTo: questionLbl.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevron.widthAnchor.constraint(equalToConstant: 16),
            chevron.heightAnchor.constraint(equalToConstant: 16),

            answerTopWhenHidden,
            answerHeightZero,
            answerLbl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            answerLbl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            answerLbl.bottomAnchor.constraint(equalTo: divider.topAnchor, constant: -16),

            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with item: FAQItem) {
        questionLbl.text = item.question
        answerLbl.text   = item.answer

        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        chevron.image = UIImage(systemName: item.isExpanded ? "chevron.up" : "chevron.down",
                                withConfiguration: cfg)

        if item.isExpanded {
            answerHeightZero.isActive     = false
            answerTopWhenHidden.isActive  = false
            answerTopWhenVisible.isActive = true
            answerLbl.alpha = 1
        } else {
            answerTopWhenVisible.isActive = false
            answerTopWhenHidden.isActive  = true
            answerHeightZero.isActive     = true
            answerLbl.alpha = 0
        }
    }
}
