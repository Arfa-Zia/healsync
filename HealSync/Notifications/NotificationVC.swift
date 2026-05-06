//
//  NotificationVC.swift
//  HealSync
//
//  Created by Arfa on 06/03/2026.
//
//
//import UIKit
//import FirebaseFirestore
//import FirebaseAuth
//
//class NotificationsVC: UIViewController {
//
//    private let db = Firestore.firestore()
//    private var notifications: [[String: Any]] = []
//
//    private let tableView = UITableView()
//    
//    private let emptyLabel: UILabel = {
//        let label = UILabel()
//        label.text = "No Notifications"
//        label.textAlignment = .center
//        label.font = .systemFont(ofSize: 18, weight: .medium)
//        label.textColor = .gray
//        label.isHidden = true  // hidden by default
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let titleLabel = UILabel()
//        titleLabel.text = "Notifications"
//        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
//        titleLabel.textColor = .black
//
//        navigationItem.titleView = titleLabel
//        
//        view.backgroundColor = UIColor(hex: "#D1F0F8")
//        tableView.backgroundColor = .clear
//        tableView.separatorStyle = .none
//        
//        let button = UIButton(type: .system)
//        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .medium)
//        button.setImage(UIImage.init(systemName: "checkmark.circle", withConfiguration: config), for: .normal)
//        button.setTitle("  Read All  ", for: .normal)
//        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
//        button.sizeToFit()
//        button.addTarget(self, action: #selector(markAllAsRead), for: .touchUpInside)
//
//        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
//
//        tableView.register(NotificationCell.self,
//                           forCellReuseIdentifier: NotificationCell.identifier)
//
//        tableView.delegate = self
//        tableView.dataSource = self
//
//        view.addSubview(tableView)
//        tableView.frame = view.bounds
//        
//        view.addSubview(emptyLabel)
//        
//        NSLayoutConstraint.activate([
//            tableView.topAnchor.constraint(equalTo: view.topAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//        
//
//        fetchNotifications()
//
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
//        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
//    }
//
//    private func fetchNotifications() {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//
//        db.collection("users")
//            .document(uid)
//            .collection("notifications")
//            .order(by: "createdAt", descending: true)
//            .addSnapshotListener { [weak self] snapshot, error in
//                guard let self = self else { return }
//                
//                if let docs = snapshot?.documents {
//                    self.notifications = docs.map { $0.data() }
//                    
//                    DispatchQueue.main.async {
//                        self.tableView.reloadData()
//                        self.emptyLabel.isHidden = !self.notifications.isEmpty
//                    }
//                }
//            }
//    }
//    @objc func markAllAsRead() {
//
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//
//        db.collection("users")
//            .document(uid)
//            .collection("notifications")
//            .whereField("isRead", isEqualTo: false)
//            .getDocuments { snapshot, error in
//
//                snapshot?.documents.forEach { doc in
//                    doc.reference.updateData(["isRead": true])
//                }
//            }
//    }
//}
//
//extension NotificationsVC: UITableViewDataSource, UITableViewDelegate {
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return notifications.count
//    }
//
//    func tableView(_ tableView: UITableView,
//                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        let cell = tableView.dequeueReusableCell(
//            withIdentifier: NotificationCell.identifier,
//            for: indexPath
//        ) as! NotificationCell
//
//        let notification = notifications[indexPath.row]
//
//        let message = notification["message"] as? String ?? ""
//
//        var date = Date()
//
//        if let timestamp = notification["createdAt"] as? Timestamp {
//            date = timestamp.dateValue()
//        }
//
//        let isRead = notification["isRead"] as? Bool ?? true
//        let type = notification["type"] as? String ?? "reminder"
//
//        cell.configure(
//            message: message,
//            date: date,
//            isRead: isRead,
//            type: type
//        )
//
//        return cell
//    }
//    func tableView(_ tableView: UITableView,
//                   commit editingStyle: UITableViewCell.EditingStyle,
//                   forRowAt indexPath: IndexPath) {
//
//        if editingStyle == .delete {
//
//            guard let uid = Auth.auth().currentUser?.uid else { return }
//
//            let notification = notifications[indexPath.row]
//
//            guard let timestamp = notification["createdAt"] as? Timestamp else { return }
//
//            db.collection("users")
//                .document(uid)
//                .collection("notifications")
//                .whereField("createdAt", isEqualTo: timestamp)
//                .getDocuments { snapshot, error in
//
//                    snapshot?.documents.first?.reference.delete()
//                }
//        }
//    }
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//
//        let notification = notifications[indexPath.row]
//
//        guard let timestamp = notification["createdAt"] as? Timestamp else { return }
//
//        db.collection("users")
//            .document(uid)
//            .collection("notifications")
//            .whereField("createdAt", isEqualTo: timestamp)
//            .getDocuments { snapshot, error in
//
//                snapshot?.documents.first?.reference.updateData([
//                    "isRead": true
//                ])
//            }
//    }
//}
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class NotificationsVC: UIViewController {

    private let db = Firestore.firestore()
    private var notifications: [[String: Any]] = []

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
        lbl.text = "Notifications"
        lbl.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let readAllBtn: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        btn.setImage(UIImage(systemName: "checkmark.circle", withConfiguration: config), for: .normal)
        btn.setTitle("  Read All", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        btn.tintColor = .systemBlue
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let navDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#C8EDF5")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Table
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle  = .none
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
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        let iv = UIImageView(image: UIImage(systemName: "bell.slash", withConfiguration: config))
        iv.tintColor = UIColor(hex: "#4FC3D8").withAlphaComponent(0.5)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No Notifications"
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#D1F0F8")
        setupLayout()
        fetchNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide system nav bar — we have our own
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore for any VC we might push/pop back to
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Layout
    private func setupLayout() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false

        // Nav bar subviews
        [backBtn, titleLabel, readAllBtn, navDivider].forEach { navBar.addSubview($0) }

        // Empty view subviews
        emptyView.addSubview(emptyIcon)
        emptyView.addSubview(emptyLabel)

        [navBar, tableView, emptyView].forEach { view.addSubview($0) }

        tableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.identifier)
        tableView.delegate   = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 20, right: 0)

        NSLayoutConstraint.activate([

            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -30),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 40),

            backBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 14),
            backBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.centerXAnchor.constraint(equalTo: navBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),

            readAllBtn.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -14),
            readAllBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),

            navDivider.leadingAnchor.constraint(equalTo: navBar.leadingAnchor),
            navDivider.trailingAnchor.constraint(equalTo: navBar.trailingAnchor),
            navDivider.bottomAnchor.constraint(equalTo: navBar.bottomAnchor),
            navDivider.heightAnchor.constraint(equalToConstant: 1),

            // Table starts right below custom nav bar
            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Empty state
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyIcon.topAnchor.constraint(equalTo: emptyView.topAnchor),
            emptyIcon.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 56),
            emptyIcon.heightAnchor.constraint(equalToConstant: 56),

            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 12),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor)
        ])

        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        readAllBtn.addTarget(self, action: #selector(markAllAsRead), for: .touchUpInside)
    }

    // MARK: - Fetch
    private func fetchNotifications() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).collection("notifications")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                if let docs = snapshot?.documents {
                    self.notifications = docs.map { $0.data() }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.emptyView.isHidden = !self.notifications.isEmpty
                    }
                }
            }
    }

    // MARK: - Actions
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc func markAllAsRead() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, _ in
                snapshot?.documents.forEach { $0.reference.updateData(["isRead": true]) }
            }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension NotificationsVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: NotificationCell.identifier, for: indexPath) as! NotificationCell
        let n = notifications[indexPath.row]
        cell.configure(
            message: n["message"] as? String ?? "",
            date:    (n["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            isRead:  n["isRead"]   as? Bool   ?? true,
            type:    n["type"]     as? String ?? "reminder"
        )
        return cell
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete,
              let uid = Auth.auth().currentUser?.uid,
              let timestamp = notifications[indexPath.row]["createdAt"] as? Timestamp else { return }
        db.collection("users").document(uid).collection("notifications")
            .whereField("createdAt", isEqualTo: timestamp)
            .getDocuments { snapshot, _ in snapshot?.documents.first?.reference.delete() }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let uid = Auth.auth().currentUser?.uid,
              let timestamp = notifications[indexPath.row]["createdAt"] as? Timestamp else { return }
        db.collection("users").document(uid).collection("notifications")
            .whereField("createdAt", isEqualTo: timestamp)
            .getDocuments { snapshot, _ in
                snapshot?.documents.first?.reference.updateData(["isRead": true])
            }
    }
}

