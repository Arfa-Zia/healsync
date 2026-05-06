//
//  BaseViewController.swift
//  HealSync
//
//  Created by Arfa on 12/01/2026.
//

import SwiftUI

class BaseViewController: UIViewController {
   
    private var bgLeftImg: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.image = UIImage(named: "bgImg left corner")
        img.contentMode = .scaleAspectFit
        img.widthAnchor.constraint(equalToConstant: 230).isActive = true
        img.heightAnchor.constraint(equalToConstant: 230).isActive = true
        return img
    }()
    
    private var bgRightImg: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.image = UIImage(named: "bgImg right corner")
        img.contentMode = .scaleAspectFit
        img.widthAnchor.constraint(equalToConstant: 230).isActive = true
        img.heightAnchor.constraint(equalToConstant: 230).isActive = true
       
        return img
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDismissKeyboard()
        view.backgroundColor = .background
            
        view.addSubview(bgLeftImg)
        bgLeftImg.topAnchor.constraint(equalTo: view.topAnchor , constant: -20).isActive = true
        bgLeftImg.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        
        view.addSubview(bgRightImg)
        bgRightImg.bottomAnchor.constraint(equalTo: view.bottomAnchor , constant: 20).isActive = true
        bgRightImg.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        }
    func setupDismissKeyboard(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    @objc func handleTapOutside(){
        view.endEditing(true)
    }
}
