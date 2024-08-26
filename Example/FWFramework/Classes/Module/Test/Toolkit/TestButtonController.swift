//
//  TestButtonController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/20.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestButtonController: UIViewController, ViewControllerProtocol {
    var count: Int = 0

    private nonisolated(unsafe) var timer: Timer?

    @objc func timerAction() {
        print("timerAction \(Date().app.string(format: "HH:mm:ss"))")
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }

    func setupNavbar() {
        app.extendedLayoutEdge = .bottom

        timer = Timer.app.commonTimer(timeInterval: 1, target: WeakProxy(target: self), selector: #selector(timerAction), userInfo: nil, repeats: true)
    }

    func setupSubviews() {
        var button = UIButton.app.button(title: "Button重复点击", font: APP.font(15), titleColor: AppTheme.textColor)
        button.frame = CGRect(x: 25, y: 15, width: 150, height: 30)
        button.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button.app.addTouch(target: self, action: #selector(onClick1(_:)))
        view.addSubview(button)

        var label = UILabel.app.label(font: APP.font(15), textColor: AppTheme.textColor, text: "View重复点击")
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.frame = CGRect(x: 200, y: 15, width: 150, height: 30)
        label.app.addTapGesture(target: self, action: #selector(onClick2(_:))) { gesture in
            gesture.highlightedAlpha = UIButton.app.highlightedAlpha
        }
        view.addSubview(label)

        button = UIButton.app.button(title: "Button不可重复点击", font: APP.font(15), titleColor: AppTheme.textColor)
        button.frame = CGRect(x: 25, y: 60, width: 150, height: 30)
        button.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button.app.disabledAlpha = UIButton.app.disabledAlpha
        button.app.addTouch(target: self, action: #selector(onClick3(_:)))
        view.addSubview(button)

        label = UILabel.app.label(font: APP.font(15), textColor: AppTheme.textColor, text: "View不可重复点击")
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.frame = CGRect(x: 200, y: 60, width: 150, height: 30)
        label.app.addTapGesture(target: self, action: #selector(onClick4(_:))) { gesture in
            gesture.disabledAlpha = UIButton.app.disabledAlpha
            gesture.highlightedAlpha = UIButton.app.highlightedAlpha
        }
        view.addSubview(label)

        button = UIButton.app.button(title: "Button1秒内不可重复点击", font: APP.font(15), titleColor: AppTheme.textColor)
        button.app.touchEventInterval = 1
        button.frame = CGRect(x: 25, y: 105, width: 200, height: 30)
        button.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button.app.addTouch(target: self, action: #selector(onClick5(_:)))
        view.addSubview(button)

        let timerButton = UIButton(type: .custom)
        timerButton.frame = CGRect(x: 20, y: 160, width: 40, height: 30)
        timerButton.titleLabel?.font = APP.font(15)
        timerButton.setTitleColor(AppTheme.textColor, for: .normal)
        timerButton.setTitle("=>", for: .normal)
        view.addSubview(timerButton)

        let sendButton = UIButton(type: .custom)
        sendButton.frame = CGRect(x: 80, y: 160, width: 40, height: 30)
        sendButton.titleLabel?.font = APP.font(15)
        sendButton.setTitleColor(AppTheme.textColor, for: .normal)
        sendButton.setTitle("发送", for: .normal)
        view.addSubview(sendButton)
        var sendTimer: Timer?
        sendButton.app.addTouch { _ in
            timerButton.app.startCountDown(60, title: "=>", waitTitle: "%lds")

            sendTimer?.invalidate()
            sendTimer = Timer.app.commonTimer(countDown: 60, block: { countDown in
                let title = countDown > 0 ? String(format: "%lds", countDown) : "发送"
                sendButton.setTitle(title, for: .normal)
                sendButton.isEnabled = countDown < 1
            })
        }

        let odometerView = OdometerView()
        odometerView.frame = CGRect(x: 140, y: 150, width: 130, height: 50)
        odometerView.textFont = APP.font(30, .semibold)
        odometerView.textColor = AppTheme.textColor
        odometerView.setNumber("$0.00")
        view.addSubview(odometerView)

        let randomButton = UIButton(type: .custom)
        randomButton.frame = CGRect(x: 290, y: 160, width: 40, height: 30)
        randomButton.titleLabel?.font = APP.font(15)
        randomButton.setTitleColor(AppTheme.textColor, for: .normal)
        randomButton.setTitle("随机", for: .normal)
        view.addSubview(randomButton)
        randomButton.app.addTouch { _ in
            let hasDigit = Bool.random()
            if hasDigit {
                odometerView.setNumber("$\(arc4random() % 1000).\(arc4random() % 100)")
            } else {
                odometerView.setNumber("$\(arc4random() % 1000)")
            }
        }

        var button1 = UIButton(type: .system)
        button1.frame = CGRect(x: 25, y: 205, width: 150, height: 50)
        button1.isEnabled = false
        button1.setTitle("System不可点", for: .normal)
        button1.setTitleColor(UIColor.black, for: .normal)
        button1.backgroundColor = APP.color(0xFFDA00)
        button1.app.setCornerRadius(5)
        view.addSubview(button1)

        var button2 = UIButton(type: .system)
        button2.frame = CGRect(x: 200, y: 205, width: 150, height: 50)
        button2.setTitle("System可点击", for: .normal)
        button2.setTitleColor(UIColor.black, for: .normal)
        button2.backgroundColor = APP.color(0xFFDA00)
        button2.app.setCornerRadius(5)
        view.addSubview(button2)

        var button3 = UIButton(type: .custom)
        button3.frame = CGRect(x: 25, y: 270, width: 150, height: 50)
        button3.isEnabled = false
        button3.setTitle("Custom不可点", for: .normal)
        button3.setTitleColor(UIColor.black, for: .normal)
        button3.backgroundColor = APP.color(0xFFDA00)
        button3.app.setCornerRadius(5)
        view.addSubview(button3)

        var button4 = UIButton(type: .custom)
        button4.frame = CGRect(x: 200, y: 270, width: 150, height: 50)
        button4.setTitle("Custom可点击", for: .normal)
        button4.setTitleColor(UIColor.black, for: .normal)
        button4.backgroundColor = APP.color(0xFFDA00)
        button4.app.setCornerRadius(5)
        view.addSubview(button4)

        button1 = UIButton(type: .system)
        button1.frame = CGRect(x: 25, y: 335, width: 150, height: 50)
        button1.isEnabled = false
        button1.app.disabledAlpha = UIButton.app.disabledAlpha
        button1.setTitle("System不可点2", for: .normal)
        button1.setTitleColor(UIColor.black, for: .normal)
        button1.backgroundColor = APP.color(0xFFDA00)
        button1.app.setCornerRadius(5)
        view.addSubview(button1)

        button2 = UIButton(type: .system)
        button2.frame = CGRect(x: 200, y: 335, width: 150, height: 50)
        button2.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button2.setTitle("System可点击2", for: .normal)
        button2.setTitleColor(UIColor.black, for: .normal)
        button2.backgroundColor = APP.color(0xFFDA00)
        button2.app.setCornerRadius(5)
        view.addSubview(button2)

        button3 = UIButton(type: .custom)
        button3.frame = CGRect(x: 25, y: 400, width: 150, height: 50)
        button3.isEnabled = false
        button3.app.disabledAlpha = UIButton.app.disabledAlpha
        button3.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button3.setTitle("Custom不可点2", for: .normal)
        button3.setTitleColor(UIColor.black, for: .normal)
        button3.backgroundColor = APP.color(0xFFDA00)
        button3.app.setCornerRadius(5)
        view.addSubview(button3)

        button4 = UIButton(type: .custom)
        button4.frame = CGRect(x: 200, y: 400, width: 150, height: 50)
        button4.app.disabledAlpha = UIButton.app.disabledAlpha
        button4.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button4.setTitle("Custom可点击2", for: .normal)
        button4.setTitleColor(UIColor.black, for: .normal)
        button4.backgroundColor = APP.color(0xFFDA00)
        button4.app.setCornerRadius(5)
        view.addSubview(button4)

        button1 = UIButton(type: .custom)
        button1.frame = CGRect(x: 25, y: 465, width: 150, height: 50)
        button1.backgroundColor = APP.color(0xFFDA00)
        button1.app.setCornerRadius(5)
        button1.app.disabledAlpha = UIButton.app.disabledAlpha
        button1.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button1.app.setTitle("按钮文字", font: APP.font(10), titleColor: .black)
        button1.app.setImage(UIImage.app.appIconImage()?.app.image(scaleSize: CGSize(width: 24, height: 24)))
        button1.app.setImageEdge(.top, spacing: 4)
        view.addSubview(button1)

        button2 = UIButton(type: .custom)
        button2.frame = CGRect(x: 200, y: 465, width: 150, height: 50)
        button2.backgroundColor = APP.color(0xFFDA00)
        button2.app.setCornerRadius(5)
        button2.app.disabledAlpha = UIButton.app.disabledAlpha
        button2.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button2.app.setTitle("按钮文字", font: APP.font(10), titleColor: .black)
        button2.app.setImage(UIImage.app.appIconImage()?.app.image(scaleSize: CGSize(width: 24, height: 24)))
        button2.app.setImageEdge(.left, spacing: 4)
        view.addSubview(button2)

        button3 = UIButton(type: .custom)
        button3.frame = CGRect(x: 25, y: 530, width: 150, height: 50)
        button3.backgroundColor = APP.color(0xFFDA00)
        button3.app.setCornerRadius(5)
        button3.app.disabledAlpha = UIButton.app.disabledAlpha
        button3.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button3.app.setTitle("按钮文字", font: APP.font(10), titleColor: .black)
        button3.app.setImage(UIImage.app.appIconImage()?.app.image(scaleSize: CGSize(width: 24, height: 24)))
        button3.app.setImageEdge(.bottom, spacing: 4)
        view.addSubview(button3)

        button4 = UIButton(type: .custom)
        button4.frame = CGRect(x: 200, y: 530, width: 150, height: 50)
        button4.backgroundColor = APP.color(0xFFDA00)
        button4.app.setCornerRadius(5)
        button4.app.disabledAlpha = UIButton.app.disabledAlpha
        button4.app.highlightedAlpha = UIButton.app.highlightedAlpha
        button4.app.setTitle("按钮文字", font: APP.font(10), titleColor: .black)
        button4.app.setImage(UIImage.app.appIconImage()?.app.image(scaleSize: CGSize(width: 24, height: 24)))
        button4.app.setImageEdge(.right, spacing: 4)
        view.addSubview(button4)
    }

    @objc func onClick1(_ sender: UIButton) {
        count += 1
        showCount()
    }

    @objc func onClick2(_ sender: UITapGestureRecognizer) {
        count += 1
        showCount()
    }

    @objc func onClick3(_ sender: UIButton) {
        count += 1
        showCount()

        sender.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            sender.isEnabled = true
        }
    }

    @objc func onClick4(_ sender: UITapGestureRecognizer) {
        count += 1
        showCount()

        sender.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            sender.isEnabled = true
        }
    }

    @objc func onClick5(_ sender: UIButton) {
        count += 1
        showCount()
    }

    func showCount() {
        UIWindow.app.showMessage(text: "点击计数：\(count)")
    }
}

public class OdometerView: UIView {
    public var textFont: UIFont = .systemFont(ofSize: UIFont.systemFontSize)
    public var textColor: UIColor = .black

    public var duration: CFTimeInterval = 1.5
    public var durationOffset: CFTimeInterval = 0.2

    private var numbersText: [String] = []
    private var scrollLayers: [CAScrollLayer] = []
    private var textLayers: [CATextLayer] = []
    private var number: String = ""
    private var lastNumber: String = ""
    private var animateCount: Int = 0
    private var animationKey = "OdometerAnimation"
    private var density: Int = 9
    private var isReverse = false

    public func setNumber(_ number: String, animated: Bool = true) {
        stopAnimations()
        self.number = number
        prepareAnimations(animated: animated)
        invalidateIntrinsicContentSize()
        createAnimations()
    }

    override public var intrinsicContentSize: CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        for i in 0..<number.count {
            let digit = number.app.substring(with: NSMakeRange(i, 1))
            let size = numberSize(digit)
            height = max(height, size.height)
            width += size.width
        }
        return CGSize(width: width, height: height)
    }

    private func stopAnimations() {
        if animateCount > 0 {
            lastNumber = number
        }

        for scrollLayer in scrollLayers {
            scrollLayer.removeAnimation(forKey: animationKey)
            scrollLayer.removeFromSuperlayer()
        }

        numbersText.removeAll()
        scrollLayers.removeAll()
        textLayers.removeAll()
    }

    private func prepareAnimations(animated: Bool) {
        isReverse = numberValue(number) < numberValue(lastNumber)
        let animated = animated && lastNumber != "" && number != lastNumber
        let numberParts = number.components(separatedBy: ".")
        let lastParts = lastNumber.components(separatedBy: ".")

        var startNumber = ""
        let endNumber = number
        if numberParts.count > 1 {
            let firstNumber = prepareNumber(startNumber: lastParts.first ?? "", endNumber: numberParts.first ?? "")
            let digitNumber = prepareNumber(startNumber: lastParts.count > 1 ? (lastParts.last ?? "") : "", endNumber: numberParts.last ?? "", isDigit: true)
            startNumber = "\(firstNumber).\(digitNumber)"
        } else {
            startNumber = prepareNumber(startNumber: lastParts.first ?? "", endNumber: endNumber)
        }

        var lastFrame: CGRect = .zero
        for i in 0..<endNumber.count {
            let startDigit = startNumber.app.substring(with: NSMakeRange(i, 1))
            let endDigit = endNumber.app.substring(with: NSMakeRange(i, 1))

            let size = numberSize(endDigit)
            lastFrame.origin.y = max(0, (frame.height - size.height) / 2.0)
            let scrollLayer = CAScrollLayer()
            scrollLayer.frame = CGRect(x: lastFrame.maxX, y: lastFrame.minY, width: size.width, height: size.height)
            lastFrame = scrollLayer.frame
            scrollLayers.append(scrollLayer)
            layer.addSublayer(scrollLayer)

            createContent(scrollLayer: scrollLayer, startDigit: startDigit, endDigit: endDigit, animated: animated)
            numbersText.append(endDigit)
        }
    }

    private func prepareNumber(startNumber: String, endNumber: String, isDigit: Bool = false) -> String {
        var result = startNumber
        let zeroCount = endNumber.count - startNumber.count
        if zeroCount >= 0 {
            for _ in 0..<zeroCount {
                result = isDigit ? result + "0" : "0" + result
            }
        } else {
            result = isDigit ? result.app.substring(to: abs(zeroCount)) : result.app.substring(from: abs(zeroCount))
        }
        return result
    }

    private func createAnimations() {
        let duration: CFTimeInterval = duration - Double(numbersText.count) * durationOffset
        var offset: CFTimeInterval = 0
        for scrollLayer in scrollLayers {
            let maxY: CGFloat = scrollLayer.sublayers?.last?.frame.origin.y ?? 0
            let animation = CABasicAnimation(keyPath: "sublayerTransform.translation.y")
            animation.duration = duration + offset
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            animation.fromValue = NSNumber(value: isReverse ? -maxY : 0)
            animation.toValue = NSNumber(value: isReverse ? 0 : -maxY)
            scrollLayer.add(animation, forKey: animationKey)

            offset += durationOffset
            beginAnimation()
            perform(#selector(finishAnimation), with: nil, afterDelay: animation.duration)
        }
    }

    private func createContent(scrollLayer: CAScrollLayer, startDigit: String, endDigit: String, animated: Bool) {
        var textForScroll: [String] = []
        if !animated || !isNumber(endDigit) || startDigit == endDigit {
            textForScroll.append(endDigit)
        } else {
            let digitValue = (startDigit as NSString).integerValue
            for i in 0..<density + 1 {
                let currentValue = (digitValue + 10 + (isReverse ? -i : i)) % 10
                textForScroll.append("\(currentValue)")
                if currentValue == (endDigit as NSString).integerValue {
                    break
                }
            }
            if isReverse {
                textForScroll = textForScroll.reversed()
            }
        }

        var offsetY: CGFloat = 0
        for text in textForScroll {
            let frame = CGRect(x: 0, y: offsetY, width: scrollLayer.frame.width, height: scrollLayer.frame.height)
            let textLayer = CATextLayer()
            textLayer.foregroundColor = textColor.cgColor
            textLayer.font = CGFont(textFont.fontName as CFString)
            textLayer.fontSize = textFont.pointSize
            textLayer.alignmentMode = .center
            textLayer.string = text
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.frame = frame
            scrollLayer.addSublayer(textLayer)
            textLayers.append(textLayer)
            offsetY = frame.maxY
        }
    }

    private func beginAnimation() {
        animateCount += 1
    }

    @objc private func finishAnimation() {
        animateCount -= 1

        if animateCount <= 0 {
            lastNumber = number
        }
    }

    private func numberValue(_ number: String) -> Double {
        let string = number.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.").inverted)
        let value = Double(string) ?? .zero
        return number.contains("-") ? -value : value
    }

    private func isNumber(_ number: String) -> Bool {
        var intNumber = 0
        let scanNumber = Scanner(string: number)
        let result = scanNumber.scanInt(&intNumber) && scanNumber.isAtEnd
        return result
    }

    private func numberSize(_ number: String) -> CGSize {
        let size = number.app.size(font: textFont)
        return APP.flat(size)
    }
}
