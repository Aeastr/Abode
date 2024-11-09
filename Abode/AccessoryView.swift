//
//  AccessoryView.swift
//  Abode
//
//  Created by Aether on 09/11/2024.
//


// AccessoryView.swift

import SwiftUI
import HomeKit

struct AccessoryView: View {
    let accessory: HMAccessory
    @ObservedObject var homeStore: HomeStore
    
    var body: some View {
        VStack {
            
            // Determine the type and render accordingly
            if accessory.isLightbulb {
                Light(accessory: accessory, homeStore: homeStore)
            } else if accessory.isOutlet {
                Plug(accessory: accessory, homeStore: homeStore)
            }
            else{
                Text(accessory.name)
                    .font(.headline)
                Text("Not yet supported")
                    .foregroundColor(.gray)
            }
//            else if accessory.isThermostat {
//                ThermostatView(accessory: accessory, homeStore: homeStore)
//            } else if accessory.isLock {
//                LockView(accessory: accessory, homeStore: homeStore)
//            } else if accessory.isMotionSensor {
//                MotionSensorView(accessory: accessory, homeStore: homeStore)
//            } else if accessory.isCamera {
//                CameraView(accessory: accessory, homeStore: homeStore)
//            } else if accessory.isFan {
//                FanView(accessory: accessory, homeStore: homeStore)
//            } else if accessory.isWindowCovering {
//                WindowCoveringView(accessory: accessory, homeStore: homeStore)
//            }
        }
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
