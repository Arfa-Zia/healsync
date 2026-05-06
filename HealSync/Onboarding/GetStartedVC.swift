//
//  ViewController.swift
//  HealSync
//
//  Created by Arfa on 08/01/2026.
//

import UIKit

class GetStartedVC: BaseViewController {

    private var containerView = BaseContainer()
    private var titleLabel = TitleLabel(text: "HealSync")
    private var subtitleLabel = SubtitleLabel(text: "Syncing users with healing guidance", noOfLines: 2)
    private var actionButton = PrimaryButton(title: "Get Started")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        actionButton.addTarget(self, action: #selector(tappedGetStarted), for: .touchUpInside)
       
    }
    
    @objc private func tappedGetStarted(){
        let nextVC = ChooseRoleVC()
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    private func setupLayout(){
        let stackView = UIStackView(arrangedSubviews: [titleLabel , subtitleLabel , actionButton])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.addSubview(stackView)
        
        containerView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 65, leading: 20, bottom: 65, trailing: 20)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.77),
            
            stackView.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor),
            
            actionButton.widthAnchor.constraint(equalToConstant: 200),
            actionButton.heightAnchor.constraint(equalToConstant: 45)
            
        ])
    }

}

