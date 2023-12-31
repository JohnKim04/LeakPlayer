//
//  PlayerViewController.swift
//  LeakPlayer
//
//  Created by John Kim on 11/20/23.
//
import MediaPlayer
import AVFoundation
import UIKit

class PlayerViewController: UIViewController {
    
    // MARK: - Public properties
    public var position: Int = 0
    public var songs: [Song] = []
    
    // MARK: - Private Properties
    private var playbackSlider: UISlider!
    private var updateTimer: Timer?
    
    // MARK: - UI Elements
    @IBOutlet var holder: UIView!
    var player: AVAudioPlayer?

    // UI for displaying song information and controls
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "My Music" // title text
        label.font = UIFont.boldSystemFont(ofSize: 28) // font size
        return label
    }()
    
    private let albumImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let songNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0 // line wrap
        label.font = UIFont.boldSystemFont(ofSize: 24)
        return label
    }()
    
    private let artistNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0 // line wrap
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private let albumNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0 // line wrap
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        return label
    }()

    let playPauseButton = UIButton()
    
    // MARK: - Lifecycle Methods
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if holder.subviews.count == 0 {
            configure()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAudioSession()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        becomeFirstResponder()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // MARK: - Audio Session Configuration
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
    }

    // MARK: - Remote Control Event Handling

    override func remoteControlReceived(with event: UIEvent?) {
        // handle remote control events (play, pause, next etc)
        guard let event = event, event.type == .remoteControl else { return }
        switch event.subtype {
        case .remoteControlPlay:
            player?.play()
        case .remoteControlPause:
            player?.pause()
        case .remoteControlNextTrack:
            didTapNextButton()
        case .remoteControlPreviousTrack:
            didTapBackButton()
        default:
            break
        }
    }
    
    func updateNowPlayingInfo() {
        // update the now playing information in the control center
        if let player = player, position < songs.count {
            let song = songs[position]
            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
            nowPlayingInfo[MPMediaItemPropertyTitle] = song.name
            nowPlayingInfo[MPMediaItemPropertyArtist] = song.artistName
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    // MARK: - Interruption Handling
    @objc func handleInterruption(notification: Notification) {
        // Handle audio interruptions
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began {
            // Interruption began, pause audio
            player?.pause()
        } else if type == .ended {
            // Interruption ended, resume audio if needed
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                player?.play()
            }
        }
    }
    
    // MARK: - UI Configuration
    func configure() {
        // configure UI elements and layout
        titleLabel.frame = CGRect(x: 0, y: 30, width: holder.frame.size.width, height: 40)
        holder.addSubview(titleLabel)
        // setup player
        let song = songs[position]
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let filePath = documentsPath?.appendingPathComponent(song.trackName).path
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            if let filePath = filePath, fileManager.fileExists(atPath: filePath) {
                // Play the song from the document directory
                player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: filePath))
            } else {
                // Play the song from the bundle
                guard let bundlePath = Bundle.main.path(forResource: song.trackName, ofType: "mp3") else { return }
                player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: bundlePath))
            }
            guard let player = player else { return }
            player.volume = 0.2
            player.play()
        } catch {
            print("Error occurred while trying to play the audio file: \(error)")
        }
        //setup user interface elements
        
        //album cover
        albumImageView.frame = CGRect(x: 30,
                                      y: 90,
                                      width: holder.frame.size.width-60,
                                      height: holder.frame.size.width-60)
        albumImageView.image = UIImage(named: song.imageName)
        holder.addSubview(albumImageView)
        
        //labels
        songNameLabel.frame = CGRect(x: 10,
                                     y: albumImageView.frame.size.height + 112,
                                      width: holder.frame.size.width-20,
                                      height: 70)
        albumNameLabel.frame = CGRect(x: 10,
                                      y: albumImageView.frame.size.height + 117 + 30,
                                      width: holder.frame.size.width-20,
                                      height: 70)
        artistNameLabel.frame = CGRect(x: 10,
                                      y: albumImageView.frame.size.height + 117 + 60,
                                      width: holder.frame.size.width-20,
                                      height: 70)
        
        songNameLabel.text = song.name
        albumNameLabel.text = song.albumName
        artistNameLabel.text = song.artistName
        
        holder.addSubview(songNameLabel)
        holder.addSubview(albumNameLabel)
        holder.addSubview(artistNameLabel)
        
        //player controls
        
        let nextButton = UIButton()
        let backButton = UIButton()
        
        //framse
        
        let yPosition = artistNameLabel.frame.origin.y + 20 + 140
        let size: CGFloat = 50
        
        playPauseButton.frame = CGRect(x: (holder.frame.size.width - size) / 2,
                                       y: yPosition,
                                       width: size,
                                       height: size)
        nextButton.frame = CGRect(x: (holder.frame.size.width - size - 80),
                                  y: yPosition,
                                  width: size,
                                  height: size)
        backButton.frame = CGRect(x:80,
                                  y: yPosition,
                                  width: size,
                                  height: size)
        
        //actions
        playPauseButton.addTarget(self, action: #selector(didTapPlayPauseButton), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        //images
        playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
        nextButton.setBackgroundImage(UIImage(systemName: "forward.fill"), for: .normal)
        backButton.setBackgroundImage(UIImage(systemName: "backward.fill"), for: .normal)
        
        playPauseButton.tintColor = .black
        nextButton.tintColor = .black
        backButton.tintColor = .black
    
        holder.addSubview(playPauseButton)
        holder.addSubview(nextButton)
        holder.addSubview(backButton)
        
        //seek slider
        playbackSlider = UISlider(frame: CGRect(x: 20,
                                                y: holder.frame.size.height-210,
                                                width: holder.frame.size.width - 40,
                                                height: 50))
        playbackSlider.tintColor = .black
        

        playbackSlider.minimumValue = 0
        if let player = player {
            playbackSlider.maximumValue = Float(player.duration)
        }
        playbackSlider.addTarget(self, action: #selector(didSlidePlaybackSlider(_:)), for: .valueChanged)
        holder.addSubview(playbackSlider)
        
        startUpdatingSlider()
            
        let sliderWidth: CGFloat = holder.frame.size.width - 40
        currentTimeLabel.frame = CGRect(x: 20, y: playbackSlider.frame.origin.y - 20, width: 50, height: 20)
        durationLabel.frame = CGRect(x: 20 + sliderWidth - 50, y: playbackSlider.frame.origin.y - 20, width: 50, height: 20)
        
        if let player = player {
            durationLabel.text = formatTime(time: player.duration)
        }
        currentTimeLabel.text = formatTime(time: 0)
        
        holder.addSubview(currentTimeLabel)
        holder.addSubview(durationLabel)
        
    }
    
    
    // MARK: - Playabck slider
    func formatTime(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startUpdatingSlider() {
        // start updating the slider
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSliderPosition()
        }
    }
    
    @objc func didSlidePlaybackSlider(_ slider: UISlider) {
        // handle playback slider value change
        player?.currentTime = TimeInterval(slider.value)
        currentTimeLabel.text = formatTime(time: TimeInterval(slider.value))
    }

    func updateSliderPosition() {
        // update playback slider position
        if let player = player {
            playbackSlider.value = Float(player.currentTime)
            currentTimeLabel.text = formatTime(time: player.currentTime)


            // Check if the song has finished playing
            if player.currentTime >= (player.duration - 1) { // Added a small buffer
                didTapNextButton()  // Move to the next song
            }
        }
    }

    // MARK: - Player Control Actions
    
    @objc func didTapBackButton () {
        // action for back button
        if position > 0 {
            position = position - 1
            player?.stop()
            for subview in holder.subviews {
                subview.removeFromSuperview()
            }
            configure()
        }
        updateNowPlayingInfo()
    }
    
    @objc func didTapNextButton () {
        // action for next button
        if position < (songs.count - 1) {
            position = position + 1
            player?.stop()
            for subview in holder.subviews {
                subview.removeFromSuperview()
            }
            configure()
        }
        updateNowPlayingInfo()
    }
    
    @objc func didTapPlayPauseButton () {
        // Action for play pause button
        if player?.isPlaying == true{
            player?.pause()
            //show play button
            playPauseButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
            //shrink image
            UIView.animate(withDuration: 0.2, animations: {
                self.albumImageView.frame = CGRect(x: 40,
                                                   y: 100,
                                                   width: self.holder.frame.size.width-80,
                                                   height: self.holder.frame.size.width-80)
            })
            
        }
        else {
            player?.play()
            playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
            //increase image
            UIView.animate(withDuration: 0.2, animations: {
                self.albumImageView.frame = CGRect(x: 30,
                                                   y: 90,
                                                   width: self.holder.frame.size.width-60,
                                                   height: self.holder.frame.size.width-60)
            })
        }
        updateNowPlayingInfo()
    }
    
    // MARK: - View Disappearance
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let player = player {
            player.stop()
        }
        UIApplication.shared.endReceivingRemoteControlEvents()
        resignFirstResponder()
    }
}
