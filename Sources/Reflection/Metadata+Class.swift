extension Metadata {
    struct Class : NominalType {

        static let kind: Kind? = .class
        var pointer: UnsafePointer<_Metadata._Class>
        
        var nominalTypeDescriptor: NominalTypeDescriptor {
            return pointer.withMemoryRebound(to: NominalTypeDescriptor.self, capacity: 15, { $0[nominalTypeDescriptorLocation] })
        }

        var nominalTypeDescriptorLocation: Int {
            return is64BitPlatform ? 8 : 11
        }

        var superclass: Class? {
            guard let superclass = pointer.pointee.superclass else { return nil }
            return Metadata.Class(type: superclass)
        }
        
        func properties() throws -> [Property.Description] {
            let properties = try fetchAndSaveProperties(nominalType: self, hashedType: HashedType(pointer))
            guard let superclass = superclass else {
                return properties
            }
            // We are not interested in the special "SwiftObject" superclass and the "NSObject" superclass. They don't
            // provide any property and will crash if we try to reflect them.
            let name = String(describing: unsafeBitCast(superclass.pointer, to: Any.Type.self))
            guard name != "SwiftObject" && name != "NSObject" else {
                return properties
            }
            return try superclass.properties() + properties
        }

    }
}

extension _Metadata {
    struct _Class {
        var kind: Int
        var superclass: Any.Type?
    }
}
