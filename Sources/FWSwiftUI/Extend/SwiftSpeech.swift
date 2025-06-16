//
//  SwiftSpeech.swift
//  FWFramework
//
//  Created by wuyong on 2025/6/13.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine
import Speech

/// [SwiftSpeech](https://github.com/Cay-Zhang/SwiftSpeech)
public struct SwiftSpeech {
    public struct ViewModifiers { }
    public struct Demos { }
    internal struct EnvironmentKeys { }
    
    public static var defaultAnimation: Animation = .interactiveSpring()
}

extension SwiftSpeech {
    public static func requestSpeechRecognitionAuthorization() {
        AuthorizationCenter.shared.requestSpeechRecognitionAuthorization()
    }
    
    class AuthorizationCenter: ObservableObject {
        @Published var speechRecognitionAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = SFSpeechRecognizer.authorizationStatus()
        
        func requestSpeechRecognitionAuthorization() {
            SFSpeechRecognizer.requestAuthorization { authStatus in
                if self.speechRecognitionAuthorizationStatus != authStatus {
                    DispatchQueue.main.async {
                        self.speechRecognitionAuthorizationStatus = authStatus
                    }
                }
            }
        }
        
        static let shared = AuthorizationCenter()
    }
}

@propertyWrapper public struct SpeechRecognitionAuthStatus: DynamicProperty {
    @ObservedObject var authCenter = SwiftSpeech.AuthorizationCenter.shared
    
    let trueValues: Set<SFSpeechRecognizerAuthorizationStatus>
    
    public var wrappedValue: SFSpeechRecognizerAuthorizationStatus {
        SwiftSpeech.AuthorizationCenter.shared.speechRecognitionAuthorizationStatus
    }
    
    public init(trueValues: Set<SFSpeechRecognizerAuthorizationStatus> = [.authorized]) {
        self.trueValues = trueValues
    }
    
    public var projectedValue: Bool {
        self.trueValues.contains(SwiftSpeech.AuthorizationCenter.shared.speechRecognitionAuthorizationStatus)
    }
}

extension SwiftSpeech.EnvironmentKeys {
    struct SwiftSpeechState: EnvironmentKey {
        static let defaultValue: SwiftSpeech.State = .pending
    }
    
    struct ActionsOnStartRecording: EnvironmentKey {
        static let defaultValue: [(_ session: SwiftSpeech.Session) -> Void] = []
    }
    
    struct ActionsOnStopRecording: EnvironmentKey {
        static let defaultValue: [(_ session: SwiftSpeech.Session) -> Void] = []
    }
    
    struct ActionsOnCancelRecording: EnvironmentKey {
        static let defaultValue: [(_ session: SwiftSpeech.Session) -> Void] = []
    }
}

public extension EnvironmentValues {
    var swiftSpeechState: SwiftSpeech.State {
        get { self[SwiftSpeech.EnvironmentKeys.SwiftSpeechState.self] }
        set { self[SwiftSpeech.EnvironmentKeys.SwiftSpeechState.self] = newValue }
    }
    
    var actionsOnStartRecording: [(_ session: SwiftSpeech.Session) -> Void] {
        get { self[SwiftSpeech.EnvironmentKeys.ActionsOnStartRecording.self] }
        set { self[SwiftSpeech.EnvironmentKeys.ActionsOnStartRecording.self] = newValue }
    }
    
    var actionsOnStopRecording: [(_ session: SwiftSpeech.Session) -> Void] {
        get { self[SwiftSpeech.EnvironmentKeys.ActionsOnStopRecording.self] }
        set { self[SwiftSpeech.EnvironmentKeys.ActionsOnStopRecording.self] = newValue }
    }
    
    var actionsOnCancelRecording: [(_ session: SwiftSpeech.Session) -> Void] {
        get { self[SwiftSpeech.EnvironmentKeys.ActionsOnCancelRecording.self] }
        set { self[SwiftSpeech.EnvironmentKeys.ActionsOnCancelRecording.self] = newValue }
    }
}

