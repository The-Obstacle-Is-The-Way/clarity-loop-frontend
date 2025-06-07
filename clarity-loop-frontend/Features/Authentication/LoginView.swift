import SwiftUI

struct LoginView: View {
    
    // MARK: - Environment
    
    @Environment(\.authService) private var authService
    
    // MARK: - State
    
    @State private var viewModel: LoginViewModel
    
    // MARK: - Initializer
    
    init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button(action: {
                        Task {
                            await viewModel.login()
                        }
                    }) {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                NavigationLink("Don't have an account? Register", destination: RegistrationView(authService: authService))
            }
            .padding()
        }
    }
}

#Preview {
    // Create a preview-safe APIClient
    let previewAPIClient = APIClient(
        baseURLString: "https://crave-trinity--clarity-backend-fastapi-app.modal.run",
        tokenProvider: { nil }
    )!
    
    LoginView(viewModel: LoginViewModel(authService: AuthService(apiClient: previewAPIClient)))
} 
