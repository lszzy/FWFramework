//
//  TestController.swift
//  Example
//
//  Created by wuyong on 2022/3/23.
//  Copyright © 2022 site.wuyong. All rights reserved.
//

import UIKit
import FWFramework

class TestController: UIViewController {
    
    // MARK: - Accessor
    private var confirmBack = false
    
    override var shouldPopController: Bool {
        if confirmBack {
            showAlertController()
            return false
        }
        return true
    }
    
    // MARK: - Subviews
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    private lazy var textFieldView: UIView = {
        let view = UIView()
        view.fw.setBorderView(.top, color: UIColor.gray, width: FW.pixelOne)
        return view
    }()
    
    private lazy var textFieldLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.fw.themeLight(.black, dark: .white)
        label.numberOfLines = 0
        label.fw.addLinkGesture { [weak self] link in
            self?.helpIconClicked(link)
        }
        return label
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Test"
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = FW.pixelOne
        textField.layer.cornerRadius = 4
        textField.fw.touchResign = true
        textField.fw.toolbarPreviousButton = nil
        textField.fw.toolbarNextButton = nil
        textField.fw.addToolbar(title: "Test", doneBlock: nil)
        return textField
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)

        setupNavbar()
        setupSubviews()
        setupLayout()
        
        renderData()
        testCoder()
        testJson()
        testWrapper()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK: - Setup
private extension TestController {
    
    private func setupNavbar() {
        navigationItem.title = "test.title".fw.localized
        if (navigationController?.children.count ?? 0) > 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBack"), style: .plain, target: self, action: #selector(leftItemClicked(_:)))
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "切换", style: .plain, target: self, action: #selector(rightItemClicked(_:)))
    }
   
    private func setupSubviews() {
        view.backgroundColor = UIColor.fw.themeLight(.white, dark: .black)
        
        view.addSubview(tableView)
        view.addSubview(textFieldView)
        textFieldView.addSubview(textFieldLabel)
        textFieldView.addSubview(textField)
    }
    
    private func setupLayout() {
        tableView.fw.layoutMaker { make in
            make.left().right().top()
        }
        textFieldView.fw.layoutMaker { make in
            make.top(toViewBottom: tableView)
            make.left().right().height(100).bottom(FW.safeAreaInsets.bottom)
        }
        textFieldLabel.fw.layoutMaker { make in
            make.left(15).right(15).top(10)
        }
        textField.fw.layoutMaker { make in
            make.left(15).right(15).bottom(10).height(25)
        }
    }
    
    private func renderData() {
        let attributedText = NSMutableAttributedString(string: "我是超过一行的文本，我可以显示图片，还可以点击图片，不信你看嘛", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        let imageAttachment = NSMutableAttributedString(attributedString: NSAttributedString.fw.attributedString(image: UIImage(named: "iconHelp"), bounds: CGRect(x: 5, y: (UIFont.systemFont(ofSize: 16).capHeight - 16) / 2.0, width: 16, height: 16)))
        imageAttachment.addAttribute(.link, value: "app://test", range: NSMakeRange(0, imageAttachment.length))
        attributedText.append(imageAttachment)
        textFieldLabel.attributedText = attributedText
    }
    
}

// MARK: - UITableView
extension TestController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView)
        cell.textLabel?.text = "test.title".fw.localized
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tableCellSelected(indexPath)
    }
    
}

// MARK: - Action
@objc private extension TestController {
    
