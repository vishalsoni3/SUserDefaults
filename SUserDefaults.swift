//
//  SUserDefaults.swift
//  TestApp
//
//  Created by Kitsol on 1/2/19.
//  Copyright © 2019 Kitsol. All rights reserved.
//

import Foundation
import UIKit

private let SecClass: String! = kSecClass as String
private let SecAttrService: String! = kSecAttrService as String
private let SecReturnAttributes: String = kSecReturnAttributes as String
private let SecMatchLimit: String! = kSecMatchLimit as String
private let SecAttrAccount: String! = kSecAttrAccount as String
private let SecAttrGeneric: String! = kSecAttrGeneric as String
private let SecValueData: String! = kSecValueData as String
private let SecReturnData: String! = kSecReturnData as String

open class SUserDefaults {
    
    public static let standard = SUserDefaults()
    
    private (set) public var serviceName: String
    
    private static let defaultServiceName: String = {
        return "ProtectedData"
    }()
    
    private convenience init() {
        self.init(serviceName: SUserDefaults.defaultServiceName)
    }
    
    public init(serviceName: String) {
        self.serviceName = serviceName
    }
    
    // Get all keys
    open func allKeys() -> Set<String> {
        let keychainQueryDictionary: [String: Any] = [
            SecClass: kSecClassGenericPassword,
            SecAttrService: serviceName,
            SecReturnAttributes: kCFBooleanTrue,
            SecMatchLimit: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQueryDictionary as CFDictionary, &result)
        guard status == errSecSuccess else {
            return []
        }
        
        var keys = Set<String>()
        if let results = result as? [[AnyHashable: Any]] {
            for attributes in results {
                if let accountData = attributes[SecAttrAccount] as? Data,
                    let key = String(data: accountData, encoding: .utf8) {
                    keys.insert(key)
                }
                else if let accountData = attributes[kSecAttrAccount] as? Data,
                    let key = String(data: accountData, encoding: .utf8) {
                    keys.insert(key)
                }
            }
        }
        return keys
    }
    
    
    open func interger(_ forKey: String) -> Int? {
        guard let number = object(forKey) as? NSNumber else {
            return nil
        }
        return number.intValue
    }
    
    open func float(_ forKey: String) -> Float? {
        guard let number = object(forKey) as? NSNumber else {
            return nil
        }
        return number.floatValue
    }
    
    open func double(_ forKey: String) -> Double? {
        guard let number = object(forKey) as? NSNumber else {
            return nil
        }
        return number.doubleValue
    }
    
    open func bool(_ forKey: String) -> Bool? {
        guard let number = object(forKey) as? NSNumber else {
            return nil
        }
        return number.boolValue
    }
    
    open func string(_ forKey: String) -> String? {
        guard let keychainData = data(forKey) else {
            return nil
        }
        return String(data: keychainData, encoding: .utf8)
    }
    
    open func image(_ forKey: String) -> UIImage? {
        guard let keychainData = data(forKey) else {
            return nil
        }
        return UIImage(data: keychainData)
    }
    
    // Retrive NSCoding data with specified key
    open func object(_ forKey: String) -> NSCoding? {
        guard let keychainData = data(forKey) else {
            return nil
        }
        return NSKeyedUnarchiver.unarchiveObject(with: keychainData) as? NSCoding
    }
    
    // Retrive object with specified key
    open func data(_ forKey: String) -> Data? {
        var keychainQueryDictionary = setupKeychainQueryDictionary(forKey)
        keychainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne
        keychainQueryDictionary[SecReturnData] = kCFBooleanTrue
        
        var result: AnyObject?
        let status = SecItemCopyMatching(keychainQueryDictionary as CFDictionary, &result)
        return status == noErr ? result as? Data : nil
    }
    
    
    @discardableResult open func set(_ value: Int, forKey: String) -> Bool {
        return set(NSNumber(value: value), forKey: forKey)
    }
    
