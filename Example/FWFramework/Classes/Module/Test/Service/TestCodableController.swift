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
    case test
    case unknown = ""
}

// MARK: - TestCustomCodableModel
struct TestCustomCodableModel: CodableModel {
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
    var sub: TestCustomCodableSubModel?
    var sub2: TestCustomCodableSubModel = .init()
    var subs: [TestCustomCodableSubModel] = []
    var subdict: [String: TestCustomCodableSubModel] = [:]
    var enum1: TestCustomCodableEnum = .unknown
    var enum2: TestCustomCodableEnum = .unknown
    var enum3: TestCustomCodableEnum?

    init() {}

    init(from decoder: any Decoder) throws {
        id = try decoder.json("id").intValue
        age = try decoder.jsonIf("age")?.intValue
        name = try decoder.decodeSafe("name") ?? ""
        amount = try decoder.decodeSafe("amount") ?? .zero
        alias = try decoder.decodeSafe("alias_key") ?? ""
        camelName = try decoder.decodeSafe("camel_name") ?? ""
        any = try decoder.decodeSafeAny("any")
        dict = try decoder.decodeSafeAny("dict")
        array = try decoder.decodeSafeAny("array")
        optional1 = try decoder.decodeSafe("optional1") ?? ""
        optional2 = try decoder.decodeSafe("optional2") ?? ""
        optional3 = try decoder.decodeSafe("optional3") ?? "default"
        // 类型不匹配解析失败时赋值nil, key不存在时不覆盖
        do {
            optional4 = try decoder.decodeSafe("optional4", throws: true) ?? 4
        } catch {
            optional4 = nil
        }
        optional5 = try decoder.decodeSafe("optional5")
        sub = try decoder.decodeSafe("sub")
        sub2 = try decoder.decodeSafe("sub2") ?? .init()
        subs = try decoder.decodeSafe("subs") ?? []
        subdict = try decoder.decodeSafe("subdict") ?? [:]
        enum1 = try decoder.decodeSafe("enum1") ?? .unknown
        enum2 = try decoder.decodeSafe("enum2") ?? .unknown
        enum3 = try decoder.decodeSafe("enum3")
    }

    func encode(to encoder: any Encoder) throws {
        try encoder.encodeSafe(id, for: "id")
        try encoder.encodeSafe(name, for: "name")
        try encoder.encodeSafe(age, for: "age")
        try encoder.encodeSafe(amount, for: "amount")
        try encoder.encodeSafe(alias, for: "alias_key")
        try encoder.encodeSafe(camelName, for: "camel_name")
        try encoder.encodeSafeAny(any, for: "any")
        try encoder.encodeSafeAny(dict, for: "dict")
        try encoder.encodeSafeAny(array, for: "array")
        try encoder.encodeSafe(optional1, for: "optional1")
        try encoder.encodeSafe(optional2, for: "optional2")
        try encoder.encodeSafe(optional3, for: "optional3")
        try encoder.encodeSafe(optional4, for: "optional4")
        try encoder.encodeSafe(optional5, for: "optional5")
        try encoder.encodeSafe(sub, for: "sub")
        try encoder.encodeSafe(sub2, for: "sub2")
        try encoder.encodeSafe(subs, for: "subs")
        try encoder.encodeSafe(subdict, for: "subdict")
        try encoder.encodeSafe(enum1, for: "enum1")
        try encoder.encodeSafe(enum2, for: "enum2")
        try encoder.encodeSafe(enum3, for: "enum3")
    }
}

struct TestCustomCodableSubModel: Codable {
    var id: Int = 0
    var name: String?
}

enum TestCustomCodableEnum: String, Codable {
    case test
    case unknown = ""
}

