//
//  VideoPlayer.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import AVFoundation
import CoreGraphics

// MARK: - VideoPlayerDelegate
/// Player delegate protocol
@objc public protocol VideoPlayerDelegate {
    @objc optional func playerReady(_ player: VideoPlayer)
    @objc optional func playerPlaybackStateDidChange(_ player: VideoPlayer)
    @objc optional func playerBufferingStateDidChange(_ player: VideoPlayer)
    @objc optional func playerBufferTimeDidChange(_ bufferTime: Double)
    @objc optional func player(_ player: VideoPlayer, didFailWithError error: Error?)
}

// MARK: - VideoPlayerPlaybackDelegate
/// Player playback protocol
@objc public protocol VideoPlayerPlaybackDelegate {
    @objc optional func playerCurrentTimeDidChange(_ player: VideoPlayer)
    @objc optional func playerPlaybackWillStartFromBeginning(_ player: VideoPlayer)
    @objc optional func playerPlaybackDidEnd(_ player: VideoPlayer)
    @objc optional func playerPlaybackWillLoop(_ player: VideoPlayer)
    @objc optional func playerPlaybackDidLoop(_ player: VideoPlayer)
}

// MARK: - VideoPlayerPlaybackState
/// Asset playback states
public enum VideoPlayerPlaybackState: Int, Sendable {
    case stopped = 0
    case playing
    case paused
    case failed
}

// MARK: - VideoPlayerBufferingState
/// Asset buffering states
public enum VideoPlayerBufferingState: Int, Sendable {
    case unknown = 0
    case ready
    case delayed
}

// MARK: - VideoPlayer
/// Video Player, simple way to play and stream media
///
/// @see https://github.com/piemonte/Player
open class VideoPlayer: UIViewController {

    // properties
    
    /// Player delegate.
    open weak var playerDelegate: VideoPlayerDelegate?

    /// Playback delegate.
    open weak var playbackDelegate: VideoPlayerPlaybackDelegate?

    // configuration

    /// Local or remote URL for the file asset to be played.
    /// URL of the asset.
    open var url: URL? {
        didSet {
            if let url = self.url {
                setup(url: url)
            }
        }
    }

    /// For setting up with AVAsset instead of URL
    /// Note: This will reset the `url` property. (cannot set both)
    open var asset: AVAsset? {
        didSet {
            if let asset = self.asset {
                setupAsset(asset)
            }
        }
    }

    /// Specifies how the video is displayed within a player layer’s bounds.
    /// The default value is `AVLayerVideoGravityResizeAspect`. See `PlayerFillMode`.
    open var fillMode: AVLayerVideoGravity {
        get {
            return self.playerView.playerFillMode
        }
        set {
            self.playerView.playerFillMode = newValue
        }
    }

    /// Determines if the video should autoplay when streaming a URL.
    open var autoplay: Bool = true

    /// Mutes audio playback when true.
    open var muted: Bool {
        get {
            return self.player.isMuted
        }
        set {
            self.player.isMuted = newValue
        }
    }

    /// Volume for the player, ranging from 0.0 to 1.0 on a linear scale.
    open var volume: Float {
        get {
            return self.player.volume
        }
        set {
            self.player.volume = newValue
        }
    }
    
    /// Rate at which the video should play once it loads
    open var rate: Float = 1 {
        didSet {
            self.player.rate = rate
        }
    }

    /// Pauses playback automatically when resigning active.
    open var playbackPausesWhenResigningActive: Bool = true

    /// Pauses playback automatically when backgrounded.
    open var playbackPausesWhenBackgrounded: Bool = true

    /// Resumes playback when became active.
    open var playbackResumesWhenBecameActive: Bool = true

    /// Resumes playback when entering foreground.
    open var playbackResumesWhenEnteringForeground: Bool = true

    // state
    
    open var isPlayingVideo: Bool {
        get {
            guard let asset = self.asset else {
                return false
            }
            return asset.tracks(withMediaType: .video).count != 0
        }
    }

    /// Playback automatically loops continuously when true.
    open var playbackLoops: Bool {
        get {
            return self.player.actionAtItemEnd == .none
        }
        set {
            if newValue {
                self.player.actionAtItemEnd = .none
            } else {
                self.player.actionAtItemEnd = .pause
            }
        }
    }

    /// Playback freezes on last frame frame when true and does not reset seek position timestamp..
    open var playbackFreezesAtEnd: Bool = false

    /// Current playback state of the Player.
    open var playbackState: VideoPlayerPlaybackState = .stopped {
        didSet {
            if playbackState != oldValue || !playbackEdgeTriggered {
                self.executeClosureOnMainQueueIfNecessary {
                    self.playerDelegate?.playerPlaybackStateDidChange?(self)
                }
            }
        }
    }

