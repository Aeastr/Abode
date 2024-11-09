//
//  ContentView.swift
//  VisionHome
//
//  Created by Aether on 20/07/2024.
//

// ContentView.swift

import SwiftUI
import HomeKit

struct ContentView: View {
    @EnvironmentObject var homeStore: HomeStore
    @AppStorage("selectedHomeId") private var selectedHomeId: String = ""
    @Environment(\.openWindow) private var openWindow

    let columns = [
            GridItem(.adaptive(minimum: 280), spacing: 16)
        ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if let selectedHome = homeStore.selectedHome {
                    LazyVStack(spacing: 16) {
                        // Scenes Section
                        Section(header: Text("Scenes")
                                    .frame(maxWidth: .infinity, alignment: .leading)) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) { // Added spacing for better layout
                                    ForEach(homeStore.actions, id: \.uniqueIdentifier) { action in
                                        ActionButton(action: action) { selectedAction in
                                            homeStore.executeAction(selectedAction)
                                        }
                                    }
                                }
                            }
                        }
                                    .padding(.horizontal, 25)
                                    
                        Divider()
                            .padding(.horizontal, 40)
                        

                        // Accessories by Room Section
                        ForEach(homeStore.rooms, id: \.uniqueIdentifier) { room in
                            if let accessories = homeStore.roomAccessories[room], !accessories.isEmpty {
                                Section(header: Text(room.name).frame(maxWidth: .infinity, alignment: .leading)) {
                                    LazyVGrid(columns: columns, spacing: 20) {
                                        ForEach(accessories, id: \.uniqueIdentifier) { accessory in
                                            AccessoryView(accessory: accessory, homeStore: homeStore)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .glassBackgroundEffect()
                                        }
                                    }

                                }.padding(.horizontal, 25)
                            }
                        }
                    }
                }
            }
            .navigationTitle(homeStore.selectedHome?.name ?? "Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
        .onAppear {
            homeStore.selectHomeById(UUID(uuidString: selectedHomeId))
        }
        .alert(isPresented: $homeStore.showingAlert) {
            Alert(title: Text("Error"), message: Text(homeStore.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}


