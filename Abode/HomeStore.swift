//
//  HomeStore.swift
//  Abode
//
//  Created by Aether on 08/11/2024.
//

// HomeStore.swift

import Foundation
import HomeKit
import SwiftUI

// MARK: - HomeStore

class HomeStore: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published var homes: [HMHome] = []
    @Published var selectedHome: HMHome?
    @Published var accessories: [HMAccessory] = []
    @Published var rooms: [HMRoom] = []
    @Published var actions: [HMActionSet] = []
    @Published var roomAccessories: [HMRoom: [HMAccessory]] = [:]
    
    // For Alert Handling
    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""
    
    // MARK: - Private Properties
    
    private var homeManager: HMHomeManager?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupHomeManager()
    }
    
    // MARK: - Home Manager Setup
    
    private func setupHomeManager() {
        homeManager = HMHomeManager()
        homeManager?.delegate = self
        updateHomes()
    }
    
    // MARK: - Home Management
    
    func updateHomes() {
        homes = homeManager?.homes ?? []
        if selectedHome == nil, let firstHome = homes.first {
            selectHome(firstHome)
        }
    }
    
    func selectHome(_ home: HMHome) {
        selectedHome = home
        accessories = home.accessories
        rooms = home.rooms
        fetchActions(for: home)
        groupAccessoriesByRoom()
        setupAccessoryObservers()
    }
    
    func selectHomeById(_ homeId: UUID?) {
        if let homeId = homeId, let home = homes.first(where: { $0.uniqueIdentifier == homeId }) {
            selectHome(home)
        } else if let firstHome = homes.first {
            selectHome(firstHome)
        }
    }
    
    private func fetchActions(for home: HMHome) {
        actions = home.actionSets.filter { !$0.actions.isEmpty }
    }
    
    private func groupAccessoriesByRoom() {
        roomAccessories = [:]
        for room in rooms {
            let accessoriesInRoom = accessories.filter { $0.room?.uniqueIdentifier == room.uniqueIdentifier }
            roomAccessories[room] = accessoriesInRoom
        }
    }
    
    // MARK: - Accessory Observers
    
    private func setupAccessoryObservers() {
            for accessory in accessories {
                accessory.delegate = self
                for service in accessory.services {
                    for characteristic in service.characteristics {
                        characteristic.enableNotification(true) { error in
                            if let error = error {
                                print("Failed to enable notification for characteristic \(characteristic.characteristicType): \(error.localizedDescription)")
                            } else {
                                print("Notification enabled for characteristic \(characteristic.characteristicType)")
                            }
                        }
                    }
                }
            }
        }
    
    // MARK: - Light Control Methods
    
    func toggleLight(_ accessory: HMAccessory) {
        guard let powerCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypePowerState) else {
            alert(message: "This accessory doesn't support power toggling.")
            return
        }

        let newValue = !(powerCharacteristic.value as? Bool ?? false)
        powerCharacteristic.writeValue(newValue) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(message: "Failed to toggle light: \(error.localizedDescription)")
                } else {
                    print("Light toggled successfully.")
                }
            }
        }
    }
    
    func adjustBrightness(_ accessory: HMAccessory, to value: Int) {
        guard let brightnessCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeBrightness) else {
            alert(message: "This accessory doesn't support brightness adjustment.")
            return
        }

        brightnessCharacteristic.writeValue(value) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(message: "Failed to adjust brightness: \(error.localizedDescription)")
                } else {
                    print("Brightness adjusted successfully.")
                    if value > 0 {
                        self?.ensureLightOn(accessory)
                    } else {
                        self?.ensureLightOff(accessory)
                    }
                }
            }
        }
    }
    
    private func ensureLightOn(_ accessory: HMAccessory) {
        guard let powerCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypePowerState) else {
            return
        }
        
        if powerCharacteristic.value as? Bool != true {
            powerCharacteristic.writeValue(true) { error in
                if let error = error {
                    print("Failed to ensure light is on: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func ensureLightOff(_ accessory: HMAccessory) {
        guard let powerCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypePowerState) else {
            return
        }
        
        if powerCharacteristic.value as? Bool == true {
            powerCharacteristic.writeValue(false) { error in
                if let error = error {
                    print("Failed to ensure light is off: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func changeColor(_ accessory: HMAccessory, to color: UIColor) {
        guard let hueCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeHue),
              let saturationCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeSaturation) else {
            alert(message: "This accessory doesn't support color change.")
            return
        }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

        hueCharacteristic.writeValue(Double(hue * 360)) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(message: "Failed to change hue: \(error.localizedDescription)")
                }
            }
        }

        saturationCharacteristic.writeValue(Double(saturation * 100)) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(message: "Failed to change saturation: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func supportsColor(_ accessory: HMAccessory) -> Bool {
        return accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeHue) != nil &&
               accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeSaturation) != nil
    }
    
    // MARK: - Plug Control Methods
    
    func togglePlug(_ accessory: HMAccessory) {
        guard let powerCharacteristic = accessory.find(serviceType: HMServiceTypeOutlet, characteristicType: HMCharacteristicTypePowerState) else {
            alert(message: "This accessory doesn't support power toggling.")
            return
        }

        let newValue = !(powerCharacteristic.value as? Bool ?? false)
        powerCharacteristic.writeValue(newValue) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(message: "Failed to toggle plug: \(error.localizedDescription)")
                } else {
                    print("Plug toggled successfully.")
                }
            }
        }
    }
    
    // MARK: - Thermostat Control Methods
    
    func setThermostatTemperature(_ accessory: HMAccessory, temperature: Double) {
        guard let targetTemperatureCharacteristic = accessory.find(serviceType: HMServiceTypeThermostat, characteristicType: HMCharacteristicTypeTargetTemperature) else {
            alert(message: "Thermostat does not support target temperature.")
            return
        }

        targetTemperatureCharacteristic.writeValue(temperature) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(message: "Failed to set thermostat temperature: \(error.localizedDescription)")
                } else {
                    print("Thermostat temperature set successfully.")
                }
            }
        }
    }
    
