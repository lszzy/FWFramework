//
//  TestController.swift
//  Example
//
//  Created by wuyong on 2022/3/23.
//  Copyright © 2022 site.wuyong. All rights reserved.
//

import UIKit
import FWFramework

class TestController: UITableViewController {
    
    // MARK: - Accessor
    
    // MARK: - Subviews

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavbar()
        setupSubviews()
        setupConstraints()
        
        testCoder()
        testJson()
    }
    
}

// MARK: - Setup
private extension TestController {
    
    private func setupNavbar() {
        navigationItem.title = "test.title".fw.localized
        navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(), style: .plain, target: nil, action: nil)
    }
   
    private func setupSubviews() {
        
    }
    
    private func setupConstraints() {
        
    }
    
}

// MARK: - UITableView
extension TestController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(with: tableView)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}

// MARK: - Action
@objc private extension TestController {
    
}

// MARK: - Private
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
