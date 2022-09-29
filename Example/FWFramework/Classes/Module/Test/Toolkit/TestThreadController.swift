//
//  TestThreadController.swift
//  FWFramework_Example
//
//  Created by wuyong on 2022/9/28.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import FWFramework

class TestThreadController: UIViewController, TableViewControllerProtocol {
    
    var queueCount: Int = 10000
    
    func setupTableStyle() -> UITableView.Style {
        .grouped
    }
    
    func setupNavbar() {
        let publicKey = "-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDI2bvVLVYrb4B0raZgFP60VXY\ncvRmk9q56QiTmEm9HXlSPq1zyhyPQHGti5FokYJMzNcKm0bwL1q6ioJuD4EFI56D\na+70XdRz1CjQPQE3yXrXXVvOsmq9LsdxTFWsVBTehdCmrapKZVVx6PKl7myh0cfX\nQmyveT/eqyZK1gYjvQIDAQAB\n-----END PUBLIC KEY-----"
        let privateKey = "-----BEGIN PRIVATE KEY-----\nMIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAMMjZu9UtVitvgHS\ntpmAU/rRVdhy9GaT2rnpCJOYSb0deVI+rXPKHI9Aca2LkWiRgkzM1wqbRvAvWrqK\ngm4PgQUjnoNr7vRd1HPUKNA9ATfJetddW86yar0ux3FMVaxUFN6F0KatqkplVXHo\n8qXubKHRx9dCbK95P96rJkrWBiO9AgMBAAECgYBO1UKEdYg9pxMX0XSLVtiWf3Na\n2jX6Ksk2Sfp5BhDkIcAdhcy09nXLOZGzNqsrv30QYcCOPGTQK5FPwx0mMYVBRAdo\nOLYp7NzxW/File//169O3ZFpkZ7MF0I2oQcNGTpMCUpaY6xMmxqN22INgi8SHp3w\nVU+2bRMLDXEc/MOmAQJBAP+Sv6JdkrY+7WGuQN5O5PjsB15lOGcr4vcfz4vAQ/uy\nEGYZh6IO2Eu0lW6sw2x6uRg0c6hMiFEJcO89qlH/B10CQQDDdtGrzXWVG457vA27\nkpduDpM6BQWTX6wYV9zRlcYYMFHwAQkE0BTvIYde2il6DKGyzokgI6zQyhgtRJ1x\nL6fhAkB9NvvW4/uWeLw7CHHVuVersZBmqjb5LWJU62v3L2rfbT1lmIqAVr+YT9CK\n2fAhPPtkpYYo5d4/vd1sCY1iAQ4tAkEAm2yPrJzjMn2G/ry57rzRzKGqUChOFrGs\nlm7HF6CQtAs4HC+2jC0peDyg97th37rLmPLB9txnPl50ewpkZuwOAQJBAM/eJnFw\nF5QAcL4CYDbfBKocx82VX/pFXng50T7FODiWbbL4UnxICE0UBFInNNiWJxNEb6jL\n5xd0pcy9O2DOeso=\n-----END PRIVATE KEY-----"
        let encodeString = "CKiZsP8wfKlELNfWNC2G4iLv0RtwmGeHgzHec6aor4HnuOMcYVkxRovNj2r0Iu3ybPxKwiH2EswgBWsi65FOzQJa01uDVcJImU5vLrx1ihJ/PADUVxAMFjVzA3+Clbr2fwyJXW6dbbbymupYpkxRSfF5Gq9KyT+tsAhiSNfU6akgNGh4DENoA2AoKoWhpMEawyIubBSsTdFXtsHK0Ze0Cyde7oI2oh8ePOVHRuce6xYELYzmZY5yhSUoEb4+/44fbVouOCTl66ppUgnR5KjmIvBVEJLBq0SgoZfrGiA3cB08q4hb5EJRW72yPPQNqJxcQTPs8SxXa9js8ZryeSxyrw=="
        let originString = "FWApplication"
        
        FW.debug("Original: %@", originString)
        let publicEncode = originString.fw.utf8Data?.fw.rsaEncrypt(publicKey: publicKey)?.fw.utf8String ?? ""
        FW.debug("Encrypted Public: %@", publicEncode)
        var privateDecode = publicEncode.fw.utf8Data?.fw.rsaDecrypt(privateKey: privateKey)?.fw.utf8String ?? ""
        FW.debug("Decrypted Private: %@", privateDecode)
        
        privateDecode = encodeString.fw.utf8Data?.fw.rsaDecrypt(privateKey: privateKey)?.fw.utf8String ?? ""
        FW.debug("Decrypted Server: %@", privateDecode)
        let privateEncode = originString.fw.utf8Data?.fw.rsaSign(privateKey: privateKey)?.fw.utf8String ?? ""
        FW.debug("Sign Private: %@", privateEncode)
        let publicDecode = privateEncode.fw.utf8Data?.fw.rsaVerify(publicKey: publicKey)?.fw.utf8String ?? ""
        FW.debug("Verify Public: %@", publicDecode)
    }
    
