//
//  TestCodableController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

struct TestCodableModel: CodableModel {
    var id: Int = 0
    var name: String = ""
    var age: Int?
    var any: Any?
    var dict: [AnyHashable: Any]?
    var array: [Any]?
    var optional1: String = ""
    var optional2: String = ""
    var optional3: String? = "default"
    var optional4: Int?
    var optional5: Int? = 5
    var sub: TestCodableSubModel?
    var sub2: TestCodableSubModel = .init()
    var subs: [TestCodableSubModel] = []
    var enum1: TestCodableEnum = .unknown
    var enum2: TestCodableEnum = .unknown
    var enum3: TestCodableEnum?
    
    init() {}
    
    init(from decoder: any Decoder) throws {
        self.init()
    }
    
    func encode(to encoder: any Encoder) throws {
        
    }
}

struct TestCodableSubModel: Codable {
    var id: Int = 0
    var name: String?
}

enum TestCodableEnum: String, Codable {
    case test = "test"
    case unknown = ""
}

struct TestAutoCodableModel: CodableModel, AutoCodable {
    @CodableValue var id: Int = 0
    @CodableValue var name: String = ""
    @CodableValue var age: Int?
    @CodableValue var any: Any?
    @CodableValue var dict: [AnyHashable: Any]?
    @CodableValue var array: [Any]?
    @CodableValue var optional1: String = ""
    @CodableValue var optional2: String = ""
    @CodableValue var optional3: String? = "default"
    @CodableValue var optional4: Int?
    @CodableValue var optional5: Int? = 5
    @CodableValue var sub: TestAutoCodableSubModel?
    @CodableValue var sub2: TestAutoCodableSubModel = .init()
    @CodableValue var subs: [TestAutoCodableSubModel] = []
    @CodableValue var enum1: TestAutoCodableModelEnum = .unknown
    @CodableValue var enum2: TestAutoCodableModelEnum = .unknown
    @CodableValue var enum3: TestAutoCodableModelEnum?
}

struct TestAutoCodableSubModel: CodableModel {
    var id: Int = 0
    var name: String?
}

enum TestAutoCodableModelEnum: String, Codable {
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
    var optional4: Int?
    var optional5: Int? = 5
    var sub: TestJSONSubModel?
    var sub2: TestJSONSubModel = .init()
    var subs: [TestJSONSubModel] = []
    var enum1: TestJSONModelEnum = .unknown
    var enum2: TestJSONModelEnum = .unknown
    var enum3: TestJSONModelEnum?
}

struct TestJSONSubModel: JSONModel {
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
            ["AutoCodable", "onAutoCodable"],
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
        
        let tests: [Bool] = [
            (model != nil),
            (model?.id == 1),
            (model?.name == "name"),
            (model?.age == 2),
            (String.app.safeString(model?.any) == "any"),
            (model?.dict != nil),
            ((model?.array as? [Int])?.first == 1),
            (model?.optional1 == ""),
            (model?.optional2 == ""),
            (model?.optional3 == "default"),
            (model?.optional4 == nil),
            (model?.optional5 == 5),
            (model?.sub?.name == "sub"),
            (model?.sub2 != nil),
            (model?.subs.first?.name == "subs"),
            (model?.enum1 == .test),
            (model?.enum2 == .unknown),
            (model?.enum3 == nil),
        ]
        
        app.showMessage(text: tests.count == tests.filter({ $0 }).count ? "✅ 测试通过 (\(tests.count))" : "❌ 测试失败 (\(tests.filter({ !$0 }).count))")
    }
    
    @objc func onAutoCodable() {
        let model: TestAutoCodableModel? = TestAutoCodableModel.decodeModel(from: [
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
        
        let tests: [Bool] = [
            (model != nil),
            (model?.id == 1),
            (model?.name == "name"),
            (model?.age == 2),
            (String.app.safeString(model?.any) == "any"),
            (model?.dict != nil),
            ((model?.array as? [Int])?.first == 1),
            (model?.optional1 == ""),
            (model?.optional2 == ""),
            (model?.optional3 == "default"),
            (model?.optional4 == nil),
            (model?.optional5 == 5),
            (model?.sub?.name == "sub"),
            (model?.sub2 != nil),
            (model?.subs.first?.name == "subs"),
            (model?.enum1 == .test),
            (model?.enum2 == .unknown),
            (model?.enum3 == nil),
        ]
        
        app.showMessage(text: tests.count == tests.filter({ $0 }).count ? "✅ 测试通过 (\(tests.count))" : "❌ 测试失败 (\(tests.filter({ !$0 }).count))")
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
        
        let tests: [Bool] = [
            (model != nil),
            (model?.id == 1),
            (model?.name == "name"),
            (model?.age == 2),
            (String.app.safeString(model?.any) == "any"),
            (model?.dict != nil),
            ((model?.array as? [Int])?.first == 1),
            (model?.optional1 == ""),
            (model?.optional2 == ""),
            (model?.optional3 == "default"),
            (model?.optional4 == nil),
            (model?.optional5 == 5),
            (model?.sub?.name == "sub"),
            (model?.sub2 != nil),
            (model?.subs.first?.name == "subs"),
            (model?.enum1 == .test),
            (model?.enum2 == .unknown),
            (model?.enum3 == nil),
        ]
        
        app.showMessage(text: tests.count == tests.filter({ $0 }).count ? "✅ 测试通过 (\(tests.count))" : "❌ 测试失败 (\(tests.filter({ !$0 }).count))")
    }
    
}
