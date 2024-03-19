//
//  TestCodableController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

// MARK: - TestCodableModel
struct TestCodableModel: CodableModel {
    var id: Int = 0
    var name: String = ""
    var age: Int?
    var amount: Float = 0
    var alias: String = ""
    var except: String = ""
    var camelName: String = ""
    var any: Any?
    var dict: [AnyHashable: Any]?
    var array: [Any]?
    var optional1: String = ""
    var optional2: String = ""
    var optional3: String? = "default"
    var optional4: Int? = 4
    var optional5: Int? = 0
    var sub: TestCodableSubModel?
    var sub2: TestCodableSubModel = .init()
    var subs: [TestCodableSubModel] = []
    var subdict: [String: TestCodableSubModel] = [:]
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
        alias = try decoder.decode("alias_key")
        camelName = try decoder.decode("camel_name")
        any = try decoder.decodeAnyIf("any")
        dict = try decoder.decodeAnyIf("dict")
        array = try decoder.decodeAnyIf("array")
        optional1 = try decoder.decodeIf("optional1") ?? ""
        if let value2 = try decoder.decodeIf("optional2", as: String.self) {
            optional2 = value2
        }
        if let value3 = try decoder.decodeIf("optional3", as: String.self) {
            optional3 = value3
        }
        // 类型不匹配解析失败时赋值nil, key不存在时不覆盖
        do {
            if let value4 = try decoder.decodeIf("optional4", as: Int?.self) {
                optional4 = value4
            }
        } catch {
            optional4 = nil
        }
        optional5 = try decoder.decodeIf("optional5", as: Int?.self) ?? nil
        sub = try decoder.decodeIf("sub")
        if let val2 = try decoder.decodeIf("sub2", as: TestCodableSubModel.self) {
            sub2 = val2
        }
        subs = try decoder.decodeIf("subs") ?? []
        subdict = try decoder.decodeIf("subdict") ?? [:]
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
        try encoder.encode(alias, for: "alias_key")
        try encoder.encode(camelName, for: "camel_name")
        try encoder.encodeAnyIf(any, for: "any")
        try encoder.encodeAnyIf(dict, for: "dict")
        try encoder.encodeAnyIf(array, for: "array")
        try encoder.encodeIf(optional1, for: "optional1")
        try encoder.encodeIf(optional2, for: "optional2")
        try encoder.encodeIf(optional3, for: "optional3")
        try encoder.encodeIf(optional4, for: "optional4")
        try encoder.encodeIf(optional5, for: "optional5")
        try encoder.encodeIf(sub, for: "sub")
        try encoder.encodeIf(sub2, for: "sub2")
        try encoder.encodeIf(subs, for: "subs")
        try encoder.encodeIf(subdict, for: "subdict")
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

// MARK: - TestJSONCodableModel
struct TestJSONCodableModel: CodableModel {
    var id: Int = 0
    var name: String = ""
    var age: Int?
    var amount: Float = 0
    var alias: String = ""
    var except: String = ""
    var camelName: String = ""
    var any: Any?
    var dict: [AnyHashable: Any]?
    var array: [Any]?
    var optional1: String = ""
    var optional2: String = ""
    var optional3: String? = "default"
    var optional4: Int? = 4
    var optional5: Int? = 0
    var sub: TestJSONCodableSubModel?
    var sub2: TestJSONCodableSubModel = .init()
    var subs: [TestJSONCodableSubModel] = []
    var subdict: [String: TestJSONCodableSubModel] = [:]
    var enum1: TestJSONCodableEnum = .unknown
    var enum2: TestJSONCodableEnum = .unknown
    var enum3: TestJSONCodableEnum?
    
    init() {}
    
    init(from decoder: any Decoder) throws {
        id = try decoder.value("id")
        name = try decoder.value("name")
        age = try decoder.valueIf("age")
        amount = try decoder.value("amount")
        alias = try decoder.value("alias_key")
        camelName = try decoder.value("camel_name")
        any = try decoder.valueAnyIf("any")
        dict = try decoder.valueAnyIf("dict")
        array = try decoder.valueAnyIf("array")
        optional1 = try decoder.valueIf("optional1") ?? ""
        if let value2 = try decoder.valueIf("optional2", as: String.self) {
            optional2 = value2
        }
        if let value3 = try decoder.valueIf("optional3", as: String.self) {
            optional3 = value3
        }
        // 类型不匹配解析失败时赋值nil, key不存在时不覆盖
        do {
            if let value4 = try decoder.valueIf("optional4", as: Int?.self) {
                optional4 = value4
            }
        } catch {
            optional4 = nil
        }
        optional5 = try decoder.valueIf("optional5", as: Int?.self) ?? nil
        sub = try decoder.valueIf("sub")
        if let val2 = try decoder.valueIf("sub2", as: TestJSONCodableSubModel.self) {
            sub2 = val2
        }
        subs = try decoder.valueIf("subs") ?? []
        subdict = try decoder.valueIf("subdict") ?? [:]
        enum1 = try decoder.value("enum1")
        if let val2 = try? decoder.valueIf("enum2", as: TestJSONCodableEnum.self) {
            enum2 = val2
        }
        enum3 = try? decoder.valueIf("enum3")
    }
    
