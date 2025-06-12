//
//  TestSwiftUIRecorderController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2025/6/13.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import FWFramework
import SwiftUI

class TestSwiftUIRecorderController: UIViewController, ViewControllerProtocol {
    func setupSubviews() {
        app.navigationBarHidden = false
        
        let hostingView = TestSwiftUIRecorderView()
            .viewContext(self)
            .wrappedHostingView()
        view.addSubview(hostingView)
        hostingView.app.layoutChain
            .horizontal()
            .top(toSafeArea: .zero)
            .bottom()
    }
}

struct TestSwiftUIRecorderView: View {
    @Environment(\.viewContext) var viewContext: ViewContext
    
    @State var locale: Locale = .current
    @State var demo: Int = 0
    
    let demos = ["Demo - Basic", "Demo - Colors", "Demo - List"]
    
    var body: some View {
        VStack(spacing: 30) {
            Button {
                let locales = Array(SwiftSpeech.supportedLocales())
                viewContext.viewController?.app.showSheet(title: nil, message: nil, actions: locales.map({
                    $0.localizedString(forLanguageCode: $0.languageCode ?? "") ?? ""
                }), actionBlock: { index in
                    locale = locales[index]
                })
            } label: {
                HStack {
                    Spacer()
                    Text(locale.localizedString(forLanguageCode: locale.languageCode ?? "") ?? "")
                    Spacer()
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            .frame(width: (APP.screenWidth - 64) / 2, height: 40)
            .border(Color.gray, width: Divider.defaultSize, cornerRadius: 20)
            
            Button {
                viewContext.viewController?.app.showSheet(title: nil, message: nil, actions: demos, actionBlock: { index in
                    demo = index
                })
            } label: {
                HStack {
                    Spacer()
                    Text(demos[demo])
                    Spacer()
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            .frame(width: (APP.screenWidth - 64) / 2, height: 40)
            .border(Color.gray, width: Divider.defaultSize, cornerRadius: 20)
            
            switch demo {
            case 1:
                SwiftSpeech.Demos.Colors()
            case 2:
                SwiftSpeech.Demos.List(locale: locale)
            default:
                SwiftSpeech.Demos.Basic(locale: locale)
            }
        }
    }
}

import SwiftUI
import Combine
import Speech

public extension SwiftSpeech.Demos {
    
    struct Basic : View {
        
        var sessionConfiguration: SwiftSpeech.Session.Configuration
        
        @State private var text = "Tap to Speak"
        
        public init(sessionConfiguration: SwiftSpeech.Session.Configuration) {
            self.sessionConfiguration = sessionConfiguration
        }
        
        public init(locale: Locale = .current) {
            self.init(sessionConfiguration: SwiftSpeech.Session.Configuration(locale: locale))
        }
        
        public init(localeIdentifier: String) {
            self.init(locale: Locale(identifier: localeIdentifier))
        }
        
        public var body: some View {
            VStack(spacing: 35.0) {
                Text(text)
                    .font(.system(size: 25, weight: .bold, design: .default))
                SwiftSpeech.RecordButton()
                    .swiftSpeechToggleRecordingOnTap(sessionConfiguration: sessionConfiguration, animation: .spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0))
                    .onRecognizeLatest(update: $text)
                
            }.onAppear {
                SwiftSpeech.requestSpeechRecognitionAuthorization()
            }
        }
        
    }
    
    struct Colors : View {

        @State private var text = "Hold and say a color!"

        static let colorDictionary: [String : Color] = [
            "black": .black,
            "white": .white,
            "blue": .blue,
            "gray": .gray,
            "green": .green,
            "orange": .orange,
            "pink": .pink,
            "purple": .purple,
            "red": .red,
            "yellow": .yellow,
            "黑色": .black,
            "白色": .white,
            "蓝色": .blue,
            "灰色": .gray,
            "绿色": .green,
            "橘色": .orange,
            "粉色": .pink,
            "紫色": .purple,
            "红色": .red,
            "黄色": .yellow,
        ]

        var color: Color? {
            Colors.colorDictionary
                .first { pair in
                    text.lowercased().contains(pair.key)
                }?
                .value
        }

        public init() { }

        public var body: some View {
            VStack(spacing: 35.0) {
                Text(text)
                    .font(.system(size: 25, weight: .bold, design: .default))
                    .foregroundColor(color)
                SwiftSpeech.RecordButton()
                    .accentColor(color)
                    .swiftSpeechRecordOnHold(locale: Locale(identifier: "en_US"), animation: .spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0))
                    .onRecognizeLatest(update: $text)
            }.onAppear {
                SwiftSpeech.requestSpeechRecognitionAuthorization()
            }
        }

    }

    struct List : View {

        var sessionConfiguration: SwiftSpeech.Session.Configuration

        @State var list: [(session: SwiftSpeech.Session, text: String)] = []
        
        public init(sessionConfiguration: SwiftSpeech.Session.Configuration) {
            self.sessionConfiguration = sessionConfiguration
        }
        
        public init(locale: Locale = .current) {
            self.init(sessionConfiguration: SwiftSpeech.Session.Configuration(locale: locale))
        }
        
        public init(localeIdentifier: String) {
            self.init(locale: Locale(identifier: localeIdentifier))
        }

        public var body: some View {
            NavigationView {
                SwiftUI.List {
                    ForEach(list, id: \.session.id) { pair in
                        Text(pair.text)
                    }
                }.overlay(
                    SwiftSpeech.RecordButton()
                        .swiftSpeechRecordOnHold(
                            sessionConfiguration: sessionConfiguration,
                            animation: .spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0),
                            distanceToCancel: 100.0
                        ).onStartRecording { session in
                            list.append((session, ""))
                        }.onCancelRecording { session in
                            _ = list.firstIndex { $0.session.id == session.id }
                                .map { list.remove(at: $0) }
                        }.onRecognize(includePartialResults: true) { session, result in
                            list.firstIndex { $0.session.id == session.id }
                                .map { index in
                                    list[index].text = result.bestTranscription.formattedString + (result.isFinal ? "" : "...")
                                }
                        } handleError: { session, error in
                            list.firstIndex { $0.session.id == session.id }
                                .map { index in
                                    list[index].text = "Error \((error as NSError).code)"
                                }
                        }.padding(20),
                    alignment: .bottom
                ).navigationBarTitle(Text("SwiftSpeech"))

            }.onAppear {
                SwiftSpeech.requestSpeechRecognitionAuthorization()
            }
        }
    }
}

extension SwiftSpeech {
    
