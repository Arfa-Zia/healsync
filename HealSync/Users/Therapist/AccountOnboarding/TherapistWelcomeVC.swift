//
//  TherapistWelcomeVC.swift
//  HealSync
//
//  Created by Arfa on 11/03/2026.
//

import UIKit

class TherapistWelcomeVC: UIViewController{

    private var titleLabel = TitleLabel(text: "Welcome" , fontSize: 44)
    private var subtitleLabel = SubtitleLabel(text: "Together, let’s make healing accessible to everyone" , noOfLines: 2 , fontSize: 18)
    private var gradientLayer = CAGradientLayer()
    
    private var backgroundImg: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.image = UIImage(named: "therapist-welcome-img")
        img.contentMode = .scaleAspectFill
      
        return img
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGradient()
        setupLayout()
        transistToNextScreen()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesBackButton = true
    }

    private func transistToNextScreen(){
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3){
            let nextVC = TherapistAddProfileDetailsVC()
            let fadeTransition = CATransition()
            fadeTransition.type = .fade
            fadeTransition.duration = 0.6
            fadeTransition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            self.view.window?.layer.add(fadeTransition, forKey: kCATransition)
            
            self.navigationController?.setViewControllers([nextVC], animated: false)
        }
    }
    private func setupGradient(){
        
        gradientLayer.colors = [
            UIColor(hex: "#D6F7FF").cgColor,
            UIColor.white.cgColor
        ]

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5 , y: 0.6)
        
        view.layer.insertSublayer(gradientLayer, at: 0)
        
    }
    
    private func setupLayout(){
        let stackView = UIStackView(arrangedSubviews: [titleLabel , subtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        view.addSubview(backgroundImg)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 150),
            backgroundImg.widthAnchor.constraint(equalTo: view.widthAnchor),
            backgroundImg.heightAnchor.constraint(equalTo: view.heightAnchor , multiplier: 0.4),
            backgroundImg.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            
        ])
    }
}


