
//
//  BookingSessionVC.swift
//  HealSync
//
//  Created by Arfa on 02/03/2026.


import UIKit
import FirebaseFirestore
import FirebaseAuth

class BookingSessionVC: UIViewController {
    
    private var therapist: Therapist
    private var selectedDate: Date?
    private var selectedSlot: String?
    private var selectedSessionType: String = "Video"
    private var availableSlots: [String] = []
    private var daysInMonth: [Date] = []
    private var selectedDayIndex: Int?
    private var slotsCollectionHeightConstraint: NSLayoutConstraint?

    // Set this to enable reschedule mode (passed from ClientSessionsVC)
    var rescheduleSession: [String: Any]?

    // Live listener — picks up therapist schedule/price changes instantly
    private var therapistListener: ListenerRegistration?
    
    private let db = Firestore.firestore()
    private let currentUserId = Auth.auth().currentUser?.uid

    private let bgLightBlue   = UIColor(hex: "#CBE9F1")
    private let cardLightBlue = UIColor(hex: "#A8E0ED")
    private let accentBlue    = UIColor(hex: "#66CFE5")
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let backButton   = CustomBackButton()
    private let headerLabel  = TitleLabel(text: "Book a Session", fontSize: 22)
    
    private let calendarCard: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let daysHeaderStack: UIStackView = {
        let stack = UIStackView()
        let days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
        for day in days {
            let lbl = UILabel()
            lbl.text = day
            lbl.font = .systemFont(ofSize: 10, weight: .bold)
            lbl.textColor = .lightGray
            lbl.textAlignment = .center
            stack.addArrangedSubview(lbl)
        }
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let calendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let timeHeaderLabel        = UILabel.sectionHeader(text: "AVAILABLE SLOTS")
    private let slotsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let sessionTypeHeaderLabel = UILabel.sectionHeader(text: "CHOOSE SESSION TYPE")
    private let sessionTypeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let noSlotsLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No slots available for this day"
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.isHidden = false
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let summaryCard = BookingSummaryView()
   
    init(therapist: Therapist) {
        self.therapist = therapist
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Reschedule helpers
    private var isRescheduling: Bool { rescheduleSession != nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgLightBlue
        setupLayout()
        setupCollectionViews()
        setupSessionTypeButtons()
        generateCurrentMonth()

        // In reschedule mode: lock the session type to the original booking's type
        if let session = rescheduleSession,
           let originalType = session["sessionType"] as? String {
            selectedSessionType = originalType
            highlightSelectedSessionType()
            // Disable all session type buttons so the patient cannot change them
            sessionTypeStack.arrangedSubviews.forEach {
                if let btn = $0 as? UIButton {
                    btn.isEnabled = false
                    btn.alpha = btn.accessibilityIdentifier == originalType ? 1.0 : 0.4
                }
            }
            // Update the header label to signal the lock
            sessionTypeHeaderLabel.text = "SESSION TYPE (locked)"
            sessionTypeHeaderLabel.textColor = .systemGray
        }

        updateSummary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        listenToTherapistSchedule()
        if let date = selectedDate { loadAvailableSlots(for: date) }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        therapistListener?.remove()
        therapistListener = nil
    }

    // MARK: - Live Schedule Listener
    private func listenToTherapistSchedule() {
        therapistListener?.remove()
        therapistListener = db.collection("users").document(therapist.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let snapshot = snapshot,
                      let updatedTherapist = Therapist(document: snapshot) else { return }

                DispatchQueue.main.async {
                    self.therapist = updatedTherapist

                    // Refresh session type button labels with latest durations
                    // (labels update but buttons stay disabled in reschedule mode)
                    self.sessionTypeStack.arrangedSubviews.forEach {
                        if let btn = $0 as? UIButton,
                           let type = btn.accessibilityIdentifier {
                            let mins = updatedTherapist.sessionDurations[type] ?? 45
                            btn.setTitle("\(type)  •  \(mins) min", for: .normal)
                        }
                    }

                    // Refresh available slots if a date is selected
                    if let date = self.selectedDate {
                        self.loadAvailableSlots(for: date)
                    }

                    self.updateSummary()
                }
            }
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [backButton, headerLabel, calendarCard, timeHeaderLabel, slotsCollectionView,
         sessionTypeHeaderLabel, sessionTypeStack, summaryCard].forEach { contentView.addSubview($0) }
        
        [monthLabel, daysHeaderStack, calendarCollectionView].forEach { calendarCard.addSubview($0) }
        
        slotsCollectionHeightConstraint = slotsCollectionView.heightAnchor.constraint(equalToConstant: 60)
        slotsCollectionHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: -50),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            backButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 35),
            backButton.heightAnchor.constraint(equalToConstant: 35),
            
            headerLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            
            calendarCard.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 25),
            calendarCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            calendarCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            calendarCard.heightAnchor.constraint(equalToConstant: 350),
            
