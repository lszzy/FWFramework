//
//  TestCodableController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/8/24.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework
import ObjectMapper

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
        self.id = try decoder.decode("id")
        self.name = try decoder.decode("name")
        if let int = try? decoder.decodeIf("age", as: Int.self) {
            self.age = int
        } else if let string = try? decoder.decodeIf("age", as: String.self) {
            self.age = Int(string) ?? .zero
        }
        self.amount = try decoder.decode("amount")
        self.alias = try decoder.decode("alias_key")
        self.camelName = try decoder.decode("camel_name")
        self.any = try decoder.decodeAnyIf("any")
        self.dict = try decoder.decodeAnyIf("dict")
        self.array = try decoder.decodeAnyIf("array")
        self.optional1 = try decoder.decodeIf("optional1") ?? ""
        if let value2 = try decoder.decodeIf("optional2", as: String.self) {
            self.optional2 = value2
        }
        if let value3 = try decoder.decodeIf("optional3", as: String.self) {
            self.optional3 = value3
        }
        // 类型不匹配解析失败时赋值nil, key不存在时不覆盖
        do {
            if let value4 = try decoder.decodeIf("optional4", as: Int?.self) {
                self.optional4 = value4
            }
        } catch {
            self.optional4 = nil
        }
        self.optional5 = try decoder.decodeIf("optional5", as: Int?.self) ?? nil
        self.sub = try decoder.decodeIf("sub")
        if let val2 = try decoder.decodeIf("sub2", as: TestCodableSubModel.self) {
            self.sub2 = val2
        }
        self.subs = try decoder.decodeIf("subs") ?? []
        self.subdict = try decoder.decodeIf("subdict") ?? [:]
        self.enum1 = try decoder.decode("enum1")
        if let val2 = try? decoder.decodeIf("enum2", as: TestCodableEnum.self) {
            self.enum2 = val2
        }
        self.enum3 = try? decoder.decodeIf("enum3")
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
        self.id = try decoder.json("id").intValue
        self.age = try decoder.jsonIf("age")?.intValue
        self.name = try decoder.decodeSafe("name") ?? ""
        self.amount = try decoder.decodeSafe("amount") ?? .zero
        self.alias = try decoder.decodeSafe("alias_key") ?? ""
        self.camelName = try decoder.decodeSafe("camel_name") ?? ""
        self.any = try decoder.decodeSafeAny("any")
        self.dict = try decoder.decodeSafeAny("dict")
        self.array = try decoder.decodeSafeAny("array")
        self.optional1 = try decoder.decodeSafe("optional1") ?? ""
        self.optional2 = try decoder.decodeSafe("optional2") ?? ""
        self.optional3 = try decoder.decodeSafe("optional3") ?? "default"
        // 类型不匹配解析失败时赋值nil, key不存在时不覆盖
        do {
            self.optional4 = try decoder.decodeSafe("optional4", throws: true) ?? 4
        } catch {
            self.optional4 = nil
        }
        self.optional5 = try decoder.decodeSafe("optional5")
        self.sub = try decoder.decodeSafe("sub")
        self.sub2 = try decoder.decodeSafe("sub2") ?? .init()
        self.subs = try decoder.decodeSafe("subs") ?? []
        self.subdict = try decoder.decodeSafe("subdict") ?? [:]
        self.enum1 = try decoder.decodeSafe("enum1") ?? .unknown
        self.enum2 = try decoder.decodeSafe("enum2") ?? .unknown
        self.enum3 = try decoder.decodeSafe("enum3")
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
struct TestMappedValueCodableModel: MappedCodableModel {
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

struct TestMappedValueCodableSubModel: MappedCodableModel {
    @MappedValue var id: Int = 0
    @MappedValue var name: String?
}

enum TestMappedValueCodableModelEnum: String, Codable {
    case test
    case unknown = ""
}

// MARK: - TestMappedValueMacroCodableModel
@MappedValueMacro
struct TestMappedValueMacroCodableModel: MappedCodableModel {
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
struct TestMappedValueMacroCodableSubModel: MappedCodableModel {
    var id: Int = 0
    var name: String?
}

enum TestMappedValueMacroCodableModelEnum: String, Codable {
    case test
    case unknown = ""
}

// MARK: - TestSmartModel
struct TestSmartModel: SmartModel {
    var id: Int = 0
    var name: String = ""
    var age: Int?
    var amount: Float = 0
    var alias: String = ""
    @IgnoredKey
    var except: String = ""
    var camelName: String = ""
    @SmartAny
    var any: Any?
    @SmartAny
    var dict: [AnyHashable: Any]?
    @SmartAny
    var array: [Any]?
    var optional1: String = ""
    var optional2: String = ""
    var optional3: String? = "default"
    var optional4: Int? = 4
    var optional5: Int? = 0
    var sub: TestSmartSubModel?
    var sub2: TestSmartSubModel = .init()
    var subs: [TestSmartSubModel] = []
    var subdict: [String: TestSmartSubModel] = [:]
    var enum1: TestSmartModelEnum = .unknown
    var enum2: TestSmartModelEnum = .unknown
    var enum3: TestSmartModelEnum?

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [
            CodingKeys.alias <--- "alias_key",
            CodingKeys.camelName <--- "camel_name"
        ]
    }
}

class TestSmartSuperModel: SmartModel {
    var id: Int = 0
    required init() {}
}

@SmartSubclass
class TestSmartSubModel: TestSmartSuperModel {
    var name: String?
}

enum TestSmartModelEnum: String, Codable {
    case test
    case unknown = ""
}

// MARK: - TestMappableModel
struct TestMappableModel: MappableModel {
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
    var sub: TestMappableSubModel?
    var sub2: TestMappableSubModel = .init()
    var subs: [TestMappableSubModel] = []
    var subdict: [String: TestMappableSubModel] = [:]
    var enum1: TestMappableModelEnum = .unknown
    var enum2: TestMappableModelEnum = .unknown
    var enum3: TestMappableModelEnum?

