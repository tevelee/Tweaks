import Foundation

public protocol StorageMechanism: AnyObject {
    associatedtype Key: Hashable
    associatedtype Value
    subscript(key: Key) -> Value? { get set }
}

public class InMemoryStore<Key: Hashable, Value>: StorageMechanism {
    private var inMemoryValues: [Key: Value] = [:]
    
    public init() {}
    
    public subscript(key: Key) -> Value? {
        get {
            inMemoryValues[key]
        }
        set(value) {
            inMemoryValues[key] = value
        }
    }
}

public class UserDefaultsStore<Key: Hashable & CustomStringConvertible, Value>: StorageMechanism {
    private let userDefaults: UserDefaults
    private let namespace: String
    private let converter: SymmetricConvering<Value, String>

    public init(userDefaults: UserDefaults = .standard,
                namespace: String = "default",
                converter: SymmetricConvering<Value, String>) {
        self.userDefaults = userDefaults
        self.namespace = namespace
        self.converter = converter
    }

    public subscript(key: Key) -> Value? {
        get {
            let storageKey = "\(namespace).\(key.description)"
            guard let data = userDefaults.string(forKey: storageKey) else { return nil }
            return try? converter.decoding.convert(data)
        }
        set(value) {
            let storageKey = "\(namespace).\(key.description)"
            if let value = value, let data = try? converter.encoding.convert(value) {
                userDefaults.set(data, forKey: storageKey)
            } else {
                userDefaults.removeObject(forKey: storageKey)
            }
        }
    }
}