    func setupSubviews() {
        tableData.addObjects(from: [
            ["Associated不加锁", "onLock1"],
            ["Associated加锁", "onLock2"],
            ["NSMutableArray", "onArray1"],
            ["FWMutableArray", "onArray2"],
            ["NSMutableArray加锁", "onArray3"],
            ["NSMutableDictionary", "onDictionary1"],
            ["FWMutableDictionary", "onDictionary2"],
            ["NSMutableDictionary加锁", "onDictionary3"],
            ["FWCacheMemory", "onCache1"],
            ["FWCacheMemory加锁", "onCache2"],
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.fw.cell(tableView: tableView)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        cell.textLabel?.text = rowData[0]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let rowData = tableData.object(at: indexPath.row) as! [String]
        fw.invokeMethod(NSSelectorFromString(rowData[1]))
    }
    
    func onQueue(_ block: @escaping BlockVoid, completion: @escaping BlockVoid) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 10
        for _ in 0 ..< queueCount {
            let operation = BlockOperation(block: block)
            queue.addOperation(operation)
        }
        queue.waitUntilAllOperationsAreFinished()
        completion()
    }
    
    func onResult(_ count: Int) {
        fw.showAlert(title: "结果", message: "期望：\(queueCount)\n实际：\(count)")
    }
    
    @objc func onLock1() {
        let key = "onLock1"
        self.fw.bindInt(0, forKey: key)
        
        onQueue { [weak self] in
            guard let self = self else { return }
            
            var value = self.fw.boundInt(forKey: key)
            value += 1
            self.fw.bindInt(value, forKey: key)
        } completion: { [weak self] in
            guard let self = self else { return }
            
            let value = self.fw.boundInt(forKey: key)
            self.onResult(value)
        }
    }
    
    @objc func onLock2() {
        let key = "onLock2"
        self.fw.bindInt(0, forKey: key)
        
        onQueue { [weak self] in
            guard let self = self else { return }
            
            self.fw.lock()
            var value = self.fw.boundInt(forKey: key)
            value += 1
            self.fw.bindInt(value, forKey: key)
            self.fw.unlock()
        } completion: { [weak self] in
            guard let self = self else { return }
            
            let value = self.fw.boundInt(forKey: key)
            self.onResult(value)
        }
    }
    
    @objc func onArray1() {
        let key = "onArray1"
        let array = NSMutableArray()
        array.add(NSObject())
        
        onQueue {
            
            array.enumerateObjects { arg, idx, stop in
                guard let obj = arg as? NSObject else { return }
                let value = obj.fw.boundInt(forKey: key)
                obj.fw.bindInt(value + 1, forKey: key)
            }
        } completion: { [weak self] in
            
            guard let obj = array.firstObject as? NSObject else { return }
            let value = obj.fw.boundInt(forKey: key)
            self?.onResult(value)
        }
    }
    
    @objc func onArray2() {
        let key = "onArray2"
        let array = MutableArray<NSObject>()
        array.add(NSObject())
        
        onQueue {
            
            array.enumerateObjects { arg, idx, stop in
                guard let obj = arg as? NSObject else { return }
                let value = obj.fw.boundInt(forKey: key)
                obj.fw.bindInt(value + 1, forKey: key)
            }
        } completion: { [weak self] in
            
            guard let obj = array.firstObject as? NSObject else { return }
            let value = obj.fw.boundInt(forKey: key)
            self?.onResult(value)
        }
    }
    
    @objc func onArray3() {
        let key = "onArray3"
        let array = NSMutableArray()
        array.add(NSObject())
        
        onQueue { [weak self] in
            
            self?.fw.lock()
            array.enumerateObjects { arg, idx, stop in
                guard let obj = arg as? NSObject else { return }
                let value = obj.fw.boundInt(forKey: key)
                obj.fw.bindInt(value + 1, forKey: key)
            }
            self?.fw.unlock()
        } completion: { [weak self] in
            
            guard let obj = array.firstObject as? NSObject else { return }
            let value = obj.fw.boundInt(forKey: key)
            self?.onResult(value)
        }
    }
    
    @objc func onDictionary1() {
        let key = "object"
        let dict = NSMutableDictionary()
        dict.setObject(NSObject(), forKey: key as NSString)
        
        onQueue {
            
            dict.enumerateKeysAndObjects { _, arg, stop in
                guard let obj = arg as? NSObject else { return }
                let value = obj.fw.boundInt(forKey: key)
                obj.fw.bindInt(value + 1, forKey: key)
            }
        } completion: { [weak self] in
            
            guard let obj = dict.object(forKey: key) as? NSObject else { return }
            let value = obj.fw.boundInt(forKey: key)
            self?.onResult(value)
        }
    }
    
    @objc func onDictionary2() {
        let key = "object"
        let dict = MutableDictionary<NSString, NSObject>()
        dict.setObject(NSObject(), forKey: key as NSString)
        
        onQueue {
            
            dict.enumerateKeysAndObjects { _, arg, stop in
                guard let obj = arg as? NSObject else { return }
                let value = obj.fw.boundInt(forKey: key)
                obj.fw.bindInt(value + 1, forKey: key)
            }
        } completion: { [weak self] in
            
            guard let obj = dict.object(forKey: key) as? NSObject else { return }
            let value = obj.fw.boundInt(forKey: key)
            self?.onResult(value)
        }
    }
    
    @objc func onDictionary3() {
        let key = "object"
        let dict = NSMutableDictionary()
        dict.setObject(NSObject(), forKey: key as NSString)
        
        onQueue { [weak self] in
            
            self?.fw.lock()
            dict.enumerateKeysAndObjects { _, arg, stop in
                guard let obj = arg as? NSObject else { return }
                let value = obj.fw.boundInt(forKey: key)
                obj.fw.bindInt(value + 1, forKey: key)
            }
            self?.fw.unlock()
        } completion: { [weak self] in
            
            guard let obj = dict.object(forKey: key) as? NSObject else { return }
            let value = obj.fw.boundInt(forKey: key)
            self?.onResult(value)
        }
    }
    
    @objc func onCache1() {
        let key = "cache"
        CacheMemory.shared.setObject(NSNumber(value: 0), forKey: key)
        
        onQueue {
            
            let value = CacheMemory.shared.object(forKey: key) as? NSNumber ?? NSNumber(value: 0)
            CacheMemory.shared.setObject(NSNumber(value: value.intValue + 1), forKey: key)
        } completion: { [weak self] in
            
            let value = CacheMemory.shared.object(forKey: key) as? NSNumber ?? NSNumber(value: 0)
            self?.onResult(value.intValue)
        }
    }
    
    @objc func onCache2() {
        let key = "cache"
        CacheMemory.shared.setObject(NSNumber(value: 0), forKey: key)
        
        onQueue { [weak self] in
            
            self?.fw.lock()
            let value = CacheMemory.shared.object(forKey: key) as? NSNumber ?? NSNumber(value: 0)
            CacheMemory.shared.setObject(NSNumber(value: value.intValue + 1), forKey: key)
            self?.fw.unlock()
        } completion: { [weak self] in
            
            let value = CacheMemory.shared.object(forKey: key) as? NSNumber ?? NSNumber(value: 0)
            self?.onResult(value.intValue)
        }
    }
    
}
