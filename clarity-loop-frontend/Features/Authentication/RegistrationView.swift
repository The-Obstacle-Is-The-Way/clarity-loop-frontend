import SwiftUI

struct RegistrationView: View {
    
    // MARK: - Environment
    
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - State
    
    @State private var viewModel: RegistrationViewModel
    
    // MARK: - Initializer
    
    init(authService: AuthServiceProtocol) {
        _viewModel = State(initialValue: RegistrationViewModel(authService: authService))
    }
    
    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            TextField("First Name", text: $viewModel.firstName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            TextField("Last Name", text: $viewModel.lastName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

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
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button(action: { viewModel.termsAccepted.toggle() }) {
                        Image(systemName: viewModel.termsAccepted ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.termsAccepted ? .blue : .gray)
                    }
                    Text("I accept the Terms of Service")
                        .font(.footnote)
                    Spacer()
                }
                
                HStack {
                    Button(action: { viewModel.privacyPolicyAccepted.toggle() }) {
                        Image(systemName: viewModel.privacyPolicyAccepted ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.privacyPolicyAccepted ? .blue : .gray)
                    }
                    Text("I accept the Privacy Policy")
                        .font(.footnote)
                    Spacer()
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                Button(action: {
                    Task {
                        await viewModel.register()
                    }
                }) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Spacer()
            
            Button("Already have an account? Login") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding()
        .navigationTitle("Register")
    }
}

#Preview {
    let previewAPIClient = APIClient(
        baseURLString: "https://crave-trinity--clarity-backend-fastapi-app.modal.run",
        tokenProvider: { nil }
    )!
    
    RegistrationView(authService: AuthService(apiClient: previewAPIClient))
} 
