//
//  ContentView.swift
//  SomniQ
//
//  Created by Maximilian Comfere on 6/30/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "moon.zzz.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 60))
            Text("SomniQ")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Sleep Disorder Tracking App")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
