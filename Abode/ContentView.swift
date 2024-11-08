//
//  ContentView.swift
//  VisionHome
//
//  Created by Aether on 20/07/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent
import HomeKit

class HomeStore: NSObject, ObservableObject {
    @Published var homes: [HMHome] = []
    @Published var selectedHome: HMHome?
    @Published var accessories: [HMAccessory] = []
    @Published var rooms: [HMRoom] = []
    @Published var actions: [HMActionSet] = []
    
    private var homeManager: HMHomeManager?
    
    override init() {
        super.init()
        setupHomeManager()
    }
    
    private func setupHomeManager() {
        homeManager = HMHomeManager()
        homeManager?.delegate = self
        updateHomes()
    }
    
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
    
    func executeAction(_ actionSet: HMActionSet) {
        selectedHome?.executeActionSet(actionSet) { error in
            if let error = error {
                print("Failed to execute action set: \(error.localizedDescription)")
            } else {
                print("Action set executed successfully")
            }
        }
    }
    
    func toggleLight(_ accessory: HMAccessory) {
        guard let characteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypePowerState) else {
            print("This accessory doesn't support power toggling")
            return
        }

        let newValue = !(characteristic.value as? Bool ?? false)
        characteristic.writeValue(newValue) { error in
            if let error = error {
                print("Failed to toggle light: \(error.localizedDescription)")
            } else {
                print("Light toggled successfully")
            }
        }
    }

    func adjustBrightness(_ accessory: HMAccessory, to value: Int) {
        guard let brightnessCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeBrightness) else {
            print("This accessory doesn't support brightness adjustment")
            return
        }

        brightnessCharacteristic.writeValue(value) { error in
            if let error = error {
                print("Failed to adjust brightness: \(error.localizedDescription)")
            } else {
                print("Brightness adjusted successfully")
                
                // If brightness is set above 0, ensure the light is on
                if value > 0 {
                    self.ensureLightOn(accessory)
                } else {
                    self.ensureLightOff(accessory)
                }
            }
        }
    }

    private func ensureLightOn(_ accessory: HMAccessory) {
        guard let powerCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypePowerState) else {
            return
        }
        
        if powerCharacteristic.value as? Bool != true {
            powerCharacteristic.writeValue(true) { _ in }
        }
    }

    private func ensureLightOff(_ accessory: HMAccessory) {
        guard let powerCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypePowerState) else {
            return
        }
        
        if powerCharacteristic.value as? Bool == true {
            powerCharacteristic.writeValue(false) { _ in }
        }
    }

    func changeColor(_ accessory: HMAccessory, to color: UIColor) {
        guard let hueCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeHue),
              let saturationCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeSaturation) else {
            print("This accessory doesn't support color change")
            return
        }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

        hueCharacteristic.writeValue(hue * 360) { error in
            if let error = error {
                print("Failed to change hue: \(error.localizedDescription)")
            }
        }

        saturationCharacteristic.writeValue(saturation * 100) { error in
            if let error = error {
                print("Failed to change saturation: \(error.localizedDescription)")
            }
        }
    }

    func supportsColor(_ accessory: HMAccessory) -> Bool {
        return accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeHue) != nil &&
               accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeSaturation) != nil
    }
}

extension HomeStore: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        updateHomes()
    }
}

extension HMAccessory {
    func find(serviceType: String, characteristicType: String) -> HMCharacteristic? {
        return services.first { $0.serviceType == serviceType }?
            .characteristics.first { $0.characteristicType == characteristicType }
    }
}