    /// Current buffering state of the Player.
    open var bufferingState: VideoPlayerBufferingState = .unknown {
        didSet {
            if bufferingState != oldValue || !playbackEdgeTriggered {
                self.executeClosureOnMainQueueIfNecessary {
                    self.playerDelegate?.playerBufferingStateDidChange?(self)
                }
            }
        }
    }

    /// Playback buffering size in seconds.
    open var bufferSizeInSeconds: Double = 10

    /// Playback is not automatically triggered from state changes when true.
    open var playbackEdgeTriggered: Bool = true

    /// Maximum duration of playback.
    open var maximumDuration: TimeInterval {
        get {
            if let playerItem = self.playerItem {
                return CMTimeGetSeconds(playerItem.duration)
            } else {
                return CMTimeGetSeconds(CMTime.indefinite)
            }
        }
    }

    /// Media playback's current time interval in seconds.
    open var currentTimeInterval: TimeInterval {
        get {
            if let playerItem = self.playerItem {
                return CMTimeGetSeconds(playerItem.currentTime())
            } else {
                return CMTimeGetSeconds(CMTime.indefinite)
            }
        }
    }
    
    /// Media playback's current time.
    open var currentTime: CMTime {
        get {
            if let playerItem = self.playerItem {
                return playerItem.currentTime()
            } else {
                return CMTime.indefinite
            }
        }
    }

    /// The natural dimensions of the media.
    open var naturalSize: CGSize {
        get {
            if let playerItem = self.playerItem,
                let track = playerItem.asset.tracks(withMediaType: .video).first {

                let size = track.naturalSize.applying(track.preferredTransform)
                return CGSize(width: abs(size.width), height: abs(size.height))
            } else {
                return CGSize.zero
            }
        }
    }
    
    open lazy var player: AVPlayer = {
        let player = AVPlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        player.actionAtItemEnd = .pause
        return player
    }()

    open lazy var playerView: VideoPlayerView = VideoPlayerView(frame: .zero)

    /// Return the av player layer for consumption by things such as Picture in Picture
    open func playerLayer() -> AVPlayerLayer? {
        return self.playerView.playerLayer
    }

    /// Indicates the desired limit of network bandwidth consumption for this item.
    open var preferredPeakBitRate: Double = 0 {
        didSet {
            self.playerItem?.preferredPeakBitRate = self.preferredPeakBitRate
        }
    }

    /// Indicates a preferred upper limit on the resolution of the video to be downloaded.
    open var preferredMaximumResolution: CGSize {
        get {
            return self.playerItem?.preferredMaximumResolution ?? CGSize.zero
        }
        set {
            self.playerItem?.preferredMaximumResolution = newValue
            self.itemMaximumResolution = newValue
        }
    }

    // private
    
    internal var playerItem: AVPlayerItem?
    internal var playerObservers = [NSKeyValueObservation]()
    internal var playerItemObservers = [NSKeyValueObservation]()
    internal var playerLayerObserver: NSKeyValueObservation?
    internal var playerTimeObserver: Any?

    internal var seekTimeRequested: CMTime?
    internal var lastBufferTime: Double = 0
    internal var itemMaximumResolution: CGSize = .zero

    // Boolean that determines if the user or calling coded has trigged autoplay manually.
    internal var hasAutoplayActivated: Bool = true

    // MARK: - lifecycle

    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    deinit {
        self.player.pause()
        self.setupPlayerItem(nil)

        self.removePlayerObservers()
        self.removeApplicationObservers()
        self.removePlayerLayerObservers()

        self.playerView.player = nil
    }

    open override func loadView() {
        super.loadView()
        self.playerView.frame = self.view.bounds
        self.view = self.playerView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.playerView.player = self.player

        if let url = self.url {
            setup(url: url)
        } else if let asset = self.asset {
            setupAsset(asset)
        }

        self.addPlayerLayerObservers()
        self.addPlayerObservers()
        self.addApplicationObservers()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.playbackState == .playing {
            self.pause()
        }
    }

    // MARK: - performance

    /// Total time spent playing.
    public var totalDurationWatched: TimeInterval {
        get {
            var totalDurationWatched = 0.0
            if let accessLog = self.playerItem?.accessLog(), accessLog.events.isEmpty == false {
                for event in accessLog.events where event.durationWatched > 0 {
                    totalDurationWatched += event.durationWatched
                }
            }
            return totalDurationWatched
        }
    }

