//
//  PreferencesVC.swift
//  HealSync
//
//  Created by Arfa on 24/03/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ClientPreferencesVC: UIViewController {

    // MARK: - Properties
    private let db = Firestore.firestore()
    private let bgColor = UIColor(hex: "#D1F0F8")

    // MARK: - Custom Nav Bar
    private let navBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#D1F0F8")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backBtn = CustomBackButton()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Preferences"
        lbl.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let navDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#C8EDF5")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Scroll
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis    = .vertical
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Segments
    private let sessionSegment   = UISegmentedControl(items: ["Video", "Audio", "Chat"])
    private let languageSegment  = UISegmentedControl(items: ["English", "Urdu"])
    private let genderSegment    = UISegmentedControl(items: ["Male", "Female"])

    // MARK: - Buttons
    private let saveBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("SAVE", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        btn.backgroundColor  = UIColor(hex: "#4FC3D8")
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let cancelBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("CANCEL", for: .normal)
        btn.setTitleColor(UIColor(hex: "#7B1C1C"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        btn.backgroundColor  = UIColor(hex: "#F5C6C6")
        btn.layer.cornerRadius = 12
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
        fetchPreferences()

        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        saveBtn.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        cancelBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Layout
    private func setupLayout() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        [backBtn, titleLabel, navDivider].forEach { navBar.addSubview($0) }

        view.addSubview(navBar)
        view.addSubview(scrollView)
        view.addSubview(activityIndicator)
        scrollView.addSubview(contentStack)

        // Card
        let card = buildPreferencesCard()

        // Buttons
        let btnStack = UIStackView(arrangedSubviews: [saveBtn, cancelBtn])
        btnStack.axis         = .horizontal
        btnStack.spacing      = 14
        btnStack.distribution = .fillEqually
        btnStack.translatesAutoresizingMaskIntoConstraints = false

        let btnWrapper = UIView()
        btnWrapper.addSubview(btnStack)
        NSLayoutConstraint.activate([
            btnStack.topAnchor.constraint(equalTo: btnWrapper.topAnchor),
            btnStack.leadingAnchor.constraint(equalTo: btnWrapper.leadingAnchor),
            btnStack.trailingAnchor.constraint(equalTo: btnWrapper.trailingAnchor),
            btnStack.bottomAnchor.constraint(equalTo: btnWrapper.bottomAnchor),
            btnStack.heightAnchor.constraint(equalToConstant: 48)
        ])

        [card, btnWrapper].forEach { contentStack.addArrangedSubview($0) }
        contentStack.setCustomSpacing(24, after: card)

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -50),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 52),

            backBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 14),
            backBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 60),
            titleLabel.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),

            navDivider.leadingAnchor.constraint(equalTo: navBar.leadingAnchor),
            navDivider.trailingAnchor.constraint(equalTo: navBar.trailingAnchor),
            navDivider.bottomAnchor.constraint(equalTo: navBar.bottomAnchor),
            navDivider.heightAnchor.constraint(equalToConstant: 1),

            scrollView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Preferences Card
    private func buildPreferencesCard() -> UIView {
        let card = UIView()
        card.backgroundColor   = .white.withAlphaComponent(0.85)
        card.layer.cornerRadius = 20
        card.layer.shadowColor   = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset  = CGSize(width: 0, height: 3)
        card.layer.shadowRadius  = 8
        card.translatesAutoresizingMaskIntoConstraints = false

        // Style all segments consistently
        [sessionSegment, languageSegment, genderSegment].forEach { seg in
            seg.selectedSegmentTintColor = UIColor(hex: "#4FC3D8")
            seg.setTitleTextAttributes([.foregroundColor: UIColor.white,
                                         .font: UIFont.systemFont(ofSize: 14, weight: .semibold)],
                                        for: .selected)
            seg.setTitleTextAttributes([.foregroundColor: UIColor(hex: "#1A3A45"),
                                         .font: UIFont.systemFont(ofSize: 14, weight: .medium)],
                                        for: .normal)
            seg.selectedSegmentIndex = UISegmentedControl.noSegment
            seg.translatesAutoresizingMaskIntoConstraints = false
        }

        let sections: [(String, UISegmentedControl)] = [
            ("Preferred Session Format", sessionSegment),
            ("Preferred Language",       languageSegment),
            ("Preferred Therapist Gender", genderSegment)
        ]

        var lastView: UIView? = nil

        for (labelText, segment) in sections {
            let lbl = makeFieldLabel(labelText)
            card.addSubview(lbl)
            card.addSubview(segment)

            lbl.translatesAutoresizingMaskIntoConstraints     = false
            segment.translatesAutoresizingMaskIntoConstraints = false

            if let prev = lastView {
                lbl.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 24).isActive = true
            } else {
                lbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 24).isActive = true
            }

            NSLayoutConstraint.activate([
                lbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),

                segment.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 10),
                segment.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
                segment.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
                segment.heightAnchor.constraint(equalToConstant: 44)
            ])

            lastView = segment
        }

        lastView?.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24).isActive = true
        return card
    }

    private func makeFieldLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text      = text
        lbl.font      = UIFont.systemFont(ofSize: 13, weight: .medium)
        lbl.textColor = UIColor(hex: "#5A8A99")
        return lbl
    }

    // MARK: - Fetch
    private func fetchPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        activityIndicator.startAnimating()

        db.collection("users").document(uid).getDocument { [weak self] snap, _ in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            guard let data = snap?.data() else { return }

            DispatchQueue.main.async {
                // Session format
                if let format = data["sessionFormat"] as? String {
                    let items = ["Video", "Audio", "Chat"]
                    if let idx = items.firstIndex(of: format) {
                        self.sessionSegment.selectedSegmentIndex = idx
                    }
                }
                // Language
                if let lang = data["preferredLanguage"] as? String {
                    let items = ["English", "Urdu"]
                    if let idx = items.firstIndex(of: lang) {
                        self.languageSegment.selectedSegmentIndex = idx
                    }
                }
                // Therapist gender
                if let gender = data["preferredTherapistGender"] as? String {
                    let items = ["Male", "Female"]
                    if let idx = items.firstIndex(of: gender) {
                        self.genderSegment.selectedSegmentIndex = idx
                    }
                }
            }
        }
    }

    // MARK: - Save
    @objc private func handleSave() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        activityIndicator.startAnimating()
        saveBtn.isEnabled = false

        let sessionFormat = sessionSegment.titleForSegment(
            at: sessionSegment.selectedSegmentIndex) ?? ""
        let preferredLanguage = languageSegment.titleForSegment(
            at: languageSegment.selectedSegmentIndex) ?? ""
        let preferredTherapistGender = genderSegment.titleForSegment(
            at: genderSegment.selectedSegmentIndex) ?? ""

        let updates: [String: Any] = [
            "sessionFormat":            sessionFormat,
            "preferredLanguage":        preferredLanguage,
            "preferredTherapistGender": preferredTherapistGender
        ]

        db.collection("users").document(uid).updateData(updates) { [weak self] error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.saveBtn.isEnabled = true
                if let error = error {
                    let alert = UIAlertController(title: "Error",
                                                  message: error.localizedDescription,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
}
