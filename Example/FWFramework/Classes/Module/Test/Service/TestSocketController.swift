//
//  TestSocketController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/27.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
import UIKit

class TestSocketController: UIViewController {
    // MARK: - Accessor
    private var serverStarted: Bool = false {
        didSet {
            if serverStarted {
                serverButton.setTitle("Stop Server", for: .normal)
            } else {
                serverButton.setTitle("Start Server", for: .normal)
            }
        }
    }

    private var isConnected: Bool = false {
        didSet {
            if isConnected {
                clientButton.setTitle("Stop Client", for: .normal)
                clientLabel.text = "client connected"
            } else {
                clientButton.setTitle("Start Client", for: .normal)
                clientLabel.text = "client disconnected"
            }
        }
    }

    private let serverAddress = "http://127.0.0.1"
    private let serverPort = UInt16(8009)

    @StoredValue("WebSocketUrl")
    private var clientURL: String = "http://127.0.0.1:8009"
    private var clientInited = false

    private lazy var server: WebSocketServer = {
        let result = WebSocketServer()
        result.onEvent = { [weak self] event in
            DispatchQueue.app.mainAsync { [weak self] in
                switch event {
                case let .connected(connection, headers):
                    self?.serverLabel.text = "\(String(describing: connection)) is connected"
                case let .disconnected(connection, reason, code):
                    self?.serverLabel.text = "\(String(describing: connection)) is disconnected"
                case let .text(connection, string):
                    self?.serverLabel.text = "Received text: \(string)"
                    connection.write(data: string.replacingOccurrences(of: "request", with: "response").app.utf8Data!, opcode: .textFrame)
                case let .binary(connection, data):
                    self?.serverLabel.text = "Received data: \(data.count)"
                    connection.write(data: data, opcode: .binaryFrame)
                case .ping:
                    break
                case .pong:
                    break
                }
            }
        }
        return result
    }()

    private lazy var client: WebSocket = {
        var request = URLRequest(url: URL(string: clientURL)!)
        request.timeoutInterval = 5
        let result = WebSocket(request: request)
        result.onEvent = { [weak self] event in
            DispatchQueue.app.mainAsync { [weak self] in
                switch event {
                case let .connected(headers):
                    self?.isConnected = true
                case let .disconnected(reason, code):
                    self?.isConnected = false
                case let .text(string):
                    self?.clientLabel.text = "Received text: \(string)"
                case let .binary(data):
                    self?.clientLabel.text = "Received data: \(data.count)"
                case .ping:
                    break
                case .pong:
                    break
                case .viabilityChanged:
                    break
                case .reconnectSuggested:
                    break
                case .cancelled:
                    self?.isConnected = false
                case let .error(error):
                    self?.isConnected = false
                case .peerClosed:
                    break
                }
            }
        }
        return result
    }()

    // MARK: - Subviews
    private lazy var serverLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.font = UIFont.systemFont(ofSize: 15)
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()

    private lazy var serverButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Start Server", for: .normal)
        button.app.addTouch(target: self, action: #selector(onServer))
        return button
    }()

    private lazy var clientLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.font = UIFont.systemFont(ofSize: 15)
        result.textAlignment = .center
        result.numberOfLines = 0
        return result
    }()

    private lazy var clientButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Start Client", for: .normal)
        button.app.addTouch(target: self, action: #selector(onClient))
        return button
    }()

    private lazy var requestButton: UIButton = {
        let button = AppTheme.largeButton()
        button.setTitle("Client Request", for: .normal)
        button.app.addTouch(target: self, action: #selector(onRequest))
        return button
    }()

    // MARK: - Lifecycle
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isConnected { client.disconnect() }
        if serverStarted { server.stop() }
    }
}

extension TestSocketController: ViewControllerProtocol {
    func setupSubviews() {
        view.addSubview(serverLabel)
        view.addSubview(serverButton)
        view.addSubview(clientLabel)
        view.addSubview(clientButton)
        view.addSubview(requestButton)
    }

    func setupLayout() {
        serverLabel.app.layoutChain
            .horizontal()
            .top(toSafeArea: 50)

        serverButton.app.layoutChain
            .centerX()
            .top(toViewBottom: serverLabel, offset: 20)

        clientLabel.app.layoutChain
            .horizontal()
            .top(toViewBottom: serverButton, offset: 100)

        clientButton.app.layoutChain
            .centerX()
            .top(toViewBottom: clientLabel, offset: 20)

        requestButton.app.layoutChain
            .centerX()
            .top(toViewBottom: clientButton, offset: 20)
    }
}

@objc extension TestSocketController {
    func onServer() {
        if serverStarted {
            server.stop()
            serverStarted = false
            serverLabel.text = "server stopped"
        } else {
            let error = server.start(address: serverAddress, port: serverPort)
            if error == nil { serverStarted = true }
            serverLabel.text = serverStarted ? "server started" : error?.localizedDescription
        }
    }

    func onClient() {
        if !clientInited {
            app.showPrompt(title: nil, message: "WebSocket Server", cancel: nil, confirm: nil) { [weak self] textField in
                textField.text = self?.clientURL
            } confirmBlock: { [weak self] value in
                self?.clientInited = true
                self?.clientURL = !value.isEmpty ? value : "http://127.0.0.1:8009"
                self?.onClient()
            }
        } else {
            if isConnected {
                client.disconnect()
            } else {
                client.connect()
            }
        }
    }

    func onRequest() {
        client.write(string: "request \(Date().app.stringValue)")
    }
}