// MARK: - TestMappedValueCodableModel
struct TestMappedValueCodableModel: CodableModel, KeyMappable {
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
    @MappedValue var sub: TestMappedValueCodableSubModel?
    @MappedValue var sub2: TestMappedValueCodableSubModel = .init()
    @MappedValue var subs: [TestMappedValueCodableSubModel] = []
    @MappedValue var subdict: [String: TestMappedValueCodableSubModel] = [:]
    @MappedValue var enum1: TestMappedValueCodableModelEnum = .unknown
    @MappedValue var enum2: TestMappedValueCodableModelEnum = .unknown
    @MappedValue var enum3: TestMappedValueCodableModelEnum?
}

struct TestMappedValueCodableSubModel: CodableModel, KeyMappable {
    @MappedValue var id: Int = 0
    @MappedValue var name: String?
}

enum TestMappedValueCodableModelEnum: String, Codable {
    case test
    case unknown = ""
}

// MARK: - TestMappedValueMacroCodableModel
@MappedValueMacro
struct TestMappedValueMacroCodableModel: CodableModel, KeyMappable {
    var id: Int = 0
    var name: String = ""
    var age: Int?
    var amount: Float = 0
    @MappedValue("alias_key")
    var alias: String = ""
    @MappedValue(ignored: true)
    var except: String = ""
    @MappedValue("camel_name")
    var camelName: String = ""
    var any: Any?
    var dict: [AnyHashable: Any]?
    var array: [Any]?
    var optional1: String = ""
    var optional2: String = ""
    var optional3: String? = "default"
    var optional4: Int? = 4
    var optional5: Int? = 0
    var sub: TestMappedValueMacroCodableSubModel?
    var sub2: TestMappedValueMacroCodableSubModel = .init()
    var subs: [TestMappedValueMacroCodableSubModel] = []
    var subdict: [String: TestMappedValueMacroCodableSubModel] = [:]
    var enum1: TestMappedValueMacroCodableModelEnum = .unknown
    var enum2: TestMappedValueMacroCodableModelEnum = .unknown
    var enum3: TestMappedValueMacroCodableModelEnum?
}

@MappedValueMacro
struct TestMappedValueMacroCodableSubModel: CodableModel, KeyMappable {
    var id: Int = 0
    var name: String?
}

enum TestMappedValueMacroCodableModelEnum: String, Codable {
    case test
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

    // HandyJSON模式时，会去解析属性offset，因此也能使用<<<等infix符号方法
    mutating func mapping(mapper: HelpingMapper) {
        mapper >>> except

        mapper <<<
            alias <-- "alias_key"

        mapper <<<
            camelName <-- "camel_name"
    }
}

class TestJSONSuperModel: JSONModel {
    var id: Int = 0

    required init() {}
}

class TestJSONSubModel: TestJSONSuperModel {
    var name: String?
}

enum TestJSONModelEnum: String, JSONModelEnum {
    case test
    case unknown = ""
}

// MARK: - TestMappedValueJSONModel
struct TestMappedValueJSONModel: JSONModel, KeyMappable {
    @MappedValue var id: Int = 0
    @MappedValue
    @ValidatedValue(.isWord)
    var name: String = ""
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
    @MappedValue var sub: TestMappedValueJSONSubModel?
    @MappedValue var sub2: TestMappedValueJSONSubModel = .init()
    @MappedValue var subs: [TestMappedValueJSONSubModel] = []
    @MappedValue var subdict: [String: TestMappedValueJSONSubModel] = [:]
    @MappedValue var enum1: TestMappedValueJSONModelEnum = .unknown
    @MappedValue var enum2: TestMappedValueJSONModelEnum = .unknown
    @MappedValue var enum3: TestMappedValueJSONModelEnum?
}

class TestMappedValueJSONSuperModel: JSONModel, KeyMappable {
    @MappedValue var id: Int = 0

    required init() {}
}

class TestMappedValueJSONSubModel: TestMappedValueJSONSuperModel {
    @MappedValue var name: String?
}

enum TestMappedValueJSONModelEnum: String, JSONModelEnum {
    case test
    case unknown = ""
}

