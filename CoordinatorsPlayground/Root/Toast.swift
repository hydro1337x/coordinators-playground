//
//  Toast.swift
//  CoordinatorsPlayground
//
//  Created by Benjamin Macanovic on 31.05.2025..
//

import SwiftUI

struct Toast: View {
    let color: Color
    let message: String
    
    var body: some View {
        HStack {
            Text(message)
                .padding(8)
        }
        .frame(height: 44)
        .background {
            shape
                .strokeBorder(.gray, lineWidth: 0.5)
                .background(shape.fill(color))
        }
    }
    
    var shape: some InsettableShape {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }
}

#Preview {
    Toast(color: .blue, message: "Message")
        
}
