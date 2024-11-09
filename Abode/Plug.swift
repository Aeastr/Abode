//
//  Plug.swift
//  Abode
//
//  Created by Aether on 08/11/2024.
//


import SwiftUI
import HomeKit

struct Plug: View {
    let accessory: HMAccessory
    @ObservedObject var homeStore: HomeStore
    @State private var isOn: Bool = false

    var body: some View {
        VStack {
            Button(action: {
                homeStore.togglePlug(accessory)
                isOn.toggle()
            }) {
                Image(systemName: isOn ? "powerplug.fill" : "powerplug")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
                    .foregroundColor(isOn ? .green : .gray)
            }

            Text(accessory.name)
                .font(.caption)
                .lineLimit(1)
                .padding(.top, 5)
        }
        .onAppear {
            initializePlugState()
        }
        .frame(width: 120)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }

    private func initializePlugState() {
        if let powerCharacteristic = accessory.find(
            serviceType: HMServiceTypeOutlet,
            characteristicType: HMCharacteristicTypePowerState
        ) {
            isOn = powerCharacteristic.value as? Bool ?? false
        }
    }
}