            monthLabel.topAnchor.constraint(equalTo: calendarCard.topAnchor, constant: 15),
            monthLabel.centerXAnchor.constraint(equalTo: calendarCard.centerXAnchor),
            
            daysHeaderStack.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: 15),
            daysHeaderStack.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor, constant: 10),
            daysHeaderStack.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor, constant: -10),
            
            calendarCollectionView.topAnchor.constraint(equalTo: daysHeaderStack.bottomAnchor, constant: 10),
            calendarCollectionView.leadingAnchor.constraint(equalTo: daysHeaderStack.leadingAnchor),
            calendarCollectionView.trailingAnchor.constraint(equalTo: daysHeaderStack.trailingAnchor),
            calendarCollectionView.bottomAnchor.constraint(equalTo: calendarCard.bottomAnchor, constant: -10),
            
            timeHeaderLabel.topAnchor.constraint(equalTo: calendarCard.bottomAnchor, constant: 25),
            timeHeaderLabel.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor),
            
            slotsCollectionView.topAnchor.constraint(equalTo: timeHeaderLabel.bottomAnchor, constant: 12),
            slotsCollectionView.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor),
            slotsCollectionView.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor),
            
            sessionTypeHeaderLabel.topAnchor.constraint(equalTo: slotsCollectionView.bottomAnchor, constant: 20),
            sessionTypeHeaderLabel.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor),
            
            sessionTypeStack.topAnchor.constraint(equalTo: sessionTypeHeaderLabel.bottomAnchor, constant: 12),
            sessionTypeStack.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor),
            sessionTypeStack.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor),
            
            summaryCard.topAnchor.constraint(equalTo: sessionTypeStack.bottomAnchor, constant: 30),
            summaryCard.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor),
            summaryCard.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor),
            summaryCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
        
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        summaryCard.confirmButton.addTarget(self, action: #selector(confirmBooking), for: .touchUpInside)
        summaryCard.cancelButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        contentView.addSubview(noSlotsLabel)
        NSLayoutConstraint.activate([
            noSlotsLabel.centerXAnchor.constraint(equalTo: slotsCollectionView.centerXAnchor),
            noSlotsLabel.centerYAnchor.constraint(equalTo: slotsCollectionView.centerYAnchor)
        ])
    }

    private func setupCollectionViews() {
        calendarCollectionView.dataSource = self
        calendarCollectionView.delegate   = self
        calendarCollectionView.register(DayCell.self,  forCellWithReuseIdentifier: "DayCell")
        slotsCollectionView.dataSource    = self
        slotsCollectionView.delegate      = self
        slotsCollectionView.register(SlotCell.self, forCellWithReuseIdentifier: "SlotCell")
    }
    
    // MARK: - Calendar
    private func generateCurrentMonth() {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: now).uppercased()
        
        guard let monthRange       = calendar.range(of: .day, in: .month, for: now),
              let firstDateOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return }
        
        let firstWeekday = calendar.component(.weekday, from: firstDateOfMonth)
        let padding = (firstWeekday + 5) % 7
        daysInMonth = Array(repeating: Date.distantPast, count: padding)
        for day in 0..<monthRange.count {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDateOfMonth) {
                daysInMonth.append(date)
            }
        }
        calendarCollectionView.reloadData()
    }

    // MARK: - Load Slots
    private func loadAvailableSlots(for date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: date)
        let slots   = therapist.schedule[weekday] ?? []
        let dayInt  = Calendar.current.component(.day, from: date)

        db.collection("users").document(therapist.uid).collection("bookedSessions")
            .whereField("dateInt", isEqualTo: dayInt)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Slots fetch error:", error.localizedDescription)
                    return
                }

                // Only confirmed bookings block a slot
                let bookedSlots = snapshot?.documents.compactMap { doc -> String? in
                    let data   = doc.data()
                    let status = data["status"] as? String ?? "confirmed"
                    guard status == "confirmed" else { return nil }
                    return data["slot"] as? String
                } ?? []

                self.availableSlots = slots.filter { !bookedSlots.contains($0) }

                DispatchQueue.main.async {
                    let hasSlots = !self.availableSlots.isEmpty
                    self.slotsCollectionView.isHidden = !hasSlots
                    self.noSlotsLabel.isHidden = hasSlots

                    let newHeight: CGFloat
                    if hasSlots {
                        let rows = ceil(CGFloat(self.availableSlots.count) / 2)
                        newHeight = rows * 45 + (rows - 1) * 10
                    } else {
                        newHeight = 60
                    }
                    UIView.animate(withDuration: 0.25) {
                        self.slotsCollectionHeightConstraint?.constant = newHeight
                        self.view.layoutIfNeeded()
                    }
                    if !hasSlots { self.selectedSlot = nil; self.updateSummary() }
                    self.slotsCollectionView.reloadData()
                }
            }
    }

    private func setupSessionTypeButtons() {
        let types = ["Video", "Audio", "Chat"]
        for type in types {
            let btn = UIButton(type: .system)
            let mins = therapist.sessionDurations[type] ?? 45
            btn.setTitle("\(type)  •  \(mins) min", for: .normal)
            btn.backgroundColor = cardLightBlue
            btn.setTitleColor(.black, for: .normal)
            btn.layer.cornerRadius = 10
            btn.heightAnchor.constraint(equalToConstant: 45).isActive = true
            btn.addTarget(self, action: #selector(sessionTypeTapped(_:)), for: .touchUpInside)
            btn.accessibilityIdentifier = type
            sessionTypeStack.addArrangedSubview(btn)
        }
        highlightSelectedSessionType()
    }
    
    @objc private func sessionTypeTapped(_ sender: UIButton) {
        guard let type = sender.accessibilityIdentifier else { return }
        selectedSessionType = type
        highlightSelectedSessionType()
        updateSummary()
    }
    
    private func highlightSelectedSessionType() {
        for view in sessionTypeStack.arrangedSubviews {
            if let btn = view as? UIButton {
                let isSelected = btn.accessibilityIdentifier == selectedSessionType
                btn.backgroundColor = isSelected ? accentBlue : cardLightBlue
            }
        }
    }

    private func updateSummary() {
        summaryCard.therapistLabel.text = "Therapist: \(therapist.fullName)"
        
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM, yyyy"
            summaryCard.dateLabel.text = "Date: \(formatter.string(from: date))"
        } else {
            summaryCard.dateLabel.text = "Date: --"
        }
        
        summaryCard.timeLabel.text = "Time: \(selectedSlot ?? "--")"
        summaryCard.typeLabel.text = "Format: \(selectedSessionType)"

        let duration = therapist.sessionDurations[selectedSessionType] ?? 45
        UIView.transition(with: summaryCard.durationLabel, duration: 0.2, options: .transitionCrossDissolve) {
            self.summaryCard.durationLabel.text = "Duration: \(duration) min"
        }

        // In reschedule mode, show the original price (no change)
        let price: Int
        if let session = rescheduleSession {
            price = session["price"] as? Int ?? therapist.prices[selectedSessionType] ?? 0
        } else {
            price = therapist.prices[selectedSessionType] ?? 0
        }
        UIView.transition(with: summaryCard.priceLabel, duration: 0.25, options: .transitionCrossDissolve) {
            self.summaryCard.priceLabel.text = "Total Price: \(price) PKR"
        }
        
        let isReady = selectedSlot != nil && selectedDate != nil
        summaryCard.confirmButton.isEnabled = isReady
        summaryCard.confirmButton.alpha     = isReady ? 1.0 : 0.5
    }
    
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func confirmBooking() {
        guard let currentUser  = Auth.auth().currentUser,
              let selectedDate = selectedDate,
              let selectedSlot = selectedSlot else { return }

        let patientId = currentUser.uid
        let now       = Date()
        let calendar  = Calendar.current

        // In reschedule mode, honour the original price/duration — not current therapist rates
        let price: Int
        let duration: Int
        if let session = rescheduleSession {
            price    = session["price"]    as? Int ?? therapist.prices[selectedSessionType] ?? 0
            duration = session["duration"] as? Int ?? therapist.sessionDurations[selectedSessionType] ?? 45
        } else {
            price    = therapist.prices[selectedSessionType] ?? 0
            duration = therapist.sessionDurations[selectedSessionType] ?? 45
        }

        if selectedDate < calendar.startOfDay(for: now) {
            showAlert(message: "You cannot book a past date."); return
        }

        if calendar.isDate(selectedDate, inSameDayAs: now) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            if let slotDate = dateFormatter.date(from: selectedSlot) {
                let slotComps = calendar.dateComponents([.hour, .minute], from: slotDate)
                var nowComps  = calendar.dateComponents([.year, .month, .day], from: now)
                nowComps.hour = slotComps.hour; nowComps.minute = slotComps.minute
                if let slotDateTime = calendar.date(from: nowComps), slotDateTime <= now {
                    showAlert(message: "You cannot book a past time slot."); return
                }
            }
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        guard let slotTime = timeFormatter.date(from: selectedSlot) else {
            showAlert(message: "Invalid time slot."); return
        }

        var fullDateComponents    = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let slotComponents        = calendar.dateComponents([.hour, .minute], from: slotTime)
        fullDateComponents.hour   = slotComponents.hour
        fullDateComponents.minute = slotComponents.minute
        guard let sessionDateTime = calendar.date(from: fullDateComponents) else {
            showAlert(message: "Could not create session time."); return
        }

        let slotIdFormatter = DateFormatter()
        slotIdFormatter.dateFormat = "yyyy-MM-dd_HH:mm"
        let slotId    = slotIdFormatter.string(from: sessionDateTime)
        let bookingId = UUID().uuidString
        let day   = calendar.component(.day,   from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        let year  = calendar.component(.year,  from: selectedDate)

        db.collection("users").document(patientId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error { print("Error fetching patient:", error.localizedDescription); return }
            guard let data = snapshot?.data(), let patientName = data["fullName"] as? String else { return }

            let bookingData: [String: Any] = [
                "bookingId":       bookingId,
                "therapistId":     self.therapist.uid,
                "therapistName":   self.therapist.fullName,
                "patientId":       patientId,
                "patientName":     patientName,
                "date":            Timestamp(date: selectedDate),
                "sessionDateTime": Timestamp(date: sessionDateTime),
                "dateInt":         day,
                "month":           month,
                "year":            year,
                "slot":            selectedSlot,
                "sessionType":     self.selectedSessionType,
                "duration":        duration,
                "price":           price,
                "status":          "confirmed",
                "createdAt":       Timestamp()
            ]

            let therapistSlotRef = self.db.collection("users")
                .document(self.therapist.uid)
                .collection("bookedSessions")
                .document(slotId)

            therapistSlotRef.getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error checking slot:", error.localizedDescription)
                    self.showAlert(message: "Could not verify slot availability. Please try again.")
                    return
                }
                // Only block if the slot exists AND is still confirmed
                // (cancelled slots should be available again for rebooking)
                if let data = snapshot?.data(),
                   (data["status"] as? String ?? "confirmed") == "confirmed" {
                    self.showAlert(message: "This slot was just booked. Please choose another.")
                    self.loadAvailableSlots(for: selectedDate)
                    return
                }

                // ── Reschedule mode: update existing booking, no new payment ──
                if self.isRescheduling {
                    self.performReschedule(
                        newBookingData: bookingData,
                        newSlotId:      slotId,
                        patientId:      patientId
                    )
                    return
                }

                let paymentVC = PaymentVC()
                paymentVC.bookingData            = bookingData
                paymentVC.therapistId            = self.therapist.uid
                paymentVC.patientId              = patientId
                paymentVC.bookingId              = slotId
                paymentVC.modalPresentationStyle = .overFullScreen

                paymentVC.onPaymentSuccess = {
                    // Write session data to both sides in a single atomic batch
                    let therapistRef = self.db.collection("users")
                        .document(self.therapist.uid)
                        .collection("bookedSessions")
                        .document(slotId)
                    let patientRef = self.db.collection("users")
                        .document(patientId)
                        .collection("mySessions")
                        .document(slotId)

                    let batch = self.db.batch()
                    batch.setData(bookingData, forDocument: therapistRef)
                    batch.setData(bookingData, forDocument: patientRef)

                    batch.commit { error in
                        if let error = error {
                            print("Booking write failed:", error.localizedDescription)
                            return
                        }
                        print("Booking saved successfully to Firestore")
                        // Fire push notifications to both parties
                        notifyUser(userId: patientId, session: bookingData, type: .booked)
                        saveTherapistNotification(
                            therapistId: self.therapist.uid,
                            session: bookingData,
                            type: .booked
                        )
                    }
                }
                self.present(paymentVC, animated: true)
            }
        }
    }
    
    func showAlert(title: String = "Error", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Reschedule
    private func performReschedule(newBookingData: [String: Any], newSlotId: String, patientId: String) {
        guard let oldSession    = rescheduleSession,
              let oldTimestamp  = oldSession["sessionDateTime"] as? Timestamp else { return }

        let oldDate      = oldTimestamp.dateValue()
        let formatter    = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH:mm"
        let oldSlotId    = formatter.string(from: oldDate)
        let rescheduleCount = (oldSession["rescheduleCount"] as? Int ?? 0) + 1

        var updatedData = newBookingData
        updatedData["rescheduleCount"] = rescheduleCount
        updatedData["rescheduledAt"]   = Timestamp(date: Date())
        updatedData["previousSlotId"]  = oldSlotId

        let therapistOldRef = db.collection("users").document(therapist.uid)
            .collection("bookedSessions").document(oldSlotId)
        let patientOldRef   = db.collection("users").document(patientId)
            .collection("mySessions").document(oldSlotId)
        let therapistNewRef = db.collection("users").document(therapist.uid)
            .collection("bookedSessions").document(newSlotId)
        let patientNewRef   = db.collection("users").document(patientId)
            .collection("mySessions").document(newSlotId)

        let batch = db.batch()
        batch.deleteDocument(therapistOldRef)
        batch.deleteDocument(patientOldRef)
        batch.setData(updatedData, forDocument: therapistNewRef)
        batch.setData(updatedData, forDocument: patientNewRef)

        batch.commit { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                print("Reschedule failed:", error.localizedDescription)
                return
            }
            notifyUser(userId: patientId, session: updatedData, type: .rescheduled)
            saveTherapistNotification(therapistId: self.therapist.uid, session: updatedData, type: .rescheduled)
            DispatchQueue.main.async { self.showRescheduleSuccess() }
        }
    }

    private func showRescheduleSuccess() {
        let alert = UIAlertController(
            title: "Session Rescheduled ✓",
            message: "Your session has been rescheduled successfully. Both you and your therapist have been notified.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Go to Sessions", style: .default) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: false)
            let scene  = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let tabBar = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController as? UITabBarController
            tabBar?.selectedIndex = 1
        })
        present(alert, animated: true)
    }
}


