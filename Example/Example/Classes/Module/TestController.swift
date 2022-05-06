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
    private var hasLeftItem = false
    
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
        view.fw.setBorderView(.top, color: UIColor.gray, width: UIScreen.fw.pixelOne)
        return view
    }()
    
    private lazy var textFieldLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.fw.themeLight(.black, dark: .white)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Test"
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = UIScreen.fw.pixelOne
        textField.layer.cornerRadius = 4
        textField.fw.touchResign = true
        return textField
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)

        setupNavbar()
        setupSubviews()
        setupConstraints()
        
        renderData()
        testCoder()
        testJson()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK: - Setup
private extension TestController {
    
    private func setupNavbar() {
        navigationItem.title = "test.title".fw.localized
        navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
        if hasLeftItem {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "navBack"), style: .plain, target: self, action: #selector(leftItemClicked(_:)))
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(rightItemClicked(_:)))
    }
   
    private func setupSubviews() {
        view.backgroundColor = UIColor.fw.themeLight(.white, dark: .black)
        
        view.addSubview(tableView)
        view.addSubview(textFieldView)
        textFieldView.addSubview(textFieldLabel)
        textFieldView.addSubview(textField)
    }
    
    private func setupConstraints() {
        tableView.fw.layoutMaker { make in
            make.left().right().top()
        }
        textFieldView.fw.layoutMaker { make in
            make.topToBottomOfView(tableView)
            make.left().right().height(100).bottom(UIScreen.fw.safeAreaInsets.bottom)
        }
        textFieldLabel.fw.layoutMaker { make in
            make.left(15).right(15).top(10)
        }
        textField.fw.layoutMaker { make in
            make.left(15).right(15).bottom(10).height(25)
        }
    }
    
    private func renderData() {
        let attributedText = NSMutableAttributedString(string: "我是超过一行的文本，我可以显示两行，还可以显示图片，不信你看嘛")
        attributedText.append(NSAttributedString.fw.attributedString(with: UIImage(named: "iconHelp"), bounds: CGRect(x: 5, y: round(UIFont.systemFont(ofSize: 16).capHeight - 16) / 2.0, width: 16, height: 16)))
        textFieldLabel.attributedText = attributedText
    }
    
}

// MARK: - UITableView
extension TestController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(with: tableView)
        cell.textLabel?.text = "test.title".fw.localized
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        textFieldView.fw.layoutChain.bottom(UIScreen.fw.safeAreaInsets.bottom)
        
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
    
    func tableCellSelected(_ indexPath: IndexPath) {
        let viewController = TestController()
        viewController.hasLeftItem = !hasLeftItem
        navigationController?.pushViewController(viewController, animated: true)
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
        var model = FWJSON(["id": 1, "info": ["name": "NAME"], "list": ["VAL1"]])
        
        var id = model["id"].intValue
        var name = model["info"]["name"].stringValue
        var list = model["list"][0].stringValue
        print("json: id => \(id), name => \(name), list => \(list)")
        
        id = model.id.intValue
        name = model.info.name.stringValue
        list = model.list.0.stringValue
        print("json: id => \(id), name => \(name), list => \(list)")
        
        model.id = 2
        model.name = FWJSON("NAME2")
        model.list.0 = "VAL2"
        id = model.id.intValue
        name = model.info.name.stringValue
        list = model.list.0.stringValue
        print("json: id => \(id), name => \(name), list => \(list)")
    }
    
}
