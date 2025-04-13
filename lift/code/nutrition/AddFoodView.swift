import SwiftUI
import AVFoundation
struct AddFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var viewModel = UserViewModel.shared
    
    @State private var searchText = ""
    @State private var isSearching: Bool = false
    @State private var searchResults: [FoodItem] = []
    @State private var selectedFood: FoodItem = FoodItem(servingSize: "", name: "", calories: 0, protein: 0, fats: 0, carbs: 0, sugars: 0, imageUrl: "")
    @State private var servings: Int = 1
    @State private var isScannerPresented = false
    @State private var isPopupPresented: Bool = false
    @State private var isFetchingData = false
    
    @State private var scanErrorMessage: String?
    @State private var isShowingScanError = false
    @State private var isShowingCreateFood: Bool = false
    @State private var selectedTab = 1  // 0: Search, 1: Custom, 2: Barcode
    
    @State private var mutableFoodItem: FoodItem?
    
    var onFoodAdded: (FoodItem) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                // Segmented Picker for switching between tabs
                Picker(selection: $selectedTab, label: Text("Select Mode")) {
                    Text("Search").tag(0)
                    Text("My Foods").tag(1)
                    Text("Scan").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Search Food
                if selectedTab == 0 {
                    VStack {
                        HStack {
                            TextField("Search for food...", text: $searchText, onCommit: searchFood)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: searchFood) {
                                Image(systemName: "magnifyingglass")
                                    .padding()
                                    .background(Color.pink)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("Using USDA Database")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if isSearching {
                            ProgressView()
                        } else {
                            ScrollView {
                                LazyVStack {
                                    ForEach(searchResults.sorted { $0.name < $1.name }) { food in
                                        FoodRowView(food: food)
                                            .onTapGesture {
                                                self.selectedFood = food
                                                self.isPopupPresented = true
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                
                // Custom Foods
                else if selectedTab == 1 {
                    VStack {
                        if viewModel.customFoods.isEmpty {
                            Text("No custom foods found.")
                                .foregroundColor(.gray)
                        } else {
                            ScrollView {
                                LazyVStack {
                                    ForEach(viewModel.customFoods) { food in
                                        FoodRowView(food: food)
                                            .onTapGesture {
                                                self.selectedFood = food
                                                print(selectedFood.name as Any)
                                                self.isPopupPresented = true
                                            }
                                        
                                    }
                                }
                            }
                        }
                        
                        Button(action: { isShowingCreateFood = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Create Custom Food")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.horizontal)
                    }
                    .padding(20)
                }
                
                // Barcode Scanner
                else if selectedTab == 2 {
                    VStack {
                        Text("Scan a barcode to find food information.")
                            .foregroundColor(.gray)
                            .padding()
                        
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
                        .padding(.horizontal)
                        Text("Using Open Food Facts Database")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Add Food")
            .sheet(isPresented: $isShowingCreateFood) {
                CreateFoodView(viewModel: viewModel)
            }
            .sheet(isPresented: $isScannerPresented) {
                BarcodeScannerSheetView(isPresented: $isScannerPresented) { scannedValue in
                    fetchNutritionData(for: scannedValue)
                }
            }
            .sheet(isPresented: $isPopupPresented) {
                FoodDetailPopup(
                    updatefood: false,
                    foodItem: $selectedFood,
                    isPresented: $isPopupPresented,
                    onAddFood: { updatedFood in
                        addToDailyTotal(updatedFood)
                    }
                )
            }
            .alert(isPresented: $isShowingScanError) {
                Alert(
                    title: Text("Scan Error"),
                    message: Text(scanErrorMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
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
        
        let apiKey = "m8AiMgvgfhUH7ADnKjLhLU7SpbBfZuZE9zur745D"
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
        isFetchingData = true
        print("📸 Scanned barcode: \(barcode)")
        
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            showScanError("Invalid barcode format.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            defer { isFetchingData = false }
            
            if let error = error {
                showScanError("Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                showScanError("No data returned from server.")
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let product = json["product"] as? [String: Any],
                      let name = (product["generic_name"] as? String).flatMap({ $0.isEmpty ? nil : $0 }) ?? product["product_name"] as? String,
                      let nutriments = product["nutriments"] as? [String: Any] else {
                    showScanError("Invalid response structure or missing fields.")
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
                    self.isScannerPresented = false
                    self.isPopupPresented = true
                    print("✅ Scanned food ready: \(scannedFood.name)")
                }
            } catch {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔍 Raw JSON:\n\(jsonString)")
                }
                showScanError("Failed to parse nutrition data.")
            }
        }.resume()
    }

    private func showScanError(_ message: String) {
        DispatchQueue.main.async {
            self.scanErrorMessage = message
            self.isShowingScanError = true
            self.isScannerPresented = false
            print("❌ Scan error: \(message)")
        }
    }
}

struct FoodRowView: View {
   let food: FoodItem
   
   var body: some View {
       HStack {
           
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
       .frame(maxWidth: .infinity, alignment: .leading)
       .padding(.horizontal, 20)
       .padding(.vertical, 10)
       .contentShape(Rectangle())
       
   }
}

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

struct BarcodeScannerSheetView: View {
    @Binding var isPresented: Bool
    var onScan: (String) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
            BarcodeScannerView(isPresented: $isPresented, onScan: onScan)
                .cornerRadius(20)
                .padding(.horizontal)
        }
        .presentationDragIndicator(.visible)
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



