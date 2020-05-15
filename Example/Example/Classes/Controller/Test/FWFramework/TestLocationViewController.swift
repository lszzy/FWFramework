//
//  TestLocationViewController.swift
//  Example
//
//  Created by wuyong on 2020/3/18.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

@objcMembers class TestLocationViewController: BaseViewController {
    lazy var startButton: UIButton = {
        let view = UIButton.fwButton(with: UIFont.appFontNormal(), titleColor: UIColor.appColorBlackOpacityLarge(), title: "Start")
        view.frame = CGRect(x: 20, y: 50, width: 60, height: 50)
        view.fwAddTouch { (sender) in
            FWLocationManager.sharedInstance.startUpdateLocation()
        }
        return view
    }()
    
    lazy var stopButton: UIButton = {
        let view = UIButton.fwButton(with: UIFont.appFontNormal(), titleColor: UIColor.appColorBlackOpacityLarge(), title: "Stop")
        view.frame = CGRect(x: 100, y: 50, width: 60, height: 50)
        view.fwAddTouch { (sender) in
            FWLocationManager.sharedInstance.stopUpdateLocation()
        }
        return view
    }()
    
    lazy var configButton: UIButton = {
        let view = UIButton.fwButton(with: UIFont.appFontNormal(), titleColor: UIColor.appColorBlackOpacityLarge(), title: "Once")
        view.frame = CGRect(x: 180, y: 50, width: 60, height: 50)
        view.fwAddTouch { (sender) in
            FWLocationManager.sharedInstance.stopWhenCompleted = !FWLocationManager.sharedInstance.stopWhenCompleted
        }
        return view
    }()
    
    lazy var resultLabel: UILabel = {
        let view = UILabel.fwLabel(with: UIFont.appFontNormal(), textColor: UIColor.appColorBlackOpacityLarge(), text: "")
        view.numberOfLines = 0
        view.frame = CGRect(x: 20, y: 100, width: FWScreenWidth - 40, height: 450)
        return view
    }()
    
    override func renderView() {
        view.addSubview(startButton)
        view.addSubview(stopButton)
        view.addSubview(configButton)
        view.addSubview(resultLabel)
    }
    
    override func renderModel() {
        FWLocationManager.sharedInstance.locationChanged = { [weak self] (manager) in
            if manager.error != nil {
                self?.resultLabel.text = manager.error?.localizedDescription
            } else {
                self?.resultLabel.text = FWLocationStringWithCoordinate(manager.location?.coordinate ?? CLLocationCoordinate2DMake(0, 0));
            }
        }
    }
    
