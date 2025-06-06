import SwiftUI

struct LoginView: View {
    
    // Using @State for the ViewModel as this view is the root of the login flow.
    @State private var viewModel: LoginViewModel
    
    // Access the shared AuthService via the environment.
    @Environment(\.authService) private var authService
    
    // State for navigation to the registration view.
    @State private var showRegistration = false
    
    init() {
        // Initialize the ViewModel with the authService from the environment.
        // Note: This is a simplified DI pattern. In a larger app, you might use a more robust factory.
        // This initialization will be completed properly once the environment is fully set up.
        _viewModel = State(initialValue: LoginViewModel(authService: AuthService(apiClient: APIClient(tokenProvider: { return nil })))) // Placeholder
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Spacer()
                
                // App Title
                Text("CLARITY Pulse")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Form Fields
                VStack(spacing: 15) {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Error Message Display
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                // Login Button
                Button(action: {
                    viewModel.signIn()
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(viewModel.isLoading ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
                
                // Forgot Password Button
                Button("Forgot Password?") {
                    viewModel.sendPasswordReset()
                }
                .font(.footnote)
                .tint(.blue)
                
                Spacer()
                
                // Registration Link
                HStack {
                    Text("Don't have an account?")
                    Button("Sign Up") {
                        showRegistration.toggle()
                    }
                    .fontWeight(.semibold)
                    .tint(.blue)
                }
                .font(.footnote)
                
            }
            .padding(30)
            .navigationDestination(isPresented: $showRegistration) {
                RegistrationView()
            }
        }
        .onAppear {
            // Re-initialize the ViewModel with the proper environment-provided service.
            // This ensures the view uses the real auth service set up at the app's root.
            _viewModel.wrappedValue = LoginViewModel(authService: authService)
        }
    }
}


// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            // Provide a mock auth service for the preview
            .environment(\.authService, MockAuthService())
    }
    
    // A mock service for SwiftUI previews
    private struct MockAuthService: AuthServiceProtocol {
        var authState: AsyncStream<User?> { AsyncStream { $0.yield(nil) } }
        var currentUser: User? { nil }
        func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO { throw APIError.unauthorized }
        func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO { throw APIError.unauthorized }
        func signOut() throws {}
        func sendPasswordReset(to email: String) async throws {}
        func getCurrentUserToken() async throws -> String { "mockToken" }
    }
    
    // Mock environment key for previews
    private struct MockAuthServiceKey: EnvironmentKey {
        static let defaultValue: AuthServiceProtocol = MockAuthService()
    }
    
    private extension EnvironmentValues {
        var authService: AuthServiceProtocol {
            get { self[MockAuthServiceKey.self] }
            set { self[MockAuthServiceKey.self] = newValue }
        }
    }
} 