    func encode(to encoder: any Encoder) throws {
        try encoder.encode(id, for: "id")
        try encoder.encode(name, for: "name")
        try encoder.encodeIf(age, for: "age")
        try encoder.encode(amount, for: "amount")
        try encoder.encode(alias, for: "alias_key")
        try encoder.encode(camelName, for: "camel_name")
        try encoder.encodeAnyIf(any, for: "any")
        try encoder.encodeAnyIf(dict, for: "dict")
        try encoder.encodeAnyIf(array, for: "array")
        try encoder.encodeIf(optional1, for: "optional1")
        try encoder.encodeIf(optional2, for: "optional2")
        try encoder.encodeIf(optional3, for: "optional3")
        try encoder.encodeIf(optional4, for: "optional4")
        try encoder.encodeIf(optional5, for: "optional5")
        try encoder.encodeIf(sub, for: "sub")
        try encoder.encodeIf(sub2, for: "sub2")
        try encoder.encodeIf(subs, for: "subs")
        try encoder.encodeIf(subdict, for: "subdict")
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

// MARK: - TestAutoCodableModel
struct TestAutoCodableModel: CodableModel {
    @MappedValue var id: Int = 0
    @MappedValue var name: String = ""
    @MappedValue var age: Int?
    @MappedValue var amount: Float = 0
    @MappedValue("alias_key")
    var alias: String = ""
    var except: String = ""
    @MappedValue("camel_name")
    var camelName: String = ""
    @MappedValue var any: Any?
    @MappedValue var dict: [AnyHashable: Any]?
    @MappedValue var array: [Any]?
    @MappedValue var optional1: String = ""
    @MappedValue var optional2: String = ""
    @MappedValue var optional3: String? = "default"
    @MappedValue var optional4: Int? = 4
    @MappedValue var optional5: Int? = 0
    @MappedValue var sub: TestAutoCodableSubModel?
    @MappedValue var sub2: TestAutoCodableSubModel = .init()
    @MappedValue var subs: [TestAutoCodableSubModel] = []
    @MappedValue var subdict: [String: TestAutoCodableSubModel] = [:]
    @MappedValue var enum1: TestAutoCodableModelEnum = .unknown
    @MappedValue var enum2: TestAutoCodableModelEnum = .unknown
    @MappedValue var enum3: TestAutoCodableModelEnum?
}

struct TestAutoCodableSubModel: CodableModel {
    @MappedValue var id: Int = 0
    @MappedValue var name: String?
}

enum TestAutoCodableModelEnum: String, Codable {
    case test = "test"
    case unknown = ""
}

// MARK: - TestMappableCodableModel
struct TestMappableCodableModel: CodableModel {
    var id: Int = 0
    var name: String = ""
    var age: Int?
    var amount: Float = 0
    var alias: String = ""
    var except: String = ""
    var camelName: String = ""
    var any: Any?
    var dict: [AnyHashable: Any]?
    var array: [Any]?
    var optional1: String = ""
    var optional2: String = ""
    var optional3: String? = "default"
    var optional4: Int? = 4
    var optional5: Int? = 0
    var sub: TestMappableCodableSubModel?
    var sub2: TestMappableCodableSubModel = .init()
    var subs: [TestMappableCodableSubModel] = []
    var subdict: [String: TestMappableCodableSubModel] = [:]
    var enum1: TestMappableCodableModelEnum = .unknown
    var enum2: TestMappableCodableModelEnum = .unknown
    var enum3: TestMappableCodableModelEnum?
    
    static let keyMapping: [KeyMap<Self>] = [
        KeyMap(\.id, to: "id"),
        KeyMap(\.name, to: "name"),
        KeyMap(\.age, to: "age"),
        KeyMap(\.amount, to: "amount"),
        KeyMap(\.alias, to: "alias_key"),
        KeyMap(\.camelName, to: "camel_name"),
        KeyMap(\.any, to: "any"),
        KeyMap(\.dict, to: "dict"),
        KeyMap(\.array, to: "array"),
        KeyMap(\.optional1, to: "optional1"),
        KeyMap(\.optional2, to: "optional2"),
        KeyMap(\.optional3, to: "optional3"),
        KeyMap(\.optional4, to: "optional4"),
        KeyMap(\.optional5, to: "optional5"),
        KeyMap(\.sub, to: "sub"),
        KeyMap(\.sub2, to: "sub2"),
        KeyMap(\.subs, to: "subs"),
        KeyMap(\.subdict, to: "subdict"),
        KeyMap(\.enum1, to: "enum1"),
        KeyMap(\.enum2, to: "enum2"),
        KeyMap(\.enum3, to: "enum3"),
    ]
}

struct TestMappableCodableSubModel: CodableModel {
    var id: Int = 0
    var name: String?
    
    static let keyMapping: [KeyMap<Self>] = [
        KeyMap(\.id, to: "id"),
        KeyMap(\.name, to: "name"),
    ]
}

enum TestMappableCodableModelEnum: String, Codable {
    case test = "test"
    case unknown = ""
}

// MARK: - TestJSONModel
struct TestJSONModel: JSONModel {
    var id: Int = 0
    var name: String = ""
    var age: Int?
    var amount: Float = 0
    var alias: String = ""
    var except: String = ""
    var camelName: String = ""
    var any: Any?
    var dict: [AnyHashable: Any]?
    var array: [Any]?
    var optional1: String = ""
    var optional2: String = ""
    var optional3: String? = "default"
    var optional4: Int? = 4
    var optional5: Int? = 0
    var sub: TestJSONSubModel?
    var sub2: TestJSONSubModel = .init()
    var subs: [TestJSONSubModel] = []
    var subdict: [String: TestJSONSubModel] = [:]
    var enum1: TestJSONModelEnum = .unknown
    var enum2: TestJSONModelEnum = .unknown
    var enum3: TestJSONModelEnum?
    
    mutating func mapping(mapper: HelpingMapper) {
        mapper >>> self.except
        
        mapper <<<
            self.alias <-- "alias_key"
        
        mapper <<<
            self.camelName <-- "camel_name"
    }
}

struct TestJSONSubModel: JSONModel {
    var id: Int = 0
    var name: String?
}

enum TestJSONModelEnum: String, JSONModelEnum {
    case test = "test"
    case unknown = ""
}

// MARK: - TestObjectParameter
class TestObjectParameter: ObjectParameter, JSONModel {
    var id: Int = 0
    var name: String = ""
    var block: BlockVoid?
    
    required init() {}
}

// MARK: - TestCodableController
class TestCodableController: UIViewController, TableViewControllerProtocol {
    
    typealias TableElement = [String]
    
    private var count = 0
    
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
            ["CodableModel+MappedValue", "onAutoCodableModel"],
            ["CodableModel+KeyMapping", "onMappableCodableModel"],
            ["JSONModel", "onJSONModel"],
            ["ObjectParameter", "onObjectParameter"],
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
            "alias_key": "alias",
            "except": "except",
            "camel_name": "camelName",
            "any": "any",
            "dict": [:],
            "array": [1],
            "optional1": NSNull(),
            "optional4": [:],
            "optional5": 5,
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
            "subdict": [
                "key": [
                    "id": 4,
                    "name": "subdict",
                ],
            ],
            "enum1": "test",
            "enum2": "unknown",
            "enum3": "unknown",
        ]
    }
    
