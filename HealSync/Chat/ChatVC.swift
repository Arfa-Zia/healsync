//
//  ChatVC.swift
//  HealSync
//
//  Created by Arfa on 18/03/2026.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChatVC: UIViewController {

    // MARK: - Properties
    private let chatId:       String
    private let otherUserId:  String
    private let otherName:    String
    private let chatType:     Chat.ChatType

    private var messages:         [ChatMessage] = []
    private var messagesListener: ListenerRegistration?
    private var onlineListener:   ListenerRegistration?
    private var typingTimer:      Timer?

    private let currentUserId   = Auth.auth().currentUser?.uid ?? ""
    private let currentUserName: String

    private let bgColor   = UIColor(hex: "#D1F0F8")
    private let teal      = UIColor(hex: "#4FC3D8")
    private let darkTeal  = UIColor(hex: "#1A7A8A")

    // MARK: - UI
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle  = .none
        tv.allowsSelection = false
        tv.keyboardDismissMode = .interactive
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    // Header
    private let headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backBtn = CustomBackButton()

    private let avatarView: UIView = {
        let v = UIView()
        v.backgroundColor  = UIColor(hex: "#C8EDF5")
        v.layer.cornerRadius = 20
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let avatarLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        lbl.textColor    = UIColor(hex: "#1A7A8A")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.isHidden = true  // hidden until image loads
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let onlineDot: UIView = {
        let v = UIView()
        v.backgroundColor  = UIColor.systemGreen
        v.layer.cornerRadius = 5
        v.layer.borderWidth  = 2
        v.layer.borderColor  = UIColor.white.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 12)
        lbl.textColor = .systemGray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let headerDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#E0F0F5")
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Chat type badge
    private let typeBadge: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A7A8A")
        lbl.backgroundColor = UIColor(hex: "#D6F0F7")
        lbl.layer.cornerRadius = 8
        lbl.clipsToBounds = true
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Input bar
    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let inputField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Type a message..."
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.backgroundColor = UIColor(hex: "#EEF8FB")
        tf.layer.cornerRadius = 20
        tf.leftView  = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode  = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        btn.tintColor = UIColor(hex: "#4FC3D8")
        btn.contentVerticalAlignment   = .fill
        btn.contentHorizontalAlignment = .fill
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private var inputContainerBottomConstraint: NSLayoutConstraint?

    // MARK: - Init
    init(chatId: String, otherUserId: String, otherName: String,
         chatType: Chat.ChatType, currentUserName: String) {
        self.chatId          = chatId
        self.otherUserId     = otherUserId
        self.otherName       = otherName
        self.chatType        = chatType
        self.currentUserName = currentUserName
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        setupLayout()
        setupKeyboard()
        listenToMessages()
        listenToOnlineStatus()
        ChatService.shared.setOnline(true, userId: currentUserId)
        ChatService.shared.markMessagesRead(chatId: chatId, userId: currentUserId)
        fetchOtherUserProfileImage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        ChatService.shared.setTyping(false, chatId: chatId, userId: currentUserId)
        ChatService.shared.setOnline(false, userId: currentUserId)
        typingTimer?.invalidate()
    }

    deinit {
        messagesListener?.remove()
        onlineListener?.remove()
    }

    // MARK: - Layout
    private func setupLayout() {
        // Avatar
        avatarView.addSubview(avatarLabel)
        avatarView.addSubview(avatarImageView)
        // onlineDot added to headerView directly to avoid clipsToBounds clipping

        let nameMeta = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        nameMeta.axis    = .vertical
        nameMeta.spacing = 2
        nameMeta.translatesAutoresizingMaskIntoConstraints = false

        [backBtn, avatarView, onlineDot, nameMeta, typeBadge, headerDivider].forEach { headerView.addSubview($0) }
        backBtn.translatesAutoresizingMaskIntoConstraints = false

        [headerView, tableView, inputContainer].forEach { view.addSubview($0) }
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(sendButton)

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(OutgoingMessageCell.self, forCellReuseIdentifier: OutgoingMessageCell.reuseID)
        tableView.register(IncomingMessageCell.self, forCellReuseIdentifier: IncomingMessageCell.reuseID)
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        nameLabel.text   = otherName
        avatarLabel.text = String(otherName.prefix(1)).uppercased()
        typeBadge.text   = chatType == .session ? "  Session Chat  " : "  Inquiry  "

        inputContainerBottomConstraint = inputContainer.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        inputContainerBottomConstraint?.isActive = true

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -30),
            backBtn.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 14),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            avatarView.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 10),
            avatarView.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),

            onlineDot.widthAnchor.constraint(equalToConstant: 11),
            onlineDot.heightAnchor.constraint(equalToConstant: 11),
            onlineDot.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 1),
            onlineDot.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 1),

            nameMeta.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10),
            nameMeta.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            typeBadge.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            typeBadge.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            typeBadge.heightAnchor.constraint(equalToConstant: 30),
            typeBadge.widthAnchor.constraint(equalToConstant: 100),
            

            headerDivider.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 10),
            headerDivider.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 1),
            headerDivider.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 64),

            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 14),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputField.heightAnchor.constraint(equalToConstant: 44),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -14),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])

        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        inputField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        inputField.delegate = self
    }

    // MARK: - Fetch Profile Image
    private func fetchOtherUserProfileImage() {
        Firestore.firestore().collection("users").document(otherUserId).getDocument { [weak self] snap, _ in
            guard let self = self,
                  let urlStr = snap?.data()?["profileImageURL"] as? String,
                  !urlStr.isEmpty,
                  let url = URL(string: urlStr) else { return }

            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self = self, let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self.avatarImageView.image  = image
                    self.avatarImageView.isHidden = false
                    self.avatarLabel.isHidden     = true
                    // Update corner radius to match avatarView
                    self.avatarView.layer.cornerRadius = 20
                }
            }.resume()
        }
    }

    // MARK: - Keyboard
    private func setupKeyboard() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ n: Notification) {
        guard let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        inputContainerBottomConstraint?.constant = -(frame.height - view.safeAreaInsets.bottom)
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
        scrollToBottom(animated: true)
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        guard let duration = n.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        inputContainerBottomConstraint?.constant = 0
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    // MARK: - Listeners
    private func listenToMessages() {
        messagesListener = ChatService.shared.listenToMessages(chatId: chatId, currentUserId: currentUserId) { [weak self] messages in
            guard let self = self else { return }
            self.messages = messages
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.scrollToBottom(animated: true)
                // Mark as read whenever new messages arrive
                ChatService.shared.markMessagesRead(chatId: self.chatId, userId: self.currentUserId)
            }
        }
    }

    private func listenToOnlineStatus() {
        onlineListener = ChatService.shared.listenToOnlineStatus(userId: otherUserId) { [weak self] isOnline, lastSeen in
            DispatchQueue.main.async {
                self?.onlineDot.backgroundColor = isOnline ? .systemGreen : .systemGray3
                if isOnline {
                    self?.statusLabel.text = "Online"
                    self?.statusLabel.textColor = .systemGreen
                } else if let lastSeen = lastSeen {
                    let f = RelativeDateTimeFormatter()
                    f.unitsStyle = .abbreviated
                    self?.statusLabel.text = "Last seen \(f.localizedString(for: lastSeen, relativeTo: Date()))"
                    self?.statusLabel.textColor = .systemGray
                }
            }
        }

        // Also listen for typing indicator
        Firestore.firestore().collection("chats").document(chatId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                let typing = snapshot?.data()?["typing"] as? [String: Bool] ?? [:]
                let isTyping = typing[self.otherUserId] ?? false
                DispatchQueue.main.async {
                    self.statusLabel.text = isTyping ? "Typing..." : (self.statusLabel.text?.contains("Online") == true ? "Online" : self.statusLabel.text)
                    self.statusLabel.textColor = isTyping ? UIColor(hex: "#4FC3D8") : self.statusLabel.textColor
                }
            }
    }

    // MARK: - Actions
    @objc private func sendMessage() {
        guard let text = inputField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }
        inputField.text = ""
        typingTimer?.invalidate()
        ChatService.shared.setTyping(false, chatId: chatId, userId: currentUserId)

        ChatService.shared.sendMessage(
            chatId:       chatId,
            senderId:     currentUserId,
            senderName:   currentUserName,
            text:         text,
            otherUserId:  otherUserId
        )
    }

    @objc private func textChanged() {
        // Fire typing indicator — debounced 2s
        ChatService.shared.setTyping(true, chatId: chatId, userId: currentUserId)
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            ChatService.shared.setTyping(false, chatId: self.chatId, userId: self.currentUserId)
        }
    }

    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    private func scrollToBottom(animated: Bool) {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = messages[indexPath.row]

        // Show timestamp if first message or gap > 10 min from previous
        var showTimestamp = indexPath.row == 0
        if indexPath.row > 0 {
            let prev = messages[indexPath.row - 1]
            showTimestamp = msg.timestamp.timeIntervalSince(prev.timestamp) > 600
        }

        if msg.isFromCurrentUser {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: OutgoingMessageCell.reuseID, for: indexPath) as! OutgoingMessageCell
            cell.configure(with: msg, showTimestamp: showTimestamp)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: IncomingMessageCell.reuseID, for: indexPath) as! IncomingMessageCell
            cell.configure(with: msg, showTimestamp: showTimestamp)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
}

