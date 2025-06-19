//
//  VideoPlayer.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import AVFoundation
import CoreGraphics
import UIKit
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - VideoPlayerDelegate
/// Player delegate protocol
@MainActor @objc public protocol VideoPlayerDelegate {
    @objc optional func playerReady(_ player: VideoPlayer)
    @objc optional func playerPlaybackStateDidChange(_ player: VideoPlayer)
    @objc optional func playerBufferingStateDidChange(_ player: VideoPlayer)
    @objc optional func playerBufferTimeDidChange(_ bufferTime: Double)
    @objc optional func player(_ player: VideoPlayer, didFailWithError error: Error?)
}

// MARK: - VideoPlayerPlaybackDelegate
/// Player playback protocol
@MainActor @objc public protocol VideoPlayerPlaybackDelegate {
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
    private class MutableState: @unchecked Sendable {
        weak var playerDelegate: VideoPlayerDelegate?
        weak var playbackDelegate: VideoPlayerPlaybackDelegate?
        var asset: AVAsset?
        var playbackState: VideoPlayerPlaybackState = .stopped
        var bufferingState: VideoPlayerBufferingState = .unknown
        var bufferSizeInSeconds: Double = 10
        var playbackEdgeTriggered: Bool = true
        var player: AVPlayer?
        var preferredPeakBitRate: Double = 0

        var playerItem: AVPlayerItem?
        var playerObservers = [NSKeyValueObservation]()
        var playerItemObservers = [NSKeyValueObservation]()
        var playerLayerObserver: NSKeyValueObservation?
        var playerTimeObserver: Any?

        var seekTimeRequested: CMTime?
        var lastBufferTime: Double = 0
        var itemMaximumResolution: CGSize = .zero
        var hasAutoplayActivated: Bool = true
    }

    /// Player delegate.
    open nonisolated weak var playerDelegate: VideoPlayerDelegate? {
        get { mutableState.playerDelegate }
        set { mutableState.playerDelegate = newValue }
    }

    /// Playback delegate.
    open nonisolated weak var playbackDelegate: VideoPlayerPlaybackDelegate? {
        get { mutableState.playbackDelegate }
        set { mutableState.playbackDelegate = newValue }
    }

    /// Local or remote URL for the file asset to be played.
    /// URL of the asset.
    open var url: URL? {
        didSet {
            if let url {
                setup(url: url)
            }
        }
    }

    /// For setting up with AVAsset instead of URL
    /// Note: This will reset the `url` property. (cannot set both)
    open var asset: AVAsset? {
        get {
            mutableState.asset
        }
        set {
            mutableState.asset = newValue
            if let asset = newValue {
                setupAsset(asset)
            }
        }
    }

    /// Specifies how the video is displayed within a player layer’s bounds.
    /// The default value is `AVLayerVideoGravityResizeAspect`. See `PlayerFillMode`.
    open var fillMode: AVLayerVideoGravity {
        get {
            playerView.playerFillMode
        }
        set {
            playerView.playerFillMode = newValue
        }
    }

    /// Determines if the video should autoplay when streaming a URL.
    open var autoplay: Bool = true

    /// Mutes audio playback when true.
    open var muted: Bool {
        get {
            player.isMuted
        }
        set {
            player.isMuted = newValue
        }
    }

    /// Volume for the player, ranging from 0.0 to 1.0 on a linear scale.
    open var volume: Float {
        get {
            player.volume
        }
        set {
            player.volume = newValue
        }
    }