    func showResults(_ tests: [Bool]) {
        count += 1
        app.showMessage(text: tests.count == tests.filter({ $0 }).count ? "✅ 测试通过 (\(count)-\(tests.count))" : "❌ 测试失败 (\(count)-\(tests.filter({ !$0 }).count))")
    }
    
    @objc func onCodableModel() {
        func testModel(_ model: TestCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                (model != nil),
                (model?.id == 1),
                (model?.name == "name"),
                (model?.age == 2),
                (model?.amount == 100.0),
                (model?.alias == "alias"),
                (model?.except == ""),
                (model?.camelName == "camelName"),
                (String.app.safeString(model?.any) == "any"),
                (model?.dict != nil),
                ((model?.array as? [Int])?.first == 1),
                (model?.optional1 == ""),
                (model?.optional2 == ""),
                (model?.optional3 == "default"),
                (model?.optional4 == (encode ? 4 : nil)),
                (model?.optional5 == 5),
                (model?.sub?.name == "sub"),
                (model?.sub2 != nil),
                (model?.subs.first?.name == "subs"),
                (model?.subdict["key"]?.name == "subdict"),
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
        showResults(tests)
    }
    
    @objc func onJSONCodableModel() {
        func testModel(_ model: TestJSONCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                (model != nil),
                (model?.id == 1),
                (model?.name == "name"),
                (model?.age == 2),
                (model?.amount == 100.0),
                (model?.alias == "alias"),
                (model?.except == ""),
                (model?.camelName == "camelName"),
                (String.app.safeString(model?.any) == "any"),
                (model?.dict != nil),
                ((model?.array as? [Int])?.first == 1),
                (model?.optional1 == ""),
                (model?.optional2 == ""),
                (model?.optional3 == "default"),
                (model?.optional4 == (encode ? 4 : nil)),
                (model?.optional5 == 5),
                (model?.sub?.name == "sub"),
                (model?.sub2 != nil),
                (model?.subs.first?.name == "subs"),
                (model?.subdict["key"]?.name == "subdict"),
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
        showResults(tests)
    }
    
    @objc func onAutoCodableModel() {
        func testModel(_ model: TestAutoCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                (model != nil),
                (model?.id == 1),
                (model?.name == "name"),
                (model?.age == 2),
                (model?.amount == 100.0),
                (model?.alias == "alias"),
                (model?.except == ""),
                (model?.camelName == "camelName"),
                (String.app.safeString(model?.any) == "any"),
                (model?.dict != nil),
                ((model?.array as? [Int])?.first == 1),
                (model?.optional1 == ""),
                (model?.optional2 == ""),
                (model?.optional3 == "default"),
                (model?.optional4 == (encode ? 4 : nil)),
                (model?.optional5 == 5),
                (model?.sub?.name == "sub"),
                (model?.sub2 != nil),
                (model?.subs.first?.name == "subs"),
                (model?.subdict["key"]?.name == "subdict"),
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
        showResults(tests)
    }
    
    @objc func onMappableCodableModel() {
        func testModel(_ model: TestMappableCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                (model != nil),
                (model?.id == 1),
                (model?.name == "name"),
                (model?.age == 2),
                (model?.amount == 100.0),
                (model?.alias == "alias"),
                (model?.except == ""),
                (model?.camelName == "camelName"),
                (String.app.safeString(model?.any) == "any"),
                (model?.dict != nil),
                ((model?.array as? [Int])?.first == 1),
                (model?.optional1 == ""),
                (model?.optional2 == ""),
                (model?.optional3 == "default"),
                (model?.optional4 == (encode ? 4 : nil)),
                (model?.optional5 == 5),
                (model?.sub?.name == "sub"),
                (model?.sub2 != nil),
                (model?.subs.first?.name == "subs"),
                (model?.subdict["key"]?.name == "subdict"),
                (model?.enum1 == .test),
                (model?.enum2 == .unknown),
                (model?.enum3 == nil),
            ]
            return results
        }
        
        var model: TestMappableCodableModel? = TestMappableCodableModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestMappableCodableModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }
    
    @objc func onJSONModel() {
        func testModel(_ model: TestJSONModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                (model != nil),
                (model?.id == 1),
                (model?.name == "name"),
                (model?.age == 2),
                (model?.amount == 100.0),
                (model?.alias == "alias"),
                (model?.except == ""),
                (model?.camelName == "camelName"),
                (String.app.safeString(model?.any) == "any"),
                (model?.dict != nil),
                ((model?.array as? [Int])?.first == 1),
                (model?.optional1 == ""),
                (model?.optional2 == ""),
                (model?.optional3 == "default"),
                (model?.optional4 == (encode ? 4 : nil)),
                (model?.optional5 == 5),
                (model?.sub?.name == "sub"),
                (model?.sub2 != nil),
                (model?.subs.first?.name == "subs"),
                (model?.subdict["key"]?.name == "subdict"),
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
        showResults(tests)
    }
    
    @objc func onObjectParameter() {
        let block: BlockVoid = {}
        let dict: [AnyHashable: Any] = [
            "id": 1,
            "name": "name",
            "block": block,
        ]
        
        func testModel(_ model: TestObjectParameter, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                (model.id == 1),
                (model.name == "name"),
                (model.block != nil),
            ]
            return results
        }
        
        var model = TestObjectParameter(dictionaryValue: dict)
        var tests = testModel(model)
        model = TestObjectParameter.decodeSafeModel(from: model.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }
    
}