public extension View {
    func onStartRecording(appendAction actionToAppend: @escaping (_ session: SwiftSpeech.Session) -> Void) ->
    ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(_ session: SwiftSpeech.Session) -> Void]>> {
        self.transformEnvironment(\.actionsOnStartRecording) { actions in
            actions.insert(actionToAppend, at: 0)
        } as! ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>>
    }
    
    func onStopRecording(appendAction actionToAppend: @escaping (_ session: SwiftSpeech.Session) -> Void) ->
    ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(_ session: SwiftSpeech.Session) -> Void]>> {
        self.transformEnvironment(\.actionsOnStopRecording) { actions in
            actions.insert(actionToAppend, at: 0)
        } as! ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>>
    }
    
    func onCancelRecording(appendAction actionToAppend: @escaping (_ session: SwiftSpeech.Session) -> Void) ->
    ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(_ session: SwiftSpeech.Session) -> Void]>> {
        self.transformEnvironment(\.actionsOnCancelRecording) { actions in
            actions.insert(actionToAppend, at: 0)
        } as! ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>>
    }
}

public extension View {
    func onStartRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session {
        self.onStartRecording { session in
            subject.send(session)
        }
    }
    
    func onStartRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session? {
        self.onStartRecording { session in
            subject.send(session)
        }
    }
    
    func onStopRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session {
        self.onStopRecording { session in
            subject.send(session)
        }
    }
    
    func onStopRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session? {
        self.onStopRecording { session in
            subject.send(session)
        }
    }
    
    func onCancelRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session {
        self.onCancelRecording { session in
            subject.send(session)
        }
    }
    
    func onCancelRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session? {
        self.onCancelRecording { session in
            subject.send(session)
        }
    }
}