// MARK: - UITextFieldDelegate
extension ChatVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}

// MARK: - Outgoing Message Cell
class OutgoingMessageCell: UITableViewCell {
    static let reuseID = "OutgoingMessageCell"

    private let bubbleView: UIView = {
        let v = UIView()
        v.backgroundColor  = UIColor(hex: "#4FC3D8")
        v.layer.cornerRadius = 18
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let messageLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.textColor = .white
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let timestampLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 10)
        lbl.textColor = .systemGray
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let readTickLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 10)
        lbl.textAlignment = .right
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(readTickLabel)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),

            readTickLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 3),
            readTickLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            readTickLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            timestampLabel.trailingAnchor.constraint(equalTo: readTickLabel.leadingAnchor, constant: -4),
            timestampLabel.centerYAnchor.constraint(equalTo: readTickLabel.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with message: ChatMessage, showTimestamp: Bool) {
        messageLabel.text = message.text
        readTickLabel.text = message.isRead ? "✓✓" : "✓"
        readTickLabel.textColor = message.isRead ? UIColor(hex: "#4FC3D8") : .systemGray3

        if showTimestamp {
            let f = DateFormatter()
            f.dateFormat = Calendar.current.isDateInToday(message.timestamp) ? "h:mm a" : "MMM d, h:mm a"
            timestampLabel.text = f.string(from: message.timestamp)
        } else {
            timestampLabel.text = nil
        }
    }
}

// MARK: - Incoming Message Cell
class IncomingMessageCell: UITableViewCell {
    static let reuseID = "IncomingMessageCell"

    private let bubbleView: UIView = {
        let v = UIView()
        v.backgroundColor  = .white
        v.layer.cornerRadius = 18
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.05
        v.layer.shadowOffset  = CGSize(width: 0, height: 1)
        v.layer.shadowRadius  = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let messageLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let timestampLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 10)
        lbl.textColor = .systemGray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(timestampLabel)

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),

            timestampLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 3),
            timestampLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            timestampLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with message: ChatMessage, showTimestamp: Bool) {
        messageLabel.text = message.text

        if showTimestamp {
            let f = DateFormatter()
            f.dateFormat = Calendar.current.isDateInToday(message.timestamp) ? "h:mm a" : "MMM d, h:mm a"
            timestampLabel.text = f.string(from: message.timestamp)
        } else {
            timestampLabel.text = nil
        }
    }
}
