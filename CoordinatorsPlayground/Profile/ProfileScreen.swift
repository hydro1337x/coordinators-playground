//
//  ProfileScreen.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 01.06.2025..
//

import SwiftUI

struct ProfileScreen: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("Profile not completed")
            }
            .frame(height: 50)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ProfileScreen()
}
