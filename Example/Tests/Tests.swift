import XCTest
import FWFramework

class Tests: XCTestCase {
    
    // MARK: - Accessor
    dynamic var observeValue: Int = 0
    
    // MARK: - Test
    func testLoader() {
        let loader = Loader<String, String>()
        let identifier = loader.add { value in
            return value + "Block"
        }
        XCTAssertEqual(loader.load("Hello "), "Hello Block")
        
        loader.remove(identifier)
        loader.add(target: self, action: #selector(loaderAction(_:)))
        XCTAssertEqual(loader.load("Hello "), "Hello Target")
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
        Swizzle.swizzleInstanceMethod(classForCoder, selector: #selector(originalAction)) { targetClass, originalCMD, originalIMP in
            let swizzleIMP: @convention(block)(Tests) -> String = { selfObject in
                typealias originalMSGType = @convention(c)(Tests, Selector) -> String
                let originalMSG: originalMSGType = unsafeBitCast(originalIMP(), to: originalMSGType.self)
                let value = originalMSG(selfObject, originalCMD)
                
                return value + " Action"
            }
            return unsafeBitCast(swizzleIMP, to: AnyObject.self)
        }
        
        Swizzle.swizzleClassMethod(classForCoder, selector: #selector(Tests.classAction)) { targetClass, originalCMD, originalIMP in
            let swizzleIMP: @convention(block)(Tests.Type) -> String = { selfObject in
                typealias originalMSGType = @convention(c)(Tests.Type, Selector) -> String
                let originalMSG: originalMSGType = unsafeBitCast(originalIMP(), to: originalMSGType.self)
                let value = originalMSG(selfObject, originalCMD)
                
                return value + " Action"
            }
            return unsafeBitCast(swizzleIMP, to: AnyObject.self)
        }
        
        fw.swizzleInstanceMethod(#selector(objectAction), identifier: "object") { targetClass, originalCMD, originalIMP in
            let swizzleIMP: @convention(block)(Tests) -> String = { selfObject in
                typealias originalMSGType = @convention(c)(Tests, Selector) -> String
                let originalMSG: originalMSGType = unsafeBitCast(originalIMP(), to: originalMSGType.self)
                let value = originalMSG(selfObject, originalCMD)
                
                return value + " Action"
            }
            return unsafeBitCast(swizzleIMP, to: AnyObject.self)
        }
        
        XCTAssertEqual(originalAction(), "Original Action")
        XCTAssertEqual(Tests.classAction(), "Class Action")
        XCTAssertEqual(objectAction(), "Object Action")
        XCTAssertTrue(fw.isSwizzleInstanceMethod(#selector(objectAction), identifier: "object"))
        
        Swizzle.exchangeInstanceMethod(classForCoder, originalSelector: #selector(exchangeAction), swizzleSelector: #selector(exchange2Action))
        Swizzle.exchangeClassMethod(classForCoder, originalSelector: #selector(Tests.exchangeClassAction), swizzleSelector: #selector(Tests.exchange2ClassAction))
        
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
    
    @objc func loaderAction(_ input: String) -> String {
        return input + "Target"
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
