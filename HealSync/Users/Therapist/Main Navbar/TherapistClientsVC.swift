//
//  TherapistClientsVC.swift
//  HealSync
//
//  Created by Arfa on 13/03/2026.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

// MARK: - Client Model
struct TherapistClient {
    let patientId:       String
    let patientName:     String
    let lastSessionDate: Date?
    let lastSessionType: String
}

class TherapistClientsVC: UIViewController {

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var clients: [TherapistClient] = []
    private var filteredClients: [TherapistClient] = []
    private var clientsListener: ListenerRegistration?
    private var currentTherapistId:   String = Auth.auth().currentUser?.uid ?? ""
    private var currentTherapistName: String = ""

    // MARK: - UI
    private let bgColor = UIColor(hex: "#D1F0F8")

    private let headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "My Clients"
        lbl.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        lbl.textColor = .black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let countLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 13)
        lbl.textColor = .systemGray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search clients..."
        sb.backgroundImage = UIImage()
        sb.searchTextField.backgroundColor = .white.withAlphaComponent(0.8)
        sb.searchTextField.layer.cornerRadius = 12
        sb.searchTextField.clipsToBounds = true
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
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
        let iv = UIImageView(image: UIImage(systemName: "person.2", withConfiguration: config))
        iv.tintColor = UIColor(hex: "#4FC3D8").withAlphaComponent(0.6)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "No clients yet"
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let emptySubLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Clients who book sessions with you will appear here"
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
        guard !currentTherapistId.isEmpty else { return }
              Firestore.firestore().collection("users").document(currentTherapistId)
                  .getDocument { [weak self] snap, _ in
                      self?.currentTherapistName = snap?.data()?["fullName"] as? String ?? ""
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchClients()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        clientsListener?.remove()
        clientsListener = nil
    }

    deinit {
        clientsListener?.remove()
    }

    // MARK: - Layout
    private func setupLayout() {
        [headerLabel, countLabel, searchBar, tableView, emptyView, activityIndicator].forEach {
            view.addSubview($0)
        }

        emptyView.addSubview(emptyIcon)
        emptyView.addSubview(emptyLabel)
        emptyView.addSubview(emptySubLabel)

        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(ClientCell.self, forCellReuseIdentifier: ClientCell.reuseID)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        searchBar.delegate = self

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            countLabel.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            searchBar.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
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
            emptySubLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 30),
            emptySubLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -30),
            emptySubLabel.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Fetch & Build Client List
    private func fetchClients() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        clientsListener?.remove()
        clientsListener = nil
        activityIndicator.startAnimating()

        clientsListener = db.collection("users").document(uid)
            .collection("bookedSessions")
            .whereField("status", isEqualTo: "confirmed")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()

                if let error = error {
                    print("❌ Clients error: \(error.localizedDescription)"); return
                }

                let sessions = snapshot?.documents.map { $0.data() } ?? []
                self.clients = self.buildClientList(from: sessions)

                // Preserve search filter if active
                let query = self.searchBar.text ?? ""
                self.filteredClients = query.isEmpty
                    ? self.clients
                    : self.clients.filter { $0.patientName.localizedCaseInsensitiveContains(query) }

                DispatchQueue.main.async {
                    let c = self.filteredClients.count
                    self.countLabel.text     = "\(c) client\(c == 1 ? "" : "s")"
                    self.emptyView.isHidden  = !self.filteredClients.isEmpty
                    self.tableView.isHidden  = self.filteredClients.isEmpty
                    self.tableView.reloadData()
                }
            }
    }

    private func buildClientList(from sessions: [[String: Any]]) -> [TherapistClient] {
        var grouped: [String: [[String: Any]]] = [:]
        for session in sessions {
            guard let id = session["patientId"] as? String else { continue }
            grouped[id, default: []].append(session)
        }

        return grouped.compactMap { patientId, sessions in
            guard let name = sessions.first?["patientName"] as? String else { return nil }
            let sorted = sessions.sorted {
                ($0["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantPast >
                ($1["sessionDateTime"] as? Timestamp)?.dateValue() ?? .distantPast
            }
            return TherapistClient(
                patientId:       patientId,
                patientName:     name,
                lastSessionDate: (sorted.first?["sessionDateTime"] as? Timestamp)?.dateValue(),
                lastSessionType: sorted.first?["sessionType"] as? String ?? "Video"
            )
        }
        .sorted { $0.patientName < $1.patientName }
    }
    
}

// MARK: - UITableViewDataSource & Delegate
extension TherapistClientsVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredClients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClientCell.reuseID, for: indexPath) as! ClientCell
        cell.configure(with: filteredClients[indexPath.row])
        cell.onMessage = { [weak self] in
            guard let self = self else { return }
            let client = self.filteredClients[indexPath.row]
            
            ChatService.shared.getOrCreateGeneralChat(
                patientId:     client.patientId,
                patientName:   client.patientName,
                therapistId:   self.currentTherapistId,
                therapistName: self.currentTherapistName
            ) { chatId in
                DispatchQueue.main.async {
                    let vc = ChatVC(
                        chatId:          chatId,
                        otherUserId:     client.patientId,
                        otherName:       client.patientName,
                        chatType:        .general,
                        currentUserName: self.currentTherapistName
                    )
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 100 }
    
}
    // MARK: - UISearchBarDelegate
    extension TherapistClientsVC: UISearchBarDelegate {
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            filteredClients = searchText.isEmpty
            ? clients
            : clients.filter { $0.patientName.localizedCaseInsensitiveContains(searchText) }
            let c = filteredClients.count
            countLabel.text     = "\(c) client\(c == 1 ? "" : "s")"
            emptyView.isHidden  = !filteredClients.isEmpty
            tableView.isHidden  = filteredClients.isEmpty
            tableView.reloadData()
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
    
    // MARK: - ClientCell
    class ClientCell: UITableViewCell {
        static let reuseID = "ClientCell"
        
        var onMessage: (() -> Void)?
        
        // MARK: - UI
        private let cardView: UIView = {
            let v = UIView()
            v.backgroundColor = .white.withAlphaComponent(0.9)
            v.layer.cornerRadius = 20
            v.layer.shadowColor   = UIColor.black.cgColor
            v.layer.shadowOpacity = 0.06
            v.layer.shadowOffset  = CGSize(width: 0, height: 3)
            v.layer.shadowRadius  = 8
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()
        
        private let accentStrip: UIView = {
            let v = UIView()
            v.backgroundColor = UIColor(hex: "#4FC3D8")
            v.layer.cornerRadius = 3
            v.translatesAutoresizingMaskIntoConstraints = false
            return v
        }()
        
        private let nameRow  = ClientCell.makeInfoRow(icon: "person.fill")
        private let typeRow  = ClientCell.makeInfoRow(icon: "video.fill")
        private let dateRow  = ClientCell.makeInfoRow(icon: "clock.arrow.circlepath")
        
        private let messageButton: UIButton = {
            var config = UIButton.Configuration.plain()
            config.image = UIImage(systemName: "bubble.left.fill")
            config.baseForegroundColor = .white
            config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            let btn = UIButton(configuration: config)
            btn.backgroundColor = UIColor(hex: "#4FC3D8")
            btn.layer.cornerRadius = 14
            btn.translatesAutoresizingMaskIntoConstraints = false
            
            return btn
        }()
        
        // MARK: - Init
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            selectionStyle  = .none
            
            contentView.addSubview(cardView)
            cardView.addSubview(accentStrip)
            cardView.addSubview(messageButton)
            
            let infoStack = UIStackView(arrangedSubviews: [nameRow, typeRow, dateRow])
            infoStack.axis    = .vertical
            infoStack.spacing = 10
            infoStack.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview(infoStack)
            
            messageButton.addTarget(self, action: #selector(messageTapped), for: .touchUpInside)
            
            NSLayoutConstraint.activate([
                cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
                
                accentStrip.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
                accentStrip.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
                accentStrip.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
                accentStrip.widthAnchor.constraint(equalToConstant: 5),
                
                infoStack.leadingAnchor.constraint(equalTo: accentStrip.trailingAnchor, constant: 14),
                infoStack.trailingAnchor.constraint(equalTo: messageButton.leadingAnchor, constant: -12),
                infoStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
                infoStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18),
                
                messageButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
                messageButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
                messageButton.widthAnchor.constraint(equalToConstant: 44),
                messageButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        // MARK: - Factory — same pattern as session card's makeInfoRow
        private static func makeInfoRow(icon: String) -> UIStackView {
            let img = UIImageView(image: UIImage(systemName: icon))
            img.tintColor = UIColor(hex: "#4FC3D8")
            img.contentMode = .scaleAspectFit
            img.widthAnchor.constraint(equalToConstant: 16).isActive = true
            img.heightAnchor.constraint(equalToConstant: 16).isActive = true
            
            let lbl = UILabel()
            lbl.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            lbl.textColor = UIColor(hex: "#1A3A45")
            
            let row = UIStackView(arrangedSubviews: [img, lbl])
            row.axis      = .horizontal
            row.spacing   = 10
            row.alignment = .center
            return row
        }
        
        private func rowLabel(_ row: UIStackView) -> UILabel? {
            row.arrangedSubviews.compactMap { $0 as? UILabel }.first
        }
        
        private func rowIcon(_ row: UIStackView) -> UIImageView? {
            row.arrangedSubviews.compactMap { $0 as? UIImageView }.first
        }
        
        @objc private func messageTapped() { onMessage?() }
        
        // MARK: - Configure
        func configure(with client: TherapistClient) {
            rowLabel(nameRow)?.text = client.patientName
            
            // Update session type icon dynamically
            let type = client.lastSessionType
            rowLabel(typeRow)?.text = type
            switch type {
            case "Audio": rowIcon(typeRow)?.image = UIImage(systemName: "phone.fill")
            case "Chat":  rowIcon(typeRow)?.image = UIImage(systemName: "bubble.left.fill")
            default:      rowIcon(typeRow)?.image = UIImage(systemName: "video.fill")
            }
            
            if let date = client.lastSessionDate {
                let cal = Calendar.current
                let f   = DateFormatter()
                f.dateFormat = "dd MMM yyyy"
                if cal.isDateInToday(date)          { rowLabel(dateRow)?.text = "Last session: Today" }
                else if cal.isDateInYesterday(date) { rowLabel(dateRow)?.text = "Last session: Yesterday" }
                else                                { rowLabel(dateRow)?.text = "Last session: \(f.string(from: date))" }
            } else {
                rowLabel(dateRow)?.text = "No sessions yet"
            }
        }
    }

