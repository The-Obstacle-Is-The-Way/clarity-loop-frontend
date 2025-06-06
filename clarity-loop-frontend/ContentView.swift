//
//  ContentView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/6/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.authService) private var authService

    var body: some View {
        if authViewModel.isLoggedIn {
            DashboardView()
        } else {
            // The LoginView should be wrapped in a NavigationView for proper UI flow.
            NavigationView {
                LoginView(authService: authService)
            }
        }
    }
}


#if DEBUG
// NOTE: The preview is temporarily simplified to ensure the project builds.
// Mocking FirebaseAuth.User is complex due to non-public initializers and
// causes the build to fail. A robust mocking strategy will be implemented later.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Text("ContentView Preview (Disabled)")
    }
}
#else
#Preview {
    Text("Preview not available.")
}
#endif
