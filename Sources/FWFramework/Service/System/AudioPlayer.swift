//
//  AudioPlayer.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
import AVFoundation

/// 音频播放器事件代理
@MainActor @objc public protocol AudioPlayerDelegate {
    @objc optional func audioPlayerWillChanged(at index: Int)
    @objc optional func audioPlayerCurrentItemChanged(_ item: AVPlayerItem)
    @objc optional func audioPlayerCurrentItemEvicted(_ item: AVPlayerItem)
    @objc optional func audioPlayerRateChanged(_ isPlaying: Bool)
    @objc optional func audioPlayerDidReachEnd()
    @objc optional func audioPlayerCurrentTimeChanged(_ time: CMTime)
    @objc optional func audioPlayerCurrentItemPreloaded(_ time: CMTime)
    @objc optional func audioPlayerDidFailed(_ item: AVPlayerItem?, error: Error?)
    @objc optional func audioPlayerReadyToPlay(_ item: AVPlayerItem?)
    @objc optional func audioPlayerItemFailedToPlayEndTime(_ item: AVPlayerItem, error: Error?)
    @objc optional func audioPlayerItemPlaybackStall(_ item: AVPlayerItem)
}

/// 音频播放器数据源
@objc public protocol AudioPlayerDataSource {
    @objc optional func audioPlayerNumberOfItems() -> Int
    /// 音频源URL，支持String|URL|AVURLAsset|AVPlayerItem等
    @objc optional func audioPlayerURLForItem(at index: Int, preBuffer: Bool) -> Any?
    @objc optional func audioPlayerLoadItem(at index: Int, preBuffer: Bool)
}

public enum AudioPlayerStatus: Int, Sendable {
    case playing = 0
    case forcePause
    case buffering
    case unknown
}

public enum AudioPlayerRepeatMode: Int, Sendable {
    case on = 0
    case once
    case off
}

public enum AudioPlayerShuffleMode: Int, Sendable {
    case on = 0
    case off
}

fileprivate enum AudioPlayerPauseReason: Int, Sendable {
    case none = 0
    case forced
    case buffering
}

/// 音频播放器
///
/// [HysteriaPlayer](https://github.com/StreetVoice/HysteriaPlayer)
open class AudioPlayer: NSObject, @unchecked Sendable {
    
    public static let shared = AudioPlayer()
    
    open weak var delegate: AudioPlayerDelegate?
    open weak var dataSource: AudioPlayerDataSource?
    open var itemsCount: Int = 0
    open var itemURLs: [Any]?
    open var disableLogs: Bool = {
        #if DEBUG
        false
        #else
        true
        #endif
    }()
    @MainActor open var audioPlayer: AVQueuePlayer {
        if let player = _audioPlayer {
            return player
        }
        
        let player = AVQueuePlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        _audioPlayer = player
        return player
    }
    private var _audioPlayer: AVQueuePlayer?
    open private(set) var playerItems: [AVPlayerItem]? = []
    
    @MainActor open var repeatMode: AudioPlayerRepeatMode = .off
    @MainActor open var shuffleMode: AudioPlayerShuffleMode = .off {
        didSet {
            playedItems.removeAll()
            if shuffleMode == .on {
                if let index = getAudioIndex(audioPlayer.currentItem) {
                    playedItems.insert(index)
                }
            }
        }
    }
    open var isMemoryCached: Bool {
        get {
            return playerItems != nil
        }
        set {
            if playerItems == nil && newValue {
                playerItems = []
            } else if playerItems != nil && !newValue {
                playerItems = nil
            }
        }
    }
    
    @MainActor open var isPlaying: Bool {
        return audioPlayer.rate != 0
    }
    open private(set) var lastItemIndex: Int = 0
    @MainActor open var currentItem: AVPlayerItem? {
        return audioPlayer.currentItem
    }
    @MainActor open var playerStatus: AudioPlayerStatus {
        if isPlaying {
            return .playing
        } else {
            switch pauseReason {
            case .forced:
                return .forcePause
            case .buffering:
                return .buffering
            default:
                return .unknown
            }
        }
    }
    