    func keyboardWillShow(_ notification: Notification) {
        let keyboardHeight = textField.fw.keyboardHeight(notification)
        textFieldView.fw.layoutChain.bottom(keyboardHeight)
        
        textField.fw.keyboardAnimate(notification) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        textFieldView.fw.layoutChain.bottom(FW.safeAreaInsets.bottom)
        
        textField.fw.keyboardAnimate(notification) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    func leftItemClicked(_ sender: Any) {
        if shouldPopController {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func rightItemClicked(_ sender: Any) {
        confirmBack = !confirmBack
    }
    
    func helpIconClicked(_ link: Any) {
        toolbarItems = [
            UIBarButtonItem.fw.item(object: "取消", block: { [weak self] _ in
                self?.navigationController?.setToolbarHidden(true, animated: true)
            }),
            UIBarButtonItem.fw.item(object: "打开", block: { [weak self] _ in
                self?.navigationController?.setToolbarHidden(true, animated: true)
                Router.openURL(link)
            }),
        ]
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    func tableCellSelected(_ indexPath: IndexPath) {
        Router.openURL(AppRouter.testUrl)
    }
    
}

// MARK: - Private
private extension TestController {
    
    func showAlertController() {
        let alertController = UIAlertController(title: nil, message: "Are you sure?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: { _ in
        }))
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }))
        present(alertController, animated: true)
    }
    
}

// MARK: - Coder
private extension TestController {
    
    struct Article: Codable {
        var title: String
        var body: String?

        init(from decoder: Decoder) throws {
            title = try decoder.decode("title")
            body = try decoder.decode("body")
        }
        
        func encode(to encoder: Encoder) throws {
            try encoder.encode(title, for: "title")
            try encoder.encode(body, for: "body")
        }
    }
    
    func testCoder() {
        let json = ["title": "TITLE", "body": "BODY"]
        guard let data = Data.fw.jsonEncode(json) else { return }
        
        guard let article = try? data.fw.decoded() as Article else { return }
        print("decode: title => \(article.title), body => \(article.body ?? "")")
        guard let articleData = try? Data.fw.encoded(article) else { return }
        print("encode: \(articleData.fw.jsonDecode ?? "")")
        do {
            let articleDecode: Article = try articleData.fw.decoded()
            print("decode: title => \(articleDecode.title), body => \(articleDecode.body ?? "")")
        } catch {}
    }
    
    func testJson() {
        var model = JSON(["id": 1, "info": ["name": "NAME"], "list": ["VAL1"]])
        
        var id = model["id"].intValue
        var name = model["info"]["name"].stringValue
        var list = model["list"][0].stringValue
        print("json: id => \(id), name => \(name), list => \(list)")
        
        id = model.id.intValue
        name = model.info.name.stringValue
        list = model.list.0.stringValue
        print("json: id => \(id), name => \(name), list => \(list)")
        
        model.id = 2
        model.name = JSON("NAME2")
        model.list.0 = "VAL2"
        id = model.id.intValue
        name = model.info.name.stringValue
        list = model.list.0.stringValue
        print("json: id => \(id), name => \(name), list => \(list)")
    }
    
    func testWrapper() {
        // Success
        TestController.fw.testWrapper()
        let clazz1 = TestController.self
        clazz1.fw.testWrapper()
        let clazz2: AnyClass = TestController.self
        if let clazz = clazz2 as? TestController.Type {
            clazz.fw.testWrapper()
        }
        
        TestController.testWrapper()
        let clazz3 = TestController.self
        clazz3.testWrapper()
        let clazz4: AnyClass = TestController.self
        if let clazz = clazz4 as? TestController.Type {
            clazz.testWrapper()
        }
        
        let clazz5: UIViewController.Type = TestController.self
        clazz5.testWrapper()
        let clazz6: AnyClass = TestController.self
        if let clazz = clazz6 as? UIViewController.Type {
            clazz.testWrapper()
        }
        
        // Error
        let clazz7: UIViewController.Type = TestController.self
        clazz7.fw.testWrapper()
        let clazz8: AnyClass = TestController.self
        if let clazz = clazz8 as? UIViewController.Type {
            clazz.fw.testWrapper()
        }
    }
    
}

extension UIViewController {
    
    public static func testWrapper() {
        Self.fw.testWrapper()
        // Error
        // fw.testWrapper()
    }
    
}

extension Wrapper where Base: UIViewController {
    
    public static func testWrapper() {
        let controller = String(describing: Base.self)
        if controller == String(describing: TestController.self) {
            Logger.debug("wrapper succeed: \(controller)")
        } else {
            Logger.error("wrapper failed: \(controller)")
        }
    }
    
}
