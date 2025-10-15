import SwiftUI

@main
struct StarkPayiOSApp: App {
    @StateObject private var viewModel = StarkPayViewModel()
    @State private var isShowingSplash = true
    
    var body: some Scene {
        WindowGroup {
            if isShowingSplash {
                SplashView(isShowingSplash: $isShowingSplash)
            } else {
                ContentView()
                    .environmentObject(viewModel)
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PayView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "dollarsign.circle.fill" : "dollarsign.circle")
                    Text("Pay")
                }
                .tag(0)
            
            ActivityView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "list.bullet.circle.fill" : "list.bullet.circle")
                    Text("Activity")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.circle.fill" : "person.circle")
                    Text("You")
                }
                .tag(2)
        }
        .accentColor(.black)
    }
}

struct PayView: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @State private var showSendSheet = false
    @State private var showRequestSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        Text("$\(viewModel.balance, specifier: "%.2f")")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Available Balance")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    
                    HStack(spacing: 40) {
                        ActionButton(
                            icon: "arrow.up.circle.fill",
                            title: "Pay",
                            color: .black
                        ) {
                            showSendSheet = true
                        }
                        
                        ActionButton(
                            icon: "arrow.down.circle.fill", 
                            title: "Request",
                            color: .black
                        ) {
                            showRequestSheet = true
                        }
                        
                        ActionButton(
                            icon: "gearshape.circle",
                            title: "Advanced",
                            color: .gray
                        ) {
                        }
                    }
                    .padding(.vertical, 20)
                    
                    if !viewModel.transactions.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Recent")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                            }
                            
                            ForEach(Array(viewModel.transactions.prefix(3)), id: \.id) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("StarkPay")
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showSendSheet) {
            SendSheet().environmentObject(viewModel)
        }
        .sheet(isPresented: $showRequestSheet) {
            RequestSheet().environmentObject(viewModel)
        }
    }
}

struct ActivityView: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.transactions, id: \.id) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    
                    if viewModel.transactions.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "clock.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No activity yet")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("Make your first payment to get started")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 100)
                    }
                }
                .padding()
            }
            .navigationTitle("Activity")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("SP")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Text("@starkpay_user")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("david@starkpay.com")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 15) {
                        MenuRow(icon: "person.circle", title: "Edit Profile")
                        MenuRow(icon: "creditcard", title: "Payment Methods")
                        MenuRow(icon: "bell", title: "Notifications")
                        MenuRow(icon: "shield", title: "Security")
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        MenuRow(icon: "gearshape.2", title: "Advanced Options")
                            .foregroundColor(.gray)
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        MenuRow(icon: "questionmark.circle", title: "Help & Support")
                        MenuRow(icon: "info.circle", title: "About")
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("You")
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: SimpleTransaction
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(transaction.isReceived ? Color.green : Color.black)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: transaction.isReceived ? "arrow.down" : "arrow.up")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.isReceived ? "From \(transaction.otherParty)" : "To \(transaction.otherParty)")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(transaction.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("\(transaction.isReceived ? "+" : "-")$\(transaction.amount, specifier: "%.2f")")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.isReceived ? .green : .black)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct SendSheet: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @State private var recipient = ""
    @State private var amount = ""
    @State private var note = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text("Pay Someone")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(spacing: 20) {
                    TextField("To: username or phone", text: $recipient)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.headline)
                    
                    TextField("$0.00", text: $amount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                    
                    TextField("What's this for?", text: $note)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.subheadline)
                }
                .padding()
                
                Button(action: {
                    if let amountValue = Double(amount), !recipient.isEmpty {
                        viewModel.sendPayment(to: recipient, amount: amountValue, note: note)
                    }
                    dismiss()
                }) {
                    Text("Pay $\(amount.isEmpty ? "0.00" : amount)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .disabled(recipient.isEmpty || amount.isEmpty)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Pay")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct RequestSheet: View {
    @EnvironmentObject var viewModel: StarkPayViewModel
    @State private var amount = ""
    @State private var note = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Text("Request Payment")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(spacing: 20) {
                    TextField("$0.00", text: $amount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                    
                    TextField("What's this for?", text: $note)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.subheadline)
                }
                .padding()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            Image(systemName: "qrcode")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("QR Code")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Request $\(amount.isEmpty ? "0.00" : amount)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .disabled(amount.isEmpty)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Request")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

@MainActor
class StarkPayViewModel: ObservableObject {
    @Published var balance: Double = 1247.83
    @Published var transactions: [SimpleTransaction] = []
    @Published var isConnected = true
    
    init() {
        setupMockData()
    }
    
    func sendPayment(to recipient: String, amount: Double, note: String) {
        balance -= amount
        
        let newTransaction = SimpleTransaction(
            id: UUID().uuidString,
            amount: amount,
            otherParty: recipient,
            isReceived: false,
            date: Date(),
            note: note
        )
        
        transactions.insert(newTransaction, at: 0)
    }
    
    private func setupMockData() {
        transactions = [
            SimpleTransaction(
                id: "1",
                amount: 25.0,
                otherParty: "alice_crypto",
                isReceived: true,
                date: Date().addingTimeInterval(-1800),
                note: "Thanks for lunch! 🍕"
            ),
            SimpleTransaction(
                id: "2", 
                amount: 12.50,
                otherParty: "bob_defi",
                isReceived: false,
                date: Date().addingTimeInterval(-3600),
                note: "Coffee money ☕"
            ),
            SimpleTransaction(
                id: "3",
                amount: 8.42,
                otherParty: "sarah_web3", 
                isReceived: true,
                date: Date().addingTimeInterval(-86400),
                note: "Split dinner"
            )
        ]
    }
}

struct SimpleTransaction: Identifiable {
    let id: String
    let amount: Double
    let otherParty: String
    let isReceived: Bool
    let date: Date
    let note: String
}

#Preview {
    ContentView()
        .environmentObject(StarkPayViewModel())
}