import XCTest
import FWFramework

class Tests: XCTestCase {
    
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
    
}

// MARK: - Private
extension Tests {
    
    @objc func loaderAction(_ input: String) -> String {
        return input + "Target"
    }
    
}
