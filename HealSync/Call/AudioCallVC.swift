//
//  AudioCallVC.swift
//  HealSync
//
//  Created by Arfa on 30/03/2026.
//

import UIKit
import AgoraRtcKit
import FirebaseAuth
import AVFoundation

// MARK: - AudioCallVC
class AudioCallVC: UIViewController {

    // MARK: - Call Parameters
    var bookingId:      String = ""
    var therapistId:    String = ""
    var therapistName:  String = ""
    var patientId:      String = ""
    var patientName:    String = ""
    var isTherapist = false

    // MARK: - Agora
    private var agoraKit: AgoraRtcEngineKit?
    private var remoteUid: UInt = 0
    private var callDuration: Int = 0
    private var durationTimer: Timer?
    private var isMuted     = false
    private var isSpeaker   = false
    private var isConnected = false

    // MARK: - UI
    private let gradientLayer   = CAGradientLayer()
    private let pulseLayer1     = CAShapeLayer()
    private let pulseLayer2     = CAShapeLayer()
    private let pulseLayer3     = CAShapeLayer()

    private let avatarContainer = UIView()
    private let avatarLabel     = UILabel()
    private let nameLabel       = UILabel()
    private let statusLabel     = UILabel()
    private let durationLabel   = UILabel()

    private let controlsCard    = UIView()
    private let muteButton      = CallControlButton(icon: "mic.fill",           label: "Mute")
    private let speakerButton   = CallControlButton(icon: "speaker.wave.2.fill", label: "Speaker")
    private let endCallButton   = UIButton()

    private var displayName: String {
        isTherapist ? patientName : therapistName
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupPulseRings()
        setupAvatar()
        setupLabels()
        setupControls()
        setupAgora()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        avatarContainer.layer.cornerRadius = avatarContainer.frame.width / 2
        updatePulseRings()
    }

    // FIX #3 — only tear down if engine is still alive
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if agoraKit != nil {
            endCall()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Background
    private func setupGradientBackground() {
        gradientLayer.colors = [
            UIColor(red: 0.07, green: 0.13, blue: 0.25, alpha: 1).cgColor,
            UIColor(red: 0.10, green: 0.22, blue: 0.38, alpha: 1).cgColor,
            UIColor(red: 0.05, green: 0.15, blue: 0.28, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    // MARK: - Pulse Rings
    private func setupPulseRings() {
        [pulseLayer1, pulseLayer2, pulseLayer3].forEach { layer in
            layer.fillColor   = UIColor.white.withAlphaComponent(0.06).cgColor
            layer.strokeColor = UIColor.white.withAlphaComponent(0.12).cgColor
            layer.lineWidth   = 1
            view.layer.insertSublayer(layer, at: 1)
        }
    }

    private func updatePulseRings() {
        let cx = view.bounds.midX
        let cy = view.bounds.midY - 60
        let radii: [CGFloat] = [90, 130, 175]
        let layers = [pulseLayer1, pulseLayer2, pulseLayer3]
        zip(layers, radii).forEach { (layer, r) in
            let path = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy), radius: r,
                                   startAngle: 0, endAngle: .pi * 2, clockwise: true)
            layer.path = path.cgPath
        }
    }

    private func startPulseAnimation() {
        let layers = [pulseLayer1, pulseLayer2, pulseLayer3]
        let delays: [Double] = [0, 0.3, 0.6]
        zip(layers, delays).forEach { (layer, delay) in
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 1.0
            scale.toValue   = 1.15
            scale.duration  = 1.4
            scale.beginTime = CACurrentMediaTime() + delay
            scale.autoreverses  = true
            scale.repeatCount   = .infinity
            scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(scale, forKey: "pulse")

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue   = 0.3
            fade.duration  = 1.4
            fade.beginTime = CACurrentMediaTime() + delay
            fade.autoreverses  = true
            fade.repeatCount   = .infinity
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(fade, forKey: "fade")
        }
    }

    // MARK: - Avatar
    private func setupAvatar() {
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.backgroundColor = UIColor(red: 0.22, green: 0.42, blue: 0.72, alpha: 0.8)
        avatarContainer.layer.borderWidth = 3
        avatarContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        view.addSubview(avatarContainer)

        avatarLabel.text = String(displayName.prefix(1)).uppercased()
        avatarLabel.font = UIFont.systemFont(ofSize: 52, weight: .medium)
        avatarLabel.textColor = .white
        avatarLabel.textAlignment = .center
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.addSubview(avatarLabel)

        NSLayoutConstraint.activate([
            avatarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -110),
            avatarContainer.widthAnchor.constraint(equalToConstant: 120),
            avatarContainer.heightAnchor.constraint(equalToConstant: 120),
            avatarLabel.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarContainer.centerYAnchor)
        ])
    }

    // MARK: - Labels
    private func setupLabels() {
        nameLabel.text = displayName
        nameLabel.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)