    /// Time weighted value of the variant indicated bitrate. Measure of overall stream quality.
    var timeWeightedIBR: Double {
        var timeWeightedIBR = 0.0
        let totalDurationWatched = self.totalDurationWatched
           
        if let accessLog = self.playerItem?.accessLog(), totalDurationWatched > 0 {
            for event in accessLog.events {
                if event.durationWatched > 0 && event.indicatedBitrate > 0 {
                    let eventTimeWeight = event.durationWatched / totalDurationWatched
                    timeWeightedIBR += event.indicatedBitrate * eventTimeWeight
                }
            }
        }
        return timeWeightedIBR
    }

    /// Stall rate measured in stalls per hour. Normalized measure of stream interruptions caused by stream buffer depleation.
    var stallRate: Double {
        var totalNumberOfStalls = 0
        let totalHoursWatched = self.totalDurationWatched / 3600
        
        if let accessLog = self.playerItem?.accessLog(), totalDurationWatched > 0 {
            for event in accessLog.events {
                totalNumberOfStalls += event.numberOfStalls
            }
        }
        return Double(totalNumberOfStalls) / totalHoursWatched
    }

    // MARK: - actions

    /// Begins playback of the media from the beginning.
    open func playFromBeginning() {
        self.playbackDelegate?.playerPlaybackWillStartFromBeginning?(self)
        self.player.seek(to: CMTime.zero)
        self.playFromCurrentTime()
    }

    /// Begins playback of the media from the current time.
    open func playFromCurrentTime() {
        if !self.autoplay {
            // External call to this method with autoplay disabled. Re-activate it before calling play.
            self.hasAutoplayActivated = true
        }
        self.play()
    }

    fileprivate func play() {
        if self.autoplay || self.hasAutoplayActivated {
            self.playbackState = .playing
            self.player.playImmediately(atRate: rate)
        }
    }

    /// Pauses playback of the media.
    open func pause() {
        if self.playbackState != .playing {
            return
        }

        self.player.pause()
        self.playbackState = .paused
    }

    /// Stops playback of the media.
    open func stop() {
        if self.playbackState == .stopped {
            return
        }

        self.player.pause()
        self.playbackState = .stopped
        self.playbackDelegate?.playerPlaybackDidEnd?(self)
    }

    /// Updates playback to the specified time.
    ///
    /// - Parameters:
    ///   - time: The time to switch to move the playback.
    ///   - completionHandler: Call block handler after seeking/
    open func seek(to time: CMTime, completionHandler: ((Bool) -> Swift.Void)? = nil) {
        if let playerItem = self.playerItem {
            return playerItem.seek(to: time, completionHandler: completionHandler)
        } else {
            self.seekTimeRequested = time
        }
    }

    /// Updates the playback time to the specified time bound.
    ///
    /// - Parameters:
    ///   - time: The time to switch to move the playback.
    ///   - toleranceBefore: The tolerance allowed before time.
    ///   - toleranceAfter: The tolerance allowed after time.
    ///   - completionHandler: call block handler after seeking
    open func seekToTime(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: ((Bool) -> Swift.Void)? = nil) {
        if let playerItem = self.playerItem {
            return playerItem.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
        }
    }