    @discardableResult open func set(_ value: Float, forKey: String) -> Bool {
        return set(NSNumber(value: value), forKey: forKey)
    }
    
    @discardableResult open func set(_ value: Double, forKey: String) -> Bool {
        return set(NSNumber(value: value), forKey: forKey)
    }
    
    @discardableResult open func set(_ value: Bool, forKey: String) -> Bool {
        return set(NSNumber(value: value), forKey: forKey)
    }
    
    @discardableResult open func set(_ value: NSCoding, forKey: String) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: value)
        return set(data, forKey: forKey)
    }
    
    @discardableResult open func set(_ value: String, forKey: String) -> Bool {
        if let data = value.data(using: .utf8) {
            return set(data, forKey: forKey)
        }
        else {
            return false
        }
    }
    
    @discardableResult open func set(_ value: UIImage, forKey: String) -> Bool {
        if let data = value.pngData() {
            return set(data, forKey: forKey)
        }
        else {
            return false
        }
    }
    
    @discardableResult open func set(_ value: Data, forKey: String) -> Bool {
        var keychainQueryDictionary = setupKeychainQueryDictionary(forKey)
        keychainQueryDictionary[SecValueData] = value
        let success = SecItemAdd(keychainQueryDictionary as CFDictionary, nil)
        if success == errSecSuccess {
            print("Saved successfully")
            return true
        }
        else if success == errSecDuplicateItem {
            print("Duplicate entry update..")
            return update(value, forKey: forKey)
        }
        else {
            print("Error in save")
            return false
        }
    }
    
    private func update(_ value: Data, forKey: String) -> Bool {
        let keychainQueryDictionary = setupKeychainQueryDictionary(forKey)
        let updateDictionary: [String: Any] = [SecValueData: value]
        let success = SecItemUpdate(keychainQueryDictionary as CFDictionary, updateDictionary as CFDictionary)
        if success == errSecSuccess {
            return true
        }
        else {
            return false
        }
    }
    
    // Prepare for add, updata, delete data as per specified key
    private func setupKeychainQueryDictionary(_ key: String) -> [String: Any] {
        var keychainQueryDictionary: [String: Any] = [SecClass: kSecClassGenericPassword]
        keychainQueryDictionary[SecAttrService] = serviceName
        
        let encodeIdentifier: Data? = key.data(using: .utf8)
        keychainQueryDictionary[SecAttrGeneric] = encodeIdentifier
        keychainQueryDictionary[SecAttrAccount] = encodeIdentifier
        
        return keychainQueryDictionary
    }
    
    
    // Remove object with specified key
    @discardableResult open func remove(_ forKey: String) -> Bool {
        let keychainQueryDictionary = setupKeychainQueryDictionary(forKey)
        let success = SecItemDelete(keychainQueryDictionary as CFDictionary)
        if success == errSecSuccess {
            return true
        }
        else {
            return false
        }
    }
    
    // Remove all Keys
    @discardableResult open func removeAllKeys() -> Bool {
        var keychainQueueDictionary: [String:Any] = [SecClass: kSecClassGenericPassword]
        keychainQueueDictionary[SecAttrService] = serviceName
        let success = SecItemDelete(keychainQueueDictionary as CFDictionary)
        if success == errSecSuccess {
            return true
        } else {
            return false
        }
    }
    
    // Wipe keychain
    open class func wipeKeychain() {
        deleteKeychainSecClass(kSecClassGenericPassword)
        deleteKeychainSecClass(kSecClassInternetPassword)
        deleteKeychainSecClass(kSecClassCertificate)
        deleteKeychainSecClass(kSecClassKey)
        deleteKeychainSecClass(kSecClassIdentity)
    }
    
    @discardableResult private class func deleteKeychainSecClass(_ secClass: AnyObject) -> Bool {
        let query = [SecClass: secClass]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            return true
        }
        else {
            return false
        }
    }
}
