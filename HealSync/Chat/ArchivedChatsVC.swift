//
//  ArchivedChatsVC.swift
//  HealSync
//
//  Created by Arfa on 19/03/2026.
//


import UIKit
import FirebaseAuth
import FirebaseFirestore

class ArchivedChatsVC: UIViewController {

    // MARK: - Properties
    private var chats: [Chat] = []
    private var patientListener:   ListenerRegistration?
    private var therapistListener: ListenerRegistration?
    private let currentUserId   = Auth.auth().currentUser?.uid ?? ""
    private var currentUserName = ""

    // MARK: - UI
    private let navBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#D1F0F8")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backBtn = CustomBackButton()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Archived Chats"
        lbl.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        lbl.textColor = .black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let navDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#C8EDF5")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle  = .none
        tv.showsVerticalScrollIndicator = false
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
        let config = UIImage.SymbolConfiguration(pointSize: 44, weight: .light)
        let iv = UIImageView(image: UIImage(systemName: "archivebox", withConfiguration: config))
        iv.tintColor = UIColor(hex: "#4FC3D8").withAlphaComponent(0.5)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No archived chats"
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let emptySubLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Session chats you archive will appear here"
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .systemGray
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
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
        view.backgroundColor = UIColor(hex: "#D1F0F8")
        setupLayout()
        fetchCurrentUserName()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        startListening()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        patientListener?.remove()
        therapistListener?.remove()
    }

    deinit {
        patientListener?.remove()
        therapistListener?.remove()
    }

    // MARK: - Layout
    private func setupLayout() {
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        [backBtn, titleLabel, navDivider].forEach { navBar.addSubview($0) }

        emptyView.addSubview(emptyIcon)
        emptyView.addSubview(emptyLabel)
        emptyView.addSubview(emptySubLabel)

        [navBar, tableView, emptyView, activityIndicator].forEach { view.addSubview($0) }

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(ChatListCell.self, forCellReuseIdentifier: ChatListCell.reuseID)
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 30, right: 0)

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -40),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 52),

            backBtn.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 14),
            backBtn.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.centerXAnchor.constraint(equalTo: navBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),

            navDivider.leadingAnchor.constraint(equalTo: navBar.leadingAnchor),
            navDivider.trailingAnchor.constraint(equalTo: navBar.trailingAnchor),
            navDivider.bottomAnchor.constraint(equalTo: navBar.bottomAnchor),
            navDivider.heightAnchor.constraint(equalToConstant: 1),

            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyIcon.topAnchor.constraint(equalTo: emptyView.topAnchor),
            emptyIcon.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 60),
            emptyIcon.heightAnchor.constraint(equalToConstant: 60),

            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 14),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),

            emptySubLabel.topAnchor.constraint(equalTo: emptyLabel.bottomAnchor, constant: 6),
            emptySubLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptySubLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 20),
            emptySubLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -20),
            emptySubLabel.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
    }

    // MARK: - Fetch username
    private func fetchCurrentUserName() {
        Firestore.firestore().collection("users").document(currentUserId)
            .getDocument { [weak self] snap, _ in
                self?.currentUserName = snap?.data()?["fullName"] as? String ?? ""
            }
    }

    // MARK: - Listen — only chats where archivedBy contains currentUserId
    private func startListening() {
        guard !currentUserId.isEmpty else { return }
        activityIndicator.startAnimating()
        patientListener?.remove()
        therapistListener?.remove()

        let db = Firestore.firestore()
        var patientChats:   [Chat] = []
        var therapistChats: [Chat] = []

        patientListener = db.collection("chats")
            .whereField("patientId",   isEqualTo: currentUserId)
            .whereField("archivedBy",  arrayContains: currentUserId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                patientChats = snapshot?.documents.compactMap {
                    Chat(id: $0.documentID, data: $0.data())
                } ?? []
                self.mergeAndReload(a: patientChats, b: therapistChats)
            }

        therapistListener = db.collection("chats")
            .whereField("therapistId", isEqualTo: currentUserId)
            .whereField("archivedBy",  arrayContains: currentUserId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                therapistChats = snapshot?.documents.compactMap {
                    Chat(id: $0.documentID, data: $0.data())
                } ?? []
                self.mergeAndReload(a: patientChats, b: therapistChats)
            }

        activityIndicator.stopAnimating()
    }

    private func mergeAndReload(a: [Chat], b: [Chat]) {
        var seen = Set<String>()
        let merged = (a + b)
            .filter { seen.insert($0.chatId).inserted }
            .sorted { ($0.lastMessageTime ?? .distantPast) > ($1.lastMessageTime ?? .distantPast) }
        DispatchQueue.main.async {
            self.chats = merged
            self.emptyView.isHidden  = !merged.isEmpty
            self.tableView.isHidden  = merged.isEmpty
            self.tableView.reloadData()
        }
    }

    // MARK: - Unarchive
    private func unarchiveChat(_ chat: Chat) {
        Firestore.firestore().collection("chats").document(chat.chatId).updateData([
            "hiddenFor":  FieldValue.arrayRemove([currentUserId]),
            "archivedBy": FieldValue.arrayRemove([currentUserId])
        ]) { error in
            if let error = error { print("Unarchive failed:", error.localizedDescription) }
        }
    }

    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ArchivedChatsVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatListCell.reuseID, for: indexPath) as! ChatListCell
        cell.configure(with: chats[indexPath.row], currentUserId: currentUserId)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 90 }

    // Swipe: Unarchive (teal) + Delete (red)
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let chat = chats[indexPath.row]

        let unarchive = UIContextualAction(style: .normal, title: "Unarchive") { [weak self] _, _, done in
            guard let self = self else { done(false); return }
            self.unarchiveChat(chat)
            done(true)
        }
        unarchive.backgroundColor = UIColor(hex: "#4FC3D8")
        unarchive.image = UIImage(systemName: "arrow.uturn.up")

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { done(false); return }
            let alert = UIAlertController(
                title: "Delete Chat",
                message: "This will permanently remove this chat for you. The other participant will not be affected.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in done(false) })
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self = self else { done(false); return }
                Firestore.firestore().collection("chats").document(chat.chatId).updateData([
                    "archivedBy":                     FieldValue.arrayRemove([self.currentUserId]),
                    "hiddenFor":                      FieldValue.arrayUnion([self.currentUserId]),
                    "deletedAt.\(self.currentUserId)": Timestamp()
                ]) { error in done(error == nil) }
            })
            self.present(alert, animated: true)
        }
        delete.backgroundColor = UIColor.systemRed
        delete.image = UIImage(systemName: "trash")

        // Unarchive on the right (primary), delete further left
        return UISwipeActionsConfiguration(actions: [unarchive, delete])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = chats[indexPath.row]
        let otherUserId = currentUserId == chat.patientId ? chat.therapistId : chat.patientId
        let otherName   = chat.otherName(currentUserId: currentUserId)

        let chatVC = ChatVC(
            chatId:          chat.chatId,
            otherUserId:     otherUserId,
            otherName:       otherName,
            chatType:        chat.type,
            currentUserName: currentUserName
        )
        chatVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chatVC, animated: true)
    }
}
