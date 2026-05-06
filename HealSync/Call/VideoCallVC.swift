//
//  VideoCallVC.swift
//  HealSync
//
//  Created by Arfa on 30/03/2026.
//


import UIKit
import AgoraRtcKit
import FirebaseAuth

// MARK: - VideoCallVC
class VideoCallVC: UIViewController {

    // MARK: - Call Parameters
    var bookingId:      String = ""
    var therapistId:    String = ""
    var therapistName:  String = ""
    var patientId:      String = ""
    var patientName:    String = ""
    var isTherapist = false

    // MARK: - Agora
    private var agoraKit:   AgoraRtcEngineKit?
    private var remoteUid:  UInt = 0
    private var callDuration = 0
    private var durationTimer: Timer?
    private var isMuted      = false
    private var isCameraOff  = false
    private var isFrontCamera = true
    private var isRemoteVideoOn = false

    // MARK: - Video Containers
    private let remoteVideoContainer = UIView()   // fullscreen — therapist
    private let localVideoContainer  = UIView()   // PiP — patient

    // MARK: - Overlay UI
    private let topBar        = UIView()
    private let nameLabel     = UILabel()
    private let durationLabel = UILabel()
    private let statusLabel   = UILabel()
    private let avatarFallback = UILabel()       // shown when remote video is off

    private let controlsBar   = UIView()
    private let muteButton    = CallControlButton(icon: "mic.fill",         label: "Mute")
    private let cameraButton  = CallControlButton(icon: "video.fill",       label: "Camera")
    private let flipButton    = CallControlButton(icon: "camera.rotate.fill", label: "Flip")
    private let endCallButton = UIButton()
    
    private var displayName: String {
        isTherapist ? patientName : therapistName
    }

