//
//  LegalWebViewVC.swift
//  HealSync
//
//  Created by Arfa on 10/02/2026.
//
import UIKit
import WebKit

class LegalWebViewVC: UIViewController {

    private let webView = WKWebView()
    private let urlString: String
    private let pageTitle: String

    init(title: String, urlString: String) {
        self.pageTitle = title
        self.urlString = urlString
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadURL()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = pageTitle

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissVC)
        )

        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadURL() {
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        webView.load(request)
    }


    @objc private func dismissVC() {
        dismiss(animated: true)
    }
}
