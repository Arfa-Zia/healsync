//
//  TherapistManageSchedulingVC.swift
//  HealSync
//
//  Created by Arfa on 26/03/2026.
//

import UIKit

import UIKit
import FirebaseFirestore
import FirebaseAuth

class TherapistSchedulingVC: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var schedulePerDay: [String: [String]] = [:]
    private var activeSlotsDay: String? { didSet { refreshTimeSlotsUI() } }
    private var timeSlotFields: [UITextField] = []
    private var dayButtons: [String: UIButton] = [:]
    private let allDays = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]

    // MARK: - Colors
    private let bgColor            = UIColor(hex: "#D6EEF5")
    private let accentBlue         = UIColor(hex: "#4FC3D8")
    private let selectedDayColor   = UIColor(hex: "#4FC3D8")
    private let activeDayColor     = UIColor(hex: "#1A7A8A")
    private let unselectedDayColor = UIColor(hex: "#B8E6F0")
    private let textColor          = UIColor(hex: "#1A3A45")

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
        lbl.text = "Set the days and times you're available for sessions"
        lbl.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        lbl.textColor = UIColor(hex: "#5A8A99")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

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

    private let divider1: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#9ECEDD").withAlphaComponent(0.5)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

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

    private let slotsHintLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Up to 6 time slots per day"
        lbl.font = UIFont.systemFont(ofSize: 11)
        lbl.textColor = UIColor(hex: "#5A8A99")
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let divider2: UIView = {
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
        titleLabel.text = "EDIT SCHEDULE"
        saveButton.setTitle("Save Changes", for: .normal)

        setupUI()
        setupTimeSlotGrid()
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

        // Build day buttons
        for day in ["Monday", "Tuesday", "Wednesday"] {
            let btn = makeDayButton(title: day)
            daysRow1StackView.addArrangedSubview(btn)
            dayButtons[day] = btn
        }
        for day in ["Thursday", "Friday", "Saturday"] {
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
            titleLabel, subtitleLabel,
            workingDaysLabel, daysRow1StackView, daysRow2StackView, sundayButton,
            divider1,
            timeSlotsLabel, editingDayLabel, timeSlotGridView, slotsHintLabel,
            divider2,
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
            subtitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            workingDaysLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
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

            divider1.topAnchor.constraint(equalTo: sundayButton.bottomAnchor, constant: 20),
            divider1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            divider1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            divider1.heightAnchor.constraint(equalToConstant: 1),

            timeSlotsLabel.topAnchor.constraint(equalTo: divider1.bottomAnchor, constant: 20),
            timeSlotsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),

            editingDayLabel.topAnchor.constraint(equalTo: timeSlotsLabel.bottomAnchor, constant: 6),
            editingDayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),

            timeSlotGridView.topAnchor.constraint(equalTo: editingDayLabel.bottomAnchor, constant: 14),
            timeSlotGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            timeSlotGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            slotsHintLabel.topAnchor.constraint(equalTo: timeSlotGridView.bottomAnchor, constant: 10),
            slotsHintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),

            divider2.topAnchor.constraint(equalTo: slotsHintLabel.bottomAnchor, constant: 20),
            divider2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            divider2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            divider2.heightAnchor.constraint(equalToConstant: 1),

            saveButton.topAnchor.constraint(equalTo: divider2.bottomAnchor, constant: 24),
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

    // MARK: - Time Slot Grid (3 rows × 2 = 6 slots max)
    private func setupTimeSlotGrid() {
        for _ in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal; rowStack.spacing = 12
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

    private func commitSlotsForActiveDay() {
        guard let day = activeSlotsDay else { return }
        let slots = timeSlotFields.compactMap { $0.text }.filter { !$0.isEmpty }
        if slots.isEmpty { schedulePerDay.removeValue(forKey: day) }
        else             { schedulePerDay[day] = slots }
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
                if let schedule = data["schedule"] as? [String: [String]] {
                    self.schedulePerDay = schedule
                    for day in schedule.keys {
                        self.dayButtons[day]?.backgroundColor = self.selectedDayColor
                        self.dayButtons[day]?.setTitleColor(.white, for: .normal)
                    }
                }
            }
        }
    }

    // MARK: - Day Tapped
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

    // MARK: - Save
    @objc private func handleSave() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        commitSlotsForActiveDay()

        guard !schedulePerDay.isEmpty else {
            showAlert(message: "Please select at least one working day."); return
        }
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

        setSavingState(true)

        let data: [String: Any] = [
            "schedule":  cleanSchedule,
            "updatedAt": Timestamp()
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

    @objc private func handleCancel() {
        navigationController?.popViewController(animated: true)
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

    private func makeDayButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(UIColor(hex: "#1A3A45"), for: .normal)
        btn.backgroundColor = unselectedDayColor
        btn.layer.cornerRadius = 10
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        btn.accessibilityLabel = title
        btn.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)
        return btn
    }
}
