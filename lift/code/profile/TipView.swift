//
//  DonationView.swift
//  Stat Lab
//
//  Created by Josh Pelzer on 5/21/25.
//


import SwiftUI
import StoreKit
import Foundation

struct TipView: View {
    @StateObject private var store = TipStore(productID: "com.yourapp.tip5")

    var body: some View {
        VStack(spacing: 24) {
            Text("Support the Developer 💙")
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)

            Text("Enjoying the app?  Leave a $5 tip to help keep it going!")
                .multilineTextAlignment(.center)

            Group {
                switch store.state {
                case .loading:
                    ProgressView("Loading…")
                case .ready(let product):
                    Button {
                        store.purchase(product)
                    } label: {
                        Text("Tip \(product.displayPrice)")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                case .failed(let errorText):
                    Text(errorText)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)

            if let thanks = store.thankYouText {
                Text(thanks)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .onAppear { store.loadProduct() }
    }
}



@MainActor
final class TipStore: ObservableObject {
    enum StoreState {
        case loading
        case ready(Product)
        case failed(String)
    }

    @Published var state: StoreState = .loading
    @Published var thankYouText: String?

    private let productID: String

    init(productID: String) {
        self.productID = productID
    }

    // MARK: – Load one product
    func loadProduct() {
        Task {
            do {
                let products = try await Product.products(for: [productID])
                guard let product = products.first else {
                    state = .failed("Product not found.")
                    return
                }
                state = .ready(product)
            } catch {
                state = .failed("Failed to load product.")
                print("StoreKit error:", error)
            }
        }
    }

    // MARK: – Purchase
    func purchase(_ product: Product) {
        Task {
            do {
                let result = try await product.purchase()

                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(_):
                        thankYouText = "Thanks for the tip! 🎉"
                    case .unverified(_, _):
                        print("Transaction could not be verified.")
                    }

                case .userCancelled:
                    // User closed the sheet—no action needed.
                    break

                case .pending:
                    // Waiting for approval (e.g., parental controls).
                    break

                @unknown default:
                    break
                }
            } catch {
                print("Purchase failed:", error)
            }
        }
    }
}


