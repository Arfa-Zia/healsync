//
//  TherapistSchedulingVC.swift
//  HealSync
//
//  Created by Arfa on 11/03/2026.
//
import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class TherapistOnboardingSchedulingVC: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Properties
    private let db = Firestore.firestore()
    private let storage = Storage.storage(url: "gs://healsync-storage-us")
    private var selectedProfileImage: UIImage?
    private var selectedTags: [String] = []
    private var selectedLanguages: [String] = []
    // Per session-type duration (minutes) and price
    private var sessionDurations: [String: Int] = ["Video": 60, "Audio": 45, "Chat": 30]
    private var sessionPrices:    [String: Int] = ["Video": 0,  "Audio": 0,  "Chat": 0]
    private let sessionTypes = ["Video", "Audio", "Chat"]
    private var schedulePerDay: [String: [String]] = [:]

    private var activeSlotsDay: String? {
        didSet { refreshTimeSlotsUI() }
    }

    // MARK: - Colors
    private let bgColor            = UIColor(hex: "#D6EEF5")
    private let accentBlue         = UIColor(hex: "#4FC3D8")
    private let selectedDayColor   = UIColor(hex: "#4FC3D8")
    private let activeDayColor     = UIColor(hex: "#1A7A8A")  // darker = "currently editing"
    private let unselectedDayColor = UIColor(hex: "#B8E6F0")
    private let textColor          = UIColor(hex: "#1A3A45")

    // MARK: - UI Components
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
        lbl.text = "COMPLETE YOUR PROFILE"
        lbl.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Profile Image
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = UIColor(hex: "#4FC3D8")
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 45
        iv.clipsToBounds = true
        iv.layer.borderWidth = 2.5
        iv.layer.borderColor = UIColor(hex: "#4FC3D8").cgColor
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let cameraIconView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#4FC3D8")
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let cameraIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "camera.fill")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let photoHintLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Upload a clear professional photo"
        lbl.font = UIFont.italicSystemFont(ofSize: 12)
        lbl.textColor = UIColor(hex: "#5A8A99")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // About Me
    private let aboutMeLabel = TherapistOnboardingSchedulingVC.fieldLabel("About Me")
    private let aboutMeTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.backgroundColor = .white.withAlphaComponent(0.7)
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.textColor = UIColor(hex: "#1A3A45")
        return tv
    }()

   
    private let maxChips = 5   // max tags or languages allowed
 
    // Tags
    private let tagsLabel        = TherapistOnboardingSchedulingVC.fieldLabel("TAGS  (max 5)")
    private let tagsTextField    = TherapistOnboardingSchedulingVC.inputTextField(placeholder: "")
    private let tagsAddButton    = TherapistOnboardingSchedulingVC.addButton()
    private let tagsChipsView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 8
        sv.alignment = .leading; sv.distribution = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
 
    // Languages
    private let languagesLabel       = TherapistOnboardingSchedulingVC.fieldLabel("Languages  (max 5)")
    private let languagesTextField   = TherapistOnboardingSchedulingVC.inputTextField(placeholder: "")
    private let languagesAddButton   = TherapistOnboardingSchedulingVC.addButton()
    private let languagesChipsView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 8
        sv.alignment = .leading; sv.distribution = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let divider1 = TherapistOnboardingSchedulingVC.dividerView()

    // Working Days
    private let workingDaysLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "SELECT WORKING DAYS"
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .heavy)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let daysRow1StackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 8; sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let daysRow2StackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 8; sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let sundayButton = UIButton(type: .system)
    private let divider2 = TherapistOnboardingSchedulingVC.dividerView()

    // Time Slots
    private let timeSlotsLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "SET TIME SLOTS"
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .heavy)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let editingDayLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Tap a selected day to edit its slots"
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = UIColor(hex: "#5A8A99")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let timeSlotGridView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 10
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var timeSlotFields: [UITextField] = []

    private let divider3 = TherapistOnboardingSchedulingVC.dividerView()

    // Session Type Pricing & Duration
    private let pricingDurationLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "PRICING & DURATION"
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .heavy)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let pricingDurationSubLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Set price and duration per session type"
        lbl.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        lbl.textColor = UIColor(hex: "#5A8A99")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Dynamically built — one row per session type (Video / Audio / Chat)
    private let pricingStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // Holds references: ["Video": (priceField, durationButton), ...]
    private var pricingRows: [String: (priceField: UITextField, durationBtn: UIButton)] = [:]

    // Save Button
    private let saveButton: UIButton = {
         let btn = UIButton(type: .system)
         btn.setTitle("Save & Continue", for: .normal)
         btn.setTitleColor(.white, for: .normal)
         btn.backgroundColor = UIColor(hex: "#4FC3D8")
         btn.layer.cornerRadius = 14
         btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
         btn.translatesAutoresizingMaskIntoConstraints = false
         return btn
     }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .white; ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private var dayButtons: [String: UIButton] = [:]
    private let allDays = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        saveButton.setTitle("Save & Continue", for: .normal)
        titleLabel.text = "COMPLETE YOUR PROFILE"
        
        setupUI()
        setupActions()
        setupTimeSlotGrid()
        setupPricingRows()
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

        cameraIconView.addSubview(cameraIconImageView)
        NSLayoutConstraint.activate([
            cameraIconImageView.centerXAnchor.constraint(equalTo: cameraIconView.centerXAnchor),
            cameraIconImageView.centerYAnchor.constraint(equalTo: cameraIconView.centerYAnchor),
            cameraIconImageView.widthAnchor.constraint(equalToConstant: 12),
            cameraIconImageView.heightAnchor.constraint(equalToConstant: 12)
        ])

        for day in ["Monday","Tuesday","Wednesday"] {
            let btn = makeDayButton(title: day)
            daysRow1StackView.addArrangedSubview(btn)
            dayButtons[day] = btn
        }
        for day in ["Thursday","Friday","Saturday"] {
            let btn = makeDayButton(title: day)
            daysRow2StackView.addArrangedSubview(btn)
            dayButtons[day] = btn
        }
        sundayButton.setTitle("Sunday", for: .normal)
        sundayButton.setTitleColor(UIColor(hex: "#1A3A45"), for: .normal)
        sundayButton.backgroundColor = unselectedDayColor
        sundayButton.layer.cornerRadius = 10
        sundayButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        sundayButton.translatesAutoresizingMaskIntoConstraints = false
        sundayButton.accessibilityLabel = "Sunday"
        sundayButton.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)
        dayButtons["Sunday"] = sundayButton

        let allSubviews: [UIView] = [
            titleLabel,
            profileImageView, cameraIconView, photoHintLabel,
            aboutMeLabel, aboutMeTextView,
            tagsLabel, tagsTextField, tagsAddButton, tagsChipsView,
            languagesLabel, languagesTextField, languagesAddButton, languagesChipsView,
            divider1,
            workingDaysLabel, daysRow1StackView, daysRow2StackView, sundayButton,
            divider2,
            timeSlotsLabel, editingDayLabel, timeSlotGridView,
            divider3,
            pricingDurationLabel, pricingDurationSubLabel, pricingStackView,
            saveButton
        ]
        allSubviews.forEach { contentView.addSubview($0) }
        saveButton.addSubview(activityIndicator)

        let p: CGFloat = 22
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            profileImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 90),
            profileImageView.heightAnchor.constraint(equalToConstant: 90),
            cameraIconView.widthAnchor.constraint(equalToConstant: 24),
            cameraIconView.heightAnchor.constraint(equalToConstant: 24),
            cameraIconView.trailingAnchor.constraint(equalTo: profileImageView.trailingAnchor),
            cameraIconView.bottomAnchor.constraint(equalTo: profileImageView.bottomAnchor),
            photoHintLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            photoHintLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            aboutMeLabel.topAnchor.constraint(equalTo: photoHintLabel.bottomAnchor, constant: 22),
            aboutMeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            aboutMeTextView.topAnchor.constraint(equalTo: aboutMeLabel.bottomAnchor, constant: 8),
            aboutMeTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            aboutMeTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            aboutMeTextView.heightAnchor.constraint(equalToConstant: 110),

           tagsLabel.topAnchor.constraint(equalTo: aboutMeTextView.bottomAnchor, constant: 18),
           tagsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
           tagsTextField.topAnchor.constraint(equalTo: tagsLabel.bottomAnchor, constant: 8),
           tagsTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
           tagsTextField.trailingAnchor.constraint(equalTo: tagsAddButton.leadingAnchor, constant: -8),
           tagsTextField.heightAnchor.constraint(equalToConstant: 46),
           tagsAddButton.centerYAnchor.constraint(equalTo: tagsTextField.centerYAnchor),
           tagsAddButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
           tagsAddButton.widthAnchor.constraint(equalToConstant: 46),
           tagsAddButton.heightAnchor.constraint(equalToConstant: 46),
           tagsChipsView.topAnchor.constraint(equalTo: tagsTextField.bottomAnchor, constant: 8),
           tagsChipsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
           tagsChipsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

           languagesLabel.topAnchor.constraint(equalTo: tagsChipsView.bottomAnchor, constant: 18),
           languagesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
           languagesTextField.topAnchor.constraint(equalTo: languagesLabel.bottomAnchor, constant: 8),
           languagesTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
           languagesTextField.trailingAnchor.constraint(equalTo: languagesAddButton.leadingAnchor, constant: -8),
           languagesTextField.heightAnchor.constraint(equalToConstant: 46),
           languagesAddButton.centerYAnchor.constraint(equalTo: languagesTextField.centerYAnchor),
           languagesAddButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
           languagesAddButton.widthAnchor.constraint(equalToConstant: 46),
           languagesAddButton.heightAnchor.constraint(equalToConstant: 46),
           languagesChipsView.topAnchor.constraint(equalTo: languagesTextField.bottomAnchor, constant: 8),
           languagesChipsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
           languagesChipsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            divider1.topAnchor.constraint(equalTo: languagesChipsView.bottomAnchor, constant: 20),
            divider1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            divider1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            divider1.heightAnchor.constraint(equalToConstant: 1),

            workingDaysLabel.topAnchor.constraint(equalTo: divider1.bottomAnchor, constant: 20),
            workingDaysLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            daysRow1StackView.topAnchor.constraint(equalTo: workingDaysLabel.bottomAnchor, constant: 14),
            daysRow1StackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            daysRow1StackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            daysRow1StackView.heightAnchor.constraint(equalToConstant: 40),
            daysRow2StackView.topAnchor.constraint(equalTo: daysRow1StackView.bottomAnchor, constant: 10),
            daysRow2StackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            daysRow2StackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            daysRow2StackView.heightAnchor.constraint(equalToConstant: 40),
            sundayButton.topAnchor.constraint(equalTo: daysRow2StackView.bottomAnchor, constant: 10),
            sundayButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            sundayButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            sundayButton.heightAnchor.constraint(equalToConstant: 40),

            divider2.topAnchor.constraint(equalTo: sundayButton.bottomAnchor, constant: 20),
            divider2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            divider2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            divider2.heightAnchor.constraint(equalToConstant: 1),

            timeSlotsLabel.topAnchor.constraint(equalTo: divider2.bottomAnchor, constant: 20),
            timeSlotsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            editingDayLabel.topAnchor.constraint(equalTo: timeSlotsLabel.bottomAnchor, constant: 6),
            editingDayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            timeSlotGridView.topAnchor.constraint(equalTo: editingDayLabel.bottomAnchor, constant: 14),
            timeSlotGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            timeSlotGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            divider3.topAnchor.constraint(equalTo: timeSlotGridView.bottomAnchor, constant: 20),
            divider3.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            divider3.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            divider3.heightAnchor.constraint(equalToConstant: 1),

            pricingDurationLabel.topAnchor.constraint(equalTo: divider3.bottomAnchor, constant: 20),
            pricingDurationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            pricingDurationSubLabel.topAnchor.constraint(equalTo: pricingDurationLabel.bottomAnchor, constant: 6),
            pricingDurationSubLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            pricingStackView.topAnchor.constraint(equalTo: pricingDurationSubLabel.bottomAnchor, constant: 14),
            pricingStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            pricingStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            saveButton.topAnchor.constraint(equalTo: pricingStackView.bottomAnchor, constant: 30),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            saveButton.heightAnchor.constraint(equalToConstant: 42),
            
            activityIndicator.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: saveButton.centerXAnchor)
        ])
    }

    // MARK: - Pricing Rows (one per session type)
    private func setupPricingRows() {
        let durations = [30, 45, 60, 75, 90, 120]

        for type in sessionTypes {
            // Row container
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 10
            row.alignment = .center
            row.distribution = .fill
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
            badge.heightAnchor.constraint(equalToConstant: 46).isActive = true

            // Price text field
            let priceField = UITextField()
            priceField.placeholder = "Price (PKR)"
            priceField.backgroundColor = .white.withAlphaComponent(0.7)
            priceField.layer.cornerRadius = 12
            priceField.keyboardType = .numberPad
            priceField.font = UIFont.systemFont(ofSize: 14)
            priceField.textColor = UIColor(hex: "#1A3A45")
            priceField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
            priceField.leftViewMode = .always
            priceField.translatesAutoresizingMaskIntoConstraints = false
            priceField.heightAnchor.constraint(equalToConstant: 46).isActive = true

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
            durationBtn.heightAnchor.constraint(equalToConstant: 46).isActive = true

            // Capture type for closure
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
                self.present(alert, animated: true)
            }, for: .touchUpInside)

            row.addArrangedSubview(badge)
            row.addArrangedSubview(priceField)
            row.addArrangedSubview(durationBtn)

            pricingStackView.addArrangedSubview(row)
            pricingRows[type] = (priceField: priceField, durationBtn: durationBtn)
        }
    }

    // MARK: - Time Slot Grid  (3 rows × 2 = max 6 slots)
    private func setupTimeSlotGrid() {
        for _ in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 12
            rowStack.distribution = .fillEqually
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            rowStack.heightAnchor.constraint(equalToConstant: 46).isActive = true

            for _ in 0..<2 {
                let tf = makeTimeTextField()
                timeSlotFields.append(tf)
                rowStack.addArrangedSubview(tf)
            }
            timeSlotGridView.addArrangedSubview(rowStack)
        }
        setTimeSlotsEnabled(false)
    }

    private func makeTimeTextField() -> UITextField {
        let tf = UITextField()
        tf.backgroundColor = .white.withAlphaComponent(0.7)
        tf.layer.cornerRadius = 12
        tf.translatesAutoresizingMaskIntoConstraints = false
 
        let clockIcon = UIImageView(image: UIImage(systemName: "clock"))
        clockIcon.tintColor = UIColor(hex: "#5A9AAA")
        clockIcon.contentMode = .scaleAspectFit
        clockIcon.frame = CGRect(x: 6, y: 0, width: 18, height: 18)
        
        let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 18))
        rightContainer.addSubview(clockIcon)
        tf.rightView = rightContainer
        tf.rightViewMode = .always
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
 
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        if #available(iOS 14.0, *) { picker.preferredDatePickerStyle = .wheels }
        picker.addTarget(self, action: #selector(timePickerChanged(_:)), for: .valueChanged)
        tf.inputView = picker
        tf.tintColor = .clear
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textColor = UIColor(hex: "#1A3A45")
        return tf
    }

    private func setTimeSlotsEnabled(_ enabled: Bool) {
        timeSlotGridView.alpha = enabled ? 1.0 : 0.45
        timeSlotFields.forEach { $0.isUserInteractionEnabled = enabled }
    }

    // MARK: - Refresh slot grid for the active day
    private func refreshTimeSlotsUI() {
        guard let day = activeSlotsDay else {
            editingDayLabel.text = "Tap a selected day to edit its slots"
            setTimeSlotsEnabled(false)
            timeSlotFields.forEach { $0.text = "" }
            return
        }
        editingDayLabel.text = "Editing slots for: \(day)"
        setTimeSlotsEnabled(true)
        let slots = schedulePerDay[day] ?? []
        for (i, tf) in timeSlotFields.enumerated() {
            tf.text = i < slots.count ? slots[i] : ""
        }
    }

    /// Flush the current grid values into schedulePerDay for the active day
    private func commitSlotsForActiveDay() {
        guard let day = activeSlotsDay else { return }
        let slots = timeSlotFields.compactMap { $0.text }.filter { !$0.isEmpty }
        if slots.isEmpty {
            schedulePerDay.removeValue(forKey: day)
        } else {
            schedulePerDay[day] = slots
        }
    }

    // MARK: - Setup Actions
    private func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tapGesture)
        cameraIconView.isUserInteractionEnabled = true
        let camTap = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        cameraIconView.addGestureRecognizer(camTap)

        tagsAddButton.addTarget(self, action: #selector(addTag), for: .touchUpInside)
        languagesAddButton.addTarget(self, action: #selector(addLanguage), for: .touchUpInside)

        for (day, btn) in dayButtons {
            btn.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)
            btn.accessibilityLabel = day
        }

        saveButton.addTarget(self, action: #selector(saveAndContinue), for: .touchUpInside)
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Load Existing Data
    private func loadExistingData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let self = self, let data = snapshot?.data() else { return }
            DispatchQueue.main.async {
                self.aboutMeTextView.text = data["about"] as? String ?? ""

                (data["tags"] as? [String] ?? []).forEach {
                    self.addChip($0, to: &self.selectedTags, stackView: self.tagsChipsView)
                }
                (data["languages"] as? [String] ?? []).forEach {
                    self.addChip($0, to: &self.selectedLanguages, stackView: self.languagesChipsView)
                }

                if let schedule = data["schedule"] as? [String: [String]] {
                    self.schedulePerDay = schedule
                    for day in schedule.keys {
                        self.dayButtons[day]?.backgroundColor = self.selectedDayColor
                        self.dayButtons[day]?.setTitleColor(.white, for: .normal)
                    }
                }

                if let prices = data["prices"] as? [String: Int] {
                    self.sessionPrices = prices
                }
                if let durations = data["sessionDurations"] as? [String: Int] {
                    self.sessionDurations = durations
                }
                // Refresh pricing row UI after loading
                for type in self.sessionTypes {
                    if let row = self.pricingRows[type] {
                        let price = self.sessionPrices[type] ?? 0
                        if price > 0 { row.priceField.text = "\(price)" }
                        let mins = self.sessionDurations[type] ?? 45
                        row.durationBtn.configuration?.title = "\(mins) min  ▼"
                    }
                }

                if let url = URL(string: data["profileImageURL"] as? String ?? "") {
                    URLSession.shared.dataTask(with: url) { imgData, _, _ in
                        guard let imgData = imgData else { return }
                        DispatchQueue.main.async { self.profileImageView.image = UIImage(data: imgData) }
                    }.resume()
                }
            }
        }
    }

    // MARK: - Factory Helpers
    static func fieldLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    static func inputTextField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.backgroundColor = .white.withAlphaComponent(0.7)
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        tf.leftViewMode = .always
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textColor = UIColor(hex: "#1A3A45")
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }

    static func addButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("+", for: .normal)
        btn.setTitleColor(UIColor(hex: "#4A8A9A"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .light)
        btn.backgroundColor = .white.withAlphaComponent(0.7)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    static func dividerView() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#9ECEDD").withAlphaComponent(0.5)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func makeDayButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(UIColor(hex: "#1A3A45"), for: .normal)
        btn.backgroundColor = unselectedDayColor
        btn.layer.cornerRadius = 10
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        btn.accessibilityLabel = title
        return btn
    }

    // MARK: - Chip Methods
    // MARK: - Chips (wrapping rows, max 5)
 
    /// Returns the current total chip count across all rows in the stack
    private func chipCount(in stackView: UIStackView) -> Int {
        stackView.arrangedSubviews.compactMap { $0 as? UIStackView }.reduce(0) { $0 + $1.arrangedSubviews.count }
    }
 
    /// Returns the last horizontal row, or creates a new one if it's full (max 2 per row)
    private func currentRow(in stackView: UIStackView, maxPerRow: Int = 2) -> UIStackView {
        if let lastRow = stackView.arrangedSubviews.last as? UIStackView,
           lastRow.arrangedSubviews.count < maxPerRow {
            return lastRow
        }
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .leading
        row.distribution = .fill
        row.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(row)
        return row
    }
 
    private func addChip(_ text: String, to array: inout [String], stackView: UIStackView) {
        guard !text.isEmpty, !array.contains(text) else { return }
 
        // Enforce max 5 limit
        if array.count >= maxChips {
            showAlert(message: "You can add a maximum of \(maxChips) items.")
            return
        }
 
        array.append(text)
 
        // Build chip view
        let container = UIView()
        container.backgroundColor = UIColor(hex: "#B8E6F0")
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false
 
        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = UIColor(hex: "#1A4A5A")
        lbl.translatesAutoresizingMaskIntoConstraints = false
 
        let removeBtn = UIButton(type: .system)
        removeBtn.setTitle("×", for: .normal)
        removeBtn.setTitleColor(UIColor(hex: "#3A7A8A"), for: .normal)
        removeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        removeBtn.translatesAutoresizingMaskIntoConstraints = false
 
        container.addSubview(lbl)
        container.addSubview(removeBtn)
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            lbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            removeBtn.leadingAnchor.constraint(equalTo: lbl.trailingAnchor, constant: 4),
            removeBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            removeBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 30)
        ])
 
        // Remove action: remove chip from its row, clean up empty rows
        let capturedText = text
        let isTagsStack = stackView == tagsChipsView
        removeBtn.addAction(UIAction { [weak self, weak container, weak stackView] _ in
            guard let self = self, let container = container, let stackView = stackView else { return }
            // Find and remove from its parent row
            for case let row as UIStackView in stackView.arrangedSubviews {
                if row.arrangedSubviews.contains(container) {
                    row.removeArrangedSubview(container)
                    container.removeFromSuperview()
                    // Remove empty row
                    if row.arrangedSubviews.isEmpty {
                        stackView.removeArrangedSubview(row)
                        row.removeFromSuperview()
                    }
                    break
                }
            }
            if isTagsStack { self.selectedTags.removeAll { $0 == capturedText } }
            else            { self.selectedLanguages.removeAll { $0 == capturedText } }
        }, for: .touchUpInside)
 
        // Add to current row (max 2 chips per row → wraps automatically)
        let row = currentRow(in: stackView)
        row.addArrangedSubview(container)
    }

    // MARK: - Actions
    @objc private func profileImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    @objc private func addTag() {
        guard let text = tagsTextField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }
        addChip(text, to: &selectedTags, stackView: tagsChipsView)
        tagsTextField.text = ""
    }

    @objc private func addLanguage() {
        guard let text = languagesTextField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }
        addChip(text, to: &selectedLanguages, stackView: languagesChipsView)
        languagesTextField.text = ""
    }

    
    @objc private func dayTapped(_ sender: UIButton) {
        guard let day = sender.accessibilityLabel else { return }

        if activeSlotsDay == day {
            // Second tap: commit & deselect only, do NOT remove slots
            commitSlotsForActiveDay()
            activeSlotsDay = nil
            updateAllDayButtonAppearances()
            return
        }

        // Switching to a different day: commit the previous one first
        commitSlotsForActiveDay()

        if schedulePerDay[day] == nil { schedulePerDay[day] = [] }
        activeSlotsDay = day
        updateAllDayButtonAppearances()
    }

    private func updateAllDayButtonAppearances() {
        for (day, btn) in dayButtons {
            let isInSchedule = schedulePerDay[day] != nil
            let isActive     = day == activeSlotsDay

            if isActive {
                btn.backgroundColor = activeDayColor
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderWidth = 2
                btn.layer.borderColor = UIColor.white.cgColor
            } else if isInSchedule {
                btn.backgroundColor = selectedDayColor
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderWidth = 0
            } else {
                btn.backgroundColor = unselectedDayColor
                btn.setTitleColor(UIColor(hex: "#1A3A45"), for: .normal)
                btn.layer.borderWidth = 0
            }
        }
    }

    @objc private func timePickerChanged(_ sender: UIDatePicker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: sender.date)

        guard let activeField = timeSlotFields.first(where: { $0.isFirstResponder }) else { return }

        // Build proposed slot list with new value substituted in for the active field
        var proposedSlots: [String] = []
        for tf in timeSlotFields {
            guard !tf.isEqual(activeField) else {
                proposedSlots.append(timeString)
                continue
            }
            if let text = tf.text, !text.isEmpty {
                proposedSlots.append(text)
            }
        }

        if let error = validateSlots(proposedSlots) {
            activeField.text = ""
            activeField.resignFirstResponder()
            showAlert(message: error)
            return
        }

        activeField.text = timeString
    }



    // MARK: - Save to Firebase
    @objc private func saveAndContinue() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        // Commit the currently visible day before saving
        commitSlotsForActiveDay()

        let about = aboutMeTextView.text ?? ""
        guard !about.isEmpty else {
            showAlert(message: "Please fill in your About Me section."); return
        }
        guard !schedulePerDay.isEmpty else {
            showAlert(message: "Please select at least one working day and add time slots."); return
        }

        // Remove days that ended up with zero slots
        let cleanSchedule = schedulePerDay.filter { !$0.value.isEmpty }
        guard !cleanSchedule.isEmpty else {
            showAlert(message: "Please add at least one time slot to a working day."); return
        }

        // Final validation pass across every day's slots
        for (day, slots) in cleanSchedule {
            if let error = validateSlots(slots) {
                showAlert(message: "\(day): \(error)"); return
            }
        }

        // Collect prices from each row
        for type in sessionTypes {
            if let row = pricingRows[type], let text = row.priceField.text, let val = Int(text) {
                sessionPrices[type] = val
            }
        }

        saveButton.setTitle("", for: .normal)
        activityIndicator.startAnimating()
        saveButton.isEnabled = false

        if let image = selectedProfileImage {
            uploadProfileImage(image, uid: uid) { [weak self] imageURL in
                self?.saveDataToFirestore(uid: uid, about: about, schedule: cleanSchedule, profileImageURL: imageURL)
            }
        } else {
            saveDataToFirestore(uid: uid, about: about, schedule: cleanSchedule, profileImageURL: nil)
        }
    }
    // MARK: - Slot Validation Helpers
    private func minutes(from timeString: String) -> Int? {
        let parts = timeString.split(separator: ":").map { Int($0) }
        guard parts.count == 2, let h = parts[0], let m = parts[1] else { return nil }
        return h * 60 + m
    }

    private func validateSlots(_ slots: [String]) -> String? {
        let times = slots.compactMap { minutes(from: $0) }.sorted()

        // Duplicate check
        if Set(slots).count != slots.count {
            return "You have duplicate time slots. Each slot must be a unique time."
        }

        // 1-hour minimum gap between consecutive slots
        for i in 1..<times.count {
            let gap = times[i] - times[i - 1]
            if gap < 60 {
                let needed = 60 - gap
                return "Slots must be at least 1 hour apart. One pair is only \(gap) min apart — move it \(needed) min later."
            }
        }
        return nil
    }

    private func uploadProfileImage(_ image: UIImage, uid: String, completion: @escaping (String) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { completion(""); return }
        let ref = storage.reference().child("therapists/\(uid)/profile.jpg")
        let meta = StorageMetadata(); meta.contentType = "image/jpeg"
        ref.putData(imageData, metadata: meta) { _, error in
            if let error = error { print("Upload error: \(error)"); completion(""); return }
            ref.downloadURL { url, _ in completion(url?.absoluteString ?? "") }
        }
    }

    private func saveDataToFirestore(uid: String, about: String,
                                     schedule: [String: [String]],
                                     profileImageURL: String?) {
        var data: [String: Any] = [
            "about":           about,
            "tags":            selectedTags,
            "languages":       selectedLanguages,
            "schedule":        schedule,
            "prices":          sessionPrices,
            "sessionDurations": sessionDurations,
            "updatedAt":       Timestamp()
        ]
        if let url = profileImageURL, !url.isEmpty { data["profileImageURL"] = url }

        db.collection("users").document(uid).updateData(data) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.saveButton.setTitle("Save & Continue", for: .normal)
                self.saveButton.isEnabled = true

                if let error = error {
                    self.showAlert(message: "Failed to save: \(error.localizedDescription)"); return
                }
                self.fetchTherapistAndNavigate(uid: uid)
            }
        }
    }

    private func fetchTherapistAndNavigate(uid: String) {
        DispatchQueue.main.async {
                self.completeOnboarding(uid: uid)
        }
    }
    
    private func completeOnboarding(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "isOnboardingComplete": true
        ]) { error in
            if let error = error { print("Error:", error.localizedDescription); return }
            DispatchQueue.main.async {
                // Navigate to dashboard
                let dashboardVC = TherapistMainTabBarController()
                ListenerManager.shared.startListening()
                self.navigationController?.setViewControllers([dashboardVC], animated: true)
            }
        }
    }
    
    @objc private func handleCancel() {
           navigationController?.popViewController(animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension TherapistOnboardingSchedulingVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        selectedProfileImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        profileImageView.image = selectedProfileImage
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UILabel letter-spacing helper
extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        guard let text = self.text else { return }
        attributedText = NSAttributedString(string: text, attributes: [.kern: spacing])
    }
}