// MARK: - TestCustomJSONModel
struct TestCustomJSONModel: JSONModel, KeyMappable {
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
    var sub: TestCustomJSONSubModel?
    var sub2: TestCustomJSONSubModel = .init()
    var subs: [TestCustomJSONSubModel] = []
    var subdict: [String: TestCustomJSONSubModel] = [:]
    var enum1: TestCustomJSONModelEnum = .unknown
    var enum2: TestCustomJSONModelEnum = .unknown
    var enum3: TestCustomJSONModelEnum?

    mutating func mappingValue(_ value: Any, forKey key: String) {
        switch key {
        case "id":
            id = value as? Int ?? .zero
        case "name":
            name = value as? String ?? ""
        case "age":
            age = value as? Int
        case "amount":
            amount = value as? Float ?? .zero
        case "alias":
            alias = value as? String ?? ""
        case "camelName":
            camelName = value as? String ?? ""
        case "any":
            any = value
        case "dict":
            dict = value as? [AnyHashable: Any]
        case "array":
            array = value as? [Any]
        case "optional1":
            optional1 = value as? String ?? ""
        case "optional2":
            optional2 = value as? String ?? ""
        case "optional3":
            optional3 = value as? String ?? "default"
        case "optional4":
            optional4 = value as? Int ?? 4
        case "optional5":
            optional5 = value as? Int ?? .zero
        case "sub":
            sub = value as? TestCustomJSONSubModel
        case "sub2":
            sub2 = value as? TestCustomJSONSubModel ?? .init()
        case "subs":
            subs = value as? [TestCustomJSONSubModel] ?? []
        case "subdict":
            subdict = value as? [String: TestCustomJSONSubModel] ?? [:]
        case "enum1":
            enum1 = value as? TestCustomJSONModelEnum ?? .unknown
        case "enum2":
            enum2 = value as? TestCustomJSONModelEnum ?? .unknown
        case "enum3":
            enum3 = value as? TestCustomJSONModelEnum
        default:
            break
        }
    }

    // 非HandyJSON模式时，不会去解析属性offset，因此也不能使用<<<等infix符号方法
    mutating func mapping(mapper: HelpingMapper) {
        mapper.exclude(key: "except")
        mapper.specify(key: "alias", names: "alias_key")
        mapper.specify(key: "camelName", names: "camel_name")
    }
}

class TestCustomJSONSuperModel: JSONModel, KeyMappable {
    var id: Int = 0

    required init() {}

    func mappingValue(_ value: Any, forKey key: String) {
        switch key {
        case "id":
            id = value as? Int ?? .zero
        default:
            break
        }
    }
}

class TestCustomJSONSubModel: TestCustomJSONSuperModel {
    var name: String?

    override func mappingValue(_ value: Any, forKey key: String) {
        switch key {
        case "name":
            name = value as? String
        default:
            super.mappingValue(value, forKey: key)
        }
    }
}

enum TestCustomJSONModelEnum: String, JSONModelEnum {
    case test
    case unknown = ""
}

// MARK: - TestMappedValueMacroJSONModel
@MappedValueMacro
struct TestMappedValueMacroJSONModel: JSONModel, KeyMappable {
    var id: Int = 0
    var name: String = ""
    var age: Int?
    var amount: Float = 0
    @MappedValue("alias_key")
    var alias: String = ""
    @MappedValue(ignored: true)
    var except: String = ""
    @MappedValue("camel_name")
    var camelName: String = ""
    var any: Any?
    var dict: [AnyHashable: Any]?
    var array: [Any]?
    var optional1: String = ""
    var optional2: String = ""
    var optional3: String? = "default"
    var optional4: Int? = 4
    var optional5: Int? = 0
    var sub: TestMappedValueMacroJSONSubModel?
    var sub2: TestMappedValueMacroJSONSubModel = .init()
    var subs: [TestMappedValueMacroJSONSubModel] = []
    var subdict: [String: TestMappedValueMacroJSONSubModel] = [:]
    var enum1: TestMappedValueMacroJSONModelEnum = .unknown
    var enum2: TestMappedValueMacroJSONModelEnum = .unknown
    var enum3: TestMappedValueMacroJSONModelEnum?
}