    /// Rate at which the video should play once it loads
    open var rate: Float = 1 {
        didSet {
            player.rate = rate
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

    /// Whether is playing video.
    open var isPlayingVideo: Bool {
        guard let asset else {
            return false
        }
        return asset.tracks(withMediaType: .video).count != 0
    }

    /// Playback automatically loops continuously when true.
    open var playbackLoops: Bool {
        get {
            player.actionAtItemEnd == .none
        }
        set {
            if newValue {
                player.actionAtItemEnd = .none
            } else {
                player.actionAtItemEnd = .pause
            }
        }
    }

    /// Playback freezes on last frame frame when true and does not reset seek position timestamp..
    open var playbackFreezesAtEnd: Bool = false

    /// Current playback state of the Player.
    open nonisolated var playbackState: VideoPlayerPlaybackState {
        get {
            mutableState.playbackState
        }
        set {
            let oldValue = mutableState.playbackState
            mutableState.playbackState = newValue

            if newValue != oldValue || !playbackEdgeTriggered {
                DispatchQueue.fw.mainAsync {
                    self.playerDelegate?.playerPlaybackStateDidChange?(self)
                }
            }
        }
    }

    /// Current buffering state of the Player.
    open nonisolated var bufferingState: VideoPlayerBufferingState {
        get {
            mutableState.bufferingState
        }
        set {
            let oldValue = mutableState.bufferingState
            mutableState.bufferingState = newValue

            if newValue != oldValue || !playbackEdgeTriggered {
                DispatchQueue.fw.mainAsync {
                    self.playerDelegate?.playerBufferingStateDidChange?(self)
                }
            }
        }
    }

    /// Playback buffering size in seconds.
    open nonisolated var bufferSizeInSeconds: Double {
        get { mutableState.bufferSizeInSeconds }
        set { mutableState.bufferSizeInSeconds = newValue }
    }

    /// Playback is not automatically triggered from state changes when true.
    open nonisolated var playbackEdgeTriggered: Bool {
        get { mutableState.playbackEdgeTriggered }
        set { mutableState.playbackEdgeTriggered = newValue }
    }

    /// Maximum duration of playback.
    open nonisolated var maximumDuration: TimeInterval {
        if let playerItem = mutableState.playerItem {
            return CMTimeGetSeconds(playerItem.duration)
        } else {
            return CMTimeGetSeconds(CMTime.indefinite)
        }
    }

    /// Media playback's current time interval in seconds.
    open nonisolated var currentTimeInterval: TimeInterval {
        if let playerItem = mutableState.playerItem {
            return CMTimeGetSeconds(playerItem.currentTime())
        } else {
            return CMTimeGetSeconds(CMTime.indefinite)
        }
    }

    /// Media playback's current time.
    open nonisolated var currentTime: CMTime {
        if let playerItem = mutableState.playerItem {
            return playerItem.currentTime()
        } else {
            return CMTime.indefinite
        }
    }

    /// The natural dimensions of the media.
    open var naturalSize: CGSize {
        if let playerItem = mutableState.playerItem,
           let track = playerItem.asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            return CGSize(width: abs(size.width), height: abs(size.height))
        } else {
            return CGSize.zero
        }
    }

    open var player: AVPlayer {
        if let player = mutableState.player {
            return player
        }

        let player = AVPlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        player.actionAtItemEnd = .pause
        mutableState.player = player
        return player
    }

    open lazy var playerView: VideoPlayerView = .init(frame: .zero)

    /// Return the av player layer for consumption by things such as Picture in Picture
    open func playerLayer() -> AVPlayerLayer? {
        playerView.playerLayer
    }

    /// Indicates the desired limit of network bandwidth consumption for this item.
    open nonisolated var preferredPeakBitRate: Double {
        get {
            mutableState.preferredPeakBitRate
        }
        set {
            mutableState.preferredPeakBitRate = newValue
            mutableState.playerItem?.preferredPeakBitRate = newValue
        }
    }

    /// Indicates a preferred upper limit on the resolution of the video to be downloaded.
    open nonisolated var preferredMaximumResolution: CGSize {
        get {
            mutableState.playerItem?.preferredMaximumResolution ?? CGSize.zero
        }
        set {
            mutableState.playerItem?.preferredMaximumResolution = newValue
            mutableState.itemMaximumResolution = newValue
        }
    }

    private let mutableState = MutableState()

    // MARK: - lifecycle
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        self.resetPlayerItem(nil)
        mutableState.player?.replaceCurrentItem(with: self.mutableState.playerItem)
        mutableState.player?.actionAtItemEnd = .pause

        self.removePlayerObservers()
        self.removeApplicationObservers()
        self.removePlayerLayerObservers()

        mutableState.player = nil

        #if DEBUG
        Logger.debug(group: Logger.fw.moduleName, "%@ deinit", NSStringFromClass(type(of: self)))
        #endif
    }

    override open func loadView() {
        super.loadView()
        playerView.frame = view.bounds
        view = playerView
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        playerView.player = player

        if let url {
            setup(url: url)
        } else if let asset {
            setupAsset(asset)
        }

        addPlayerLayerObservers()
        addPlayerObservers()
        addApplicationObservers()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if playbackState == .playing {
            pause()
        }
    }

