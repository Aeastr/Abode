//
//  ActionButton.swift
//  Abode
//
//  Created by Aether on 09/11/2024.
//


import SwiftUI
import HomeKit

struct ActionButton: View {
    let action: HMActionSet
    let executeAction: (HMActionSet) -> Void
    
    var body: some View {
        Button(action: {
            executeAction(action)
        }) {
            Text(action.name)
        }
    }
}