extension BookingSessionVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView == calendarCollectionView ? daysInMonth.count : availableSlots.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == calendarCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! DayCell
            let date = daysInMonth[indexPath.item]
            if date == Date.distantPast {
                cell.configure(day: 0, isSelected: false, accentColor: .clear)
                cell.isHidden = true
            } else {
                cell.isHidden = false
                cell.configure(day: Calendar.current.component(.day, from: date),
                                isSelected: indexPath.item == selectedDayIndex,
                                accentColor: accentBlue)
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SlotCell", for: indexPath) as! SlotCell
            let slot = availableSlots[indexPath.item]
            cell.configure(slot: slot, isSelected: slot == selectedSlot,
                           accentColor: accentBlue, normalColor: cardLightBlue)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == calendarCollectionView {
            let date = daysInMonth[indexPath.item]
            guard date != Date.distantPast else { return }
            selectedDayIndex = indexPath.item
            selectedDate     = date
            loadAvailableSlots(for: date)
            calendarCollectionView.reloadData()
        } else {
            selectedSlot = availableSlots[indexPath.item]
            slotsCollectionView.reloadData()
        }
        updateSummary()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == calendarCollectionView {
            return CGSize(width: collectionView.frame.width / 7, height: 35)
        } else {
            return CGSize(width: (collectionView.frame.width - 10) / 2, height: 45)
        }
    }
}