    // MARK: - performance

    /// Total time spent playing.
    public var totalDurationWatched: TimeInterval {
        var totalDurationWatched = 0.0
        if let accessLog = mutableState.playerItem?.accessLog(), accessLog.events.isEmpty == false {
            for event in accessLog.events where event.durationWatched > 0 {
                totalDurationWatched += event.durationWatched
            }
        }
        return totalDurationWatched
    }

    /// Time weighted value of the variant indicated bitrate. Measure of overall stream quality.
    var timeWeightedIBR: Double {
        var timeWeightedIBR = 0.0
        let totalDurationWatched = totalDurationWatched

        if let accessLog = mutableState.playerItem?.accessLog(), totalDurationWatched > 0 {
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
        let totalHoursWatched = totalDurationWatched / 3600

        if let accessLog = mutableState.playerItem?.accessLog(), totalDurationWatched > 0 {
            for event in accessLog.events {
                totalNumberOfStalls += event.numberOfStalls
            }
        }
        return Double(totalNumberOfStalls) / totalHoursWatched
    }

    // MARK: - actions

    /// Begins playback of the media from the beginning.
    open func playFromBeginning() {
        playbackDelegate?.playerPlaybackWillStartFromBeginning?(self)
        player.seek(to: CMTime.zero)
        playFromCurrentTime()
    }

    /// Begins playback of the media from the current time.
    open func playFromCurrentTime() {
        if !autoplay {
            // External call to this method with autoplay disabled. Re-activate it before calling play.
            mutableState.hasAutoplayActivated = true
        }
        play()
    }

    fileprivate func play() {
        if autoplay || mutableState.hasAutoplayActivated {
            playbackState = .playing
            player.playImmediately(atRate: rate)
        }
    }

    /// Pauses playback of the media.
    open func pause() {
        if playbackState != .playing {
            return
        }

        player.pause()
        playbackState = .paused
    }

    /// Stops playback of the media.
    open func stop() {
        if playbackState == .stopped {
            return
        }

        player.pause()
        playbackState = .stopped
        playbackDelegate?.playerPlaybackDidEnd?(self)
    }

    /// Updates playback to the specified time.
    ///
    /// - Parameters:
    ///   - time: The time to switch to move the playback.
    ///   - completionHandler: Call block handler after seeking/
    open nonisolated func seek(to time: CMTime, completionHandler: (@Sendable (Bool) -> Void)? = nil) {
        if let playerItem = mutableState.playerItem {
            return playerItem.seek(to: time, completionHandler: completionHandler)
        } else {
            mutableState.seekTimeRequested = time
        }
    }

    /// Updates the playback time to the specified time bound.
    ///
    /// - Parameters:
    ///   - time: The time to switch to move the playback.
    ///   - toleranceBefore: The tolerance allowed before time.
    ///   - toleranceAfter: The tolerance allowed after time.
    ///   - completionHandler: call block handler after seeking
    open func seekToTime(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: (@Sendable (Bool) -> Void)? = nil) {
        if let playerItem = mutableState.playerItem {
            return playerItem.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
        }
    }

    /// Captures a snapshot of the current Player asset.
    ///
    /// - Parameter completionHandler: Returns a UIImage of the requested video frame. (Great for thumbnails!)
    open func takeSnapshot(completionHandler: (@MainActor @Sendable (_ image: UIImage?, _ error: Error?) -> Void)?) {
        guard let asset = mutableState.playerItem?.asset else {
            DispatchQueue.main.async {
                completionHandler?(nil, nil)
            }
            return
        }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let currentTime = mutableState.playerItem?.currentTime() ?? CMTime.zero

        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: currentTime)]) { _, image, _, result, error in
            guard let image else {
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
            case .failed, .cancelled:
                fallthrough
            @unknown default:
                DispatchQueue.main.async {
                    completionHandler?(nil, nil)
                }
            }
        }
    }

    // MARK: - loading

    fileprivate func setup(url: URL) {
        guard isViewLoaded else { return }

        // ensure everything is reset beforehand
        if playbackState == .playing {
            pause()
        }

        // Reset autoplay flag since a new url is set.
        mutableState.hasAutoplayActivated = false
        if autoplay {
            playbackState = .playing
        } else {
            playbackState = .stopped
        }

        setupPlayerItem(nil)

        asset = AVURLAsset(url: url, options: .none)
    }

    fileprivate func setupAsset(_ asset: AVAsset, loadableKeys: [String] = ["tracks", "playable", "duration"]) {
        guard isViewLoaded else { return }

        if playbackState == .playing {
            pause()
        }

        bufferingState = .unknown

        setupPlayerItem(nil)

        self.asset?.loadValuesAsynchronously(forKeys: loadableKeys, completionHandler: { () in
            guard let asset = self.mutableState.asset else { return }

            for key in loadableKeys {
                var error: NSError?
                let status = asset.statusOfValue(forKey: key, error: &error)
                if status == .failed {
                    self.playbackState = .failed
                    let failedError = error
                    DispatchQueue.fw.mainAsync {
                        self.playerDelegate?.player?(self, didFailWithError: failedError)
                    }
                    return
                }
            }

            if !asset.isPlayable {
                self.playbackState = .failed
                DispatchQueue.fw.mainAsync {
                    self.playerDelegate?.player?(self, didFailWithError: NSError(domain: "VideoPlayer", code: 0, userInfo: nil))
                }
                return
            }

            DispatchQueue.fw.mainAsync {
                guard let asset = self.asset else { return }

                let playerItem = AVPlayerItem(asset: asset)
                self.setupPlayerItem(playerItem)
            }
        })
    }

    fileprivate func setupPlayerItem(_ playerItem: AVPlayerItem?) {
        resetPlayerItem(playerItem)

        player.replaceCurrentItem(with: mutableState.playerItem)
        player.rate = rate

        // update new playerItem settings
        if playbackLoops {
            player.actionAtItemEnd = .none
        } else {
            player.actionAtItemEnd = .pause
        }
    }

    fileprivate nonisolated func resetPlayerItem(_ playerItem: AVPlayerItem?) {
        removePlayerItemObservers()

        if let currentPlayerItem = mutableState.playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentPlayerItem)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: currentPlayerItem)
        }

        mutableState.playerItem = playerItem

        mutableState.playerItem?.audioTimePitchAlgorithm = .spectral
        mutableState.playerItem?.preferredPeakBitRate = preferredPeakBitRate
        mutableState.playerItem?.preferredMaximumResolution = mutableState.itemMaximumResolution

        if let seek = mutableState.seekTimeRequested, mutableState.playerItem != nil {
            mutableState.seekTimeRequested = nil
            self.seek(to: seek)
        }

        if let updatedPlayerItem = mutableState.playerItem {
            addPlayerItemObservers()
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: updatedPlayerItem)
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlayToEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: updatedPlayerItem)
        }
    }

    // MARK: - UIApplication

    func addApplicationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    nonisolated func removeApplicationObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - AVPlayerItem handlers

    @objc func playerItemDidPlayToEndTime(_ aNotification: Notification) {
        DispatchQueue.fw.mainAsync {
            if self.playbackLoops {
                self.playbackDelegate?.playerPlaybackWillLoop?(self)
                self.player.seek(to: CMTime.zero)
                self.player.play()
                self.player.rate = self.rate
                self.playbackDelegate?.playerPlaybackDidLoop?(self)
            } else if self.playbackFreezesAtEnd {
                self.stop()
            } else {
                self.player.seek(to: CMTime.zero, completionHandler: { [weak self] _ in
                    DispatchQueue.fw.mainAsync { [weak self] in
                        self?.stop()
                    }
                })
            }
        }
    }

    @objc func playerItemFailedToPlayToEndTime(_ aNotification: Notification) {
        playbackState = .failed
    }

    // MARK: - UIApplication handlers

    @objc func handleApplicationWillResignActive(_ aNotification: Notification) {
        if playbackState == .playing && playbackPausesWhenResigningActive {
            pause()
        }
    }

    @objc func handleApplicationDidBecomeActive(_ aNotification: Notification) {
        if playbackState == .paused && playbackResumesWhenBecameActive {
            play()
        }
    }

    @objc func handleApplicationDidEnterBackground(_ aNotification: Notification) {
        if playbackState == .playing && playbackPausesWhenBackgrounded {
            pause()
        }
    }

    @objc func handleApplicationWillEnterForeground(_ aNoticiation: Notification) {
        if playbackState != .playing && playbackResumesWhenEnteringForeground {
            play()
        }
    }

    // MARK: - AVPlayerItemObservers

    nonisolated func addPlayerItemObservers() {
        guard let playerItem = mutableState.playerItem else {
            return
        }

        mutableState.playerItemObservers.append(playerItem.observe(\.isPlaybackBufferEmpty, options: [.new, .old]) { [weak self] object, _ in
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

        mutableState.playerItemObservers.append(playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .old]) { [weak self] object, _ in
            guard let self else { return }

            if object.isPlaybackLikelyToKeepUp {
                bufferingState = .ready
                if playbackState == .playing {
                    DispatchQueue.fw.mainAsync {
                        self.playFromCurrentTime()
                    }
                }
            }

            switch object.status {
            case .failed:
                playbackState = VideoPlayerPlaybackState.failed
            default:
                break
            }
        })

        mutableState.playerItemObservers.append(playerItem.observe(\.loadedTimeRanges, options: [.new, .old]) { [weak self] object, _ in
            guard let self else { return }

            let timeRanges = object.loadedTimeRanges
            if let timeRange = timeRanges.first?.timeRangeValue {
                let bufferedTime = CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration))
                if mutableState.lastBufferTime != bufferedTime {
                    mutableState.lastBufferTime = bufferedTime
                    DispatchQueue.fw.mainAsync {
                        self.playerDelegate?.playerBufferTimeDidChange?(bufferedTime)
                    }
                }
            }

            let currentTime = CMTimeGetSeconds(object.currentTime())
            let passedTime = mutableState.lastBufferTime <= 0 ? currentTime : (mutableState.lastBufferTime - currentTime)

            if (passedTime >= bufferSizeInSeconds ||
                mutableState.lastBufferTime == maximumDuration ||
                timeRanges.first == nil) &&
                playbackState == .playing {
                DispatchQueue.fw.mainAsync {
                    self.play()
                }
            }
        })
    }

    nonisolated func removePlayerItemObservers() {
        for observer in mutableState.playerItemObservers {
            observer.invalidate()
        }
        mutableState.playerItemObservers.removeAll()
    }

    // MARK: - AVPlayerLayerObservers

    func addPlayerLayerObservers() {
        mutableState.playerLayerObserver = playerView.playerLayer.observe(\.isReadyForDisplay, options: [.new, .old]) { [weak self] _, _ in
            DispatchQueue.fw.mainAsync { [weak self] in
                if let strongSelf = self {
                    strongSelf.playerDelegate?.playerReady?(strongSelf)
                }
            }
        }
    }

    nonisolated func removePlayerLayerObservers() {
        playbackDelegate = nil
        mutableState.playerLayerObserver?.invalidate()
        mutableState.playerLayerObserver = nil
    }

    // MARK: - AVPlayerObservers

    func addPlayerObservers() {
        mutableState.playerTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 100), queue: DispatchQueue.main, using: { [weak self] _ in
            guard let self else { return }
            DispatchQueue.fw.mainAsync {
                self.playbackDelegate?.playerCurrentTimeDidChange?(self)
            }
        })

        mutableState.playerObservers.append(player.observe(\.timeControlStatus, options: [.new, .old]) { [weak self] object, _ in
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

    nonisolated func removePlayerObservers() {
        if let observer = mutableState.playerTimeObserver {
            mutableState.player?.removeTimeObserver(observer)
        }
        for observer in mutableState.playerObservers {
            observer.invalidate()
        }
        mutableState.playerObservers.removeAll()
        playerDelegate = nil
    }
}

// MARK: - VideoPlayerView
open class VideoPlayerView: UIView {
    override open class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    open var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    open var player: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player = newValue
            playerLayer.isHidden = (playerLayer.player == nil)
        }
    }

    open var playerBackgroundColor: UIColor? {
        get {
            if let cgColor = playerLayer.backgroundColor {
                return UIColor(cgColor: cgColor)
            }
            return nil
        }
        set {
            playerLayer.backgroundColor = newValue?.cgColor
        }
    }

    open var playerFillMode: AVLayerVideoGravity {
        get {
            playerLayer.videoGravity
        }
        set {
            playerLayer.videoGravity = newValue
        }
    }

    open var isReadyForDisplay: Bool {
        playerLayer.isReadyForDisplay
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.isHidden = true
        self.playerFillMode = .resizeAspect
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        playerLayer.isHidden = true
        self.playerFillMode = .resizeAspect
    }
}