    public static func requestSpeechRecognitionAuthorization() {
        AuthorizationCenter.shared.requestSpeechRecognitionAuthorization()
    }
    
    class AuthorizationCenter: ObservableObject {
        @Published var speechRecognitionAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = SFSpeechRecognizer.authorizationStatus()
        
        func requestSpeechRecognitionAuthorization() {
            // Asynchronously make the authorization request.
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
    /**
     An enumeration representing the state of recording. Typically used by a **View Component** and set by a **Functional Component**.
     - Note: The availability of speech recognition cannot be determined using the `State`
             and should be attained using `@Environment(\.isSpeechRecognitionAvailable)`.
     */
    enum State {
        /// Indicating there is no recording in progress.
        /// - Note: It's the default value for `@Environment(\.swiftSpeechState)`.
        case pending
        /// Indicating there is a recording in progress and the user does not intend to cancel it.
        case recording
        /// Indicating there is a recording in progress and the user intends to cancel it.
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
                    .environment(\.isEnabled, $authStatus)  // When isEnabled is false, the accent color is gray and all user interactions are disabled inside the view.
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
    
    /**
     A `Session` is a light-weight struct that essentially holds a weak reference to its underlying class whose lifespan is managed by the framework.
     If you are filling in a `(Session) -> Void` handler provided by the framework, you may want to check its `stringPublisher` and `resultPublisher` properties.
     - Note: You can only call `startRecording()` once on a `Session` and after it completes the recognition task, all of its properties will be `nil` and actions will take no effect.
     */
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
        
        /**
         Sets up the audio stuff automatically for you and start recording the user's voice.
         
         - Note: Avoid using this method twice.
                 Start receiving the recognition results by subscribing to one of the publishers.
         - Throws: Errors can occur when:
                   1. There is problem in the structure of the graph. Input can't be routed to output or to a recording tap through converter type nodes.
                   2. An AVAudioSession error occurred
                   3. The driver failed to start the hardware
         */
        public func startRecording() {
            guard let recognizer = SpeechRecognizer.recognizer(withID: id) else { return }
            recognizer.startRecording()
        }
        
        public func stopRecording() {
            guard let recognizer = SpeechRecognizer.recognizer(withID: id) else { return }
            recognizer.stopRecording()
        }
        
        /**
         Immediately halts the recognition process and invalidate the `Session`.
         */
        public func cancel() {
            guard let recognizer = SpeechRecognizer.recognizer(withID: id) else { return }
            recognizer.cancel()
        }
        
    }
}

public extension SwiftSpeech.Session {
    struct Configuration {
        /**
         The locale representing the language you want to use for speech recognition.
         The default value is `.current`.
         
         To get a list of locales supported by SwiftSpeech, use `SwiftSpeech.supportedLocales()`.
         */
        public var locale: Locale = .current
        
