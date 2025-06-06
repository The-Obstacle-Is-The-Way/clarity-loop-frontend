//
//  HealthMetricCardView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import SwiftUI

struct HealthMetricCardView: View {
    let metric: HealthMetricDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.metricType.capitalized)
                .font(.headline)
            
            // This is a simplified display. We'll need to format
            // the different data types (biometric, sleep, etc.) more elegantly later.
            if let biometric = metric.biometricData {
                Text("HR: \(biometric.heartRate ?? 0, specifier: "%.0f")")
            }
            
            Text(metric.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
} 
