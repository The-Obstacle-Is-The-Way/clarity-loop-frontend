import SwiftUI

struct RegistrationView: View {
    
    @State private var viewModel: RegistrationViewModel
    @Environment(\.authService) private var authService
    @Environment(\.dismiss) private var dismiss
    
    init() {
        // This will be properly initialized via onAppear
        _viewModel = State(initialValue: RegistrationViewModel(authService: MockAuthService()))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    TextField("First Name", text: $viewModel.firstName)
                        .textContentType(.givenName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    TextField("Last Name", text: $viewModel.lastName)
                        .textContentType(.familyName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                VStack(spacing: 15) {
                    Toggle(isOn: $viewModel.termsAccepted) {
                        Text("I accept the [Terms of Service](https://clarity.health/terms)")
                    }
                    Toggle(isOn: $viewModel.privacyPolicyAccepted) {
                        Text("I accept the [Privacy Policy](https://clarity.health/privacy)")
                    }
                }
                .font(.caption)
                .tint(.blue)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    viewModel.register()
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().progressViewStyle(.circular)
                        } else {
                            Text("Create Account")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(viewModel.isLoading ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(30)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Registration Successful", isPresented: $viewModel.registrationComplete) {
            Button("OK", role: .cancel) {
                dismiss() // Dismiss the registration view
            }
        } message: {
            Text("Please check your email to verify your account before logging in.")
        }
        .onAppear {
            // Properly initialize the ViewModel with the environment's auth service
            _viewModel.wrappedValue = RegistrationViewModel(authService: authService)
        }
    }
}

// MARK: - Preview
struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegistrationView()
                .environment(\.authService, MockAuthService())
        }
    }
    
    // A mock service for SwiftUI previews
    private struct MockAuthService: AuthServiceProtocol {
        var authState: AsyncStream<User?> { AsyncStream { $0.yield(nil) } }
        var currentUser: User? { nil }
        func signIn(withEmail email: String, password: String) async throws -> UserSessionResponseDTO { throw APIError.unauthorized }
        func register(withEmail email: String, password: String, details: UserRegistrationRequestDTO) async throws -> RegistrationResponseDTO {
            // Simulate a successful registration for preview purposes
            return RegistrationResponseDTO(userId: UUID(), email: email, status: "pending_verification", verificationEmailSent: true, createdAt: Date())
        }
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