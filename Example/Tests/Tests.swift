import XCTest
import FWFramework
#if FWMacroSPM
import FWObjC
#endif

class Tests: XCTestCase {
    
    // MARK: - Accessor
    dynamic var observeValue: Int = 0
    
    // MARK: - Test
    func testLoader() {
        let loader = Loader<NSString, NSString>()
        let identifier = loader.add { value in
            return value.appending("Block") as NSString
        }
        XCTAssertEqual(loader.load("Hello "), "Hello Block")
        
        loader.remove(identifier)
        loader.add(target: self, action: #selector(loaderAction(_:)))
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
        let observeId = fw.observeMessage(messageName) { _ in
            messageValue += 1
        }
        fw.sendMessage(messageName, toReceiver: self)
        fw.unobserveMessage(messageName, identifier: observeId)
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
    
}

// MARK: - Private
extension Tests {
    
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
