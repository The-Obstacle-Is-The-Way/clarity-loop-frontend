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
            
            TextField("First Name", text: $viewModel.firstName)
            TextField("Last Name", text: $viewModel.lastName)
            TextField("Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $viewModel.password)
            SecureField("Confirm Password", text: $viewModel.confirmPassword)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button { viewModel.termsAccepted.toggle() } content: {
                        Image(systemName: viewModel.termsAccepted ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.termsAccepted ? .blue : .gray)
                    }
                    Text("I accept the Terms of Service")
                        .font(.footnote)
                    Spacer()
                }
                
                HStack {
                    Button { viewModel.privacyPolicyAccepted.toggle() } content: {
                        Image(systemName: viewModel.privacyPolicyAccepted ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.privacyPolicyAccepted ? .blue : .gray)
                    }
                    Text("I accept the Privacy Policy")
                        .font(.footnote)
                    Spacer()
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: viewModel.register) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Register")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            
            Spacer()
            
            Button("Already have an account? Login") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .navigationTitle("Sign Up")
        .navigationBarBackButtonHidden(true)
    }
} 