// MARK: - BookingSummaryView
class BookingSummaryView: UIView {
    let therapistLabel = UILabel.summaryLabel()
    let dateLabel      = UILabel.summaryLabel()
    let timeLabel      = UILabel.summaryLabel()
    let typeLabel      = UILabel.summaryLabel()
    let durationLabel  = UILabel.summaryLabel()
    let priceLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Total Price: 0 PKR"
        lbl.font = .systemFont(ofSize: 14, weight: .bold)
        return lbl
    }()
    
    let confirmButton = UIButton.actionButton(title: "CONFIRM", color: UIColor(hex: "#A3E8AB"))
    let cancelButton  = UIButton.actionButton(title: "CANCEL",  color: UIColor(hex: "#E3B5B5"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white.withAlphaComponent(0.6)
        layer.cornerRadius = 20
        translatesAutoresizingMaskIntoConstraints = false
        
        let infoStack = UIStackView(arrangedSubviews: [
            therapistLabel, dateLabel, timeLabel, typeLabel, durationLabel, priceLabel
        ])
        infoStack.axis    = .vertical
        infoStack.spacing = 8
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        
        let btnStack = UIStackView(arrangedSubviews: [confirmButton, cancelButton])
        btnStack.spacing      = 15
        btnStack.distribution = .fillEqually
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(infoStack)
        addSubview(btnStack)
        
        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            infoStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            btnStack.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 20),
            btnStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            btnStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            btnStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            btnStack.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

class DayCell: UICollectionViewCell {
    private let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        label.frame = contentView.bounds
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
        contentView.layer.cornerRadius = 17.5
    }
    func configure(day: Int, isSelected: Bool, accentColor: UIColor) {
        label.text = day == 0 ? "" : "\(day)"
        contentView.backgroundColor = isSelected ? accentColor : .clear
        label.textColor = isSelected ? .white : .black
    }
    required init?(coder: NSCoder) { fatalError() }
}

class SlotCell: UICollectionViewCell {
    private let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        label.frame = contentView.bounds
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .medium)
        contentView.layer.cornerRadius = 10
    }
    func configure(slot: String, isSelected: Bool, accentColor: UIColor, normalColor: UIColor) {
        label.text = slot
        contentView.backgroundColor = isSelected ? accentColor : normalColor
        label.textColor = .black
    }
    required init?(coder: NSCoder) { fatalError() }
}

extension UILabel {
    static func sectionHeader(text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 14, weight: .bold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }
    static func summaryLabel() -> UILabel {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14)
        return lbl
    }
}

extension UIButton {
    static func actionButton(title: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = color
        btn.setTitleColor(.black, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        btn.layer.cornerRadius = 8
        return btn
    }
}
