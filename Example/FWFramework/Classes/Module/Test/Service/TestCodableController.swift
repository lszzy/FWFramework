//
//  TestCodableController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

struct TestCodableModel: CodableModel, AutoCodable {
    @CodableValue var id: Int = 0
    @CodableValue var name: String = ""
    @CodableValue var age: Int?
    @CodableValue var optional1: String = ""
    @CodableValue var optional2: String = ""
    @CodableValue var optional3: String? = "default"
    @CodableValue var optional4: Int? = 4
    @CodableValue var optional5: Int? = 5
    @CodableValue var sub: TestSubCodableModel?
    @CodableValue var sub2: TestSubCodableModel = .init()
    @CodableValue var subs: [TestSubCodableModel] = []
    @CodableValue var enum1: TestCodableModelEnum = .unknown
    @CodableValue var enum2: TestCodableModelEnum = .unknown
    @CodableValue var enum3: TestCodableModelEnum?
}

struct TestSubCodableModel: CodableModel {
    var id: Int = 0
    var name: String?
}

enum TestCodableModelEnum: String, Codable {
    case test = "test"
    case unknown = ""
}

struct TestJSONModel: JSONModel {
    var id: Int = 0
    var name: String = ""
    var age: Int?
    var any: Any?
    var dict: [AnyHashable: Any]?
    var array: [Any]?
    var optional1: String = ""
    var optional2: String = ""
    var optional3: String? = "default"
    var optional4: Int? = 4
    var optional5: Int? = 5
    var sub: TestSubJSONModel?
    var sub2: TestSubJSONModel = .init()
    var subs: [TestSubJSONModel] = []
    var enum1: TestJSONModelEnum = .unknown
    var enum2: TestJSONModelEnum = .unknown
    var enum3: TestJSONModelEnum?
}

struct TestSubJSONModel: JSONModel {
    var id: Int = 0
    var name: String?
}

enum TestJSONModelEnum: String, JSONModelEnum {
    case test = "test"
    case unknown = ""
}

class TestCodableController: UIViewController, TableViewControllerProtocol {
    
    typealias TableElement = [String]
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.app.cell(tableView: tableView)
        let rowData = tableData[indexPath.row]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData[indexPath.row]
        app.invokeMethod(NSSelectorFromString(rowData[1]))
    }
    
    func setupSubviews() {
        tableData.append(contentsOf: [
            ["CodableModel", "onCodableModel"],
            ["JSONModel", "onJSONModel"],
        ])
    }
    
}

extension TestCodableController {
    
    @objc func onCodableModel() {
        let model: TestCodableModel? = TestCodableModel.decodeModel(from: [
            "id": 1,
            "name": "name",
            "age": "2",
            "optional1": NSNull(),
            "optional4": [:],
            "sub": [
                "id": 2,
                "name": "sub",
            ],
            "subs": [
                [
                    "id": 3,
                    "name": "subs",
                ],
            ],
            "enum1": "test",
            "enum2": "unknown",
            "enum3": "unknown",
        ])
        
        var success: Bool = true
        success = success && (model != nil)
        success = success && (model?.id == 1)
        success = success && (model?.name == "name")
        success = success && (model?.age == 2)
        success = success && (model?.optional1 == "")
        success = success && (model?.optional2 == "")
        success = success && (model?.optional3 == "default")
        success = success && (model?.optional4 == nil)
        success = success && (model?.optional5 == 5)
        success = success && (model?.sub?.name == "sub")
        success = success && (model?.sub2 != nil)
        success = success && (model?.subs.first?.name == "subs")
        success = success && (model?.enum1 == .test)
        success = success && (model?.enum2 == .unknown)
        success = success && (model?.enum3 == nil)
        
        app.showMessage(text: success ? "✅ 测试通过" : "❌ 测试失败")
    }
    
    @objc func onJSONModel() {
        let model: TestJSONModel? = TestJSONModel.decodeModel(from: [
            "id": 1,
            "name": "name",
            "age": "2",
            "any": "any",
            "dict": [:],
            "array": [1],
            "optional1": NSNull(),
            "optional4": [:],
            "sub": [
                "id": 2,
                "name": "sub",
            ],
            "subs": [
                [
                    "id": 3,
                    "name": "subs",
                ],
            ],
            "enum1": "test",
            "enum2": "unknown",
            "enum3": "unknown",
        ])
        
        var success: Bool = true
        success = success && (model != nil)
        success = success && (model?.id == 1)
        success = success && (model?.name == "name")
        success = success && (model?.age == 2)
        success = success && (String.app.safeString(model?.any) == "any")
        success = success && (model?.dict != nil)
        success = success && ((model?.array as? [Int])?.first == 1)
        success = success && (model?.optional1 == "")
        success = success && (model?.optional2 == "")
        success = success && (model?.optional3 == "default")
        success = success && (model?.optional4 == nil)
        success = success && (model?.optional5 == 5)
        success = success && (model?.sub?.name == "sub")
        success = success && (model?.sub2 != nil)
        success = success && (model?.subs.first?.name == "subs")
        success = success && (model?.enum1 == .test)
        success = success && (model?.enum2 == .unknown)
        success = success && (model?.enum3 == nil)
        
        app.showMessage(text: success ? "✅ 测试通过" : "❌ 测试失败")
    }
    
}