public extension View {
    func swiftSpeechRecordOnHold(
        sessionConfiguration: SwiftSpeech.Session.Configuration = SwiftSpeech.Session.Configuration(),
        animation: Animation = SwiftSpeech.defaultAnimation,
        distanceToCancel: CGFloat = 50.0
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.RecordOnHold> {
        self.modifier(
            SwiftSpeech.ViewModifiers.RecordOnHold(
                sessionConfiguration: sessionConfiguration,
                animation: animation,
                distanceToCancel: distanceToCancel
            )
        )
    }
    
    func swiftSpeechRecordOnHold(
        locale: Locale,
        animation: Animation = SwiftSpeech.defaultAnimation,
        distanceToCancel: CGFloat = 50.0
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.RecordOnHold> {
        self.swiftSpeechRecordOnHold(sessionConfiguration: SwiftSpeech.Session.Configuration(locale: locale), animation: animation, distanceToCancel: distanceToCancel)
    }
    
    func swiftSpeechToggleRecordingOnTap(
        sessionConfiguration: SwiftSpeech.Session.Configuration = SwiftSpeech.Session.Configuration(),
        animation: Animation = SwiftSpeech.defaultAnimation
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.ToggleRecordingOnTap> {
        self.modifier(SwiftSpeech.ViewModifiers.ToggleRecordingOnTap(sessionConfiguration: sessionConfiguration, animation: animation))
    }
    
    func swiftSpeechToggleRecordingOnTap(
        locale: Locale = .autoupdatingCurrent,
        animation: Animation = SwiftSpeech.defaultAnimation
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.ToggleRecordingOnTap> {
        self.swiftSpeechToggleRecordingOnTap(sessionConfiguration: SwiftSpeech.Session.Configuration(locale: locale), animation: animation)
    }
    
    func onRecognize(
        includePartialResults isPartialResultIncluded: Bool = true,
        handleResult resultHandler: @escaping (SwiftSpeech.Session, SFSpeechRecognitionResult) -> Void,
        handleError errorHandler: @escaping (SwiftSpeech.Session, Error) -> Void
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        modifier(
            SwiftSpeech.ViewModifiers.OnRecognize(
                isPartialResultIncluded: isPartialResultIncluded,
                switchToLatest: false,
                resultHandler: resultHandler,
                errorHandler: errorHandler
            )
        )
    }
    
    func onRecognizeLatest(
        includePartialResults isPartialResultIncluded: Bool = true,
        handleResult resultHandler: @escaping (SwiftSpeech.Session, SFSpeechRecognitionResult) -> Void,
        handleError errorHandler: @escaping (SwiftSpeech.Session, Error) -> Void
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        modifier(
            SwiftSpeech.ViewModifiers.OnRecognize(
                isPartialResultIncluded: isPartialResultIncluded,
                switchToLatest: true,
                resultHandler: resultHandler,
                errorHandler: errorHandler
            )
        )
    }
    
    func onRecognizeLatest(
        includePartialResults isPartialResultIncluded: Bool = true,
        handleResult resultHandler: @escaping (SFSpeechRecognitionResult) -> Void,
        handleError errorHandler: @escaping (Error) -> Void
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        onRecognizeLatest(
            includePartialResults: isPartialResultIncluded,
            handleResult: { _, result in resultHandler(result) },
            handleError: { _, error in errorHandler(error) }
        )
    }
    
    func onRecognizeLatest(
        includePartialResults isPartialResultIncluded: Bool = true,
        update textBinding: Binding<String>
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        onRecognizeLatest(includePartialResults: isPartialResultIncluded) { result in
            textBinding.wrappedValue = result.bestTranscription.formattedString
        } handleError: { _ in }
    }
    
    func printRecognizedText(
        includePartialResults isPartialResultIncluded: Bool = true
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        onRecognize(includePartialResults: isPartialResultIncluded) { session, result in
            print("[SwiftSpeech] Recognized Text: \(result.bestTranscription.formattedString)")
        } handleError: { _, _ in }
    }
}

public extension Subject where Output == SpeechRecognizer.ID?, Failure == Never {
    func mapResolved<T>(_ transform: @escaping (SpeechRecognizer) -> T) -> Publishers.CompactMap<Self, T> {
        return self
            .compactMap { (id) -> T? in
                if let recognizer = SpeechRecognizer.recognizer(withID: id) {
                    return transform(recognizer)
                } else {
                    return nil
                }
            }
    }
    
    func mapResolved<T>(_ keyPath: KeyPath<SpeechRecognizer, T>) -> Publishers.CompactMap<Self, T> {
        return self
            .compactMap { (id) -> T? in
                if let recognizer = SpeechRecognizer.recognizer(withID: id) {
                    return recognizer[keyPath: keyPath]
                } else {
                    return nil
                }
            }
    }
}

public extension SwiftSpeech {
    static func supportedLocales() -> Set<Locale> {
        SFSpeechRecognizer.supportedLocales()
    }
}

public extension SwiftSpeech {
    enum State {
        case pending
        case recording
        case cancelling
    }
}

public extension SwiftSpeech {
    struct RecordButton : View {
        @Environment(\.swiftSpeechState) var state: SwiftSpeech.State
        @SpeechRecognitionAuthStatus var authStatus
        
        public init() { }
        
        var backgroundColor: Color {
            switch state {
            case .pending:
                return .accentColor
            case .recording:
                return .red
            case .cancelling:
                return .init(white: 0.1)
            }
        }
        
        var scale: CGFloat {
            switch state {
            case .pending:
                return 1.0
            case .recording:
                return 1.8
            case .cancelling:
                return 1.4
            }
        }
        
        public var body: some View {
            ZStack {
                backgroundColor
                    .animation(.easeOut(duration: 0.2))
                    .clipShape(Circle())
                    .environment(\.isEnabled, $authStatus)
                    .zIndex(0)
                
                Image(systemName: state != .cancelling ? "waveform" : "xmark")
                    .font(.system(size: 30, weight: .medium, design: .default))
                    .foregroundColor(.white)
                    .opacity(state == .recording ? 0.8 : 1.0)
                    .padding(20)
                    .transition(.opacity)
                    .layoutPriority(2)
                    .zIndex(1)
                
            }
            .scaleEffect(scale)
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.2), radius: 5, x: 0, y: 3)
        }
        
    }
}

extension SwiftSpeech {
    @dynamicMemberLookup public struct Session : Identifiable {
        public let id: UUID
        
        public subscript<T>(dynamicMember keyPath: KeyPath<SpeechRecognizer, T>) -> T? {
            return SpeechRecognizer.recognizer(withID: id)?[keyPath: keyPath]
        }
        
        public init(id: UUID = UUID(), configuration: Configuration) {
            self.id = id
            _ = SpeechRecognizer.new(id: id, sessionConfiguration: configuration)
        }
        
        public init(id: UUID = UUID(), locale: Locale = .current) {
            self.init(id: id, configuration: Configuration(locale: locale))
        }
        
        public func startRecording() {
            guard let recognizer = SpeechRecognizer.recognizer(withID: id) else { return }
            recognizer.startRecording()
        }
        
        public func stopRecording() {
            guard let recognizer = SpeechRecognizer.recognizer(withID: id) else { return }
            recognizer.stopRecording()
        }
        
        public func cancel() {
            guard let recognizer = SpeechRecognizer.recognizer(withID: id) else { return }
            recognizer.cancel()
        }
    }
}

public extension SwiftSpeech.Session {
    struct Configuration {
        public var locale: Locale = .current
        
        public var taskHint: SFSpeechRecognitionTaskHint = .unspecified
        
        public var shouldReportPartialResults: Bool = true
        
        public var requiresOnDeviceRecognition: Bool = false
        
        public var contextualStrings: [String] = []
        
        public var interactionIdentifier: String? = nil
        
        public var audioSessionConfiguration: AudioSessionConfiguration = .recordOnly
        
        public init(
            locale: Locale = .current,
            taskHint: SFSpeechRecognitionTaskHint = .unspecified,
            shouldReportPartialResults: Bool = true,
            requiresOnDeviceRecognition: Bool = false,
            contextualStrings: [String] = [],
            interactionIdentifier: String? = nil,
            audioSessionConfiguration: AudioSessionConfiguration = .recordOnly
        ) {
            self.locale = locale
            self.taskHint = taskHint
            self.shouldReportPartialResults = shouldReportPartialResults
            self.requiresOnDeviceRecognition = requiresOnDeviceRecognition
            self.contextualStrings = contextualStrings
            self.interactionIdentifier = interactionIdentifier
            self.audioSessionConfiguration = audioSessionConfiguration
        }
    }
}

public extension SwiftSpeech.Session {
    struct AudioSessionConfiguration {
        public var onStartRecording: (AVAudioSession) throws -> Void
        public var onStopRecording: (AVAudioSession) throws -> Void
        
        public init(onStartRecording: @escaping (AVAudioSession) throws -> Void, onStopRecording: @escaping (AVAudioSession) throws -> Void) {
            self.onStartRecording = onStartRecording
            self.onStopRecording = onStopRecording
        }
        
        public static let recordOnly = AudioSessionConfiguration { audioSession in
            try audioSession.setCategory(.record, mode: .default, options: [])
            try audioSession.setActive(true, options: [])
        } onStopRecording: { audioSession in
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
        
        public static let playAndRecord = AudioSessionConfiguration { audioSession in
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: [])
        } onStopRecording: { _ in }
        
        public static let none = AudioSessionConfiguration { _ in } onStopRecording: { _ in }
    }
}

public class SpeechRecognizer {
    static var instances = [SpeechRecognizer]()
    
    public typealias ID = UUID
    
    private var id: SpeechRecognizer.ID
    
    public var sessionConfiguration: SwiftSpeech.Session.Configuration
    
    private let speechRecognizer: SFSpeechRecognizer
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private let resultSubject = PassthroughSubject<SFSpeechRecognitionResult, Error>()
    
    public var resultPublisher: AnyPublisher<SFSpeechRecognitionResult, Error> {
        resultSubject.eraseToAnyPublisher()
    }
    
    public var stringPublisher: AnyPublisher<String, Error> {
        resultSubject
            .map(\.bestTranscription.formattedString)
            .eraseToAnyPublisher()
    }
    
    public func startRecording() {
        do {
            recognitionTask?.cancel()
            self.recognitionTask = nil
            
            #if canImport(UIKit)
            try sessionConfiguration.audioSessionConfiguration.onStartRecording(AVAudioSession.sharedInstance())
            #endif
            
            let inputNode = audioEngine.inputNode

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
            
            recognitionRequest.shouldReportPartialResults = sessionConfiguration.shouldReportPartialResults
            recognitionRequest.requiresOnDeviceRecognition = sessionConfiguration.requiresOnDeviceRecognition
            recognitionRequest.taskHint = sessionConfiguration.taskHint
            recognitionRequest.contextualStrings = sessionConfiguration.contextualStrings
            recognitionRequest.interactionIdentifier = sessionConfiguration.interactionIdentifier
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    self.resultSubject.send(result)
                    if result.isFinal {
                        self.resultSubject.send(completion: .finished)
                        SpeechRecognizer.remove(id: self.id)
                    }
                } else if let error = error {
                    self.stopRecording()
                    self.resultSubject.send(completion: .failure(error))
                    SpeechRecognizer.remove(id: self.id)
                } else {
                    fatalError("No result and no error")
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            resultSubject.send(completion: .failure(error))
            SpeechRecognizer.remove(id: self.id)
        }
    }
    
    public func stopRecording() {
        self.recognitionRequest?.endAudio()
        self.recognitionTask?.finish()
        self.audioEngine.stop()
        self.audioEngine.inputNode.removeTap(onBus: 0)
        
        do {
            try sessionConfiguration.audioSessionConfiguration.onStopRecording(AVAudioSession.sharedInstance())
        } catch {
            resultSubject.send(completion: .failure(error))
            SpeechRecognizer.remove(id: self.id)
        }
        
    }
    
    public func cancel() {
        stopRecording()
        resultSubject.send(completion: .finished)
        recognitionTask?.cancel()
        SpeechRecognizer.remove(id: self.id)
    }
    
    // MARK: - Init
    fileprivate init(id: ID, sessionConfiguration: SwiftSpeech.Session.Configuration) {
        self.id = id
        self.speechRecognizer = SFSpeechRecognizer(locale: sessionConfiguration.locale) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
        self.sessionConfiguration = sessionConfiguration
    }
    
    public static func new(id: ID, sessionConfiguration: SwiftSpeech.Session.Configuration) -> SpeechRecognizer {
        let recognizer = SpeechRecognizer(id: id, sessionConfiguration: sessionConfiguration)
        instances.append(recognizer)
        return recognizer
    }
    
    public static func recognizer(withID id: ID?) -> SpeechRecognizer? {
        return instances.first { $0.id == id }
    }
    
    @discardableResult
    public static func remove(id: ID?) -> SpeechRecognizer? {
        if let index = instances.firstIndex(where: { $0.id == id }) {
            return instances.remove(at: index)
        } else {
            return nil
        }
    }
    
    deinit {
        self.recognitionTask = nil
        self.recognitionRequest = nil
    }
    
}

public extension SwiftSpeech {
    struct FunctionalComponentDelegate: DynamicProperty {
        @Environment(\.actionsOnStartRecording) var actionsOnStartRecording
        @Environment(\.actionsOnStopRecording) var actionsOnStopRecording
        @Environment(\.actionsOnCancelRecording) var actionsOnCancelRecording
        
        public init() { }
        
        mutating public func update() {
            _actionsOnStartRecording.update()
            _actionsOnStopRecording.update()
            _actionsOnCancelRecording.update()
        }
        
        public func onStartRecording(session: SwiftSpeech.Session) {
            for action in actionsOnStartRecording {
                action(session)
            }
        }
        
        public func onStopRecording(session: SwiftSpeech.Session) {
            for action in actionsOnStopRecording {
                action(session)
            }
        }
        
        public func onCancelRecording(session: SwiftSpeech.Session) {
            for action in actionsOnCancelRecording {
                action(session)
            }
        }
    }
}

// MARK: - Functional Components
public extension SwiftSpeech.ViewModifiers {
    struct RecordOnHold : ViewModifier {
        public init(sessionConfiguration: SwiftSpeech.Session.Configuration = SwiftSpeech.Session.Configuration(), animation: Animation = SwiftSpeech.defaultAnimation, distanceToCancel: CGFloat = 50.0) {
            self.sessionConfiguration = sessionConfiguration
            self.animation = animation
            self.distanceToCancel = distanceToCancel
        }
        
        var sessionConfiguration: SwiftSpeech.Session.Configuration
        var animation: Animation
        var distanceToCancel: CGFloat
        
        @SpeechRecognitionAuthStatus var authStatus

        @State var recordingSession: SwiftSpeech.Session? = nil
        @State var viewComponentState: SwiftSpeech.State = .pending
        
        var delegate = SwiftSpeech.FunctionalComponentDelegate()
        
        var gesture: some Gesture {
            let longPress = LongPressGesture(minimumDuration: 0)
                .onEnded { _ in
                    withAnimation(self.animation, self.startRecording)
                    self.viewComponentState = .recording
                }
            
            let drag = DragGesture(minimumDistance: 0)
                .onChanged { value in
                    withAnimation(self.animation) {
                        if value.translation.height < -self.distanceToCancel {
                            self.viewComponentState = .cancelling
                        } else {
                            self.viewComponentState = .recording
                        }
                    }
                }
                .onEnded { value in
                    if value.translation.height < -self.distanceToCancel {
                        withAnimation(self.animation, self.cancelRecording)
                    } else {
                        withAnimation(self.animation, self.endRecording)
                    }
                }
            
            return longPress.simultaneously(with: drag)
        }
        
        public func body(content: Content) -> some View {
            content
                .gesture(gesture, including: $authStatus ? .gesture : .none)
                .environment(\.swiftSpeechState, viewComponentState)
        }
        
        fileprivate func startRecording() {
            let id = SpeechRecognizer.ID()
            let session = SwiftSpeech.Session(id: id, configuration: sessionConfiguration)
            self.viewComponentState = .recording
            self.recordingSession = session
            delegate.onStartRecording(session: session)
            session.startRecording()
        }
        
        fileprivate func cancelRecording() {
            guard let session = recordingSession else { return }
            session.cancel()
            delegate.onCancelRecording(session: session)
            self.viewComponentState = .pending
            self.recordingSession = nil
        }
        
        fileprivate func endRecording() {
            guard let session = recordingSession else { return }
            recordingSession?.stopRecording()
            delegate.onStopRecording(session: session)
            self.viewComponentState = .pending
            self.recordingSession = nil
        }
        
    }
    
    struct ToggleRecordingOnTap : ViewModifier {
        public init(sessionConfiguration: SwiftSpeech.Session.Configuration = SwiftSpeech.Session.Configuration(), animation: Animation = SwiftSpeech.defaultAnimation) {
            self.sessionConfiguration = sessionConfiguration
            self.animation = animation
        }
        
        var sessionConfiguration: SwiftSpeech.Session.Configuration
        var animation: Animation
        
        @SpeechRecognitionAuthStatus var authStatus

        @State var recordingSession: SwiftSpeech.Session? = nil
        @State var viewComponentState: SwiftSpeech.State = .pending
        
        var delegate = SwiftSpeech.FunctionalComponentDelegate()
        
        var gesture: some Gesture {
            TapGesture()
                .onEnded {
                    withAnimation(self.animation) {
                        if self.viewComponentState == .pending {  // if not recording
                            self.startRecording()
                        } else {  // if recording
                            self.endRecording()
                        }
                    }
                }
        }
        
        public func body(content: Content) -> some View {
            content
                .gesture(gesture, including: $authStatus ? .gesture : .none)
                .environment(\.swiftSpeechState, viewComponentState)
        }
        
        fileprivate func startRecording() {
            let id = SpeechRecognizer.ID()
            let session = SwiftSpeech.Session(id: id, configuration: sessionConfiguration)
            self.viewComponentState = .recording
            self.recordingSession = session
            delegate.onStartRecording(session: session)
            session.startRecording()
        }
        
        fileprivate func endRecording() {
            guard let session = recordingSession else { return }
            recordingSession?.stopRecording()
            delegate.onStopRecording(session: session)
            self.viewComponentState = .pending
            self.recordingSession = nil
        }
        
    }
    
}

// MARK: - SwiftSpeech Modifiers
public extension SwiftSpeech.ViewModifiers {
    struct OnRecognize : ViewModifier {
        @State var model: Model
        
        init(isPartialResultIncluded: Bool,
             switchToLatest: Bool,
             resultHandler: @escaping (SwiftSpeech.Session, SFSpeechRecognitionResult) -> Void,
             errorHandler: @escaping (SwiftSpeech.Session, Error) -> Void
        ) {
            self._model = State(initialValue: Model(isPartialResultIncluded: isPartialResultIncluded, switchToLatest: switchToLatest, resultHandler: resultHandler, errorHandler: errorHandler))
        }
        
        public func body(content: Content) -> some View {
            content
                .onStartRecording(sendSessionTo: model.sessionSubject)
                .onCancelRecording(sendSessionTo: model.cancelSubject)
        }
        
        class Model {
            
            let sessionSubject = PassthroughSubject<SwiftSpeech.Session, Never>()
            let cancelSubject = PassthroughSubject<SwiftSpeech.Session, Never>()
            var cancelBag = Set<AnyCancellable>()
            
            init(
                isPartialResultIncluded: Bool,
                switchToLatest: Bool,
                resultHandler: @escaping (SwiftSpeech.Session, SFSpeechRecognitionResult) -> Void,
                errorHandler: @escaping (SwiftSpeech.Session, Error) -> Void
            ) {
                let transform = { (session: SwiftSpeech.Session) -> AnyPublisher<(SwiftSpeech.Session, SFSpeechRecognitionResult), Never>? in
                    session.resultPublisher?
                        .filter { result in
                            isPartialResultIncluded ? true : (result.isFinal)
                        }.catch { (error: Error) -> Empty<SFSpeechRecognitionResult, Never> in
                            errorHandler(session, error)
                            return Empty(completeImmediately: true)
                        }.map { (session, $0) }
                        .eraseToAnyPublisher()
                }
                
                let receiveValue = { (tuple: (SwiftSpeech.Session, SFSpeechRecognitionResult)) -> Void in
                    let (session, result) = tuple
                    resultHandler(session, result)
                }
                
                if switchToLatest {
                    sessionSubject
                        .compactMap(transform)
                        .merge(with:
                            cancelSubject
                                .map { _ in Empty<(SwiftSpeech.Session, SFSpeechRecognitionResult), Never>(completeImmediately: true).eraseToAnyPublisher() }
                        ).switchToLatest()
                        .sink(receiveValue: receiveValue)
                        .store(in: &cancelBag)
                } else {
                    sessionSubject
                        .compactMap(transform)
                        .flatMap(maxPublishers: .unlimited) { $0 }
                        .sink(receiveValue: receiveValue)
                        .store(in: &cancelBag)
                }
            }
        }
    }
}

#endif