struct ContentView: View {
    @EnvironmentObject var homeStore: HomeStore
    @AppStorage("selectedHomeId") private var selectedHomeId: String = ""
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        
        TabView{
            Tab("Home", systemImage: "homekit") {
                NavigationStack {
                    ScrollView {
                        
                        
                        if let selectedHome = homeStore.selectedHome {
                            
                            ScrollView(.horizontal) {
                                HStack{
                                    
                                        ForEach(selectedHome.accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeLightbulb } }, id: \.uniqueIdentifier) { accessory in
                                            Light(accessory: accessory, homeStore: homeStore)
                                                .contextMenu {
                                                    Button {
                                                        openWindow(value: accessory.identifier)
                                                    } label: {
                                                        Label("Open Window", systemImage: "macwindow")
                                                    }

                                                }
                                            
                                            
                                        }
                                    
                                }
                            }
                            Section(header: Text("Actions in \(selectedHome.name)")) {
                                ForEach(homeStore.actions, id: \.uniqueIdentifier) { action in
                                    Button(action: {
                                        homeStore.executeAction(action)
                                    }) {
                                        Text(action.name)
                                    }
                                }
                            }
                            
                            
                        }
                    }
                    .navigationTitle(homeStore.selectedHome?.name ?? "Home")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Section() {
                                Picker("Home", selection: Binding(
                                    get: { selectedHomeId },
                                    set: { newValue in
                                        selectedHomeId = newValue
                                        homeStore.selectHomeById(UUID(uuidString: newValue))
                                    }
                                )) {
                                    ForEach(homeStore.homes, id: \.uniqueIdentifier) { home in
                                        Text(home.name).tag(home.uniqueIdentifier.uuidString)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                    }
                }
                .onAppear {
                    homeStore.selectHomeById(UUID(uuidString: selectedHomeId))
                }
            }
            
            ForEach(homeStore.rooms, id: \.uniqueIdentifier){ room in
                Tab(room.name, systemImage: "square.split.bottomrightquarter") {
                    
                }
            }
            
        }
    }
}

struct Light: View {
    let accessory: HMAccessory
    let homeStore: HomeStore
    @State private var brightness: Double = 0
    @State private var color: Color = .white
    @State private var isOn: Bool = false
    @State private var showControl = false
    
    var showOptions = false

    var body: some View {
        
        VStack(alignment: .leading){
                    
            HStack(){
                        Button(action: {
                            homeStore.toggleLight(accessory)
                            isOn.toggle()
                        }) {
                            Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
                            //                        .foregroundStyle(color)
                            
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .background(isOn ? color.opacity(brightness / 120) : Color.clear)
                        .animation(.smooth, value: isOn)
                        .animation(.smooth, value: brightness)
                        .glassBackgroundEffect()
                        
                        Text(accessory.name)
                    .font(.title2)
                
                    }
                    
            
           


            if homeStore.supportsColor(accessory) {
                HStack {
                    Slider(value: isOn ? $brightness : .constant(0), in: 0...100, step: 1) { _ in
                        homeStore.adjustBrightness(accessory, to: Int(brightness))
                        if brightness > 0 && !isOn {
                            isOn = true
                        } else if brightness == 0 && isOn {
                            isOn = false
                        }
                    }
                    .animation(.smooth, value: isOn)
                    
                    ColorPicker("", selection: $color)
                        .onChange(of: color) { newColor in
                            homeStore.changeColor(accessory, to: UIColor(newColor))
                        }
                        .labelsHidden()
                        .aspectRatio(1, contentMode: .fit).clipped()
                }
            }
                }
        
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isOn ? color.opacity(brightness / 120) : Color.clear)
        .glassBackgroundEffect()
                .sheet(isPresented: $showControl, content: {
                    NavigationStack{
                        LightControlView(accessory: accessory, homeStore: homeStore, brightness: $brightness, color: $color, isOn: $isOn)
                            .toolbar{
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button(action: {
                                        showControl.toggle()
                                    }) {
                                        Text("Done")
                                        //                        .foregroundStyle(color)
                                        
                                    }
                                }
                            }
                            .navigationTitle(accessory.name)
                    }
                })
            
            
        
                .onAppear {
                            if let brightnessCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeBrightness) {
                                brightness = brightnessCharacteristic.value as? Double ?? 0
                            }
                            if let powerCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypePowerState) {
                                isOn = powerCharacteristic.value as? Bool ?? false
                            }
                            // Ensure initial state is consistent
                            if brightness > 0 {
                                isOn = true
                            }
                    
                    if let hueCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeHue),
                       let satCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeSaturation),
                       let briCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeBrightness),
                       let tempCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeColorTemperature) {

                        if let hueValue = hueCharacteristic.value as? NSNumber,
                           let satValue = satCharacteristic.value as? NSNumber,
                           let briValue = briCharacteristic.value as? NSNumber {
                            
                            // Normalize the values
                            let normalizedHue = hueValue.doubleValue / 360.0
                            let normalizedSaturation = satValue.doubleValue / 100.0
                            let normalizedBrightness = briValue.doubleValue / 100.0
                            
                            color = Color(hue: normalizedHue, saturation: normalizedSaturation, brightness: 1.0)
                            
                            print("Normalized Hue: \(normalizedHue)")
                            print("Normalized Saturation: \(normalizedSaturation)")
                            print("Normalized Brightness: \(normalizedBrightness)")
                        } else {
                            print("Failed to cast characteristic values to NSNumber")
                            
                            // Further inspection of value types
                            if hueCharacteristic.value != nil {
                                print("Hue value type: \(type(of: hueCharacteristic.value!))")
                            } else {
                                print("Hue value is nil")
                            }
                            
                            if satCharacteristic.value != nil {
                                print("Saturation value type: \(type(of: satCharacteristic.value!))")
                            } else {
                                print("Saturation value is nil")
                            }
                            
                            if briCharacteristic.value != nil {
                                print("Brightness value type: \(type(of: briCharacteristic.value!))")
                            } else {
                                print("Brightness value is nil")
                            }
                        }

                        // Handle color temperature
                        if let tempValue = tempCharacteristic.value as? NSNumber {
                            let colorTemperature = tempValue.doubleValue
                            print("Color Temperature: \(colorTemperature) K")
                            // You may want to update your color object or handle the color temperature value as needed
                        } else {
                            print("Failed to cast color temperature value to NSNumber")
                        }
                    } else {
                        print("Failed to retrieve characteristic values")
                    }

                        }
    }
}


