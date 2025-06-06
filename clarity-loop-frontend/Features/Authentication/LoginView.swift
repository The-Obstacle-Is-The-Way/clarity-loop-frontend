import SwiftUI

struct LoginView: View {
    
    // MARK: - Environment
    
    @Environment(\.authService) private var authService
    
    // MARK: - State
    
    @State private var viewModel: LoginViewModel
    @State private var isRegistrationPresented = false
    
    // MARK: - Initializer
    
    init(authService: AuthServiceProtocol) {
        _viewModel = State(initialValue: LoginViewModel(authService: authService))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            
            Text("Welcome to CLARITY Pulse")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: viewModel.signIn) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            
            Button("Forgot Password?", action: viewModel.sendPasswordReset)
                .font(.footnote)

            Spacer()
            
            NavigationLink(value: "registration") {
                Text("Don't have an account? Sign Up")
            }
        }
        .padding()
        .navigationTitle("Login")
        .navigationDestination(for: String.self) { destination in
            if destination == "registration" {
                RegistrationView(authService: authService)
            }
        }
    }
} 
