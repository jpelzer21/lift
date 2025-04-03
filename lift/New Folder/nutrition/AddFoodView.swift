import SwiftUI
import AVFoundation
struct AddFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var searchText = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [FoodItem] = []
    @State private var selectedFood: FoodItem?
    @State private var servings: Int = 1
    @State private var isScannerPresented = false
    @State private var isPopupPresented: Bool = false
    @State private var isFetchingData = false
    
    @State private var scanErrorMessage: String? // Store error messages
    @State private var isShowingScanError = false // Track error alert visibility
    
    @State private var mutableFoodItem: FoodItem?
    
    var onFoodAdded: (FoodItem) -> Void
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    TextField("Search for food...", text: $searchText, onCommit: {
                        // search for food
                        searchFood()
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                    Button {
                        // search for food
                    }label: {
                        Image(systemName: "magnifyingglass")
                            .padding()
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 20)
                
                Text("Using Open Food Facts Database")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                
                if isSearching {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVStack {
                            ForEach(searchResults) { result in
                                FoodRowView(food: result)
                                    .contentShape(Rectangle()) // Ensure it's tappable
                                    .onTapGesture {
                                        print("Tapped \(result.name)")
                                        self.selectedFood = result
                                        self.isPopupPresented = true
                                    }
                            }
                        }
                    }
                }
                           
                Spacer()
                Button(action: { isScannerPresented = true }) {
                    HStack {
                        Image(systemName: "barcode.viewfinder")
                        Text("Scan Barcode")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 20)
                
                
                

            }
            .padding(20)
            .sheet(isPresented: $isScannerPresented) {
                BarcodeScannerView(isPresented: $isScannerPresented) { scannedValue in
                    fetchNutritionData(for: scannedValue)
                }
            }
            .alert("Scan Failed", isPresented: $isShowingScanError, presenting: scanErrorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error)
            }
            .onTapGesture { // Dismiss the keyboard when tapping anywhere on the screen
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            if isPopupPresented, let food = selectedFood {
                // Create a binding to the mutableFoodItem
                FoodDetailPopup(
                    updatefood: false,
                    foodItem: Binding<FoodItem>(
                        get: { self.mutableFoodItem ?? food },
                        set: { self.mutableFoodItem = $0 }
                    ),
                    isPresented: $isPopupPresented,
                    onAddFood: { updatedFood in
                        // Use the servings from the mutableFoodItem if it exists
//                        let servings = self.mutableFoodItem?.servings ?? 1
                        self.addToDailyTotal(updatedFood)
                    }
                )
                .onAppear {
                    // Initialize the mutable copy when the popup appears
                    self.mutableFoodItem = food
                }
            }
        }
        
    }
    
    func addToDailyTotal(_ food: FoodItem) {
        let adjustedFood = FoodItem(
            servingSize: food.servingSize,
            name: food.name,
            calories: (food.calories ?? 0) * Double(servings),
            protein: (food.protein ?? 0) * Double(servings),
            fats: (food.fats ?? 0) * Double(servings),
            carbs: (food.carbs ?? 0) * Double(servings),
            sugars: (food.sugars ?? 0) * Double(servings),
            imageUrl: food.imageUrl,
            servings: food.servings
        )
        onFoodAdded(adjustedFood)  // Send new food back to NutritionView
        presentationMode.wrappedValue.dismiss()
    }
    
    private func searchFood() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isSearching = true
        searchByName(searchText) { results in
            searchResults = results
            isSearching = false
        }
    }
    
    func searchByName(_ name: String, completion: @escaping ([FoodItem]) -> Void) {
        guard !name.isEmpty else {
            completion([])
            return
        }
        
        let apiKey = "DEMO_KEY" // Replace with your actual API key
        let query = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.nal.usda.gov/fdc/v1/foods/search?api_key=\(apiKey)&query=\(query)&pageSize=30"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Error fetching food data: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(FoodSearchResponse.self, from: data)
                
                let filteredFoods = decodedResponse.foods.filter { $0.description.lowercased().contains(name.lowercased()) }

                let foodItems = filteredFoods.map { food in
                    let calories = food.foodNutrients.first(where: { $0.nutrientName.lowercased().contains("energy") })?.value ?? 0
                    let protein = food.foodNutrients.first(where: { $0.nutrientName.lowercased().contains("protein") })?.value ?? 0
                    let fats = food.foodNutrients.first(where: { $0.nutrientName.lowercased().contains("fat") })?.value ?? 0
                    let carbs = food.foodNutrients.first(where: { $0.nutrientName.lowercased().contains("carbohydrate") })?.value ?? 0
                    let sugars = food.foodNutrients.first(where: { $0.nutrientName.lowercased().contains("sugars") })?.value ?? 0
                    
                    return FoodItem(
                        servingSize: "Per 100g",
                        name: food.description,
                        calories: calories,
                        protein: protein,
                        fats: fats,
                        carbs: carbs,
                        sugars: sugars,
                        imageUrl: nil
                    )
                }
                
                DispatchQueue.main.async {
                    completion(Array(foodItems.prefix(30))) // Ensure the final list does not exceed 30
                }
            } catch {
                print("❌ Failed to decode JSON: \(error)")
                completion([])
            }
        }.resume()
    }
    
    func fetchNutritionData(for barcode: String) {
        guard !isFetchingData else { return }
        print("📸 Scanned barcode: \(barcode)")
        let urlString = "https://world.openfoodfacts.net/api/v2/product/\(barcode)"
        guard let url = URL(string: urlString) else {
            scanErrorMessage = "Invalid barcode format."
            isShowingScanError = true
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.scanErrorMessage = "Network error: \(error.localizedDescription)"
                    self.isShowingScanError = true
                }
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let product = json["product"] as? [String: Any],
                  let name = (product["generic_name"] as? String).flatMap({ $0.isEmpty ? nil : $0 }) ?? product["product_name"] as? String,
                  let nutriments = product["nutriments"] as? [String: Any] else {
                DispatchQueue.main.async {
                    self.scanErrorMessage = "No product data found for this barcode."
                    self.isShowingScanError = true
                }
                return
            }
            
            let imageUrl = product["image_url"] as? String ?? ""
            let servingSize = product["serving_size"] as? String ?? "N/A"
            let calories = nutriments["energy-kcal_serving"] as? Double ?? 0
            let protein = nutriments["proteins_serving"] as? Double ?? 0
            let fats = nutriments["fat_serving"] as? Double ?? 0
            let carbs = nutriments["carbohydrates_serving"] as? Double ?? 0
            let sugars = nutriments["sugars_serving"] as? Double ?? 0
            
            let scannedFood = FoodItem(
                servingSize: servingSize,
                name: name,
                calories: calories,
                protein: protein,
                fats: fats,
                carbs: carbs,
                sugars: sugars,
                imageUrl: imageUrl
            )
            
            DispatchQueue.main.async {
                self.selectedFood = scannedFood
                self.servings = 1
                self.isPopupPresented = true
                self.isScannerPresented = false // Dismiss scanner after successful fetch
                print("✅ Food scanned: \(scannedFood.name), popup should appear")
            }
        }.resume()
    }
}
struct FoodRowView: View {
   let food: FoodItem
   
