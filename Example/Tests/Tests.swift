import XCTest
@_spi(FW) import FWFramework
#if FWMacroSPM
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import FWMacro
#endif

class Tests: XCTestCase {
    
    // MARK: - Accessor
    dynamic var observeValue: Int = 0
    
    @StoredValue("testKey")
    var defaultsValue = ""
    
    @StoredValue("testOptionKey")
    var defaultsOptionValue: Int? = 0
    
    @StoredValue("testNilKey")
    var defaultsNilValue: Int?
    
    @ValidatedValue(.isEmail)
    var validateValue = ""
    
    @ValidatedValue(.isEmail)
    var validateOptionValue: String? = ""
    
    @ValidatedValue(.isEmail)
    var validateNilValue: String?
    
    // MARK: - Test
    func testLoader() {
        let loader = Loader<NSString, NSString>()
        let identifier = loader.append { value in
            return value.appending("Block") as NSString
        }
        XCTAssertEqual(loader.load("Hello "), "Hello Block")
        
        loader.remove(identifier)
        loader.append(target: self, action: #selector(loaderAction(_:)))
        XCTAssertEqual(loader.load("Hello "), "Hello Target")
    }
    
    func testString() {
        let string = "String中文Emoji表情😀"
        let nsstring = string as NSString
        XCTAssertEqual(string.count, 16)
        XCTAssertEqual(nsstring.length, 17)
    }
    
    func testRuntime() {
        fw.setProperty("Value", forName: "testRuntime")
        XCTAssertEqual(fw.property(forName: "testRuntime") as? String, "Value")
        
        fw.setPropertyWeak(self, forName: "testRuntime2")
        XCTAssert(fw.property(forName: "testRuntime2") is Tests)
        
        fw.tempObject = 1
        XCTAssertEqual(fw.tempObject as? Int, 1)
        
        fw.bindObject(1, forKey: "testRuntime3")
        XCTAssertEqual(fw.boundInt(forKey: "testRuntime3"), 1)
        fw.removeBinding(forKey: "testRuntime3")
        XCTAssertEqual(fw.boundInt(forKey: "testRuntime3"), 0)
        
        XCTAssertEqual(fw.invokeMethod(#selector(loaderAction(_:)), object: "Hello ") as? String, "Hello Target")
    }
    
    func testSwizzle() {
        NSObject.fw.swizzleInstanceMethod(classForCoder, selector: #selector(originalAction), methodSignature: (@convention(c)(Tests, Selector) -> String).self, swizzleSignature: (@convention(block)(Tests) -> String).self) { store in {
            let value = store.original($0, store.selector)
            return value + " Action"
        }}
        
        NSObject.fw.swizzleClassMethod(classForCoder, selector: #selector(Tests.classAction)) { (store: SwizzleStore<@convention(c)(Tests.Type, Selector) -> String, @convention(block)(Tests.Type) -> String>) in {
            let value = store.original($0, store.selector)
            return value + " Action"
        }}
        
        fw.swizzleInstanceMethod(#selector(objectAction), identifier: "object", methodSignature: (@convention(c)(Tests, Selector) -> String).self, swizzleSignature: (@convention(block)(Tests) -> String).self) { store in { selfObject in
            let value = store.original(selfObject, store.selector)
            return value + " Action"
        }}
        
        XCTAssertEqual(originalAction(), "Original Action")
        XCTAssertEqual(Tests.classAction(), "Class Action")
        XCTAssertEqual(objectAction(), "Object Action")
        XCTAssertTrue(fw.isSwizzleInstanceMethod(#selector(objectAction), identifier: "object"))
        
        Tests.fw.exchangeInstanceMethod(#selector(exchangeAction), swizzleMethod: #selector(exchange2Action))
        Tests.fw.exchangeClassMethod(#selector(Tests.exchangeClassAction), swizzleMethod: #selector(Tests.exchange2ClassAction))
        
        XCTAssertEqual(exchangeAction(), "Exchange1Exchange2")
        XCTAssertEqual(Tests.exchangeClassAction(), "Exchange3Exchange4")
    }
    
    func testMessage() {
        var messageValue: Int = 0
        let messageName = Notification.Name.init(rawValue: "Test")
        let observer = fw.observeMessage(messageName) { _ in
            messageValue += 1
        }
        fw.sendMessage(messageName, toReceiver: self)
        fw.unobserveMessage(messageName, observer: observer)
        fw.sendMessage(messageName, toReceiver: self)
        XCTAssertEqual(messageValue, 1)
        
        var notificationValue: Int = 0
        let notificationName = Notification.Name.init(rawValue: "Test2")
        fw.observeNotification(notificationName, object: self) { _ in
            notificationValue += 2
        }
        fw.postNotification(notificationName, object: self, userInfo: nil)
        fw.postNotification(notificationName)
        fw.unobserveNotification(notificationName, object: self)
        fw.postNotification(notificationName, object: self, userInfo: nil)
        XCTAssertEqual(notificationValue, 2)
        
        var propertyValue: Int = 0
        fw.observeProperty("observeValue") { _, change in
            propertyValue += change[.newKey] as? Int ?? 0
        }
        observeValue = 1
        observeValue = 2
        fw.unobserveAllProperties()
        observeValue = 4
        XCTAssertEqual(propertyValue, 3)
    }
    
    func testDefaults() {
        defaultsValue = "testValue"
        XCTAssertEqual(defaultsValue, "testValue")
        defaultsValue = ""
        XCTAssertEqual(defaultsValue, "")
        
        defaultsOptionValue = 1
        XCTAssertEqual(defaultsOptionValue, 1)
        defaultsOptionValue = nil
        XCTAssertEqual(defaultsOptionValue, 0)
        
        defaultsNilValue = 1
        XCTAssertEqual(defaultsNilValue, 1)
        defaultsNilValue = nil
        XCTAssertEqual(defaultsNilValue, nil)
    }
    
    func testRouter() {
        var parameter = TestParameter()
        parameter.isTrue = true
        parameter.routerSource = "test"
        parameter.routerOptions = .embedInNavigation
        parameter.routerHandler = { _, _ in }
        parameter.ignoreValue = 1
        parameter.merge(from: [
            "routerSource": "test2",
        ])
        XCTAssertEqual(parameter.routerSource, "test2")
        var dict = parameter.dictionaryValue
        XCTAssertEqual(dict["isTrue"] as? Bool, parameter.isTrue)
        XCTAssertEqual(dict["ignoreValue"] as? Int, nil)
        XCTAssertEqual(dict[Router.Parameter.routerSourceKey] as? String, parameter.routerSource)
        XCTAssertEqual(dict[Router.Parameter.routerOptionsKey] as? NavigatorOptions ?? [], parameter.routerOptions)
        XCTAssertTrue(dict[Router.Parameter.routerHandlerKey] != nil)
        
        dict["isTrue"] = "true"
        let object = TestParameter(dictionaryValue: dict)
        XCTAssertTrue(object.isTrue)
        XCTAssertEqual(object.ignoreValue, 0)
        XCTAssertEqual(object.routerSource, parameter.routerSource)
        XCTAssertEqual(object.routerOptions, parameter.routerOptions)
        XCTAssertTrue(object.routerHandler != nil)
    }
    
    func testValidator() {
        validateValue = "errorValue"
        XCTAssertEqual(validateValue, "")
        validateValue = "test@test.com"
        XCTAssertEqual(validateValue, "test@test.com")
        validateValue = "errorValue"
        XCTAssertEqual(validateValue, "")
        
        validateOptionValue = "errorValue"
        XCTAssertEqual(validateOptionValue, "")
        validateOptionValue = "test@test.com"
        XCTAssertEqual(validateOptionValue, "test@test.com")
        validateOptionValue = nil
        XCTAssertEqual(validateOptionValue, "")
        
        validateNilValue = "errorValue"
        XCTAssertEqual(validateNilValue, nil)
        validateNilValue = "test@test.com"
        XCTAssertEqual(validateNilValue, "test@test.com")
        validateNilValue = nil
        XCTAssertEqual(validateNilValue, nil)
    }
    
    func testOptional() {
        var string: String?
        XCTAssertEqual(string.then({ _ in 3 }), nil)
        string = string ?? "Hello"
        XCTAssertEqual(string, "Hello")
        
        string = "Hello"
        string = string.then { value in
            value + " World"
        }
        XCTAssertEqual(string, "Hello World")
    }
    
    func testEnum() {
        let optionalVal: TestEnum? = nil
        XCTAssertTrue(optionalVal == nil)
        XCTAssertTrue(optionalVal != TestEnum.none)
        
        var val: TestEnum = .none
        XCTAssertTrue(val == .none)
        XCTAssertTrue(val != .partly(0.5))
        XCTAssertTrue(val != .fully)
        
        val = .partly(0.5)
        XCTAssertTrue(val != .none)
        XCTAssertTrue(val == .partly(0.5))
        XCTAssertTrue(val != .partly(0.8))
        XCTAssertTrue(val != .fully)
        
        val = .fully
        XCTAssertTrue(val != .none)
        XCTAssertTrue(val != .partly(0.5))
        XCTAssertTrue(val == .fully)
    }
    
    func testBlock() {
        var value: Int = 0
        var block = MulticastBlock()
        block.append {
            value += 1
        }
        block.invoke()
        XCTAssertEqual(value, 1)
        block.append {
            value += 1
        }
        XCTAssertEqual(value, 1)
        block.invoke()
        XCTAssertEqual(value, 3)
        
        value = 0
        block = MulticastBlock()
        block.autoRemoved = true
        block.append {
            value += 1
        }
        block.invoke()
        XCTAssertEqual(value, 1)
        block.append {
            value += 1
        }
        XCTAssertEqual(value, 1)
        block.invoke()
        XCTAssertEqual(value, 2)
        
        value = 0
        block = MulticastBlock()
        block.invokeOnce = true
        block.append {
            value += 1
        }
        block.invoke()
        XCTAssertEqual(value, 1)
        block.append {
            value += 1
        }
        XCTAssertEqual(value, 2)
        block.invoke()
        XCTAssertEqual(value, 2)
    }
    
}

// MARK: - Private
extension Tests {
    
    class TestParameter: Router.Parameter {
        @MappedValue var isTrue: Bool = false
        var ignoreValue: Int = 0
    }
    
    #if FWMacroSPM
    @MappedValueMacro
    class TestMappedValueModel {
        var id: Int = 0
        @MappedValue
        var name: String?
        
        var _ignoreValue: String?
        var ignoreValue_: String?
        var ignoreValue: String { "" }
        static var staticId: Int = 0
        func testMethod() {}
    }
    
    @MappedValueMacro
    class TestSubMappedValueModel: TestMappedValueModel {
        var childId: Int = 0
        @MappedValue 
        var childName: String?
        
        var _childIgnoreValue: String?
        var childIgnoreValue_: String?
        var childIgnoreValue: String { "" }
        static var staticChildId: Int = 0
        func childTestMethod() {}
    }
    #endif
    
    enum TestEnum: Equatable {
        case none
        case partly(CGFloat)
        case fully
    }
    
    @objc func loaderAction(_ input: NSString) -> NSString? {
        return input.appending("Target") as NSString
    }
    
    @objc func originalAction() -> String {
        return "Original"
    }
    
    @objc class func classAction() -> String {
        return "Class"
    }
    
    @objc func objectAction() -> String {
        return "Object"
    }
    
    @objc func exchangeAction() -> String {
        return "Exchange1"
    }
    
    @objc func exchange2Action() -> String {
        return exchange2Action() + "Exchange2"
    }
    
    @objc class func exchangeClassAction() -> String {
        return "Exchange3"
    }
    
    @objc class func exchange2ClassAction() -> String {
        return exchange2ClassAction() + "Exchange4"
    }
    
}