@MappedValueMacro
struct TestMappedValueMacroJSONSubModel: JSONModel, KeyMappable {
    var id: Int = 0
    var name: String?
}

enum TestMappedValueMacroJSONModelEnum: String, JSONModelEnum {
    case test
    case unknown = ""
}

// MARK: - TestObjectParameter
class TestObjectParameter: ObjectParameter, JSONModel, KeyMappable {
    @MappedValue var id: Int = 0
    @MappedValue var name: String = ""
    @MappedValue var block: BlockVoid?

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
        tableData.count
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
        _ = perform(NSSelectorFromString(rowData[1]))
    }

    func setupSubviews() {
        tableData.append(contentsOf: [
            ["CodableModel", "onCodableModel"],
            ["CodableModel+Custom", "onCustomCodableModel"],
            ["CodableModel+MappedValue", "onMappedValueCodableModel"],
            ["CodableModel+MappedValueMacro", "onMappedValueMacroCodableModel"],
            ["JSONModel", "onJSONModel"],
            ["JSONModel+Custom", "onCustomJSONModel"],
            ["JSONModel+MappedValue", "onMappedValueJSONModel"],
            ["JSONModel+MappedValueMacro", "onMappedValueMacroJSONModel"],
            ["ObjectParameter", "onObjectParameter"],
            ["Optional.isNil", "onOptionalNil"]
        ])
    }
}

