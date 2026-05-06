//
//  ClientTherapistVC.swift
//  HealSync
//
//  Created by Arfa on 10/02/2026.
//
//
import UIKit
import Firebase

class ClientTherapistVC: UIViewController {

    // MARK: - Properties
    private var allTherapists: [Therapist] = []
    private var filteredTherapists: [Therapist] = []

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let searchTextField = UITextField()

    private let headerLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Find a Therapist"
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
        lbl.text = "No therapists found"
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.textAlignment = .center
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
        fetchTherapists()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Layout
    private func setupLayout() {
        // Search bar
        let searchContainer = makeSearchBar()

        // Therapist cards scroll area
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis    = .vertical
        contentStack.spacing = 14
        scrollView.addSubview(contentStack)

        // Empty view
        emptyView.addSubview(emptyIcon)
        emptyView.addSubview(emptyLabel)

        [headerLabel, countLabel, searchContainer,
         scrollView, emptyView, activityIndicator].forEach { view.addSubview($0) }

        let p: CGFloat = 20

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: p),

            countLabel.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -p),

            searchContainer.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 14),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: p),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -p),
            searchContainer.heightAnchor.constraint(equalToConstant: 46),

            scrollView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 14),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: p),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -p),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyIcon.topAnchor.constraint(equalTo: emptyView.topAnchor),
            emptyIcon.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 60),
            emptyIcon.heightAnchor.constraint(equalToConstant: 60),

            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 14),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Search Bar
    private func makeSearchBar() -> UIView {
        let container = UIView()
        container.backgroundColor = .white.withAlphaComponent(0.7)
        container.layer.cornerRadius = 14
        container.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = UIColor(hex: "#4FC3D8")
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true

        searchTextField.placeholder = "Search by name or specialty..."
        searchTextField.backgroundColor = .clear
        searchTextField.font = UIFont.systemFont(ofSize: 14)
        searchTextField.autocapitalizationType = .none
        searchTextField.autocorrectionType = .no
        searchTextField.addTarget(self, action: #selector(searchTextChanged(_:)), for: .editingChanged)

        let stack = UIStackView(arrangedSubviews: [icon, searchTextField])
        stack.axis      = .horizontal
        stack.alignment = .center
        stack.spacing   = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    // MARK: - Fetch
    private func fetchTherapists() {
        activityIndicator.startAnimating()
        TherapistService.shared.fetchAllTherapists { [weak self] therapists in
            guard let self = self else { return }
            self.allTherapists      = therapists
            self.filteredTherapists = therapists
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.reloadCards()
            }
        }
    }

    // MARK: - Search
    @objc private func searchTextChanged(_ sender: UITextField) {
        let text = sender.text ?? ""
        filteredTherapists = text.isEmpty ? allTherapists : allTherapists.filter {
            $0.fullName.localizedCaseInsensitiveContains(text) ||
            $0.specialization.localizedCaseInsensitiveContains(text) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(text) }
        }
        reloadCards()
    }

    // MARK: - Reload Cards
    private func reloadCards() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let c = filteredTherapists.count
        countLabel.text    = "\(c) therapist\(c == 1 ? "" : "s")"
        emptyView.isHidden = !filteredTherapists.isEmpty

        for (index, therapist) in filteredTherapists.enumerated() {
            let card = makeTherapistCard(for: therapist, index: index)
            contentStack.addArrangedSubview(card)
        }
    }

    // MARK: - Therapist Card (matches client card design)
    private func makeTherapistCard(for therapist: Therapist, index: Int) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor  = .white.withAlphaComponent(0.9)
        cardView.layer.cornerRadius  = 20
        cardView.layer.shadowColor   = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowOffset  = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius  = 8
        cardView.translatesAutoresizingMaskIntoConstraints = false

        // Teal accent strip
        let accentStrip = UIView()
        accentStrip.backgroundColor  = UIColor(hex: "#4FC3D8")
        accentStrip.layer.cornerRadius = 3
        accentStrip.translatesAutoresizingMaskIntoConstraints = false

        // Info rows — no tags
        let nameRow = makeInfoRow(icon: "person.fill",  text: therapist.fullName)
        let specRow = makeInfoRow(icon: "stethoscope",  text: therapist.specialization)
        let expRow  = makeInfoRow(icon: "clock",        text: "\(therapist.experience)+ years experience")

        // View Profile button — full width at bottom
        let profileBtn = UIButton(type: .system)
        profileBtn.setTitle("View Profile", for: .normal)
        profileBtn.setTitleColor(.white, for: .normal)
        profileBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        profileBtn.backgroundColor  = UIColor(hex: "#4FC3D8")
        profileBtn.layer.cornerRadius = 12
        profileBtn.tag = index
        profileBtn.addTarget(self, action: #selector(viewProfileTapped(_:)), for: .touchUpInside)
        profileBtn.heightAnchor.constraint(equalToConstant: 46).isActive = true

        let infoStack = UIStackView(arrangedSubviews: [nameRow, specRow, expRow])
        infoStack.axis    = .vertical
        infoStack.spacing = 12

        let mainStack = UIStackView(arrangedSubviews: [infoStack, profileBtn])
        mainStack.axis    = .vertical
        mainStack.spacing = 18
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        [accentStrip, mainStack].forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            accentStrip.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            accentStrip.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            accentStrip.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            accentStrip.widthAnchor.constraint(equalToConstant: 5),

            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: accentStrip.trailingAnchor, constant: 14),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])

        return cardView
    }

    // MARK: - Info Row Factory (identical to therapist client card)
    private func makeInfoRow(icon: String, text: String) -> UIStackView {
        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor    = UIColor(hex: "#4FC3D8")
        img.contentMode  = .scaleAspectFit
        img.widthAnchor.constraint(equalToConstant: 16).isActive  = true
        img.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let lbl = UILabel()
        lbl.text      = text
        lbl.font      = UIFont.systemFont(ofSize: 17, weight: .medium)
        lbl.textColor = UIColor(hex: "#1A3A45")
        lbl.numberOfLines = 1

        let row = UIStackView(arrangedSubviews: [img, lbl])
        row.axis      = .horizontal
        row.spacing   = 10
        row.alignment = .center
        return row
    }

    // MARK: - Actions
    @objc private func viewProfileTapped(_ sender: UIButton) {
        let therapist = filteredTherapists[sender.tag]
        let profileVC = TherapistProfileVC(therapist: therapist)
        profileVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(profileVC, animated: true)
    }
}
