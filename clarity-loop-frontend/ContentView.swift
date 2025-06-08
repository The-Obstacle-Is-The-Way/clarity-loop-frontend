//
//  ContentView.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/6/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.authService) private var authService

    var body: some View {
        if authViewModel.isLoggedIn {
            MainTabView()
        } else {
            // The LoginView should be wrapped in a NavigationStack for proper UI flow.
            NavigationStack {
                LoginView(viewModel: LoginViewModel(authService: authService))
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