    @MainActor open var playingItemCurrentTime: Float {
        let currentTime = audioPlayer.currentItem?.currentTime()
        guard let currentTime = currentTime, currentTime.isValid else { return 0 }
        let current = currentTime.seconds
        return current.isFinite ? Float(current) : 0
    }
    @MainActor open var playingItemDurationTime: Float {
        let durationTime = playerItemDuration()
        guard durationTime.isValid else { return 0 }
        let duration = durationTime.seconds
        return duration.isFinite ? Float(duration) : 0
    }
    open var observePeriodicTime: Bool = false {
        didSet {
            guard observePeriodicTime != oldValue else { return }
            if !observePeriodicTime, let token = periodicTimeToken {
                removeTimeObserver(token)
                periodicTimeToken = nil
            }
        }
    }
    
    private var pauseReason: AudioPlayerPauseReason = .none
    private var playedItems: Set<Int> = .init()
    private var periodicTimeToken: Any?
    
    private var routeChangedWhilePlaying = false
    private var interruptedWhilePlaying = false
    private var isPreBuffered = false
    private var tookAudioFocus = false
    private var prepareingItemHash: Int = 0
    private var audioQueue = DispatchQueue(label: "site.wuyong.queue.audioplayer")
    
    public override init() {
        super.init()
    }
    
    deinit {
        if tookAudioFocus {
            destroyPlayer()
        }
        
        #if DEBUG
        Logger.debug(group: Logger.fw.moduleName, "%@ deinit", NSStringFromClass(type(of: self)))
        #endif
    }
    
    open func setupPlayerItem(url: Any, index: Int) {
        var playerItem: AVPlayerItem?
        if let item = url as? AVPlayerItem {
            playerItem = item
        } else if let urlAsset = url as? AVURLAsset {
            playerItem = AVPlayerItem(asset: urlAsset)
        } else if let urlValue = url as? URL {
            playerItem = AVPlayerItem(url: urlValue)
        } else if let urlParameter = url as? URLParameter {
            playerItem = AVPlayerItem(url: urlParameter.urlValue)
        }
        guard let playerItem = playerItem else { return }
        
        setupPlayerItem(playerItem: playerItem, index: index)
    }
    
    @MainActor open func playItem(from startIndex: Int) {
        willPlayPlayerItem(at: startIndex)
        audioPlayer.pause()
        audioPlayer.removeAllItems()
        let foundSource = findSourceInPlayerItems(startIndex, play: true)
        if !foundSource {
            getSourceURL(at: startIndex, preBuffer: false)
        }
    }
    
    open func removeAllItems() {
        _audioPlayer?.items().forEach({ item in
            item.seek(to: .zero, completionHandler: nil)
            unobservePlayerItem(item)
        })
        
        playerItems = isMemoryCached ? [] : nil
        _audioPlayer?.removeAllItems()
    }
    
    open func removeQueueItems() {
        if let audioPlayer = _audioPlayer {
            while audioPlayer.items().count > 1 {
                audioPlayer.remove(audioPlayer.items()[1])
            }
        }
    }
    
    open func getAudioIndex(_ item: AVPlayerItem?) -> Int? {
        guard let item = item else { return nil }
        let number = item.fw.propertyNumber(forName: "audioIndex")
        return number?.intValue
    }
    
    open func removeItem(at index: Int) {
        if isMemoryCached {
            let items = self.playerItems ?? []
            for item in items {
                let checkIndex = getAudioIndex(item)
                if checkIndex == index {
                    var playerItems = self.playerItems ?? []
                    playerItems.removeAll { $0 == item }
                    self.playerItems = playerItems
                    
                    if let audioPlayer = _audioPlayer {
                        if audioPlayer.items().firstIndex(of: item) != nil {
                            audioPlayer.remove(item)
                        }
                    }
                } else if let checkIndex = checkIndex, checkIndex > index {
                    setAudioIndex(item, index: checkIndex - 1)
                }
            }
        } else {
            if let audioPlayer = _audioPlayer {
                for item in audioPlayer.items() {
                    let checkIndex = getAudioIndex(item)
                    if checkIndex == index {
                        audioPlayer.remove(item)
                    } else if let checkIndex = checkIndex, checkIndex > index {
                        setAudioIndex(item, index: checkIndex - 1)
                    }
                }
            }
        }
    }
    
    @MainActor open func moveItem(from: Int, to: Int) {
        playerItems?.forEach({ item in
            resetItemIndex(item, from: from, to: to)
        })
        
        audioPlayer.items().forEach({ item in
            if resetItemIndex(item, from: from, to: to) {
                removeQueueItems()
            }
        })
    }
    
