//
//  ContentView.swift
//  AnimalGestioneProject
//
//  Created by 垣原親伍 on 2024/03/30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: AnimalDataStore
    
    var body: some View {
        AnimalListView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AnimalDataStore())
}