struct LightControlView: View {
    let accessory: HMAccessory
    let homeStore: HomeStore
    @Binding var brightness: Double
    @Binding var color: Color
    @Binding var isOn: Bool
    @State private var showingColorPicker = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(accessory.name)
                Spacer()
                Button(action: {
                    homeStore.toggleLight(accessory)
                    isOn.toggle()
                }) {
                    Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
                }
            }
            
            Slider(value: $brightness, in: 0...100, step: 1) { _ in
                homeStore.adjustBrightness(accessory, to: Int(brightness))
                if brightness > 0 && !isOn {
                    isOn = true
                } else if brightness == 0 && isOn {
                    isOn = false
                }
            }


            if homeStore.supportsColor(accessory) {
                HStack {
                    Text("Color")
                    Spacer()
                    ColorPicker("Select color", selection: $color)
                        .onChange(of: color) { newColor in
                            homeStore.changeColor(accessory, to: UIColor(newColor))
                        }
                }
            }
        }
        .padding()
        .onAppear {
                    if let brightnessCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeBrightness) {
                        brightness = brightnessCharacteristic.value as? Double ?? 0
                    }
                    if let powerCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypePowerState) {
                        isOn = powerCharacteristic.value as? Bool ?? false
                    }
                    // Ensure initial state is consistent
                    if brightness > 0 {
                        isOn = true
                    }
            
            if let hueCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeHue),
               let satCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeSaturation),
               let briCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeBrightness),
               let tempCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeColorTemperature) {

                if let hueValue = hueCharacteristic.value as? NSNumber,
                   let satValue = satCharacteristic.value as? NSNumber,
                   let briValue = briCharacteristic.value as? NSNumber {
                    
                    // Normalize the values
                    let normalizedHue = hueValue.doubleValue / 360.0
                    let normalizedSaturation = satValue.doubleValue / 100.0
                    let normalizedBrightness = briValue.doubleValue / 100.0
                    
                    color = Color(hue: normalizedHue, saturation: normalizedSaturation, brightness: 1.0)
                    
                    print("Normalized Hue: \(normalizedHue)")
                    print("Normalized Saturation: \(normalizedSaturation)")
                    print("Normalized Brightness: \(normalizedBrightness)")
                } else {
                    print("Failed to cast characteristic values to NSNumber")
                    
                    // Further inspection of value types
                    if hueCharacteristic.value != nil {
                        print("Hue value type: \(type(of: hueCharacteristic.value!))")
                    } else {
                        print("Hue value is nil")
                    }
                    
                    if satCharacteristic.value != nil {
                        print("Saturation value type: \(type(of: satCharacteristic.value!))")
                    } else {
                        print("Saturation value is nil")
                    }
                    
                    if briCharacteristic.value != nil {
                        print("Brightness value type: \(type(of: briCharacteristic.value!))")
                    } else {
                        print("Brightness value is nil")
                    }
                }

                // Handle color temperature
                if let tempValue = tempCharacteristic.value as? NSNumber {
                    let colorTemperature = tempValue.doubleValue
                    print("Color Temperature: \(colorTemperature) K")
                    // You may want to update your color object or handle the color temperature value as needed
                } else {
                    print("Failed to cast color temperature value to NSNumber")
                }
            } else {
                print("Failed to retrieve characteristic values")
            }

                }
    }
}