    @MainActor open func play() {
        pauseReason = .none
        audioPlayer.play()
    }
    
    @MainActor open func pause() {
        pauseReason = .forced
        audioPlayer.pause()
    }
    
    @MainActor open func playPrevious() {
        let nowIndex = getAudioIndex(audioPlayer.currentItem) ?? 0
        if nowIndex == 0 {
            if repeatMode == .on {
                playItem(from: audioPlayerItemsCount() - 1)
            } else {
                pause()
                audioPlayer.currentItem?.seek(to: .zero, completionHandler: { [weak self] _ in
                    self?.play()
                })
            }
        } else {
            playItem(from: nowIndex - 1)
        }
    }
    
    @MainActor open func playNext() {
        if shuffleMode == .on {
            if let nextIndex = randomIndex() {
                playItem(from: nextIndex)
            } else {
                pauseReason = .forced
                delegate?.audioPlayerDidReachEnd?()
            }
        } else {
            let nowIndex = getAudioIndex(audioPlayer.currentItem) ?? lastItemIndex
            if nowIndex + 1 < audioPlayerItemsCount() {
                if audioPlayer.items().count > 1 {
                    willPlayPlayerItem(at: nowIndex + 1)
                    audioPlayer.advanceToNextItem()
                } else {
                    playItem(from: nowIndex + 1)
                }
            } else {
                if repeatMode == .off {
                    pauseReason = .forced
                    delegate?.audioPlayerDidReachEnd?()
                } else {
                    playItem(from: 0)
                }
            }
        }
    }
    
