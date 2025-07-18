//
//  SwiftSpeech.swift
//  FWFramework
//
//  Created by wuyong on 2025/6/13.
//

import Combine
import Speech
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

/// [SwiftSpeech](https://github.com/Cay-Zhang/SwiftSpeech)
public enum SwiftSpeech {
    public struct ViewModifiers {}
    public struct Demos {}
    struct EnvironmentKeys {}

    public static var defaultAnimation: Animation {
        get { FrameworkConfiguration.speechDefaultAnimation }
        set { FrameworkConfiguration.speechDefaultAnimation = newValue }
    }
}

extension SwiftSpeech {
    @MainActor public static func requestSpeechRecognitionAuthorization() {
        AuthorizationCenter.shared.requestSpeechRecognitionAuthorization()
    }

    class AuthorizationCenter: ObservableObject, @unchecked Sendable {
        @Published var speechRecognitionAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = SFSpeechRecognizer.authorizationStatus()

        func requestSpeechRecognitionAuthorization() {
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.fw.mainAsync {
                    if self.speechRecognitionAuthorizationStatus != authStatus {
                        self.speechRecognitionAuthorizationStatus = authStatus
                    }
                }
            }
        }

        @MainActor static let shared = AuthorizationCenter()
    }
}

@propertyWrapper @MainActor public struct SpeechRecognitionAuthStatus: DynamicProperty {
    @ObservedObject var authCenter = SwiftSpeech.AuthorizationCenter.shared

    let trueValues: Set<SFSpeechRecognizerAuthorizationStatus>

    public var wrappedValue: SFSpeechRecognizerAuthorizationStatus {
        SwiftSpeech.AuthorizationCenter.shared.speechRecognitionAuthorizationStatus
    }

    public init(trueValues: Set<SFSpeechRecognizerAuthorizationStatus> = [.authorized]) {
        self.trueValues = trueValues
    }

    public var projectedValue: Bool {
        trueValues.contains(SwiftSpeech.AuthorizationCenter.shared.speechRecognitionAuthorizationStatus)
    }
}

extension SwiftSpeech.EnvironmentKeys {
    struct SwiftSpeechState: EnvironmentKey {
        static let defaultValue: SwiftSpeech.State = .pending
    }

    struct ActionsOnStartRecording: EnvironmentKey {
        static var defaultValue: [(_ session: SwiftSpeech.Session) -> Void] { [] }
    }

    struct ActionsOnStopRecording: EnvironmentKey {
        static var defaultValue: [(_ session: SwiftSpeech.Session) -> Void] { [] }
    }

    struct ActionsOnCancelRecording: EnvironmentKey {
        static var defaultValue: [(_ session: SwiftSpeech.Session) -> Void] { [] }
    }
}

extension EnvironmentValues {
    public var swiftSpeechState: SwiftSpeech.State {
        get { self[SwiftSpeech.EnvironmentKeys.SwiftSpeechState.self] }
        set { self[SwiftSpeech.EnvironmentKeys.SwiftSpeechState.self] = newValue }
    }

    public var actionsOnStartRecording: [(_ session: SwiftSpeech.Session) -> Void] {
        get { self[SwiftSpeech.EnvironmentKeys.ActionsOnStartRecording.self] }
        set { self[SwiftSpeech.EnvironmentKeys.ActionsOnStartRecording.self] = newValue }
    }

    public var actionsOnStopRecording: [(_ session: SwiftSpeech.Session) -> Void] {
        get { self[SwiftSpeech.EnvironmentKeys.ActionsOnStopRecording.self] }
        set { self[SwiftSpeech.EnvironmentKeys.ActionsOnStopRecording.self] = newValue }
    }

    public var actionsOnCancelRecording: [(_ session: SwiftSpeech.Session) -> Void] {
        get { self[SwiftSpeech.EnvironmentKeys.ActionsOnCancelRecording.self] }
        set { self[SwiftSpeech.EnvironmentKeys.ActionsOnCancelRecording.self] = newValue }
    }
}

@MainActor extension View {
    public func onStartRecording(appendAction actionToAppend: @escaping (_ session: SwiftSpeech.Session) -> Void) ->
        ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(_ session: SwiftSpeech.Session) -> Void]>> {
        transformEnvironment(\.actionsOnStartRecording) { actions in
            actions.insert(actionToAppend, at: 0)
        } as! ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>>
    }

    public func onStopRecording(appendAction actionToAppend: @escaping (_ session: SwiftSpeech.Session) -> Void) ->
        ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(_ session: SwiftSpeech.Session) -> Void]>> {
        transformEnvironment(\.actionsOnStopRecording) { actions in
            actions.insert(actionToAppend, at: 0)
        } as! ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>>
    }

    public func onCancelRecording(appendAction actionToAppend: @escaping (_ session: SwiftSpeech.Session) -> Void) ->
        ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(_ session: SwiftSpeech.Session) -> Void]>> {
        transformEnvironment(\.actionsOnCancelRecording) { actions in
            actions.insert(actionToAppend, at: 0)
        } as! ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>>
    }
}

