//
//  BOWApp.swift
//  BOW
//
//  Created by Jacob Davis on 7/27/22.
//

import SwiftUI

@main
struct BOWApp: App {
    
    @StateObject var appState = AppState()
    @StateObject var priceData = PriceData.shared
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(priceData)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                print("₿OW => Entered Background Phase")
                Task {
                    await PriceData.shared.disconnectTickerSocket()
                    await PriceData.shared.disconnectCandleSocket()
                }
            case .active:
                print("₿OW => Entered Active Phase")
                Task {
                    await appState.load()
                    await appState.sync()
                    await PriceData.shared.connectTickerSocket()
                    await PriceData.shared.connectCandleSocket()
                }
            case .inactive:
                print("₿OW => Entered Inactive Phase")
            default:
                print("₿OW => Entered Unknown Phase")
            }
        }
    }
}
