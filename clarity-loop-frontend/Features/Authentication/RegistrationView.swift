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