    init() {}

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        id <- map["id"]
        name <- map["name"]
        age <- (map["age"], TransformOf<Int, String>(fromJSON: { Int($0 ?? "") }, toJSON: { String($0 ?? 0) }))
        amount <- map["amount"]
        alias <- map["alias_key"]
        camelName <- map["camel_name"]
        any <- map["any"]
        dict <- map["dict"]
        array <- map["array"]
        optional1 <- map["optional1"]
        optional2 <- map["optional2"]
        optional3 <- map["optional3"]
        optional4 <- map["optional4"]
        optional5 <- map["optional5"]
        sub <- map["sub"]
        sub2 <- map["sub2"]
        subs <- map["subs"]
        subdict <- map["subdict"]
        enum1 <- map["enum1"]
        enum2 <- map["enum2"]
        enum3 <- map["enum3"]
    }
}

class TestMappableSuperModel: MappableModel {
    var id: Int = 0

    required init() {}

    required init?(map: Map) {}

    func mapping(map: Map) {
        id <- map["id"]
    }
}

class TestMappableSubModel: TestMappableSuperModel {
    var name: String?

    required init() {
        super.init()
    }

    required init?(map: Map) {
        super.init(map: map)
    }

    override func mapping(map: Map) {
        super.mapping(map: map)

        name <- map["name"]
    }
}

enum TestMappableModelEnum: String {
    case test
    case unknown = ""
}

// MARK: - TestObjectParameter
class TestObjectParameter: ObjectParameter {
    var id: Int = 0
    var name: String = ""
    var block: BlockVoid?

    required init() {}

    required init(dictionaryValue: [AnyHashable: Any]) {
        self.id = dictionaryValue["id"].safeInt
        self.name = dictionaryValue["name"].safeString
        self.block = dictionaryValue["block"] as? BlockVoid
    }

