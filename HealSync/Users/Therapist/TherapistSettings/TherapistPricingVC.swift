//
//  TherapistManagePricingVC.swift
//  HealSync
//
//  Created by Arfa on 26/03/2026.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class TherapistPricingVC: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Properties
    private let db = Firestore.firestore()
    private let sessionTypes = ["Video", "Audio", "Chat"]
    private var sessionDurations: [String: Int] = ["Video": 60, "Audio": 45, "Chat": 30]
    private var sessionPrices:    [String: Int] = ["Video": 0,  "Audio": 0,  "Chat": 0]

    // Holds references to each row's controls
    private var pricingRows: [String: (priceField: UITextField, durationBtn: UIButton)] = [:]

    // MARK: - Colors
    private let bgColor    = UIColor(hex: "#D6EEF5")
    private let accentBlue = UIColor(hex: "#4FC3D8")
    private let textColor  = UIColor(hex: "#1A3A45")

    // MARK: - UI
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Set your pricing and session duration for each session type"
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        lbl.textColor = UIColor(hex: "#5A8A99")
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Header labels row
    private let headerBadgeLabel: UILabel = makeColumnHeader("TYPE")
    private let headerPriceLabel: UILabel = makeColumnHeader("PRICE (PKR)")
    private let headerDurationLabel: UILabel = makeColumnHeader("DURATION")

    private let pricingStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 14
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let infoCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#C8EDF5").withAlphaComponent(0.6)
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let infoLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "💡 Set a price of 0 to offer a free session type. Clients will see these rates before booking."
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.textColor = UIColor(hex: "#1A5A6A")
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let divider1: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#9ECEDD").withAlphaComponent(0.5)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Save / Cancel
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(hex: "#4FC3D8")
        btn.layer.cornerRadius = 14
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Cancel", for: .normal)
        btn.setTitleColor(UIColor(hex: "#4A1113"), for: .normal)
        btn.backgroundColor = UIColor(hex: "#D3AAB1")
        btn.layer.cornerRadius = 14
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .white; ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        titleLabel.text = "EDIT PRICING"
        saveButton.setTitle("Save Changes", for: .normal)

        setupUI()
        setupPricingRows()
        setupActions()
        loadExistingData()
        setupKeyboardDismiss()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        infoCard.addSubview(infoLabel)

        let headerRow = UIStackView(arrangedSubviews: [headerBadgeLabel, headerPriceLabel, headerDurationLabel])
        headerRow.axis = .horizontal; headerRow.spacing = 10; headerRow.alignment = .center
        headerRow.distribution = .fill
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerBadgeLabel.widthAnchor.constraint(equalToConstant: 52).isActive = true
        headerDurationLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true

        let allSubviews: [UIView] = [
            titleLabel, subtitleLabel,
            headerRow,
            pricingStackView,
            infoCard,
            divider1,
            saveButton, cancelButton
        ]
        allSubviews.forEach { contentView.addSubview($0) }
        saveButton.addSubview(activityIndicator)

        let p: CGFloat = 22
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: -20),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            headerRow.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            headerRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            headerRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            pricingStackView.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 10),
            pricingStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            pricingStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            infoCard.topAnchor.constraint(equalTo: pricingStackView.bottomAnchor, constant: 20),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            infoLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 12),
            infoLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 14),
            infoLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -14),
            infoLabel.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -12),

            divider1.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 24),
            divider1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            divider1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            divider1.heightAnchor.constraint(equalToConstant: 1),

            saveButton.topAnchor.constraint(equalTo: divider1.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            saveButton.heightAnchor.constraint(equalToConstant: 40),

            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            activityIndicator.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor)
        ])
    }

    // MARK: - Pricing Rows
    private func setupPricingRows() {
        let durations = [15, 30, 45, 60, 75, 90, 120]

        for type in sessionTypes {
            let row = UIStackView()
            row.axis = .horizontal; row.spacing = 10
            row.alignment = .center; row.distribution = .fill
            row.translatesAutoresizingMaskIntoConstraints = false

            // Session type badge
            let badge = UILabel()
            badge.text = type
            badge.font = UIFont.systemFont(ofSize: 13, weight: .bold)
            badge.textColor = UIColor(hex: "#1A7A8A")
            badge.textAlignment = .center
            badge.backgroundColor = UIColor(hex: "#C8EDF5")
            badge.layer.cornerRadius = 8
            badge.clipsToBounds = true
            badge.translatesAutoresizingMaskIntoConstraints = false
            badge.widthAnchor.constraint(equalToConstant: 52).isActive = true
            badge.heightAnchor.constraint(equalToConstant: 50).isActive = true

            // Price text field
            let priceField = UITextField()
            priceField.placeholder = "0"
            priceField.backgroundColor = .white.withAlphaComponent(0.7)
            priceField.layer.cornerRadius = 12
            priceField.keyboardType = .numberPad
            priceField.font = UIFont.systemFont(ofSize: 14)
            priceField.textColor = UIColor(hex: "#1A3A45")
            priceField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
            priceField.leftViewMode = .always
            priceField.translatesAutoresizingMaskIntoConstraints = false
            priceField.heightAnchor.constraint(equalToConstant: 50).isActive = true

            // PKR suffix label inside field
            let pkrLabel = UILabel()
            pkrLabel.text = "PKR  "
            pkrLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
            pkrLabel.textColor = UIColor(hex: "#5A8A99")
            priceField.rightView = pkrLabel
            priceField.rightViewMode = .always

            // Duration dropdown button
            let defaultMins = sessionDurations[type] ?? 45
            var config = UIButton.Configuration.plain()
            config.title = "\(defaultMins) min  ▼"
            config.baseForegroundColor = UIColor(hex: "#1A3A45")
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
                var a = attrs; a.font = UIFont.systemFont(ofSize: 13); return a
            }
            let durationBtn = UIButton(configuration: config)
            durationBtn.contentHorizontalAlignment = .center
            durationBtn.backgroundColor = .white.withAlphaComponent(0.7)
            durationBtn.layer.cornerRadius = 12
            durationBtn.translatesAutoresizingMaskIntoConstraints = false
            durationBtn.widthAnchor.constraint(equalToConstant: 100).isActive = true
            durationBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true

            let capturedType = type
            durationBtn.addAction(UIAction { [weak self, weak durationBtn] _ in
                guard let self = self, let btn = durationBtn else { return }
                let alert = UIAlertController(title: "\(capturedType) Duration", message: nil, preferredStyle: .actionSheet)
                for mins in durations {
                    alert.addAction(UIAlertAction(title: "\(mins) min", style: .default) { _ in
                        self.sessionDurations[capturedType] = mins
                        btn.configuration?.title = "\(mins) min  ▼"
                    })
                }
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = btn; popover.sourceRect = btn.bounds
                }
                self.present(alert, animated: true)
            }, for: .touchUpInside)

            row.addArrangedSubview(badge)
            row.addArrangedSubview(priceField)
            row.addArrangedSubview(durationBtn)

            pricingStackView.addArrangedSubview(row)
            pricingRows[type] = (priceField: priceField, durationBtn: durationBtn)
        }
    }

    // MARK: - Actions Setup
    private func setupActions() {
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Load Data
    private func loadExistingData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self = self, let data = snapshot?.data() else { return }
            DispatchQueue.main.async {
                if let prices = data["prices"] as? [String: Int] {
                    self.sessionPrices = prices
                }
                if let durations = data["sessionDurations"] as? [String: Int] {
                    self.sessionDurations = durations
                }
                // Refresh UI
                for type in self.sessionTypes {
                    guard let row = self.pricingRows[type] else { continue }
                    let price = self.sessionPrices[type] ?? 0
                    if price > 0 { row.priceField.text = "\(price)" }
                    let mins = self.sessionDurations[type] ?? 45
                    row.durationBtn.configuration?.title = "\(mins) min  ▼"
                }
            }
        }
    }

    // MARK: - Collect Prices
    private func collectPricesFromUI() {
        for type in sessionTypes {
            guard let row = pricingRows[type] else { continue }
            if let text = row.priceField.text, let val = Int(text) {
                sessionPrices[type] = val
            } else {
                sessionPrices[type] = 0
            }
        }
    }

    // MARK: - Save
    @objc private func handleSave() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        collectPricesFromUI()

        setSavingState(true)

        let data: [String: Any] = [
            "prices":           sessionPrices,
            "sessionDurations": sessionDurations,
            "updatedAt":        Timestamp()
        ]

        db.collection("users").document(uid).updateData(data) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.setSavingState(false)
                if let error = error { self.showAlert(message: "Failed to save: \(error.localizedDescription)"); return }
                    self.navigationController?.popViewController(animated: true)

            }
        }
    }

    private func completeOnboarding(uid: String) {
        db.collection("users").document(uid).updateData(["isOnboardingComplete": true]) { [weak self] error in
            guard let self = self else { return }
            if let error = error { print("Onboarding complete error:", error.localizedDescription); return }
            DispatchQueue.main.async {
                let dashboardVC = TherapistMainTabBarController()
                ListenerManager.shared.startListening()
                self.navigationController?.setViewControllers([dashboardVC], animated: true)
            }
        }
    }

    @objc private func handleCancel() {
        navigationController?.popViewController(animated: true)
    }

    private func setSavingState(_ saving: Bool) {
        if saving {
            saveButton.setTitle("", for: .normal)
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            saveButton.setTitle("Save Changes", for: .normal)
        }
        saveButton.isEnabled = !saving
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Column Header Factory
    private static func makeColumnHeader(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .heavy)
        lbl.textColor = UIColor(hex: "#5A8A99")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }
}
