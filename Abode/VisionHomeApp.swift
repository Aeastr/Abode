//
//  VisionHomeApp.swift
//  VisionHome
//
//  Created by Aether on 20/07/2024.
//

import SwiftUI
import HomeKit

@main
struct VisionHomeApp: App {
    
    @StateObject private var homeStore = HomeStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(homeStore)
        }
        
        WindowGroup(for: UUID.self) { id in
            
                Light(accessory: homeStore.accessories.first(where: { HMAccessory in
                    HMAccessory.uniqueIdentifier == id.wrappedValue.unsafelyUnwrapped
                })! , homeStore: homeStore)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 200, height: 100)
    }
}
