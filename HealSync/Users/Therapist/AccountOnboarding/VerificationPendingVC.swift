//
//  VerficationPendingVC.swift
//  HealSync
//
//  Created by Arfa on 11/03/2026.
//
import UIKit
import FirebaseAuth
import FirebaseFirestore

class VerificationPendingVC: BaseViewController {

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private let cardView = BaseContainer(opacity: 0.7, shadow: true)
    private let titleLabel = TitleLabel(text: "LICENSE VERIFICATION IN PROGRESS", fontSize: 18)
    private let descriptionLabel = SubtitleLabel(text: "Your license is being reviewed by our team. You'll move to further process once it's verified", noOfLines: 0, fontSize: 14)

    private let hourglass: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light, scale: .default)
        let img = UIImageView(image: UIImage(systemName: "hourglass", withConfiguration: config))
        img.tintColor = UIColor(hex: "FFB636")
        img.contentMode = .scaleAspectFit
        return img
    }()

    private let statusCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hex: "#C4EBF6")
        v.layer.cornerRadius = 14
        return v
    }()

    private let statusLabel = SubtitleLabel(text: "Status:  Under Review", fontSize: 15)
    private let submittedLabel: SubtitleLabel = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        let label = SubtitleLabel(text: "Submitted:  \(formatter.string(from: Date()))", fontSize: 14)
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    private let estimateLabel: UILabel = {
        let label = UILabel()
        label.text = "Estimated Review Time:  24hrs - 48hrs"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hex: "#055707")
        label.numberOfLines = 2
        return label
    }()

    private let contactButton = PrimaryButton(title: "Contact Us", fontSize: 16)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        listenForApproval()
    }

    // Prevent back swipe gesture
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    @MainActor
    deinit { listener?.remove() }

    private func setupUI() {
        // Hide back button so user cannot navigate back
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = nil

        view.addSubview(cardView)
        [titleLabel, descriptionLabel, hourglass, statusCard, contactButton].forEach {
            cardView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        cardView.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.textColor = .darkGray
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.numberOfLines = 2

        statusCard.addSubview(statusLabel)
        statusCard.addSubview(submittedLabel)
        statusCard.addSubview(estimateLabel)
        [statusLabel, submittedLabel, estimateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            hourglass.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            hourglass.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            statusCard.topAnchor.constraint(equalTo: hourglass.bottomAnchor, constant: 20),
            statusCard.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 15),
            statusLabel.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 15),

            submittedLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            submittedLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),

            estimateLabel.topAnchor.constraint(equalTo: submittedLabel.bottomAnchor, constant: 10),
            estimateLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            estimateLabel.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -15),

            contactButton.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 25),
            contactButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 30),
            contactButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -30),
            contactButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -25)
        ])
    }

    private func listenForApproval() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data(),
                      let status = data["verificationStatus"] as? String else { return }

                if status == "approved" {
                    self.listener?.remove() // stop listening once approved
                    DispatchQueue.main.async {
                        self.goToSchedulingScreen()
                    }
                }
            }
    }

    private func goToSchedulingScreen() {
        let schedulingVC = TherapistOnboardingSchedulingVC()

        // Replace entire window root so there's no way to navigate back
        guard let window = view.window ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {

            // Fallback: push if window is not accessible
            navigationController?.pushViewController(schedulingVC, animated: true)
            return
        }

        let navController = UINavigationController(rootViewController: schedulingVC)
        navController.navigationBar.isHidden = true

        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve) {
            window.rootViewController = navController
        }
        window.makeKeyAndVisible()
    }
}

