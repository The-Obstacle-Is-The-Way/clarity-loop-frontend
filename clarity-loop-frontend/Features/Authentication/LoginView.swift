import SwiftUI
import FirebaseAuth

struct LoginView: View {
    
    // The ViewModel is now initialized directly with the service from the environment.
    @State private var viewModel: LoginViewModel
    
    // Access the shared AuthService via the environment.
    @Environment(\.authService) private var authService
    
    // State for navigation to the registration view.
    @State private var showRegistration = false
    
    init(authService: AuthServiceProtocol) {
        _viewModel = State(initialValue: LoginViewModel(authService: authService))
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
                RegistrationView(authService: authService)
            }
        }
    }
} 