   var body: some View {
       HStack {
//           if let imageUrl = food.imageUrl, let url = URL(string: imageUrl) {
//               AsyncImage(url: url) { image in
//                   image.resizable()
//                       .aspectRatio(contentMode: .fit)
//                       .frame(width: 50, height: 50)
//                       .cornerRadius(8)
//               } placeholder: {
//                   ProgressView()
//                       .frame(width: 50, height: 50)
//               }
//           } else {
//               Image(systemName: "photo")
//                   .frame(width: 50, height: 50)
//                   .foregroundColor(.gray)
//           }
           
           VStack(alignment: .leading, spacing: 4) {
               Text(food.name)
                   .font(.headline)
                   .minimumScaleFactor(0.75)
                   .lineLimit(3)
               
               Text("\(Int(food.calories ?? 0)) cal • \(food.servingSize)")
                   .font(.subheadline)
                   .foregroundColor(.secondary)
           }
           
           Spacer()
       }
       .padding(.vertical, 8)
       .contentShape(Rectangle())
       
   }
}
// MARK: - Barcode Scanner View
struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onScan: (String) -> Void
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: BarcodeScannerView
        var captureSession: AVCaptureSession?
        
        init(parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let scannedValue = metadataObject.stringValue {
                DispatchQueue.main.async {
                    self.parent.onScan(scannedValue)
                    self.parent.isPresented = false
                }
            }
        }
        
        func setupFailed() {
            DispatchQueue.main.async {
                self.parent.isPresented = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let coordinator = context.coordinator
        
        // Setup capture session
        let captureSession = AVCaptureSession()
        coordinator.captureSession = captureSession
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("❌ No camera found")
            coordinator.setupFailed()
            return viewController
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            print("❌ Failed to initialize camera input")
            coordinator.setupFailed()
            return viewController
        }
        
        captureSession.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else {
            print("❌ Failed to initialize metadata output")
            coordinator.setupFailed()
            return viewController
        }
        
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(coordinator, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.ean13, .ean8, .code128]
        
        // Setup preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = viewController.view.layer.bounds
        viewController.view.layer.addSublayer(previewLayer)
        
        // Start session on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No state modifications here
        if !isPresented {
            context.coordinator.captureSession?.stopRunning()
        }
    }
}

struct FoodSearchResponse: Codable {
    let foods: [USDAFood]
}

struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let foodNutrients: [USDANutrient]

    enum CodingKeys: String, CodingKey {
        case fdcId
        case description
        case foodNutrients
    }
}

struct USDANutrient: Codable {
    let nutrientName: String
    let value: Double?
}