    /// Captures a snapshot of the current Player asset.
    ///
    /// - Parameter completionHandler: Returns a UIImage of the requested video frame. (Great for thumbnails!)
    open func takeSnapshot(completionHandler: ((_ image: UIImage?, _ error: Error?) -> Void)? ) {
        guard let asset = self.playerItem?.asset else {
            DispatchQueue.main.async {
                completionHandler?(nil, nil)
            }
            return
        }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let currentTime = self.playerItem?.currentTime() ?? CMTime.zero

        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: currentTime)]) { (requestedTime, image, actualTime, result, error) in
            guard let image = image else {
                DispatchQueue.main.async {
                    completionHandler?(nil, error)
                }
                return
            }
            
            switch result {
            case .succeeded:
                let uiimage = UIImage(cgImage: image)
                DispatchQueue.main.async {
                    completionHandler?(uiimage, nil)
                }
                break
            case .failed, .cancelled:
                fallthrough
            @unknown default:
                DispatchQueue.main.async {
                    completionHandler?(nil, nil)
                }
                break
            }
        }
    }

    // MARK: - loading

    fileprivate func setup(url: URL) {
        guard isViewLoaded else { return }

        // ensure everything is reset beforehand
        if self.playbackState == .playing {
            self.pause()
        }

        // Reset autoplay flag since a new url is set.
        self.hasAutoplayActivated = false
        if self.autoplay {
            self.playbackState = .playing
        } else {
            self.playbackState = .stopped
        }

        self.setupPlayerItem(nil)
        
        self.asset = AVURLAsset(url: url, options: .none)
    }

    fileprivate func setupAsset(_ asset: AVAsset, loadableKeys: [String] = ["tracks", "playable", "duration"]) {
        guard isViewLoaded else { return }

        if self.playbackState == .playing {
            self.pause()
        }

        self.bufferingState = .unknown

        self.setupPlayerItem(nil)

        self.asset?.loadValuesAsynchronously(forKeys: loadableKeys, completionHandler: { () -> Void in
            guard let asset = self.asset else {
                return
            }
            
            for key in loadableKeys {
                var error: NSError? = nil
                let status = asset.statusOfValue(forKey: key, error: &error)
                if status == .failed {
                    self.playbackState = .failed
                    self.executeClosureOnMainQueueIfNecessary {
                        self.playerDelegate?.player?(self, didFailWithError: error)
                    }
                    return
                }
            }

            if !asset.isPlayable {
                self.playbackState = .failed
                self.executeClosureOnMainQueueIfNecessary {
                    self.playerDelegate?.player?(self, didFailWithError: NSError(domain: "VideoPlayer", code: 0, userInfo: nil))
                }
                return
            }

            let playerItem = AVPlayerItem(asset:asset)
            self.setupPlayerItem(playerItem)
        })
    }

    fileprivate func setupPlayerItem(_ playerItem: AVPlayerItem?) {

        self.removePlayerItemObservers()

        if let currentPlayerItem = self.playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentPlayerItem)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: currentPlayerItem)
        }

        self.playerItem = playerItem
        
        self.playerItem?.audioTimePitchAlgorithm = .spectral
        self.playerItem?.preferredPeakBitRate = self.preferredPeakBitRate
        self.playerItem?.preferredMaximumResolution = self.itemMaximumResolution

        if let seek = self.seekTimeRequested, self.playerItem != nil {
            self.seekTimeRequested = nil
            self.seek(to: seek)
        }

        if let updatedPlayerItem = self.playerItem {
            self.addPlayerItemObservers()
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: updatedPlayerItem)
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: updatedPlayerItem)
        }

        self.player.replaceCurrentItem(with: self.playerItem)
        self.player.rate = rate

        // update new playerItem settings
        if self.playbackLoops {
            self.player.actionAtItemEnd = .none
        } else {
            self.player.actionAtItemEnd = .pause
        }
    }

    // MARK: - UIApplication

    internal func addApplicationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    internal func removeApplicationObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - AVPlayerItem handlers

    @objc internal func playerItemDidPlayToEndTime(_ aNotification: Notification) {
        self.executeClosureOnMainQueueIfNecessary {
            if self.playbackLoops {
                self.playbackDelegate?.playerPlaybackWillLoop?(self)
                self.player.seek(to: CMTime.zero)
                self.player.play()
                self.player.rate = self.rate
                self.playbackDelegate?.playerPlaybackDidLoop?(self)
            } else if self.playbackFreezesAtEnd {
                self.stop()
            } else {
                self.player.seek(to: CMTime.zero, completionHandler: { _ in
                    self.stop()
                })
            }
        }
    }

    @objc internal func playerItemFailedToPlayToEndTime(_ aNotification: Notification) {
        self.playbackState = .failed
    }

    // MARK: - UIApplication handlers

    @objc internal func handleApplicationWillResignActive(_ aNotification: Notification) {
        if self.playbackState == .playing && self.playbackPausesWhenResigningActive {
            self.pause()
        }
    }

    @objc internal func handleApplicationDidBecomeActive(_ aNotification: Notification) {
        if self.playbackState == .paused && self.playbackResumesWhenBecameActive {
            self.play()
        }
    }

    @objc internal func handleApplicationDidEnterBackground(_ aNotification: Notification) {
        if self.playbackState == .playing && self.playbackPausesWhenBackgrounded {
            self.pause()
        }
    }

    @objc internal func handleApplicationWillEnterForeground(_ aNoticiation: Notification) {
        if self.playbackState != .playing && self.playbackResumesWhenEnteringForeground {
            self.play()
        }
    }

    // MARK: - AVPlayerItemObservers

    internal func addPlayerItemObservers() {
        guard let playerItem = self.playerItem else {
            return
        }

        self.playerItemObservers.append(playerItem.observe(\.isPlaybackBufferEmpty, options: [.new, .old]) { [weak self] (object, change) in
            if object.isPlaybackBufferEmpty {
                self?.bufferingState = .delayed
            }

            switch object.status {
            case .failed:
                self?.playbackState = VideoPlayerPlaybackState.failed
            default:
                break
            }
        })

        self.playerItemObservers.append(playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .old]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }

            if object.isPlaybackLikelyToKeepUp {
                strongSelf.bufferingState = .ready
                if strongSelf.playbackState == .playing {
                    strongSelf.playFromCurrentTime()
                }
            }

            switch object.status {
            case .failed:
                strongSelf.playbackState = VideoPlayerPlaybackState.failed
                break
            default:
                break
            }
        })

        self.playerItemObservers.append(playerItem.observe(\.loadedTimeRanges, options: [.new, .old]) { [weak self] (object, change) in
            guard let strongSelf = self else {
                return
            }

            let timeRanges = object.loadedTimeRanges
            if let timeRange = timeRanges.first?.timeRangeValue {
                let bufferedTime = CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration))
                if strongSelf.lastBufferTime != bufferedTime {
                    strongSelf.lastBufferTime = bufferedTime
                    strongSelf.executeClosureOnMainQueueIfNecessary {
                        strongSelf.playerDelegate?.playerBufferTimeDidChange?(bufferedTime)
                    }
                }
            }

            let currentTime = CMTimeGetSeconds(object.currentTime())
            let passedTime = strongSelf.lastBufferTime <= 0 ? currentTime : (strongSelf.lastBufferTime - currentTime)

            if (passedTime >= strongSelf.bufferSizeInSeconds ||
                strongSelf.lastBufferTime == strongSelf.maximumDuration ||
                timeRanges.first == nil) &&
                strongSelf.playbackState == .playing {
                strongSelf.play()
            }
        })
    }

    internal func removePlayerItemObservers() {
        for observer in self.playerItemObservers {
            observer.invalidate()
        }
        self.playerItemObservers.removeAll()
    }

    // MARK: - AVPlayerLayerObservers

    internal func addPlayerLayerObservers() {
        self.playerLayerObserver = self.playerView.playerLayer.observe(\.isReadyForDisplay, options: [.new, .old]) { [weak self] (object, change) in
            self?.executeClosureOnMainQueueIfNecessary {
                if let strongSelf = self {
                    strongSelf.playerDelegate?.playerReady?(strongSelf)
                }
            }
        }
    }

    internal func removePlayerLayerObservers() {
        self.playbackDelegate = nil
        self.playerLayerObserver?.invalidate()
        self.playerLayerObserver = nil
    }

    // MARK: - AVPlayerObservers

    internal func addPlayerObservers() {
        self.playerTimeObserver = self.player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 100), queue: DispatchQueue.main, using: { [weak self] timeInterval in
            guard let strongSelf = self else {
                return
            }
            strongSelf.playbackDelegate?.playerCurrentTimeDidChange?(strongSelf)
        })

        self.playerObservers.append(self.player.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] (object, change) in
            switch object.timeControlStatus {
            case .paused:
                self?.playbackState = .paused
            case .playing:
                self?.playbackState = .playing
            case .waitingToPlayAtSpecifiedRate:
                fallthrough
            @unknown default:
                break
            }
        })
    }

    internal func removePlayerObservers() {
        if let observer = self.playerTimeObserver {
            self.player.removeTimeObserver(observer)
        }
        for observer in self.playerObservers {
            observer.invalidate()
        }
        self.playerObservers.removeAll()
        self.playerDelegate = nil
    }

    // MARK: - queues

    internal func executeClosureOnMainQueueIfNecessary(withClosure closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async(execute: closure)
        }
    }

}

// MARK: - VideoPlayerView
open class VideoPlayerView: UIView {

    open override class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }

    open var playerLayer: AVPlayerLayer {
        get {
            return self.layer as! AVPlayerLayer
        }
    }

    open var player: AVPlayer? {
        get {
            return self.playerLayer.player
        }
        set {
            self.playerLayer.player = newValue
            self.playerLayer.isHidden = (self.playerLayer.player == nil)
        }
    }

    open var playerBackgroundColor: UIColor? {
        get {
            if let cgColor = self.playerLayer.backgroundColor {
                return UIColor(cgColor: cgColor)
            }
            return nil
        }
        set {
            self.playerLayer.backgroundColor = newValue?.cgColor
        }
    }

    open var playerFillMode: AVLayerVideoGravity {
        get {
            return self.playerLayer.videoGravity
        }
        set {
            self.playerLayer.videoGravity = newValue
        }
    }

    open var isReadyForDisplay: Bool {
        get {
            return self.playerLayer.isReadyForDisplay
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.playerLayer.isHidden = true
        self.playerFillMode = .resizeAspect
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.playerLayer.isHidden = true
        self.playerFillMode = .resizeAspect
    }

    deinit {
        self.player?.pause()
        self.player = nil
    }

}