        /**
         A value that indicates the type of speech recognition being performed.
         The default value is `.unspecified`.
         
         `.unspecified` - An unspecified type of task.
         
         `.dictation` - A task that uses captured speech for text entry.
         
         `.search` - A task that uses captured speech to specify search terms.
         
         `.confirmation` - A task that uses captured speech for short, confirmation-style requests.
         */
        public var taskHint: SFSpeechRecognitionTaskHint = .unspecified
        
        /// A Boolean value that indicates whether you want intermediate results returned for each utterance.
        /// The default value is `true`.
        public var shouldReportPartialResults: Bool = true
        
        /// A Boolean value that determines whether a request must keep its audio data on the device.
        public var requiresOnDeviceRecognition: Bool = false
        
        /**
         An array of phrases that should be recognized, even if they are not in the system vocabulary.
         The default value is `[]`.
         
         Use this property to specify short custom phrases that are unique to your app. You might include phrases with the names of characters, products, or places that are specific to your app. You might also include domain-specific terminology or unusual or made-up words. Assigning custom phrases to this property improves the likelihood of those phrases being recognized.
         
         Keep phrases relatively brief, limiting them to one or two words whenever possible. Lengthy phrases are less likely to be recognized. In addition, try to limit each phrase to something the user can say without pausing.
         
         Limit the total number of phrases to no more than 100.
         */
        public var contextualStrings: [String] = []
        
        /**
         A string that you use to identify sessions representing different types of interactions/speech recognition needs.
         The default value is `nil`.
         
         If one part of your app lets users speak phone numbers and another part lets users speak street addresses, consistently identifying the part of the app that makes a recognition request may help improve the accuracy of the results.
         */
        public var interactionIdentifier: String? = nil
        
        /**
         A configuration for configuring/activating/deactivating your app's `AVAudioSession` at the appropriate time.
         The default value is `.recordOnly`, which activate/deactivate a **record only** audio session when a recording session starts/stops.
         
         See `SwiftSpeech.Session.AudioSessionConfiguration` for more options.
         */
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
        
        /**
         Create a configuration using two closures.
         */
        public init(onStartRecording: @escaping (AVAudioSession) throws -> Void, onStopRecording: @escaping (AVAudioSession) throws -> Void) {
            self.onStartRecording = onStartRecording
            self.onStopRecording = onStopRecording
        }
        
