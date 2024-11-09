//
//  Untitled.swift
//  Abode
//
//  Created by Aether on 08/11/2024.
//

// HMAccessory+Extensions.swift

import HomeKit

extension HMAccessory {
    func find(serviceType: String, characteristicType: String) -> HMCharacteristic? {
        return services.first { $0.serviceType == serviceType }?
            .characteristics.first { $0.characteristicType == characteristicType }
    }

    var isLightbulb: Bool {
        return services.contains { $0.serviceType == HMServiceTypeLightbulb }
    }
    
    var isOutlet: Bool {
        return services.contains { $0.serviceType == HMServiceTypeOutlet }
    }
    
    var isThermostat: Bool {
        return services.contains { $0.serviceType == HMServiceTypeThermostat }
    }
    
    var isLock: Bool {
        return services.contains { $0.serviceType == HMServiceTypeLockMechanism }
    }
    
    var isMotionSensor: Bool {
        return services.contains { $0.serviceType == HMServiceTypeMotionSensor }
    }
    
    var isCamera: Bool {
        return services.contains { $0.serviceType == HMServiceTypeCameraControl }
    }
    
    var isFan: Bool {
        return services.contains { $0.serviceType == HMServiceTypeFan }
    }
    
    var isWindowCovering: Bool {
        return services.contains { $0.serviceType == HMServiceTypeWindowCovering }
    }
    
    // Add more computed properties for other accessory types as needed
}