extension TestCodableController {
    func testCodableData() -> [AnyHashable: Any] {
        [
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
                "name": "sub"
            ],
            "subs": [
                [
                    "id": 3,
                    "name": "subs"
                ]
            ],
            "subdict": [
                "key": [
                    "id": 4,
                    "name": "subdict"
                ]
            ],
            "enum1": "test",
            "enum2": "unknown",
            "enum3": "unknown"
        ]
    }

    func showResults(_ tests: [Bool]) {
        count += 1
        app.showMessage(text: tests.count == tests.filter { $0 }.count ? "✅ 测试通过 (\(count)-\(tests.count))" : "❌ 测试失败 (\(count)-\(tests.filter { !$0 }.count))")
    }

    @objc func onCodableModel() {
        func testModel(_ model: TestCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                model != nil,
                model?.id == 1,
                model?.name == "name",
                model?.age == 2,
                model?.amount == 100.0,
                model?.alias == "alias",
                model?.except == "",
                model?.camelName == "camelName",
                String.app.safeString(model?.any) == "any",
                model?.dict != nil,
                (model?.array as? [Int])?.first == 1,
                model?.optional1 == "",
                model?.optional2 == "",
                model?.optional3 == "default",
                model?.optional4 == (encode ? 4 : nil),
                model?.optional5 == 5,
                model?.sub?.name == "sub",
                model?.sub2 != nil,
                model?.subs.first?.name == "subs",
                model?.subdict["key"]?.name == "subdict",
                model?.enum1 == .test,
                model?.enum2 == .unknown,
                model?.enum3 == nil
            ]
            return results
        }

        var model: TestCodableModel? = TestCodableModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestCodableModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }

    @objc func onCustomCodableModel() {
        func testModel(_ model: TestCustomCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                model != nil,
                model?.id == 1,
                model?.name == "name",
                model?.age == 2,
                model?.amount == 100.0,
                model?.alias == "alias",
                model?.except == "",
                model?.camelName == "camelName",
                String.app.safeString(model?.any) == "any",
                model?.dict != nil,
                (model?.array as? [Int])?.first == 1,
                model?.optional1 == "",
                model?.optional2 == "",
                model?.optional3 == "default",
                model?.optional4 == (encode ? 4 : nil),
                model?.optional5 == 5,
                model?.sub?.name == "sub",
                model?.sub2 != nil,
                model?.subs.first?.name == "subs",
                model?.subdict["key"]?.name == "subdict",
                model?.enum1 == .test,
                model?.enum2 == .unknown,
                model?.enum3 == nil
            ]
            return results
        }

        var model: TestCustomCodableModel? = TestCustomCodableModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestCustomCodableModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }

    @objc func onMappedValueCodableModel() {
        func testModel(_ model: TestMappedValueCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                model != nil,
                model?.id == 1,
                model?.name == "name",
                model?.age == 2,
                model?.amount == 100.0,
                model?.alias == "alias",
                model?.except == "",
                model?.camelName == "camelName",
                String.app.safeString(model?.any) == "any",
                model?.dict != nil,
                (model?.array as? [Int])?.first == 1,
                model?.optional1 == "",
                model?.optional2 == "",
                model?.optional3 == "default",
                model?.optional4 == (encode ? 4 : nil),
                model?.optional5 == 5,
                model?.sub?.name == "sub",
                model?.sub2 != nil,
                model?.subs.first?.name == "subs",
                model?.subdict["key"]?.name == "subdict",
                model?.enum1 == .test,
                model?.enum2 == .unknown,
                model?.enum3 == nil
            ]
            return results
        }

        var model: TestMappedValueCodableModel? = TestMappedValueCodableModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestMappedValueCodableModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }

    @objc func onMappedValueMacroCodableModel() {
        func testModel(_ model: TestMappedValueMacroCodableModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                model != nil,
                model?.id == 1,
                model?.name == "name",
                model?.age == 2,
                model?.amount == 100.0,
                model?.alias == "alias",
                model?.except == "",
                model?.camelName == "camelName",
                String.app.safeString(model?.any) == "any",
                model?.dict != nil,
                (model?.array as? [Int])?.first == 1,
                model?.optional1 == "",
                model?.optional2 == "",
                model?.optional3 == "default",
                model?.optional4 == (encode ? 4 : nil),
                model?.optional5 == 5,
                model?.sub?.name == "sub",
                model?.sub2 != nil,
                model?.subs.first?.name == "subs",
                model?.subdict["key"]?.name == "subdict",
                model?.enum1 == .test,
                model?.enum2 == .unknown,
                model?.enum3 == nil
            ]
            return results
        }

        var model: TestMappedValueMacroCodableModel? = TestMappedValueMacroCodableModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestMappedValueMacroCodableModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }

    @objc func onJSONModel() {
        func testModel(_ model: TestJSONModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                model != nil,
                model?.id == 1,
                model?.name == "name",
                model?.age == 2,
                model?.amount == 100.0,
                model?.alias == "alias",
                model?.except == "",
                model?.camelName == "camelName",
                String.app.safeString(model?.any) == "any",
                model?.dict != nil,
                (model?.array as? [Int])?.first == 1,
                model?.optional1 == "",
                model?.optional2 == "",
                model?.optional3 == "default",
                model?.optional4 == (encode ? 4 : nil),
                model?.optional5 == 5,
                model?.sub?.name == "sub",
                model?.sub2 != nil,
                model?.subs.first?.name == "subs",
                model?.subdict["key"]?.name == "subdict",
                model?.enum1 == .test,
                model?.enum2 == .unknown,
                model?.enum3 == nil
            ]
            return results
        }

        var model: TestJSONModel? = TestJSONModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestJSONModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }

    @objc func onCustomJSONModel() {
        func testModel(_ model: TestCustomJSONModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                model != nil,
                model?.id == 1,
                model?.name == "name",
                model?.age == 2,
                model?.amount == 100.0,
                model?.alias == "alias",
                model?.except == "",
                model?.camelName == "camelName",
                String.app.safeString(model?.any) == "any",
                model?.dict != nil,
                (model?.array as? [Int])?.first == 1,
                model?.optional1 == "",
                model?.optional2 == "",
                model?.optional3 == "default",
                model?.optional4 == 4,
                model?.optional5 == 5,
                model?.sub?.name == "sub",
                model?.sub2 != nil,
                model?.subs.first?.name == "subs",
                model?.subdict["key"]?.name == "subdict",
                model?.enum1 == .test,
                model?.enum2 == .unknown,
                model?.enum3 == nil
            ]
            return results
        }

        var model: TestCustomJSONModel? = TestCustomJSONModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestCustomJSONModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }

    @objc func onMappedValueJSONModel() {
        func testModel(_ model: TestMappedValueJSONModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                model != nil,
                model?.id == 1,
                model?.name == "name",
                model?.age == 2,
                model?.amount == 100.0,
                model?.alias == "alias",
                model?.except == "",
                model?.camelName == "camelName",
                String.app.safeString(model?.any) == "any",
                model?.dict != nil,
                (model?.array as? [Int])?.first == 1,
                model?.optional1 == "",
                model?.optional2 == "",
                model?.optional3 == "default",
                model?.optional4 == (encode ? 4 : nil),
                model?.optional5 == 5,
                model?.sub?.name == "sub",
                model?.sub2 != nil,
                model?.subs.first?.name == "subs",
                model?.subdict["key"]?.name == "subdict",
                model?.enum1 == .test,
                model?.enum2 == .unknown,
                model?.enum3 == nil
            ]
            return results
        }

        var model: TestMappedValueJSONModel? = TestMappedValueJSONModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestMappedValueJSONModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }

    @objc func onMappedValueMacroJSONModel() {
        func testModel(_ model: TestMappedValueMacroJSONModel?, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                model != nil,
                model?.id == 1,
                model?.name == "name",
                model?.age == 2,
                model?.amount == 100.0,
                model?.alias == "alias",
                model?.except == "",
                model?.camelName == "camelName",
                String.app.safeString(model?.any) == "any",
                model?.dict != nil,
                (model?.array as? [Int])?.first == 1,
                model?.optional1 == "",
                model?.optional2 == "",
                model?.optional3 == "default",
                model?.optional4 == (encode ? 4 : nil),
                model?.optional5 == 5,
                model?.sub?.name == "sub",
                model?.sub2 != nil,
                model?.subs.first?.name == "subs",
                model?.subdict["key"]?.name == "subdict",
                model?.enum1 == .test,
                model?.enum2 == .unknown,
                model?.enum3 == nil
            ]
            return results
        }

        var model: TestMappedValueMacroJSONModel? = TestMappedValueMacroJSONModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestMappedValueMacroJSONModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }

    @objc func onObjectParameter() {
        let block: BlockVoid = {}
        let dict: [AnyHashable: Any] = [
            "id": 1,
            "name": "name",
            "block": block
        ]

        func testModel(_ model: TestObjectParameter, encode: Bool = false) -> [Bool] {
            let results: [Bool] = [
                model.id == 1,
                model.name == "name",
                model.block != nil
            ]
            return results
        }

        var model = TestObjectParameter(dictionaryValue: dict)
        var tests = testModel(model)
        model = TestObjectParameter.decodeSafeModel(from: model.encodeObject())
        tests += testModel(model, encode: true)
        showResults(tests)
    }

    @objc func onOptionalNil() {
        let dict: [String: Any?] = ["name": "John", "age": nil]
        let name: Any? = dict["name"] as? Any
        let age: Any? = dict["age"] as? Any
        let value: Any? = nil

        var tests: [Bool] = []
        tests.append(!APP.isNil(name))
        tests.append(APP.isNil(age))
        tests.append(APP.isNil(value))
        showResults(tests)
    }
}