    @MainActor open func seek(to seconds: Double, completionHandler: (@Sendable (Bool) -> Void)? = nil) {
        if let completionHandler = completionHandler {
            audioPlayer.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: Int32(NSEC_PER_SEC)), completionHandler: completionHandler)
        } else {
            audioPlayer.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: Int32(NSEC_PER_SEC)))
        }
    }
    
    @MainActor open func addBoundaryTimeObserver(for times: [NSValue], queue: DispatchQueue?, using block: @escaping @Sendable () -> Void) -> Any {
        let observer = audioPlayer.addBoundaryTimeObserver(forTimes: times, queue: queue, using: block)
        return observer
    }
    
    @MainActor open func addPeriodicTimeObserver(for interval: CMTime, queue: DispatchQueue?, using block: @escaping @Sendable (CMTime) -> Void) -> Any {
        let observer = audioPlayer.addPeriodicTimeObserver(forInterval: interval, queue: queue, using: block)
        return observer
    }
    
    open func removeTimeObserver(_ observer: Any) {
        _audioPlayer?.removeTimeObserver(observer)
    }
    
    open func destroyPlayer() {
        tookAudioFocus = false
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            if !disableLogs {
                Logger.debug(group: Logger.fw.moduleName, "AudioPlayer: set active error: %@", error.localizedDescription)
            }
        }
        DispatchQueue.fw.mainSyncIf {
            UIApplication.shared.endReceivingRemoteControlEvents()
        }
        NotificationCenter.default.removeObserver(self)
        
        if let token = periodicTimeToken {
            removeTimeObserver(token)
            periodicTimeToken = nil
        }
        
        _audioPlayer?.removeObserver(self, forKeyPath: "status", context: nil)
        _audioPlayer?.removeObserver(self, forKeyPath: "rate", context: nil)
        _audioPlayer?.removeObserver(self, forKeyPath: "currentItem", context: nil)
        
        removeAllItems()
        
        DispatchQueue.fw.mainSyncIf {
            _audioPlayer?.pause()
        }
        delegate = nil
        dataSource = nil
    }
    
    @MainActor open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as? AVPlayer == self.audioPlayer, keyPath == "status" {
            if audioPlayer.status == .readyToPlay {
                if observePeriodicTime && periodicTimeToken == nil {
                    periodicTimeToken = addPeriodicTimeObserver(for: CMTimeMakeWithSeconds(1.0, preferredTimescale: Int32(NSEC_PER_SEC)), queue: .main, using: { [weak self] time in
                        DispatchQueue.fw.mainAsync { [weak self] in
                            self?.delegate?.audioPlayerCurrentTimeChanged?(time)
                        }
                    })
                }
                delegate?.audioPlayerReadyToPlay?(nil)
                if !isPlaying {
                    audioPlayer.play()
                }
            } else if audioPlayer.status == .failed {
                if !disableLogs {
                    Logger.debug(group: Logger.fw.moduleName, "AudioPlayer: %@", audioPlayer.error?.localizedDescription ?? "")
                }
                
                delegate?.audioPlayerDidFailed?(nil, error: audioPlayer.error)
            }
        }
        
        if object as? AVPlayer == self.audioPlayer, keyPath == "rate" {
            delegate?.audioPlayerRateChanged?(isPlaying)
        }
        
        if object as? AVPlayer == self.audioPlayer, keyPath == "currentItem" {
            let newPlayerItem = change?[.newKey] as? AVPlayerItem
            let lastPlayerItem = change?[.oldKey] as? AVPlayerItem
            if let lastPlayerItem = lastPlayerItem {
                unobservePlayerItem(lastPlayerItem)
                
                delegate?.audioPlayerCurrentItemEvicted?(lastPlayerItem)
            }
            if let newPlayerItem = newPlayerItem {
                observePlayerItem(newPlayerItem)
                
                delegate?.audioPlayerCurrentItemChanged?(newPlayerItem)
            }
        }
        
        if object as? AVPlayerItem == audioPlayer.currentItem, let item = audioPlayer.currentItem, keyPath == "status" {
            isPreBuffered = false
            if item.status == .failed {
                delegate?.audioPlayerDidFailed?(item, error: item.error)
            } else if item.status == .readyToPlay {
                delegate?.audioPlayerReadyToPlay?(item)
                if !isPlaying && pauseReason != .forced {
                    audioPlayer.play()
                }
            }
        }
        
        if audioPlayer.items().count > 1, object as? AVPlayerItem == audioPlayer.items()[1], keyPath == "loadedTimeRanges" {
            isPreBuffered = true
        }
        
        if object as? AVPlayerItem == audioPlayer.currentItem, let item = audioPlayer.currentItem, keyPath == "loadedTimeRanges" {
            if item.hash != prepareingItemHash {
                prepareNextPlayerItem()
                prepareingItemHash = item.hash
            }
            
            let timeRanges = change?[.newKey] as? [NSValue] ?? []
            if timeRanges.count > 0 {
                let timeRange = timeRanges[0].timeRangeValue
                delegate?.audioPlayerCurrentItemPreloaded?(CMTimeAdd(timeRange.start, timeRange.duration))
                
                if audioPlayer.rate == 0 && pauseReason != .forced {
                    pauseReason = .buffering
                    
                    let bufferdTime = CMTimeAdd(timeRange.start, timeRange.duration)
                    let milestone = CMTimeAdd(audioPlayer.currentTime(), CMTimeMakeWithSeconds(5.0, preferredTimescale: timeRange.duration.timescale))
                    
                    if bufferdTime > milestone && audioPlayer.currentItem?.status == .readyToPlay && !interruptedWhilePlaying && !routeChangedWhilePlaying {
                        if !isPlaying {
                            if !disableLogs {
                                Logger.debug(group: Logger.fw.moduleName, "AudioPlayer: resume from buffering..")
                            }
                            play()
                        }
                    }
                }
            }
        }
    }
    
    @MainActor private func preAction() {
        tookAudioFocus = true
        
        backgroundPlayable()
        audioSessionNotification()
    }
    
    @MainActor private func backgroundPlayable() {
        let audioSession = AVAudioSession.sharedInstance()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        if audioSession.category != .playback {
            if UIDevice.current.isMultitaskingSupported {
                do {
                    try audioSession.setCategory(.playback)
                } catch {
                    if !disableLogs {
                        Logger.debug(group: Logger.fw.moduleName, "AudioPlayer: set category error: %@", error.localizedDescription)
                    }
                }
                
                do {
                    try audioSession.setActive(true)
                } catch {
                    if !disableLogs {
                        Logger.debug(group: Logger.fw.moduleName, "AudioPlayer: set active error: %@", error.localizedDescription)
                    }
                }
            }
        } else {
            if !disableLogs {
                Logger.debug(group: Logger.fw.moduleName, "AudioPlayer: unable to register background playback")
            }
        }
    }
    
    private func setAudioIndex(_ item: AVPlayerItem, index: Int) {
        item.fw.setPropertyNumber(NSNumber(value: index), forName: "audioIndex")
    }
    
    @MainActor private func willPlayPlayerItem(at index: Int) {
        if !tookAudioFocus {
            preAction()
        }
        lastItemIndex = index
        playedItems.insert(index)
        
        delegate?.audioPlayerWillChanged?(at: lastItemIndex)
    }
    
    private func audioPlayerItemsCount() -> Int {
        if let count = dataSource?.audioPlayerNumberOfItems?() {
            return count
        }
        if itemsCount > 0 {
            return itemsCount
        }
        return itemURLs?.count ?? 0
    }
    
    private func getSourceURL(at index: Int, preBuffer: Bool) {
        if let url = dataSource?.audioPlayerURLForItem?(at: index, preBuffer: preBuffer) {
            let sendableUrl = SendableObject(url)
            audioQueue.async { [weak self] in
                self?.setupPlayerItem(url: sendableUrl.object, index: index)
            }
        } else if dataSource?.audioPlayerLoadItem?(at: index, preBuffer: preBuffer) != nil {
        } else {
            if let itemURLs = itemURLs, index < itemURLs.count {
                let sendableUrl = SendableObject(itemURLs[index])
                audioQueue.async { [weak self] in
                    self?.setupPlayerItem(url: sendableUrl.object, index: index)
                }
            }
        }
    }
    
    private func setupPlayerItem(playerItem: AVPlayerItem, index: Int) {
        DispatchQueue.main.async {
            self.setAudioIndex(playerItem, index: index)
            if self.isMemoryCached {
                var playerItems = self.playerItems ?? []
                playerItems.append(playerItem)
                self.playerItems = playerItems
            }
            self.insertPlayerItem(playerItem)
        }
    }
    
    @MainActor private func findSourceInPlayerItems(_ index: Int, play: Bool = false) -> Bool {
        for item in (playerItems ?? []) {
            if let checkIndex = getAudioIndex(item), checkIndex == index {
                if item.status == .readyToPlay {
                    item.seek(to: .zero) { [weak self] _ in
                        self?.insertPlayerItem(item, play: play)
                    }
                    return true
                }
            }
        }
        return false
    }
    
    @MainActor private func prepareNextPlayerItem() {
        if shuffleMode == .on || repeatMode == .once { return }
        
        let nowIndex = lastItemIndex
        var findInPlayerItems = false
        let itemsCount = audioPlayerItemsCount()
        
        if nowIndex + 1 < itemsCount {
            findInPlayerItems = findSourceInPlayerItems(nowIndex + 1)
            if !findInPlayerItems {
                getSourceURL(at: nowIndex + 1, preBuffer: true)
            }
        }
    }
    
    @MainActor private func insertPlayerItem(_ item: AVPlayerItem, play: Bool = false) {
        if audioPlayer.items().count > 1 {
            removeQueueItems()
        }
        if audioPlayer.canInsert(item, after: nil) {
            audioPlayer.insert(item, after: nil)
            
            if play && item.status == .readyToPlay {
                audioPlayer.play()
            }
        }
    }
    
    @discardableResult
    private func resetItemIndex(_ item: AVPlayerItem, from sourceIndex: Int, to destinationIndex: Int) -> Bool {
        guard let checkIndex = getAudioIndex(item) else { return false }
        var replaceIndex: Int?
        if checkIndex == sourceIndex {
            replaceIndex = destinationIndex
        } else if checkIndex == destinationIndex {
            replaceIndex = sourceIndex > checkIndex ? checkIndex + 1 : checkIndex - 1
        } else if checkIndex > destinationIndex && checkIndex < sourceIndex {
            replaceIndex = checkIndex + 1
        } else if checkIndex < destinationIndex && checkIndex > sourceIndex {
            replaceIndex = checkIndex - 1
        }
        
        if let replaceIndex = replaceIndex {
            setAudioIndex(item, index: replaceIndex)
            if lastItemIndex == checkIndex {
                lastItemIndex = replaceIndex
            }
            return true
        }
        return false
    }
    
    @MainActor private func playerItemDuration() -> CMTime {
        var error: NSError?
        if audioPlayer.currentItem?.asset.statusOfValue(forKey: "duration", error: &error) == .loaded {
            let playerItem = audioPlayer.currentItem
            let loadedRanges = playerItem?.seekableTimeRanges ?? []
            if loadedRanges.count > 0 {
                let range = loadedRanges[0].timeRangeValue
                return range.duration
            } else {
                return .invalid
            }
        } else {
            return .invalid
        }
    }
    
    @MainActor private func audioSessionNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlayEndTime(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemPlaybackStall(_:)), name: .AVPlayerItemPlaybackStalled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(interruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(routeChanged(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        
        audioPlayer.addObserver(self, forKeyPath: "status", options: [.initial, .new], context: nil)
        audioPlayer.addObserver(self, forKeyPath: "rate", options: [], context: nil)
        audioPlayer.addObserver(self, forKeyPath: "currentItem", options: [.initial, .new, .old], context: nil)
    }
    
    private func observePlayerItem(_ item: AVPlayerItem) {
        guard !item.fw.propertyBool(forName: "observePlayerItem") else { return }
        item.fw.setPropertyBool(true, forName: "observePlayerItem")
        
        item.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
    }
    
    private func unobservePlayerItem(_ item: AVPlayerItem) {
        guard item.fw.propertyBool(forName: "observePlayerItem") else { return }
        item.fw.setPropertyBool(false, forName: "observePlayerItem")
        
        item.removeObserver(self, forKeyPath: "loadedTimeRanges", context: nil)
        item.removeObserver(self, forKeyPath: "status", context: nil)
    }
    
    @MainActor @objc private func interruption(_ notification: Notification) {
        guard let interruptionValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionValue) else {
            return
        }
        
        if interruptionType == .began && pauseReason != .forced {
            interruptedWhilePlaying = true
            pause()
        } else if interruptionType == .ended && interruptedWhilePlaying {
            interruptedWhilePlaying = false
            play()
        }
        if !disableLogs {
            Logger.debug(group: Logger.fw.moduleName, "AudioPlayer: interruption: %@", interruptionType == .began ? "began" : "ended")
        }
    }
    
    @MainActor @objc private func routeChanged(_ notification: Notification) {
        guard let routeChangeValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let routeChangeReason = AVAudioSession.RouteChangeReason(rawValue: routeChangeValue) else {
            return
        }
        
        if routeChangeReason == .oldDeviceUnavailable && pauseReason != .forced {
            routeChangedWhilePlaying = true
            pause()
        } else if routeChangeReason == .newDeviceAvailable && routeChangedWhilePlaying {
            routeChangedWhilePlaying = false
            play()
        }
        if !disableLogs {
            Logger.debug(group: Logger.fw.moduleName, "AudioPlayer: routeChanged: %@", routeChangeReason == .newDeviceAvailable ? "New Device Available" : "Old Device Unavailable")
        }
    }
    
    @MainActor @objc private func playerItemDidReachEnd(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == audioPlayer.currentItem else {
            return
        }
        
        guard let currentIndex = getAudioIndex(audioPlayer.currentItem) else {
            return
        }
        
        if repeatMode == .once {
            playItem(from: currentIndex)
        } else if shuffleMode == .on {
            if let nextIndex = randomIndex() {
                playItem(from: nextIndex)
            } else {
                pause()
                delegate?.audioPlayerDidReachEnd?()
            }
        } else {
            if audioPlayer.items().count == 1 || !isPreBuffered {
                if currentIndex + 1 < audioPlayerItemsCount() {
                    playNext()
                } else {
                    if repeatMode == .off {
                        pause()
                        delegate?.audioPlayerDidReachEnd?()
                    } else {
                        playItem(from: 0)
                    }
                }
            }
        }
    }
    
    @MainActor @objc private func playerItemFailedToPlayEndTime(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == audioPlayer.currentItem else {
            return
        }
        
        let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
        delegate?.audioPlayerItemFailedToPlayEndTime?(item, error: error)
    }
    
    @MainActor @objc private func playerItemPlaybackStall(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == audioPlayer.currentItem else {
            return
        }
        
        delegate?.audioPlayerItemPlaybackStall?(item)
    }
    
    @MainActor private func randomIndex() -> Int? {
        let itemsCount = audioPlayerItemsCount()
        if playedItems.count == itemsCount {
            playedItems = []
            if repeatMode == .off {
                return nil
            }
        }
        
        var index: Int = 0
        repeat {
            index = Int(arc4random()) % itemsCount
        } while playedItems.contains(index)
        
        return index
    }
    
}
