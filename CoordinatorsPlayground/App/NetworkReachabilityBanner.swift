//
//  NetworkReachabilityBanner.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 15.06.2025..
//

import SwiftUI

struct NetworkReachabilityBanner: View {
    var body: some View {
        VStack{}
            .frame(maxWidth: .infinity)
            .background(Color(.systemOrange))
            .overlay {
                Text("Network is not reachable")
                    .font(.caption)
                    .offset(y: -6)
            }
    }
}

#Preview {
    NavigationStack {
        VStack {
            NetworkReachabilityBanner()
            Spacer()
        }
    }
}