    public var dictionaryValue: [AnyHashable: Any] {
        var dictionary: [AnyHashable: Any] = [:]
        dictionary["id"] = id
        dictionary["name"] = name
        dictionary["block"] = block
        return dictionary
    }
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
            ["MappedCodableModel", "onMappedValueCodableModel"],
            ["MappedCodableModel+Macro", "onMappedValueMacroCodableModel"],
            ["SmartModel", "onSmartModel"],
            ["MappableModel", "onMappableModel"],
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

    func showResults(_ tests: [Bool], _ time: TimeInterval?) {
        count += 1
        var text = tests.count == tests.filter { $0 }.count ? "✅ 测试通过 (\(count)-\(tests.count))" : "❌ 测试失败 (\(count)-\(tests.filter { !$0 }.count))"
        if let time {
            text += "\n测试耗时：\(NSNumber(value: time).app.roundString(3))s"
        }
        app.showMessage(text: text)
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

        Benchmark.begin("codable")
        for _ in 0..<1000 {
            var model: TestCodableModel? = TestCodableModel.decodeModel(from: testCodableData())
            model = TestCodableModel.decodeModel(from: model?.encodeObject())
        }
        let time = Benchmark.end("codable")
        showResults(tests, time)
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

        Benchmark.begin("codable")
        for _ in 0..<1000 {
            var model: TestCustomCodableModel? = TestCustomCodableModel.decodeModel(from: testCodableData())
            model = TestCustomCodableModel.decodeModel(from: model?.encodeObject())
        }
        let time = Benchmark.end("codable")
        showResults(tests, time)
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

        Benchmark.begin("codable")
        for _ in 0..<1000 {
            var model: TestMappedValueCodableModel? = TestMappedValueCodableModel.decodeModel(from: testCodableData())
            model = TestMappedValueCodableModel.decodeModel(from: model?.encodeObject())
        }
        let time = Benchmark.end("codable")
        showResults(tests, time)
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

        Benchmark.begin("codable")
        for _ in 0..<1000 {
            var model: TestMappedValueMacroCodableModel? = TestMappedValueMacroCodableModel.decodeModel(from: testCodableData())
            model = TestMappedValueMacroCodableModel.decodeModel(from: model?.encodeObject())
        }
        let time = Benchmark.end("codable")
        showResults(tests, time)
    }

    @objc func onSmartModel() {
        func testModel(_ model: TestSmartModel?, encode: Bool = false) -> [Bool] {
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

        SmartSentinel.debugMode = .verbose
        var model: TestSmartModel? = TestSmartModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestSmartModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)

        SmartSentinel.debugMode = .none
        Benchmark.begin("codable")
        for _ in 0..<1000 {
            var model: TestSmartModel? = TestSmartModel.decodeModel(from: testCodableData())
            model = TestSmartModel.decodeModel(from: model?.encodeObject())
        }
        let time = Benchmark.end("codable")
        showResults(tests, time)
    }

    @objc func onMappableModel() {
        func testModel(_ model: TestMappableModel?, encode: Bool = false) -> [Bool] {
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

        var model: TestMappableModel? = TestMappableModel.decodeModel(from: testCodableData())
        var tests = testModel(model)
        model = TestMappableModel.decodeModel(from: model?.encodeObject())
        tests += testModel(model, encode: true)

        Benchmark.begin("codable")
        for _ in 0..<1000 {
            var model: TestMappableModel? = TestMappableModel.decodeModel(from: testCodableData())
            model = TestMappableModel.decodeModel(from: model?.encodeObject())
        }
        let time = Benchmark.end("codable")
        showResults(tests, time)
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
        model = TestObjectParameter(dictionaryValue: model.dictionaryValue)
        tests += testModel(model, encode: true)

        Benchmark.begin("codable")
        for _ in 0..<1000 {
            var model = TestObjectParameter(dictionaryValue: dict)
            model = TestObjectParameter(dictionaryValue: model.dictionaryValue)
        }
        let time = Benchmark.end("codable")
        showResults(tests, time)
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
        showResults(tests, nil)
    }
}
