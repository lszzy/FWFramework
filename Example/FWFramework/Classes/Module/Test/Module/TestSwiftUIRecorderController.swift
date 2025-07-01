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
                viewContext.viewController?.app.showSheet(title: nil, message: nil, actions: locales.map {
                    $0.localizedString(forLanguageCode: $0.languageCode ?? "") ?? ""
                }, actionBlock: { index in
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
                DemosColors(locale: locale)
            case 2:
                DemosList(locale: locale)
            default:
                DemosBasic(locale: locale)
            }
        }
    }
}

extension TestSwiftUIRecorderView {
    struct DemosBasic: View {
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

    struct DemosColors: View {
        @State private var text = "Hold and say a color!"

        private var locale: Locale?

        static let colorDictionary: [String: Color] = [
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
            "黄色": .yellow
        ]

        var color: Color? {
            DemosColors.colorDictionary
                .first { pair in
                    text.lowercased().contains(pair.key)
                }?
                .value
        }

        public init(locale: Locale? = nil) {
            self.locale = locale
        }

        public var body: some View {
            VStack(spacing: 35.0) {
                Text(text)
                    .font(.system(size: 25, weight: .bold, design: .default))
                    .foregroundColor(color)
                SwiftSpeech.RecordButton()
                    .accentColor(color)
                    .swiftSpeechRecordOnHold(locale: locale ?? Locale(identifier: "en_US"), animation: .spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0))
                    .onRecognizeLatest(update: $text)
            }.onAppear {
                SwiftSpeech.requestSpeechRecognitionAuthorization()
            }
        }
    }

    struct DemosList: View {
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