//    // MARK: - Lock Control Methods
    // fix later
//
//    func setLockState(_ accessory: HMAccessory, locked: Bool) {
//        guard let targetStateCharacteristic = accessory.find(serviceType: HMServiceTypeLockMechanism, characteristicType: HMCharacteristicValueTargetLockMechanismState) else {
//            alert(message: "Lock does not support target state.")
//            return
//        }
//
//        // Use the correct enumeration values
//        let targetState: HMCharacteristicValueTargetLockMechanismState = locked ? .secured : .unsecured
//
//        // Write the value to the characteristic
//        targetStateCharacteristic.writeValue(targetState) { [weak self] error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    self?.alert(message: "Failed to set lock state: \(error.localizedDescription)")
//                } else {
//                    print("Lock state set successfully.")
//                }
//            }
//        }
//    }
    
    // MARK: - Window Covering Control Methods
        
    func setWindowCoveringPosition(_ accessory: HMAccessory, position: Int) {
        // Corrected: Call 'find' on HMAccessory instead of HMService
        guard let positionCharacteristic = accessory.find(serviceType: HMServiceTypeWindowCovering, characteristicType: HMCharacteristicTypePositionState) else {
            alert(message: "Window Covering does not support position state.")
            return
        }

        positionCharacteristic.writeValue(position) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(message: "Failed to set window covering position: \(error.localizedDescription)")
                } else {
                    print("Window covering position set successfully.")
                }
            }
        }
    }
    
    // MARK: - Fan Control Methods
    
    func toggleFan(_ accessory: HMAccessory) {
        guard let powerCharacteristic = accessory.find(serviceType: HMServiceTypeFan, characteristicType: HMCharacteristicTypePowerState) else {
            alert(message: "This accessory doesn't support power toggling.")
            return
        }

        let newValue = !(powerCharacteristic.value as? Bool ?? false)
        powerCharacteristic.writeValue(newValue) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(message: "Failed to toggle fan: \(error.localizedDescription)")
                } else {
                    print("Fan toggled successfully.")
                }
            }
        }
    }
    
    func setFanSpeed(_ accessory: HMAccessory, speed: Int) {
        guard let speedCharacteristic = accessory.find(serviceType: HMServiceTypeFan, characteristicType: HMCharacteristicTypeRotationSpeed) else {
            alert(message: "Fan does not support speed adjustment.")
            return
        }

        speedCharacteristic.writeValue(speed) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(message: "Failed to set fan speed: \(error.localizedDescription)")
                } else {
                    print("Fan speed set successfully.")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func alert(message: String) {
        self.alertMessage = message
        self.showingAlert = true
    }
    
    // Execute Action
    func executeAction(_ actionSet: HMActionSet) {
            selectedHome?.executeActionSet(actionSet) { error in
                if let error = error {
                    print("Failed to execute action set: \(error.localizedDescription)")
                } else {
                    print("Action set executed successfully")
                }
            }
        }
}

// MARK: - HMHomeManagerDelegate

extension HomeStore: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        updateHomes()
    }
}

// MARK: - HMAccessoryDelegate

extension HomeStore: HMAccessoryDelegate {
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdate value: Any?, for characteristic: HMCharacteristic) {
        // Notify observers to update UI
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