    override func renderData() {
        let json: FWJSON = FWJSON([
            "array": [12.34, 56.78],
            "users": [
                [
                    "id": 987654,
                    "info": [
                        "name": "jack",
                        "email": "jack@gmail.com"
                    ],
                    "feeds": [98833, 23443, 213239, 23232]
                ],
                [
                    "id": 654321,
                    "info": [
                        "name": "jeffgukang",
                        "email": "jeffgukang@gmail.com"
                    ],
                    "feeds": [12345, 56789, 12423, 12412]
                ]
            ]
            ])

        // Getting a double from a JSON Array
        json["array"][0].double

        // Getting an array of string from a JSON Array
        let arrayOfString = json["users"].arrayValue.map({$0["info"]["name"]})
        print(arrayOfString)

        // Getting a string from a JSON Dictionary
        json["users"][0]["info"]["name"].stringValue

        // Getting a string using a path to the element
        let path = ["users", 1, "info", "name"] as [FWJSONSubscriptType]
        var name = json["users", 1, "info", "name"].string

        // With a custom way
        let keys: [FWJSONSubscriptType] = ["users", 1, "info", "name"]
        name = json[keys].string

        // Just the same
        name = json["users"][1]["info"]["name"].string

        // Alternatively
        name = json["users", 1, "info", "name"].string
        
        // If json is .Dictionary
        for (key, subJson):(String, FWJSON) in json {
            //Do something you want
            print(key)
            print(subJson)
        }

        /*The first element is always a String, even if the JSON is an Array*/
        //If json is .Array
        //The `index` is 0..<json.count's string value
        for (index, subJson):(String, FWJSON) in json["array"] {
            //Do something you want
            print("\(index): \(subJson)")
        }
        
        let errorJson = FWJSON(["name", "age"])
        if let name = errorJson[999].string {
            //Do something you want
            print(name)
        } else {
            print(errorJson[999].error!) // "Array[999] is out of bounds"
        }

        let errorJson2 = FWJSON(["name": "Jack", "age": 25])
        if let name = errorJson2["address"].string {
            //Do something you want
            print(name)
        } else {
            print(errorJson2["address"].error!) // "Dictionary["address"] does not exist"
        }

        let errorJson3 = FWJSON(12345)
        if let age = errorJson3[0].string {
            //Do something you want
            print(age)
        } else {
            print(errorJson3[0])       // "Array[0] failure, It is not an array"
            print(errorJson3[0].error!) // "Array[0] failure, It is not an array"
        }

        if let name = json["name"].string {
            //Do something you want
            print(name)
        } else {
            print(json["name"])       // "Dictionary[\"name"] failure, It is not an dictionary"
            print(json["name"].error!) // "Dictionary[\"name"] failure, It is not an dictionary"
        }
        
        // Example json
        let jsonOG: FWJSON = FWJSON([
            "id": 987654,
            "user": [
                "favourites_count": 8,
                "name": "jack",
                "email": "jack@gmail.com",
                "is_translator": true
            ]
            ])

        //NSNumber
        if let id = jsonOG["user"]["favourites_count"].number {
            //Do something you want
            print(id)
        } else {
            //Print the error
            print(jsonOG["user"]["favourites_count"].error!)
        }

        //String
        if let id = jsonOG["user"]["name"].string {
            //Do something you want
            print(id)
        } else {
            //Print the error
            print(jsonOG["user"]["name"].error!)
        }

        //Bool
        if let id = jsonOG["user"]["is_translator"].bool {
            //Do something you want
            print(id)
        } else {
            //Print the error
            print(jsonOG["user"]["is_translator"].error!)
        }
        
        // Example json
        let jsonNOG: FWJSON = FWJSON([
            "id": 987654,
            "name": "jack",
            "list": [
                ["number": 1],
                ["number": 2],
                ["number": 3]
            ],
            "user": [
                "favourites_count": 8,
                "email": "jack@gmail.com",
                "is_translator": true
            ]
            ])

        //If not a Number or nil, return 0
        let idNOG: Int = jsonOG["id"].intValue
        print(idNOG)

        //If not a String or nil, return ""
        let nameNOG: String = jsonNOG["name"].stringValue
        print(nameNOG)

        //If not an Array or nil, return []
        let listNOG: Array = jsonNOG["list"].arrayValue
        print(listNOG)

        //If not a Dictionary or nil, return [:]
        let userNOG: Dictionary = jsonNOG["user"].dictionaryValue
        print(userNOG)
        
        var jsonSetter: FWJSON = FWJSON([
            "id": 987654,
            "name": "jack",
            "array": [0, 2, 4, 6, 8],
            "double": 3513.352,
            "dictionary": [
                "name": "Jack",
                "sex": "man"
            ],
            "user": [
                "favourites_count": 8,
                "email": "jack@gmail.com",
                "is_translator": true
            ]
            ])

        jsonSetter["name"] = FWJSON("new-name")
        jsonSetter["array"][0] = FWJSON(1)

        jsonSetter["id"].int = 123456
        jsonSetter["double"].double = 123456.789
        jsonSetter["name"].string = "Jeff"
        jsonSetter.arrayObject = [1, 2, 3, 4]
        jsonSetter.dictionaryObject = ["name": "Jeff", "age": 20]
        
        let rawObject: Any = jsonSetter.object

        let rawValue: Any = jsonSetter.rawValue

        //convert the JSON to raw NSData
        do {
            let rawData = try jsonSetter.rawData()
            print(rawData)
        } catch {
            print("Error \(error)")
        }

        //convert the JSON to a raw String
        if let rawString = jsonSetter.rawString() {
            print(rawString)
        } else {
            print("Nil")
        }

        // shows you whether value specified in JSON or not
        if jsonSetter["name"].exists() {
            print(jsonSetter["name"])
        }

        // StringLiteralConvertible
        let jsonLiteralString: FWJSON = "I'm a json"

        // IntegerLiteralConvertible
        let jsonLiteralInt: FWJSON =  12345

        // BooleanLiteralConvertible
        let jsonLiteralBool: FWJSON =  true

        // FloatLiteralConvertible
        let jsonLiteralFloat: FWJSON =  2.8765

        // DictionaryLiteralConvertible
        let jsonLiteralDictionary: FWJSON =  ["I": "am", "a": "json"]

        // ArrayLiteralConvertible
        let jsonLiteralArray: FWJSON =  ["I", "am", "a", "json"]

        // With subscript in array
        var jsonSubscriptArray: FWJSON =  [1, 2, 3]
        jsonSubscriptArray[0] = 100
        jsonSubscriptArray[1] = 200
        jsonSubscriptArray[2] = 300
        jsonSubscriptArray[999] = 300 // Don't worry, nothing will happen

        // With subscript in dictionary
        var jsonSubscriptDictionary: FWJSON = ["name": "Jack", "age": 25]
        jsonSubscriptDictionary["name"] = "Mike"
        jsonSubscriptDictionary["age"] = "25" // It's OK to set String
        jsonSubscriptDictionary["address"] = "L.A" // Add the "address": "L.A." in json

        // Array & Dictionary
        var jsonArrayDictionary: FWJSON =  ["name": "Jack", "age": 25, "list": ["a", "b", "c", ["what": "this"]]]
        jsonArrayDictionary["list"][3]["what"] = "that"
        jsonArrayDictionary["list", 3, "what"] = "that"

        let arrayDictionarypath: [FWJSONSubscriptType] = ["list", 3, "what"]
        jsonArrayDictionary[arrayDictionarypath] = "that"

        // With other JSON objects
        let user: FWJSON = ["username": "Steve", "password": "supersecurepassword"]
        let auth: FWJSON = [
            "user": user.object, //use user.object instead of just user
            "apikey": "supersecretapitoken"
        ]
        
        var original: FWJSON = [
            "first_name": "John",
            "age": 20,
            "skills": ["Coding", "Reading"],
            "address": [
                "street": "Front St",
                "zip": "12345"
            ]
        ]

        let update: FWJSON = [
            "last_name": "Doe",
            "age": 21,
            "skills": ["Writing"],
            "address": [
                "zip": "12342",
                "city": "New York City"
            ]
        ]

        try? original.merge(with: update)
        print(original)

        let stringRepresentationDict = ["1": 2, "2": "two", "3": nil] as [String: Any?]
        let stringRepresentionJson: FWJSON = FWJSON(stringRepresentationDict)
        let representation = stringRepresentionJson.rawString([.castNilToNSNull: true])
        print(representation!)
    }
}
