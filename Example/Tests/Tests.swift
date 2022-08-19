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
    
}

// MARK: - Private
extension Tests {
    
    @objc func loaderAction(_ input: String) -> String {
        return input + "Target"
    }
    
}
