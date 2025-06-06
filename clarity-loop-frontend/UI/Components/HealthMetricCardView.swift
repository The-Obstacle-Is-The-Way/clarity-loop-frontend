//
//  HealthMetricCardView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import SwiftUI

struct HealthMetricCardView: View {
    let title: String
    let value: String
    let systemImageName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let systemImageName = systemImageName {
                    Image(systemName: systemImageName)
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                Text(title)
                    .font(.headline)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 
