import SwiftUI
import StoreKit
import Foundation


struct TipView: View {
    @StateObject private var tipper = TipManager()

    var body: some View {
        VStack(spacing: 24) {
            Text("Support the Developer 💙")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)

            Text("Enjoying the app?  Leave a $5 tip to help keep it going!")
                .multilineTextAlignment(.center)

            Button {
                tipper.purchaseTip()
            } label: {
                Text("Tip $5")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(tipper.isPurchasing)

            if let message = tipper.message {
                Text(message)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .padding()
    }
}



@MainActor
final class TipManager: ObservableObject {
    @Published var message: String?
    @Published var isPurchasing = false

    private let productID = "jpelz21.lift.tip5"

    /// Starts the purchase flow for the $5 tip.
    func purchaseTip() {
        isPurchasing = true
        Task {
            defer { isPurchasing = false }

            do {
                let products = try await Product.products(for: [productID])
                print("Fetched products: \(products.map(\.id))")  // <--- DEBUG LINE

                guard let product = products.first else {
                    message = "Unable to load tip."
                    return
                }

                let result = try await product.purchase()

                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified:
                        message = "Thanks for the tip! 🎉"
                    case .unverified:
                        message = "Purchase could not be verified."
                    }

                case .userCancelled:
                    break
                case .pending:
                    message = "Purchase is pending approval."
                @unknown default:
                    break
                }
            } catch {
                message = "Something went wrong. Please try again later."
                print("StoreKit error:", error)
            }
        }
    }
}