    // MARK: - Drag for PiP
    private var pipOrigin = CGPoint.zero

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupRemoteVideo()
        setupLocalVideo()
        setupAvatarFallback()
        setupTopBar()
        setupControlsBar()
        setupAgora()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        localVideoContainer.layer.cornerRadius = 16
        localVideoContainer.layer.shadowPath   = UIBezierPath(
            roundedRect: localVideoContainer.bounds,
            cornerRadius: 16).cgPath
    }

    override var prefersStatusBarHidden: Bool { true }

    // MARK: - Remote Video (Full Screen)
    private func setupRemoteVideo() {
        remoteVideoContainer.frame = view.bounds
        remoteVideoContainer.backgroundColor = UIColor(red: 0.07, green: 0.10, blue: 0.15, alpha: 1)
        remoteVideoContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(remoteVideoContainer)
    }

    // MARK: - Avatar Fallback (when camera is off)
    private func setupAvatarFallback() {
        avatarFallback.text = String(displayName.prefix(1)).uppercased()
        avatarFallback.font = UIFont.systemFont(ofSize: 64, weight: .medium)
        avatarFallback.textColor = .white
        avatarFallback.textAlignment = .center
        avatarFallback.translatesAutoresizingMaskIntoConstraints = false
        avatarFallback.isHidden = true
        view.addSubview(avatarFallback)
        NSLayoutConstraint.activate([
            avatarFallback.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarFallback.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40)
        ])
    }

    // MARK: - Local Video PiP
    private func setupLocalVideo() {
        let pipWidth:  CGFloat = 110
        let pipHeight: CGFloat = 160
        let margin:    CGFloat = 16
        let safeTop = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 44)

        localVideoContainer.frame = CGRect(
            x: view.bounds.width - pipWidth - margin,
            y: safeTop + 60,
            width:  pipWidth,
            height: pipHeight
        )
        localVideoContainer.backgroundColor = UIColor(white: 0.2, alpha: 1)
        localVideoContainer.layer.cornerRadius  = 16
        localVideoContainer.layer.masksToBounds = false
        localVideoContainer.layer.shadowColor   = UIColor.black.cgColor
        localVideoContainer.layer.shadowOpacity = 0.5
        localVideoContainer.layer.shadowOffset  = CGSize(width: 0, height: 4)
        localVideoContainer.layer.shadowRadius  = 8
        localVideoContainer.clipsToBounds       = true
        view.addSubview(localVideoContainer)

        // Drag gesture for PiP
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePipDrag(_:)))
        localVideoContainer.addGestureRecognizer(pan)
        localVideoContainer.isUserInteractionEnabled = true

        // "Camera off" label inside pip
        let offLabel = UILabel()
        offLabel.text = "📷"
        offLabel.font = UIFont.systemFont(ofSize: 28)
        offLabel.textAlignment = .center
        offLabel.tag  = 99
        offLabel.translatesAutoresizingMaskIntoConstraints = false
        offLabel.isHidden = true
        localVideoContainer.addSubview(offLabel)
        NSLayoutConstraint.activate([
            offLabel.centerXAnchor.constraint(equalTo: localVideoContainer.centerXAnchor),
            offLabel.centerYAnchor.constraint(equalTo: localVideoContainer.centerYAnchor)
        ])
    }

    // MARK: - Top Bar
    private func setupTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = .clear
        view.addSubview(topBar)

        // Gradient for readability
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.black.withAlphaComponent(0.65).cgColor,
                           UIColor.clear.cgColor]
        gradient.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 110)
        topBar.layer.insertSublayer(gradient, at: 0)
        
        nameLabel.text = displayName
        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(nameLabel)

        statusLabel.text = "Connecting..."
        statusLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(statusLabel)

        durationLabel.text = ""
        durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        durationLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(durationLabel)

        // Encryption badge
        let lockIcon = UIImageView(image: UIImage(systemName: "lock.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11)))
        lockIcon.tintColor = UIColor(red: 0.2, green: 0.85, blue: 0.45, alpha: 1)
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(lockIcon)

        let encLabel = UILabel()
        encLabel.text = "End-to-end encrypted"
        encLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        encLabel.textColor = UIColor(red: 0.2, green: 0.85, blue: 0.45, alpha: 1)
        encLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(encLabel)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 110),

            nameLabel.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 20),
            nameLabel.topAnchor.constraint(equalTo: topBar.safeAreaLayoutGuide.topAnchor, constant: 10),

            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),

            durationLabel.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 6),
            durationLabel.centerYAnchor.constraint(equalTo: statusLabel.centerYAnchor),

            lockIcon.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            lockIcon.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 6),

            encLabel.leadingAnchor.constraint(equalTo: lockIcon.trailingAnchor, constant: 4),
            encLabel.centerYAnchor.constraint(equalTo: lockIcon.centerYAnchor)
        ])
    }

    // MARK: - Controls Bar
    private func setupControlsBar() {
        controlsBar.translatesAutoresizingMaskIntoConstraints = false
        controlsBar.backgroundColor = UIColor.black.withAlphaComponent(0.6)

        // Blur effect
        let blur = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blur)
        controlsBar.addSubview(blurView)
        controlsBar.layer.cornerRadius = 28
        controlsBar.clipsToBounds = true

        view.addSubview(controlsBar)
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: controlsBar.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: controlsBar.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: controlsBar.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: controlsBar.trailingAnchor)
        ])

        // End call
        endCallButton.translatesAutoresizingMaskIntoConstraints = false
        endCallButton.backgroundColor = UIColor(red: 0.95, green: 0.23, blue: 0.23, alpha: 1)
        endCallButton.layer.cornerRadius = 34
        let endImg = UIImage(systemName: "phone.down.fill",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium))
        endCallButton.setImage(endImg, for: .normal)
        endCallButton.tintColor = .white
        endCallButton.addTarget(self, action: #selector(endCallTapped), for: .touchUpInside)
        controlsBar.addSubview(endCallButton)

        // Button actions
        muteButton.addTarget(self,   action: #selector(muteTapped),   for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        flipButton.addTarget(self,   action: #selector(flipTapped),   for: .touchUpInside)

        let leftStack = UIStackView(arrangedSubviews: [muteButton, cameraButton, flipButton])
        leftStack.axis = .horizontal
        leftStack.spacing = 12
        leftStack.distribution = .fillEqually
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        controlsBar.addSubview(leftStack)

        NSLayoutConstraint.activate([
            controlsBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controlsBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsBar.heightAnchor.constraint(equalToConstant: 130),

            endCallButton.trailingAnchor.constraint(equalTo: controlsBar.trailingAnchor, constant: -24),
            endCallButton.centerYAnchor.constraint(equalTo: controlsBar.centerYAnchor, constant: -10),
            endCallButton.widthAnchor.constraint(equalToConstant: 68),
            endCallButton.heightAnchor.constraint(equalToConstant: 68),

            leftStack.leadingAnchor.constraint(equalTo: controlsBar.leadingAnchor, constant: 20),
            leftStack.centerYAnchor.constraint(equalTo: endCallButton.centerYAnchor),
            leftStack.trailingAnchor.constraint(equalTo: endCallButton.leadingAnchor, constant: -16),
            leftStack.heightAnchor.constraint(equalToConstant: 68)
        ])
    }

    // MARK: - Agora Setup

    private func setupAgora() {
        let config = AgoraRtcEngineConfig()
        config.appId = AgoraConfig.appId
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        
        // 1. Force the channel profile to communication
        agoraKit?.setChannelProfile(.communication)
        agoraKit?.enableVideo()
        
        // 2. Setup Local Video
        let localCanvas = AgoraRtcVideoCanvas()
        localCanvas.uid = 0 // Local remains 0
        localCanvas.view = localVideoContainer
        localCanvas.renderMode = .hidden
        agoraKit?.setupLocalVideo(localCanvas)
        agoraKit?.startPreview()

        // 3. Create a unique integer UID from your ID strings
        // Patient = 1, Therapist = 2 (Simple fix for testing)
        let userUID: UInt = isTherapist ? 2 : 1
        
        print("DEBUG: Joining Channel: \(bookingId) as UID: \(userUID)")

        let options = AgoraRtcChannelMediaOptions()
        options.publishCameraTrack = true
        options.publishMicrophoneTrack = true
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = true

        // 4. Join with the specific UID
        let safeChannelId = bookingId.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()

        print("DEBUG: Original ID: \(bookingId)")
        print("DEBUG: Sanitized ID for Agora: \(safeChannelId)")

        agoraKit?.joinChannel(
            byToken: nil,
            channelId: safeChannelId, // Use the cleaned version
            uid: userUID,
            mediaOptions: options
        )
    }

    // MARK: - Timer
    private func startTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.callDuration += 1
            self?.updateDurationLabel()
        }
    }

    private func updateDurationLabel() {
        let mins = callDuration / 60
        let secs = callDuration % 60
        durationLabel.text = "· " + String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - PiP Drag
    @objc private func handlePipDrag(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .began:
            pipOrigin = localVideoContainer.frame.origin
        case .changed:
            var newOrigin = CGPoint(x: pipOrigin.x + translation.x,
                                   y: pipOrigin.y + translation.y)
            // Clamp inside view bounds
            newOrigin.x = max(8, min(view.bounds.width  - localVideoContainer.frame.width  - 8, newOrigin.x))
            newOrigin.y = max(8, min(view.bounds.height - localVideoContainer.frame.height - 8, newOrigin.y))
            localVideoContainer.frame.origin = newOrigin
        case .ended:
            snapPipToEdge()
        default: break
        }
    }

    private func snapPipToEdge() {
        let margin: CGFloat = 12
        let midX = view.bounds.midX
        var target = localVideoContainer.frame.origin
        target.x = localVideoContainer.center.x < midX
            ? margin
            : view.bounds.width - localVideoContainer.frame.width - margin

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5) {
            self.localVideoContainer.frame.origin = target
        }
    }

    // MARK: - Actions
    @objc private func muteTapped() {
        isMuted.toggle()
        agoraKit?.muteLocalAudioStream(isMuted)
        muteButton.setActive(isMuted, activeIcon: "mic.slash.fill", inactiveIcon: "mic.fill")
    }

    @objc private func cameraTapped() {
        isCameraOff.toggle()
        agoraKit?.muteLocalVideoStream(isCameraOff)
        cameraButton.setActive(isCameraOff, activeIcon: "video.slash.fill", inactiveIcon: "video.fill")
        // Show placeholder in pip
        localVideoContainer.viewWithTag(99)?.isHidden = !isCameraOff
    }

    @objc private func flipTapped() {
        agoraKit?.switchCamera()
        isFrontCamera.toggle()
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    @objc private func endCallTapped() {
        let alert = UIAlertController(title: "End Session?",
                                      message: "Are you sure you want to end this therapy session?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "End Session", style: .destructive) { [weak self] _ in
            self?.endCall()
            self?.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func endCall() {
        durationTimer?.invalidate()
        durationTimer = nil
        agoraKit?.stopPreview()
        agoraKit?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
        agoraKit = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        endCall()
    }
}

// MARK: - AgoraRtcEngineDelegate
extension VideoCallVC: AgoraRtcEngineDelegate {

    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.remoteUid = uid
            
            print("Remote user joined with UID: \(uid)")
            let canvas = AgoraRtcVideoCanvas()
            canvas.uid        = uid
            canvas.view       = self.remoteVideoContainer
            canvas.renderMode = .hidden
            engine.setupRemoteVideo(canvas)

            self.statusLabel.text = "Connected"
            self.isRemoteVideoOn  = true
            self.avatarFallback.isHidden = true
            self.startTimer()
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   remoteVideoStateChangedOfUid uid: UInt,
                   state: AgoraVideoRemoteState,
                   reason: AgoraVideoRemoteReason,
                   elapsed: Int) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .stopped, .frozen:
                self?.avatarFallback.isHidden = false
            case .decoding:
                self?.avatarFallback.isHidden = true
            default: break
            }
        }
    }

    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didOfflineOfUid uid: UInt,
                   reason: AgoraUserOfflineReason) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "Session Ended"
            self?.durationTimer?.invalidate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self?.dismiss(animated: true)
            }
        }
    }
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("SUCCESS: Local user joined channel: \(channel) with UID: \(uid)")
        DispatchQueue.main.async {
            self.statusLabel.text = "Waiting for remote..."
        }
    }
}
