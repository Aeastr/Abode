//
//  Light.swift
//  Abode
//
//  Created by Aether on 08/11/2024.
//


// Light.swift

import SwiftUI
import HomeKit

struct Light: View {
    let accessory: HMAccessory
    let homeStore: HomeStore
    @State private var brightness: Double = 0
    @State private var color: Color = .white
    @State private var isOn: Bool = false
    @State private var showControl = false
    
    var showOptions = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    homeStore.toggleLight(accessory)
                    isOn.toggle()
                }) {
                    Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
                }
                .aspectRatio(1, contentMode: .fit)
                .background(isOn ? color.opacity(brightness / 120) : Color.clear)
                .animation(.easeInOut, value: isOn)
                .animation(.easeInOut, value: brightness)
                // .glassBackgroundEffect() // Custom modifier, ensure it's defined somewhere
                
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
                    .animation(.easeInOut, value: isOn)
                    
                    ColorPicker("", selection: $color)
                        .onChange(of: color) { newColor in
                            homeStore.changeColor(accessory, to: UIColor(newColor))
                        }
                        .labelsHidden()
                        .aspectRatio(1, contentMode: .fit)
                        .clipped()
                }
            }
        }
        .padding()
        .padding(.horizontal, 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isOn ? color.opacity(brightness / 120) : Color.clear)
        // .glassBackgroundEffect() // Custom modifier
        .sheet(isPresented: $showControl) {
            NavigationStack {
                LightControlView(accessory: accessory, homeStore: homeStore, brightness: $brightness, color: $color, isOn: $isOn)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                showControl.toggle()
                            }) {
                                Text("Done")
                            }
                        }
                    }
                    .navigationTitle(accessory.name)
            }
        }
        .onAppear {
            initializeLightState()
        }
    }
    
    private func initializeLightState() {
        if let brightnessCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeBrightness) {
            brightness = brightnessCharacteristic.value as? Double ?? 0
        }
        if let powerCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypePowerState) {
            isOn = powerCharacteristic.value as? Bool ?? false
        }
        if brightness > 0 {
            isOn = true
        }
        updateColor()
    }
    
    private func updateColor() {
        if let hueCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeHue),
           let satCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeSaturation),
           let briCharacteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeBrightness) {

            if let hueValue = hueCharacteristic.value as? Double,
               let satValue = satCharacteristic.value as? Double,
               let _ = briCharacteristic.value as? Double {

                let normalizedHue = hueValue / 360.0
                let normalizedSaturation = satValue / 100.0

                color = Color(hue: normalizedHue, saturation: normalizedSaturation, brightness: 1.0)
            } else {
                print("Failed to cast characteristic values")
            }
        } else {
            print("Failed to retrieve characteristic values")
        }
    }
}
