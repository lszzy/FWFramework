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
    var amount: Float = 0
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
        id = try decoder.decode("id")
        name = try decoder.decode("name")
        if let int = try? decoder.decodeIf("age", as: Int.self) {
            age = int
        } else if let string = try? decoder.decodeIf("age", as: String.self) {
            age = Int(string) ?? .zero
        }
        amount = try decoder.decode("amount")
        any = try decoder.decodeAnyIf("any")
        dict = try decoder.decodeIf("dict")
        array = try decoder.decodeIf("array")
        optional1 = try decoder.decodeIf("optional1") ?? ""
        if let value2 = try decoder.decodeIf("optional2", as: String.self) {
            optional2 = value2
        }
        if let value3 = try decoder.decodeIf("optional3", as: String.self) {
            optional3 = value3
        }
        optional4 = try decoder.decodeIf("optional4", as: Int?.self) ?? nil
        if let value5 = try decoder.decodeIf("optional5", as: Int.self) {
            optional5 = value5
        }
        sub = try decoder.decodeIf("sub")
        if let val2 = try decoder.decodeIf("sub2", as: TestCodableSubModel.self) {
            sub2 = val2
        }
        subs = try decoder.decodeIf("subs") ?? []
        enum1 = try decoder.decode("enum1")
        if let val2 = try? decoder.decodeIf("enum2", as: TestCodableEnum.self) {
            enum2 = val2
        }
        enum3 = try? decoder.decodeIf("enum3")
    }
    
    func encode(to encoder: any Encoder) throws {
        try encoder.encode(id, for: "id")
        try encoder.encode(name, for: "name")
        try encoder.encodeIf(age, for: "age")
        try encoder.encode(amount, for: "amount")
        try encoder.encodeAnyIf(any, for: "any")
        try encoder.encodeIf(dict, for: "dict")
        try encoder.encodeIf(array, for: "array")
        try encoder.encodeIf(optional1, for: "optional1")
        try encoder.encodeIf(optional2, for: "optional2")
        try encoder.encodeIf(optional3, for: "optional3")
        try encoder.encodeIf(optional4, for: "optional4")
        try encoder.encodeIf(optional5, for: "optional5")
        try encoder.encodeIf(sub, for: "sub")
        try encoder.encodeIf(sub2, for: "sub2")
        try encoder.encodeIf(subs, for: "subs")
        try encoder.encode(enum1, for: "enum1")
        try encoder.encodeIf(enum2, for: "enum2")
        try encoder.encodeIf(enum3, for: "enum3")
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

struct TestJSONCodableModel: CodableModel {
    var id: Int = 0
    var name: String = ""
    var age: Int?
    var amount: Float = 0
    var any: Any?
    var dict: [AnyHashable: Any]?
    var array: [Any]?
    var optional1: String = ""
    var optional2: String = ""
    var optional3: String? = "default"
    var optional4: Int?
    var optional5: Int? = 5
    var sub: TestJSONCodableSubModel?
    var sub2: TestJSONCodableSubModel = .init()
    var subs: [TestJSONCodableSubModel] = []
    var enum1: TestJSONCodableEnum = .unknown
    var enum2: TestJSONCodableEnum = .unknown
    var enum3: TestJSONCodableEnum?
    
    init() {}
    
    init(from decoder: any Decoder) throws {
        id = try decoder.value("id")
        name = try decoder.value("name")
        age = try decoder.valueIf("age")
        amount = try decoder.value("amount")
        any = try decoder.valueAnyIf("any")
        dict = try decoder.valueIf("dict")
        array = try decoder.valueIf("array")
        optional1 = try decoder.valueIf("optional1") ?? ""
        if let value2 = try decoder.valueIf("optional2", as: String.self) {
            optional2 = value2
        }
        if let value3 = try decoder.valueIf("optional3", as: String.self) {
            optional3 = value3
        }
        optional4 = try decoder.valueIf("optional4", as: Int?.self) ?? nil
        if let value5 = try decoder.valueIf("optional5", as: Int.self) {
            optional5 = value5
        }
        sub = try decoder.valueIf("sub")
        if let val2 = try decoder.valueIf("sub2", as: TestJSONCodableSubModel.self) {
            sub2 = val2
        }
        subs = try decoder.valueIf("subs") ?? []
        enum1 = try decoder.value("enum1")
        if let val2 = try decoder.valueIf("enum2", as: TestJSONCodableEnum.self) {
            enum2 = val2
        }
        enum3 = try decoder.valueIf("enum3")
    }
    
    func encode(to encoder: any Encoder) throws {
        try encoder.encode(id, for: "id")
        try encoder.encode(name, for: "name")
        try encoder.encodeIf(age, for: "age")
        try encoder.encode(amount, for: "amount")
        try encoder.encodeAnyIf(any, for: "any")
        try encoder.encodeIf(dict, for: "dict")
        try encoder.encodeIf(array, for: "array")
        try encoder.encodeIf(optional1, for: "optional1")
        try encoder.encodeIf(optional2, for: "optional2")
        try encoder.encodeIf(optional3, for: "optional3")
        try encoder.encodeIf(optional4, for: "optional4")
        try encoder.encodeIf(optional5, for: "optional5")
        try encoder.encodeIf(sub, for: "sub")
        try encoder.encodeIf(sub2, for: "sub2")
        try encoder.encodeIf(subs, for: "subs")
        try encoder.encode(enum1, for: "enum1")
        try encoder.encodeIf(enum2, for: "enum2")
        try encoder.encodeIf(enum3, for: "enum3")
    }
}

struct TestJSONCodableSubModel: Codable {
    var id: Int = 0
    var name: String?
}

enum TestJSONCodableEnum: String, Codable {
    case test = "test"
    case unknown = ""
}

struct TestAutoCodableModel: CodableModel, AutoCodable {
    @CodableValue var id: Int = 0
    @CodableValue var name: String = ""
    @CodableValue var age: Int?
    @CodableValue var amount: Float = 0
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
    var amount: Float = 0
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
            ["CodableModel+JSON", "onJSONCodableModel"],
            ["CodableModel+AutoCodable", "onAutoCodableModel"],
            ["JSONModel", "onJSONModel"],
        ])
    }
    
}

