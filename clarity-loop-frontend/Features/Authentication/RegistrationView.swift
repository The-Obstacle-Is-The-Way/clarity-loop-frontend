import SwiftUI
import FirebaseAuth

struct RegistrationView: View {
    
    @State private var viewModel: RegistrationViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(authService: AuthServiceProtocol) {
        _viewModel = State(initialValue: RegistrationViewModel(authService: authService))
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
    }
} 