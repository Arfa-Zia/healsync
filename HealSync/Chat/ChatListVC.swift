//
//  ChatListVC.swift
//  HealSync
//
//  Created by Arfa on 18/03/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChatListVC: UIViewController {

    // MARK: - Properties
    private var chats: [Chat] = []
    private var patientChatsListener:   ListenerRegistration?
    private var therapistChatsListener: ListenerRegistration?
    private let currentUserId   = Auth.auth().currentUser?.uid ?? ""
    private var currentUserName = ""

    // MARK: - UI
    private let bgColor = UIColor(hex: "#D1F0F8")

    private let headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Chats"
        lbl.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        lbl.textColor = .black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let archiveBtn: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        btn.setImage(UIImage(systemName: "archivebox", withConfiguration: config), for: .normal)
        btn.tintColor = UIColor(hex: "#4FC3D8")
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
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
        let iv = UIImageView(image: UIImage(systemName: "bubble.left.and.bubble.right", withConfiguration: config))
        iv.tintColor = UIColor(hex: "#4FC3D8").withAlphaComponent(0.6)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No conversations yet"
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let emptySubLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = ""  // set dynamically based on user role
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
        view.backgroundColor = bgColor
        setupLayout()
        fetchCurrentUserName()
        archiveBtn.addTarget(self, action: #selector(openArchive), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        startListening()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        patientChatsListener?.remove()
        therapistChatsListener?.remove()
    }

    // MARK: - Layout
    private func setupLayout() {
        emptyView.addSubview(emptyIcon)
        emptyView.addSubview(emptyLabel)
        emptyView.addSubview(emptySubLabel)

        [headerLabel, archiveBtn, tableView, emptyView, activityIndicator].forEach { view.addSubview($0) }

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(ChatListCell.self, forCellReuseIdentifier: ChatListCell.reuseID)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            archiveBtn.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            archiveBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            archiveBtn.widthAnchor.constraint(equalToConstant: 36),
            archiveBtn.heightAnchor.constraint(equalToConstant: 36),

            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
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
    }

    // MARK: - Fetch current user name
    private func fetchCurrentUserName() {
        Firestore.firestore().collection("users").document(currentUserId).getDocument { [weak self] snap, _ in
            guard let self = self else { return }
            self.currentUserName = snap?.data()?["fullName"] as? String ?? ""
            let role = snap?.data()?["role"] as? String ?? "patient"
            DispatchQueue.main.async {
                self.emptySubLabel.text = role == "therapist"
                    ? "Chats will appear here when patients contact you"
                    : "Go to a therapist's profile and tap Chat to start"
            }
        }
    }

    // MARK: - Open Archive
    @objc private func openArchive() {
        let vc = ArchivedChatsVC()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Listen
    private func startListening() {
        guard !currentUserId.isEmpty else { return }
        activityIndicator.startAnimating()
        patientChatsListener?.remove()
        therapistChatsListener?.remove()

        // Two simple queries — no composite index needed, sorted in-memory
        // Each fires independently as a real-time listener
        let db = Firestore.firestore()
        var patientChats:   [Chat] = []
        var therapistChats: [Chat] = []

        let patientListener = db.collection("chats")
            .whereField("patientId", isEqualTo: currentUserId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                patientChats = snapshot?.documents.compactMap {
                    Chat(id: $0.documentID, data: $0.data())
                }.filter { !($0.hiddenFor.contains(self.currentUserId)) } ?? []
                self.mergeAndReload(a: patientChats, b: therapistChats)
            }

        let therapistListener = db.collection("chats")
            .whereField("therapistId", isEqualTo: currentUserId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                therapistChats = snapshot?.documents.compactMap {
                    Chat(id: $0.documentID, data: $0.data())
                }.filter { !($0.hiddenFor.contains(self.currentUserId)) } ?? []
                self.mergeAndReload(a: patientChats, b: therapistChats)
            }

        // Store both so we can remove them
        self.patientChatsListener    = patientListener
        self.therapistChatsListener  = therapistListener
        self.activityIndicator.stopAnimating()
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
}

// MARK: - UITableViewDataSource & Delegate
extension ChatListVC: UITableViewDataSource, UITableViewDelegate {
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

    func tableView(_ tableView: UITableView,
                    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let chat = chats[indexPath.row]

        if chat.type == .session {
            let archive = UIContextualAction(style: .normal, title: "Archive") { [weak self] _, _, done in
                guard let self = self else { done(false); return }
                // Archive = hide from active list but NO deletedAt — full history preserved
                // User can access archived chats from the archive button
                Firestore.firestore().collection("chats").document(chat.chatId).updateData([
                    "hiddenFor": FieldValue.arrayUnion([self.currentUserId]),
                    "archivedBy": FieldValue.arrayUnion([self.currentUserId])
                ]) { error in done(error == nil) }
            }
            archive.backgroundColor = UIColor.systemGray
            archive.image = UIImage(systemName: "archivebox")
            return UISwipeActionsConfiguration(actions: [archive])
        } else {
            // Delete action for general chats
            let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
                guard let self = self else { done(false); return }
                // Only hide for current user — other participant keeps the chat
                // Also store deletedAt so messages before this timestamp are hidden
                Firestore.firestore().collection("chats").document(chat.chatId).updateData([
                    "hiddenFor": FieldValue.arrayUnion([self.currentUserId]),
                    "deletedAt.\(self.currentUserId)": Timestamp()
                ]) { error in done(error == nil) }
                // Listener will auto-remove since hiddenFor now contains currentUserId
            }
            delete.backgroundColor = UIColor.systemRed
            delete.image = UIImage(systemName: "trash")
            return UISwipeActionsConfiguration(actions: [delete])
        }
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

// MARK: - ChatListCell
class ChatListCell: UITableViewCell {
    static let reuseID = "ChatListCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.9)
        v.layer.cornerRadius  = 16
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowOffset  = CGSize(width: 0, height: 2)
        v.layer.shadowRadius  = 6
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor  = UIColor(hex: "#C8EDF5")
        v.layer.cornerRadius = 24
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        lbl.textColor = UIColor(hex: "#1A7A8A")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        return lbl
    }()

    private let previewLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .systemGray
        lbl.numberOfLines = 1
        return lbl
    }()

    private let timeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 11)
        lbl.textColor = .systemGray
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let unreadBadge: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        lbl.textColor = .white
        lbl.backgroundColor = UIColor(hex: "#4FC3D8")
        lbl.textAlignment = .center
        lbl.layer.cornerRadius = 10
        lbl.clipsToBounds = true
        lbl.isHidden = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let typeBadge: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        lbl.textColor = UIColor(hex: "#1A7A8A")
        lbl.backgroundColor = UIColor(hex: "#D6F0F7")
        lbl.textAlignment = .center
        lbl.layer.cornerRadius = 6
        lbl.clipsToBounds = true
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none

        avatarView.addSubview(avatarLabel)
        avatarView.addSubview(avatarImageView)
        contentView.addSubview(cardView)

        // typeBadge is part of the text stack — no overlap
        let textStack = UIStackView(arrangedSubviews: [nameLabel, previewLabel, typeBadge])
        textStack.axis      = .vertical
        textStack.spacing   = 4
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.setCustomSpacing(8, after: previewLabel)

        // Right column: time on top, unread badge on bottom
        let rightStack = UIStackView(arrangedSubviews: [timeLabel, unreadBadge])
        rightStack.axis      = .vertical
        rightStack.spacing   = 4
        rightStack.alignment = .trailing
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        [avatarView, textStack, rightStack].forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            avatarView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            avatarView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),

            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),

            rightStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            rightStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: rightStack.leadingAnchor, constant: -8),
            textStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),

            typeBadge.heightAnchor.constraint(equalToConstant: 20),
            typeBadge.widthAnchor.constraint(equalToConstant: 60),
            unreadBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            unreadBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with chat: Chat, currentUserId: String) {
        let otherName    = chat.otherName(currentUserId: currentUserId)
        let otherUserId  = currentUserId == chat.patientId ? chat.therapistId : chat.patientId
        nameLabel.text   = otherName
        avatarLabel.text = String(otherName.prefix(1)).uppercased()
        avatarImageView.isHidden = true
        avatarLabel.isHidden     = false
        previewLabel.text = chat.lastMessage.isEmpty ? "No messages yet" : chat.lastMessage

        // Load profile image
        Firestore.firestore().collection("users").document(otherUserId)
            .getDocument { [weak self] snap, _ in
                guard let self = self,
                      let urlStr = snap?.data()?["profileImageURL"] as? String,
                      !urlStr.isEmpty,
                      let url = URL(string: urlStr) else { return }
                URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                    guard let self = self, let data = data, let img = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        self.avatarImageView.image   = img
                        self.avatarImageView.isHidden = false
                        self.avatarLabel.isHidden     = true
                    }
                }.resume()
            }

        typeBadge.text = chat.type == .session ? "  Session  " : "  Inquiry  "

        // Time
        if let time = chat.lastMessageTime {
            let f = DateFormatter()
            f.dateFormat = Calendar.current.isDateInToday(time) ? "h:mm a" : "MMM d"
            timeLabel.text = f.string(from: time)
        }

        // Unread badge
        let unread = chat.unread(for: currentUserId)
        unreadBadge.isHidden = unread == 0
        unreadBadge.text     = unread > 99 ? "99+" : "\(unread)"

        // Bold preview if unread
        previewLabel.font = unread > 0
            ? UIFont.systemFont(ofSize: 13, weight: .semibold)
            : UIFont.systemFont(ofSize: 13)
        previewLabel.textColor = unread > 0 ? UIColor(hex: "#1A3A45") : .systemGray
    }
}
