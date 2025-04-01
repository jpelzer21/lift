////
////  AddFoodView.swift
////  lift
////
////  Created by Josh Pelzer on 3/29/25.
////
//
//

//
//struct AddFoodView: View {
//    @Environment(\.presentationMode) var presentationMode
//
//    @State private var searchText = ""
//    @State private var searchResults: [FoodItem] = []
//    @State private var isSearching = false
//    @State private var isScannerPresented = false
//    @State private var isPopupPresented = false
//    @State private var selectedFood: FoodItem?
//    @State private var servings = 1
//
//    var onAddFood: (FoodItem) -> Void
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                VStack(spacing: 20) {
//                    
//                    VStack(spacing: 5) {
//                        // Search Bar
//                        HStack {
//                            TextField("Search for food...", text: $searchText)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .onSubmit {
//                                    searchFood()
//                                }
//                                .padding(.leading)
//                            
//                            Button {
//                                searchFood()
//                            }label: {
//                                Image(systemName: "magnifyingglass")
//                                    .padding()
//                                    .background(Color.pink)
//                                    .foregroundColor(.white)
//                                    .clipShape(Circle())
//                            }
//                        }
//                        .padding(.horizontal)
//                        
//                        Text("Using Open Food Facts Database")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                    
//                    // Barcode Scanner Button
//                    Button(action: { isScannerPresented = true }) {
//                        HStack {
//                            Image(systemName: "barcode.viewfinder")
//                            Text("Scan Barcode")
//                        }
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.pink)
//                        .foregroundColor(.white)
//                        .clipShape(RoundedRectangle(cornerRadius: 10))
//                    }
//                    .padding(.horizontal)
//                    
//                    // Search Results List
//                    if isSearching {
//                        ProgressView("Searching...")
//                            .progressViewStyle(CircularProgressViewStyle())
//                            .padding()
//                    } else if !searchResults.isEmpty {
//                        List {
//                            ForEach(searchResults, id: \.id) { food in
//                                foodRow(food)
//                            }
//                        }
//                    }
//                    Spacer()
//                    
//                }
//                .navigationTitle("Add Food")
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        Button("Cancel") {
//                            presentationMode.wrappedValue.dismiss()
//                        }
//                    }
//                    //                ToolbarItem(placement: .navigationBarTrailing) {
//                    //                    Button(action: {
//                    //                        isPopupPresented = true
//                    //                        selectedFood = FoodItem(name: "", calories: 0, protein: 0, fats: 0, carbs: 0, sugars: 0, scans: 0, imageUrl: "")
//                    //                    }) {
//                    //                        Image(systemName: "plus")
//                    //                    }
//                    //                }
//                }
//                if isPopupPresented {
//                    if let food = selectedFood {
//                        FoodDetailPopup(
//                            food: food,
//                            servings: $servings,
//                            isPresented: $isPopupPresented
//                        ) {
//                            onAddFood(food)
//                            isPopupPresented = false
//                            selectedFood = nil
//                        }
//                    }
//                }
//            }
//        }
//        .onTapGesture {
//            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//        }
//        .sheet(isPresented: $isScannerPresented) {
//            BarcodeScannerView(isPresented: $isScannerPresented) { scannedValue in
//                fetchNutritionData(for: scannedValue)
//            }
//        }
////        .sheet(isPresented: $isPopupPresented) {
////            if let food = selectedFood {
////                FoodDetailPopup(
////                    food: food,
////                    servings: $servings,
////                    isPresented: $isPopupPresented
////                ) {
////                    
////                    onAddFood(food)
////                    isPopupPresented = false
////                    selectedFood = nil
////                    presentationMode.wrappedValue.dismiss()
////                }
////            }
////        }
//    }
//
//    // MARK: - Food Row
//    private func foodRow(_ food: FoodItem) -> some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text(food.name)
//                    .font(.headline)
//                Text("\(String(format: "%.1f", food.calories ?? 0)) kcal, \(String(format: "%.1f", food.protein ?? 0))g protein")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//            Spacer()
//            URLImage(url: food.imageUrl)
//                .frame(width: 44, height: 44)
//        }
//        .padding()
//        .background(Color(UIColor.systemBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 10))
//        .shadow(radius: 2)
//        .padding(.horizontal)
//        .onTapGesture {
//            DispatchQueue.main.async {
//                self.selectedFood = food
//                self.servings = 1
//                self.isPopupPresented = true // Ensure this happens after selectedFood is set
//            }
////            selectedFood = food
////            servings = 1
////            isPopupPresented = true
//            print("✅ Food selected: \(food)")
//        }
//    }
//
//    private func searchFood() {
//        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//        isSearching = true
//        fetchFoodByName(searchText) { results in
//            searchResults = results
//            isSearching = false
//        }
//    }
//    
//    func fetchFoodByName(_ name: String, completion: @escaping ([FoodItem]) -> Void) {
//        isSearching = true
//
//        let urlString = "https://world.openfoodfacts.net/cgi/search.pl?search_terms=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&json=true"
//
//        guard let url = URL(string: urlString) else {
//            isSearching = false
//            return
//        }
//
//        URLSession.shared.dataTask(with: url) { data, _, error in
//            defer { DispatchQueue.main.async { isSearching = false } }
//
//            guard let data = data, error == nil else { return }
//
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let products = json["products"] as? [[String: Any]] {
//
//                    let lowercasedSearch = name.lowercased()
//                    
//                    var foodItems = products.compactMap { product -> FoodItem? in
//                        guard let name = product["product_name"] as? String else { return nil }
////                        let lowercasedName = name.lowercased()
//                        let nutriments = product["nutriments"] as? [String: Any] ?? [:]
//                        
//                        return FoodItem(
//                            name: name,
//                            calories: nutriments["energy-kcal_serving"] as? Double ?? nutriments["energy-kcal_100g"] as? Double,
//                            protein: nutriments["proteins_serving"] as? Double ?? nutriments["proteins_100g"] as? Double,
//                            fats: nutriments["fat_serving"] as? Double ?? nutriments["fat_100g"] as? Double,
//                            carbs: nutriments["carbohydrates_serving"] as? Double ?? nutriments["carbohydrates_100g"] as? Double,
//                            sugars: nutriments["sugars_serving"] as? Double ?? nutriments["sugars_100g"] as? Double,
//                            scans: product["unique_scans_n"] as? Int ?? 0,
//                            imageUrl: product["image_url"] as? String
//                        )
//                    }
//                    
//                    // Sorting logic
//                    foodItems.sort {
//                        let nameA = $0.name.lowercased()
//                        let nameB = $1.name.lowercased()
//
//                        let exactMatchA = nameA == lowercasedSearch
//                        let exactMatchB = nameB == lowercasedSearch
//
//                        let startsWithA = nameA.hasPrefix(lowercasedSearch)
//                        let startsWithB = nameB.hasPrefix(lowercasedSearch)
//
//                        if exactMatchA != exactMatchB {
//                            return exactMatchA // Prioritize exact match
//                        } else if startsWithA != startsWithB {
//                            return startsWithA // Prioritize starts-with match
//                        } else {
//                            return $0.scans > $1.scans // Prioritize popular items
//                        }
//                    }
//
//                    DispatchQueue.main.async {
//                        completion(foodItems)
//                    }
//                }
//            } catch {
//                print("Failed to parse JSON: \(error)")
//            }
//        }.resume()
//    }
//
//    func fetchNutritionData(for barcode: String) {
//        print("FETCHING NUTRITION DATA FOR BARCODE: \(barcode)")
//        
//        let urlString = "https://world.openfoodfacts.net/api/v2/product/\(barcode)?fields=product_name,nutriments,image_url"
//        
//        guard let url = URL(string: urlString) else {
//            print("❌ Invalid URL")
//            return
//        }
//        
//        URLSession.shared.dataTask(with: url) { data, _, _ in
//            guard let data = data,
//                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                  let product = json["product"] as? [String: Any],
//                  let name = product["product_name"] as? String,
//                  let nutriments = product["nutriments"] as? [String: Any] else {
//                print("❌ Failed to fetch product data or parse JSON")
//                return
//            }
//            
//            // Check the entire product object
//            print("Fetched Product: \(product)")
//            
//            let imageUrl = product["image_url"] as? String ?? "https://via.placeholder.com/150"
//            print("Image URL: \(imageUrl)") // Check if image URL is fetched
//            
//            let calories = nutriments["energy-kcal_serving"] as? Double ?? nutriments["energy-kcal_100g"] as? Double ?? 0
//            let protein = nutriments["proteins_serving"] as? Double ?? nutriments["proteins_100g"] as? Double ?? 0
//            let fats = nutriments["fat_serving"] as? Double ?? nutriments["fat_100g"] as? Double ?? 0
//            let carbs = nutriments["carbohydrates_serving"] as? Double ?? nutriments["carbohydrates_100g"] as? Double ?? 0
//            let sugars = nutriments["sugars_serving"] as? Double ?? nutriments["sugars_100g"] as? Double ?? 0
//
//            // Create FoodItem with the fetched data
//            let scannedFood = FoodItem(name: name, calories: calories, protein: protein, fats: fats, carbs: carbs, sugars: sugars, scans: 0, imageUrl: imageUrl)
//
//            // Log the scannedFood object
//            print("Scanned Food: \(scannedFood)")
//
//            DispatchQueue.main.async {
//                self.selectedFood = scannedFood
//                self.servings = 1
//                self.isPopupPresented = true
//                print("✅ Food scanned: \(scannedFood.name), popup should appear")
//            }
//        }.resume()
//    }
//    
//}
//

//
//struct URLImage: View {
//    let url: String?
//    
//    @State private var imageData: Data? = nil
//    
//    var body: some View {
//        Group {
//            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
//                Image(uiImage: uiImage)
//                    .resizable()
//                    .scaledToFit()
//            } else {
////                Image(systemName: "chevron.right")
//                ProgressView()
//                    .onAppear {
//                        loadImage()
//                    }
//            }
//        }
//    }
//    
//    private func loadImage() {
//        guard let urlString = url, let url = URL(string: urlString) else {
//            return
//        }
//        
//        URLSession.shared.dataTask(with: url) { data, _, _ in
//            if let data = data {
//                DispatchQueue.main.async {
//                    self.imageData = data
//                }
//            }
//        }.resume()
//    }
//}
//
//struct FoodItem: Identifiable, Codable {
//    var id = UUID()
//    let name: String
//    let calories: Double?
//    let protein: Double?
//    let fats: Double?
//    let carbs: Double?
//    let sugars: Double?
//    let scans: Int
//    let imageUrl: String?
//}



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
    
    @State private var mutableFoodItem: FoodItem?
    
    var onFoodAdded: (FoodItem) -> Void

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    TextField("Search for food...", text: $searchText, onCommit: {
                        searchFood()
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)

                    Button {
                        searchFood()
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
                    List {
                        ForEach(searchResults, id: \.id) { result in
                            FoodRowView(food: result)
                                .onTapGesture {
                                    self.selectedFood = result
                                    self.isPopupPresented = true
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
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
        isSearching = true
        
        let searchTerms = name.lowercased().components(separatedBy: " ")
        let urlString = "https://world.openfoodfacts.net/cgi/search.pl?search_terms=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&json=true&sort_by=unique_scans_n"

        guard let url = URL(string: urlString) else {
            isSearching = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            defer { DispatchQueue.main.async { self.isSearching = false } }

            guard let data = data, error == nil else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let products = json["products"] as? [[String: Any]] {
                    
                    let foodItems = products.compactMap { product -> (FoodItem, Int)? in
                        // Get name - use generic_name first, fall back to product_name
                        let productName = product["product_name"] as? String ?? ""
                        let genericName = product["generic_name"] as? String
                        let displayName = genericName?.isEmpty ?? true ? productName : genericName!
                        
                        guard !displayName.isEmpty else { return nil }
                        
                        let lowercasedName = displayName.lowercased()
                        let scans = product["unique_scans_n"] as? Int ?? 0
                        
                        // Check relevance
                        let containsAllTerms = searchTerms.allSatisfy { lowercasedName.contains($0) }
                        guard containsAllTerms || searchTerms.contains(where: { lowercasedName.contains($0) }) else {
                            return nil
                        }
                        
                        let nutriments = product["nutriments"] as? [String: Any] ?? [:]
                        
                        let foodItem = FoodItem(
                            servingSize: product["serving_size"] as? String ?? "N/A",
                            name: displayName,
                            calories: nutriments["energy-kcal_serving"] as? Double ?? nutriments["energy-kcal_100g"] as? Double,
                            protein: nutriments["proteins_serving"] as? Double ?? nutriments["proteins_100g"] as? Double,
                            fats: nutriments["fat_serving"] as? Double ?? nutriments["fat_100g"] as? Double,
                            carbs: nutriments["carbohydrates_serving"] as? Double ?? nutriments["carbohydrates_100g"] as? Double,
                            sugars: nutriments["sugars_serving"] as? Double ?? nutriments["sugars_100g"] as? Double,
                            imageUrl: product["image_url"] as? String
                        )
                        
                        return (foodItem, scans)
                    }
                    .sorted { $0.1 > $1.1 } // Sort by scan count (popularity)
                    .map { $0.0 } // Keep just the FoodItems

                    DispatchQueue.main.async {
                        completion(foodItems)
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }.resume()
    }




    func fetchNutritionData(for barcode: String) {
        guard !isFetchingData else { return }
        print("📸 Scanned barcode: \(barcode)")
        let urlString = "https://world.openfoodfacts.net/api/v2/product/\(barcode)"

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let product = json["product"] as? [String: Any],
                  let name = (product["generic_name"] as? String).flatMap({ $0.isEmpty ? nil : $0 }) ?? product["product_name"] as? String,
                  let nutriments = product["nutriments"] as? [String: Any] else {
                print("❌ Failed to fetch product data or parse JSON")
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
           if let imageUrl = food.imageUrl, let url = URL(string: imageUrl) {
               AsyncImage(url: url) { image in
                   image.resizable()
                       .aspectRatio(contentMode: .fit)
                       .frame(width: 50, height: 50)
                       .cornerRadius(8)
               } placeholder: {
                   ProgressView()
                       .frame(width: 50, height: 50)
               }
           } else {
               Image(systemName: "photo")
                   .frame(width: 50, height: 50)
                   .foregroundColor(.gray)
           }
           
           VStack(alignment: .leading, spacing: 4) {
               Text(food.name)
                   .font(.headline)
                   .lineLimit(1)
               
               Text("\(Int(food.calories ?? 0)) cal • \(food.servingSize)")
                   .font(.subheadline)
                   .foregroundColor(.secondary)
           }
           
           Spacer()
       }
       .padding(.vertical, 8)
   }
}


// MARK: - Barcode Scanner View
struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onScan: (String) -> Void
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: BarcodeScannerView
        
        init(parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let scannedValue = metadataObject.stringValue {
                DispatchQueue.main.async {
                    self.parent.onScan(scannedValue)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("❌ No camera found")
            return UIViewController()
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            print("❌ Failed to initialize camera input")
            return UIViewController()
        }
        
        captureSession.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .code128] // Common barcode formats
        } else {
            print("❌ Failed to initialize metadata output")
            return UIViewController()
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        let viewController = UIViewController()
        let view = UIView(frame: UIScreen.main.bounds)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.layer.bounds
        viewController.view = view
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if !isPresented {
            (uiViewController.view.layer.sublayers?.first as? AVCaptureVideoPreviewLayer)?.session?.stopRunning()
        }
    }
}