        /**
         A record only configuration that is activated/deactivated when a recording session starts/stops.
         
         During the recording session, virtually all output on the system is silenced. Audio from other apps can resume after the recording session stops.
         */
        public static let recordOnly = AudioSessionConfiguration { audioSession in
            try audioSession.setCategory(.record, mode: .default, options: [])
            try audioSession.setActive(true, options: [])
        } onStopRecording: { audioSession in
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
        
        /**
         A configuration that allows both play and record and is **NOT** deactivated when a recording session stops. You should manually deactivate your session.
         
         This configuration is non-mixable, meaning it will interrupt any ongoing audio session when it is activated.
         */
        public static let playAndRecord = AudioSessionConfiguration { audioSession in
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: [])
        } onStopRecording: { _ in }
        
        /**
         A configuration that does nothing. Use this configuration when you want to configure, activate, and deactivate your app's audio session manually.
         */
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
    
    /// A convenience publisher that emits `result.bestTranscription.formattedString`.
    public var stringPublisher: AnyPublisher<String, Error> {
        resultSubject
            .map(\.bestTranscription.formattedString)
            .eraseToAnyPublisher()
    }
    
    public func startRecording() {
        do {
            // Cancel the previous task if it's running.
            recognitionTask?.cancel()
            self.recognitionTask = nil
            
            // Configure the audio session for the app if it's on iOS/Mac Catalyst.
            #if canImport(UIKit)
            try sessionConfiguration.audioSessionConfiguration.onStartRecording(AVAudioSession.sharedInstance())
            #endif
            
            let inputNode = audioEngine.inputNode

            // Create and configure the speech recognition request.
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
            
            // Use `sessionConfiguration` to configure the recognition request
            recognitionRequest.shouldReportPartialResults = sessionConfiguration.shouldReportPartialResults
            recognitionRequest.requiresOnDeviceRecognition = sessionConfiguration.requiresOnDeviceRecognition
            recognitionRequest.taskHint = sessionConfiguration.taskHint
            recognitionRequest.contextualStrings = sessionConfiguration.contextualStrings
            recognitionRequest.interactionIdentifier = sessionConfiguration.interactionIdentifier
            
            // Create a recognition task for the speech recognition session.
            // Keep a reference to the task so that it can be cancelled.
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

            // Configure the microphone input.
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
        
        // Call this method explicitly to let the speech recognizer know that no more audio input is coming.
        self.recognitionRequest?.endAudio()
        
        // self.recognitionRequest = nil
        
        // For audio buffer–based recognition, recognition does not finish until this method is called, so be sure to call it when the audio source is exhausted.
        self.recognitionTask?.finish()
        
        // self.recognitionTask = nil
        
        self.audioEngine.stop()
        self.audioEngine.inputNode.removeTap(onBus: 0)
        
        do {
            try sessionConfiguration.audioSessionConfiguration.onStopRecording(AVAudioSession.sharedInstance())
        } catch {
            resultSubject.send(completion: .failure(error))
            SpeechRecognizer.remove(id: self.id)
        }
        
    }
    
    /// Call this method to immediately stop recording AND the recognition task (i.e. stop recognizing & receiving results).
    /// This method will call `stopRecording()` first and then send a completion (`.finished`) event to the publishers. Finally, it will cancel the recognition task and dispose of the SpeechRecognizer instance.
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
//            print("Removing speech recognizer: index \(index)")
            return instances.remove(at: index)
        } else {
//            print("Removing speech recognizer: no such id found")
            return nil
        }
    }
    
    deinit {
//        print("Speech Recognizer: Deinit")
        self.recognitionTask = nil
        self.recognitionRequest = nil
    }
    
}

public struct SwiftSpeech {
    public struct ViewModifiers { }
    public struct Demos { }
    internal struct EnvironmentKeys { }
    
    /// Change this when the app starts to configure the default animation used for all record on hold functional components.
    public static var defaultAnimation: Animation = .interactiveSpring()
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
            // View update
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
    
    /**
     `viewComponentState` will never be `.cancelling` here.
     */
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
            // View update
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