extension TestCodableController {
    
    func testCodableData() -> [AnyHashable: Any] {
        return [
            "id": 1,
            "name": "name",
            "age": "2",
            "amount": 100,
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
        ]
    }
    
    @objc func onCodableModel() {
        func testModel(_ model: TestCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                (model != nil),
                (model?.id == 1),
                (model?.name == "name"),
                (model?.age == 2),
                (model?.amount == 100.0),
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
            return results
        }
        
        var model: TestCodableModel? = TestCodableModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestCodableModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        app.showMessage(text: tests.count == tests.filter({ $0 }).count ? "✅ 测试通过 (\(tests.count))" : "❌ 测试失败 (\(tests.filter({ !$0 }).count))")
    }
    
    @objc func onJSONCodableModel() {
        func testModel(_ model: TestJSONCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                (model != nil),
                (model?.id == 1),
                (model?.name == "name"),
                (model?.age == 2),
                (model?.amount == 100.0),
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
            return results
        }
        
        var model: TestJSONCodableModel? = TestJSONCodableModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestJSONCodableModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        app.showMessage(text: tests.count == tests.filter({ $0 }).count ? "✅ 测试通过 (\(tests.count))" : "❌ 测试失败 (\(tests.filter({ !$0 }).count))")
    }
    
    @objc func onAutoCodableModel() {
        func testModel(_ model: TestAutoCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                (model != nil),
                (model?.id == 1),
                (model?.name == "name"),
                (model?.age == 2),
                (model?.amount == 100.0),
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
            return results
        }
        
        var model: TestAutoCodableModel? = TestAutoCodableModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestAutoCodableModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        app.showMessage(text: tests.count == tests.filter({ $0 }).count ? "✅ 测试通过 (\(tests.count))" : "❌ 测试失败 (\(tests.filter({ !$0 }).count))")
    }
    
    @objc func onJSONModel() {
        func testModel(_ model: TestJSONModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                (model != nil),
                (model?.id == 1),
                (model?.name == "name"),
                (model?.age == 2),
                (model?.amount == 100.0),
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
            return results
        }
        
        var model: TestJSONModel? = TestJSONModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestJSONModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        app.showMessage(text: tests.count == tests.filter({ $0 }).count ? "✅ 测试通过 (\(tests.count))" : "❌ 测试失败 (\(tests.filter({ !$0 }).count))")
    }
    
}