        statusLabel.text = "Connecting..."
        statusLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        durationLabel.text = ""
        durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        durationLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        durationLabel.textAlignment = .center
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(durationLabel)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: avatarContainer.bottomAnchor, constant: 24),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            durationLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 6),
            durationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Controls
    private func setupControls() {
        controlsCard.translatesAutoresizingMaskIntoConstraints = false
        controlsCard.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        controlsCard.layer.cornerRadius = 32
        controlsCard.layer.borderWidth  = 1
        controlsCard.layer.borderColor  = UIColor.white.withAlphaComponent(0.12).cgColor
        view.addSubview(controlsCard)

        let topRow = UIStackView(arrangedSubviews: [muteButton, speakerButton])
        topRow.axis = .horizontal
        topRow.spacing = 24
        topRow.distribution = .fillEqually
        topRow.translatesAutoresizingMaskIntoConstraints = false
        controlsCard.addSubview(topRow)

        endCallButton.translatesAutoresizingMaskIntoConstraints = false
        endCallButton.backgroundColor = UIColor(red: 0.95, green: 0.23, blue: 0.23, alpha: 1)
        endCallButton.layer.cornerRadius = 36
        let endImage = UIImage(systemName: "phone.down.fill",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .medium))
        endCallButton.setImage(endImage, for: .normal)
        endCallButton.tintColor = .white
        endCallButton.addTarget(self, action: #selector(endCallTapped), for: .touchUpInside)
        controlsCard.addSubview(endCallButton)

        muteButton.addTarget(self,    action: #selector(muteTapped),    for: .touchUpInside)
        speakerButton.addTarget(self, action: #selector(speakerTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            controlsCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            controlsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            controlsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            controlsCard.heightAnchor.constraint(equalToConstant: 180),

            topRow.topAnchor.constraint(equalTo: controlsCard.topAnchor, constant: 28),
            topRow.leadingAnchor.constraint(equalTo: controlsCard.leadingAnchor, constant: 40),
            topRow.trailingAnchor.constraint(equalTo: controlsCard.trailingAnchor, constant: -40),
            topRow.heightAnchor.constraint(equalToConstant: 70),

            endCallButton.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 20),
            endCallButton.centerXAnchor.constraint(equalTo: controlsCard.centerXAnchor),
            endCallButton.widthAnchor.constraint(equalToConstant: 72),
            endCallButton.heightAnchor.constraint(equalToConstant: 72)
        ])
    }

    // MARK: - Agora Setup
    private func setupAgora() {
        // FIX #5 — Configure AVAudioSession BEFORE initialising Agora.
        // Without this the patient's microphone may be silently blocked
        // by the default AVAudioSession category on a real device.
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession setup error: \(error)")
        }

        let config = AgoraRtcEngineConfig()
        config.appId = AgoraConfig.appId
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)

        // FIX #2 — Must call setClientRole(.broadcaster) in SDK 4.x or
        // audio publishing is silently blocked for the non-initiating peer.
        agoraKit?.setChannelProfile(.communication)
        agoraKit?.setClientRole(.broadcaster)          // ← KEY FIX

        agoraKit?.disableVideo()
        agoraKit?.enableAudio()
        agoraKit?.setAudioProfile(.default)

        // FIX #1 — Hash-derived unique UID instead of hardcoded 1/2.
        // Hardcoded UIDs silently kick out whichever peer joins second
        // when the same fixed value is reused across sessions.
        let myId = isTherapist ? therapistId : patientId
        let userUID: UInt = UInt(abs(myId.hashValue) % 999_999) + 1

        let options = AgoraRtcChannelMediaOptions()
        options.publishMicrophoneTrack = true
        options.autoSubscribeAudio     = true
        options.clientRoleType         = .broadcaster  // ← belt-and-suspenders

        let safeChannelId = bookingId
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()

        print("DEBUG: Joining channel: \(safeChannelId) as UID: \(userUID) (isTherapist=\(isTherapist))")

        agoraKit?.joinChannel(
            byToken: nil,
            channelId: safeChannelId,
            uid: userUID,
            mediaOptions: options
        )
    }

    // MARK: - Timer
    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.callDuration += 1
            self?.updateDurationLabel()
        }
    }

    private func updateDurationLabel() {
        let mins = callDuration / 60
        let secs = callDuration % 60
        durationLabel.text = String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - Actions
    @objc private func muteTapped() {
        isMuted.toggle()
        agoraKit?.muteLocalAudioStream(isMuted)
        muteButton.setActive(isMuted, activeIcon: "mic.slash.fill", inactiveIcon: "mic.fill")
    }

    @objc private func speakerTapped() {
        isSpeaker.toggle()
        agoraKit?.setEnableSpeakerphone(isSpeaker)
        speakerButton.setActive(isSpeaker,
                                activeIcon: "speaker.wave.3.fill",
                                inactiveIcon: "speaker.wave.2.fill")
    }

    @objc private func endCallTapped() {
        endCall()
        dismiss(animated: true)
    }

    // FIX #3 & #4 — Guard against double-destroy; nil agoraKit BEFORE destroy
    private func endCall() {
        guard agoraKit != nil else { return }
        durationTimer?.invalidate()
        durationTimer = nil
        agoraKit?.leaveChannel(nil)
        agoraKit = nil
        AgoraRtcEngineKit.destroy()
    }
}

// MARK: - AgoraRtcEngineDelegate
extension AudioCallVC: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("SUCCESS: Local user joined channel '\(channel)' with UID: \(uid)")
        DispatchQueue.main.async {
            self.statusLabel.text = "Waiting for remote..."
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.remoteUid   = uid
            self.isConnected = true
            self.statusLabel.text = "Connected · Audio Call"
            self.startDurationTimer()
            self.startPulseAnimation()
            UIView.animate(withDuration: 0.3) {
                self.durationLabel.alpha = 1
            }
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didOfflineOfUid uid: UInt,
                   reason: AgoraUserOfflineReason) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.statusLabel.text = "Call Ended"
            self.durationTimer?.invalidate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.dismiss(animated: true)
            }
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("Agora error: \(errorCode.rawValue)")
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "Connection Error (\(errorCode.rawValue))"
        }
    }
}