@MainActor extension View {
    public func onStartRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session {
        onStartRecording { session in
            subject.send(session)
        }
    }

    public func onStartRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session? {
        onStartRecording { session in
            subject.send(session)
        }
    }

    public func onStopRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session {
        onStopRecording { session in
            subject.send(session)
        }
    }

    public func onStopRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session? {
        onStopRecording { session in
            subject.send(session)
        }
    }

    public func onCancelRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session {
        onCancelRecording { session in
            subject.send(session)
        }
    }

    public func onCancelRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session? {
        onCancelRecording { session in
            subject.send(session)
        }
    }
}

@MainActor extension View {
    public func swiftSpeechRecordOnHold(
        sessionConfiguration: SwiftSpeech.Session.Configuration = SwiftSpeech.Session.Configuration(),
        animation: Animation = SwiftSpeech.defaultAnimation,
        distanceToCancel: CGFloat = 50.0
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.RecordOnHold> {
        modifier(
            SwiftSpeech.ViewModifiers.RecordOnHold(
                sessionConfiguration: sessionConfiguration,
                animation: animation,
                distanceToCancel: distanceToCancel
            )
        )
    }

    public func swiftSpeechRecordOnHold(
        locale: Locale,
        animation: Animation = SwiftSpeech.defaultAnimation,
        distanceToCancel: CGFloat = 50.0
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.RecordOnHold> {
        swiftSpeechRecordOnHold(sessionConfiguration: SwiftSpeech.Session.Configuration(locale: locale), animation: animation, distanceToCancel: distanceToCancel)
    }

    public func swiftSpeechToggleRecordingOnTap(
        sessionConfiguration: SwiftSpeech.Session.Configuration = SwiftSpeech.Session.Configuration(),
        animation: Animation = SwiftSpeech.defaultAnimation
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.ToggleRecordingOnTap> {
        modifier(SwiftSpeech.ViewModifiers.ToggleRecordingOnTap(sessionConfiguration: sessionConfiguration, animation: animation))
    }

    public func swiftSpeechToggleRecordingOnTap(
        locale: Locale = .autoupdatingCurrent,
        animation: Animation = SwiftSpeech.defaultAnimation
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.ToggleRecordingOnTap> {
        swiftSpeechToggleRecordingOnTap(sessionConfiguration: SwiftSpeech.Session.Configuration(locale: locale), animation: animation)
    }

    public func onRecognize(
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

    public func onRecognizeLatest(
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

    public func onRecognizeLatest(
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

    public func onRecognizeLatest(
        includePartialResults isPartialResultIncluded: Bool = true,
        update textBinding: Binding<String>
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        onRecognizeLatest(includePartialResults: isPartialResultIncluded) { result in
            textBinding.wrappedValue = result.bestTranscription.formattedString
        } handleError: { _ in }
    }

    public func printRecognizedText(
        includePartialResults isPartialResultIncluded: Bool = true
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        onRecognize(includePartialResults: isPartialResultIncluded) { _, result in
            print("[SwiftSpeech] Recognized Text: \(result.bestTranscription.formattedString)")
        } handleError: { _, _ in }
    }
}

extension Subject where Output == SpeechRecognizer.ID?, Failure == Never {
    public func mapResolved<T>(_ transform: @escaping (SpeechRecognizer) -> T) -> Publishers.CompactMap<Self, T> {
        compactMap { id -> T? in
            if let recognizer = SpeechRecognizer.recognizer(withID: id) {
                return transform(recognizer)
            } else {
                return nil
            }
        }
    }

    public func mapResolved<T>(_ keyPath: KeyPath<SpeechRecognizer, T>) -> Publishers.CompactMap<Self, T> {
        compactMap { id -> T? in
            if let recognizer = SpeechRecognizer.recognizer(withID: id) {
                return recognizer[keyPath: keyPath]
            } else {
                return nil
            }
        }
    }
}

extension SwiftSpeech {
    public static func supportedLocales() -> Set<Locale> {
        SFSpeechRecognizer.supportedLocales()
    }
}

extension SwiftSpeech {
    public enum State: Sendable {
        case pending
        case recording
        case cancelling
    }
}

extension SwiftSpeech {
    public struct RecordButton: View {
        @Environment(\.swiftSpeechState) var state: SwiftSpeech.State
        @SpeechRecognitionAuthStatus var authStatus

        public init() {}

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
    @dynamicMemberLookup public struct Session: Identifiable {
        public let id: UUID

        public subscript<T>(dynamicMember keyPath: KeyPath<SpeechRecognizer, T>) -> T? {
            SpeechRecognizer.recognizer(withID: id)?[keyPath: keyPath]
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

extension SwiftSpeech.Session {
    public struct Configuration {
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

extension SwiftSpeech.Session {
    public struct AudioSessionConfiguration: @unchecked Sendable {
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
    static var instances: [SpeechRecognizer] {
        get { FrameworkConfiguration.speechRecognizerInstances }
        set { FrameworkConfiguration.speechRecognizerInstances = newValue }
    }

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
            recognitionTask = nil

            #if canImport(UIKit)
            try sessionConfiguration.audioSessionConfiguration.onStartRecording(AVAudioSession.sharedInstance())
            #endif

            let inputNode = audioEngine.inputNode

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }

            recognitionRequest.shouldReportPartialResults = sessionConfiguration.shouldReportPartialResults
            recognitionRequest.requiresOnDeviceRecognition = sessionConfiguration.requiresOnDeviceRecognition
            recognitionRequest.taskHint = sessionConfiguration.taskHint
            recognitionRequest.contextualStrings = sessionConfiguration.contextualStrings
            recognitionRequest.interactionIdentifier = sessionConfiguration.interactionIdentifier

            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    resultSubject.send(result)
                    if result.isFinal {
                        resultSubject.send(completion: .finished)
                        SpeechRecognizer.remove(id: id)
                    }
                } else if let error {
                    stopRecording()
                    resultSubject.send(completion: .failure(error))
                    SpeechRecognizer.remove(id: id)
                } else {
                    fatalError("No result and no error")
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
                self.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            resultSubject.send(completion: .failure(error))
            SpeechRecognizer.remove(id: id)
        }
    }

    public func stopRecording() {
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        do {
            try sessionConfiguration.audioSessionConfiguration.onStopRecording(AVAudioSession.sharedInstance())
        } catch {
            resultSubject.send(completion: .failure(error))
            SpeechRecognizer.remove(id: id)
        }
    }

    public func cancel() {
        stopRecording()
        resultSubject.send(completion: .finished)
        recognitionTask?.cancel()
        SpeechRecognizer.remove(id: id)
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
        instances.first { $0.id == id }
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

extension SwiftSpeech {
    public struct FunctionalComponentDelegate: DynamicProperty {
        @Environment(\.actionsOnStartRecording) var actionsOnStartRecording
        @Environment(\.actionsOnStopRecording) var actionsOnStopRecording
        @Environment(\.actionsOnCancelRecording) var actionsOnCancelRecording

        public init() {}

        public mutating func update() {
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
extension SwiftSpeech.ViewModifiers {
    public struct RecordOnHold: ViewModifier {
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
                    try? withAnimation(animation, startRecording)
                    viewComponentState = .recording
                }

            let drag = DragGesture(minimumDistance: 0)
                .onChanged { value in
                    withAnimation(animation) {
                        if value.translation.height < -distanceToCancel {
                            viewComponentState = .cancelling
                        } else {
                            viewComponentState = .recording
                        }
                    }
                }
                .onEnded { value in
                    if value.translation.height < -distanceToCancel {
                        try? withAnimation(animation, cancelRecording)
                    } else {
                        try? withAnimation(animation, endRecording)
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
            viewComponentState = .recording
            recordingSession = session
            delegate.onStartRecording(session: session)
            session.startRecording()
        }

        fileprivate func cancelRecording() {
            guard let session = recordingSession else { return }
            session.cancel()
            delegate.onCancelRecording(session: session)
            viewComponentState = .pending
            recordingSession = nil
        }

        fileprivate func endRecording() {
            guard let session = recordingSession else { return }
            recordingSession?.stopRecording()
            delegate.onStopRecording(session: session)
            viewComponentState = .pending
            recordingSession = nil
        }
    }

    public struct ToggleRecordingOnTap: ViewModifier {
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
                    withAnimation(animation) {
                        if viewComponentState == .pending { // if not recording
                            startRecording()
                        } else { // if recording
                            endRecording()
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
            viewComponentState = .recording
            recordingSession = session
            delegate.onStartRecording(session: session)
            session.startRecording()
        }

        fileprivate func endRecording() {
            guard let session = recordingSession else { return }
            recordingSession?.stopRecording()
            delegate.onStopRecording(session: session)
            viewComponentState = .pending
            recordingSession = nil
        }
    }
}

// MARK: - SwiftSpeech Modifiers
extension SwiftSpeech.ViewModifiers {
    public struct OnRecognize: ViewModifier {
        @State var model: Model

        init(isPartialResultIncluded: Bool,
             switchToLatest: Bool,
             resultHandler: @escaping (SwiftSpeech.Session, SFSpeechRecognitionResult) -> Void,
             errorHandler: @escaping (SwiftSpeech.Session, Error) -> Void) {
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

                let receiveValue = { (tuple: (SwiftSpeech.Session, SFSpeechRecognitionResult)) in
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

// MARK: - FrameworkConfiguration+SwiftSpeech
extension FrameworkConfiguration {
    fileprivate static var speechDefaultAnimation: Animation = .interactiveSpring()
    fileprivate static var speechRecognizerInstances = [SpeechRecognizer]()
}
