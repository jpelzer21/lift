import SwiftUI
import AVFoundation

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
                    self.parent.isPresented = false // Dismiss after scanning
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let captureSession = AVCaptureSession()
        let videoCaptureDevice = AVCaptureDevice.default(for: .video)
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice!),
              captureSession.canAddInput(videoInput) else {
            return UIViewController()
        }

        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .code128] // Common barcode formats
        } else {
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

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct NutritionView: View {
    @State private var foodsEaten: [FoodItem] = UserDefaultsManager.loadFoods()
    @State private var isAddingFood = false
    
    @State private var dailyCalories: Double = 0
    @State private var calorieGoal: Double = 2000
    @State private var dailyProtein: Double = 0
    @State private var proteinGoal: Double = 200
    @State private var dailyFats: Double = 0
    @State private var fatsGoal: Double = 50
    @State private var dailySugars: Double = 0
    @State private var sugarsGoal: Double = 50
    @State private var dailyCarbs: Double = 0
    @State private var carbsGoal: Double = 300
    
    var calorieProgress: Double {
        min(dailyCalories / calorieGoal, 1.0)
    }
    
    var proteinProgress: Double {
        min(dailyProtein / proteinGoal, 1.0)
    }
    
    var fatsProgress: Double {
        min(dailyFats / fatsGoal, 1.0)
    }
    
    var sugarsProgress: Double {
        min(dailySugars / sugarsGoal, 1.0)
    }
    
    var carbsProgress: Double {
        min(dailyCarbs / carbsGoal, 1.0)
    }

    var body: some View {
        VStack {
            ZStack {
                // Center Calorie Circle
                ZStack {
                    Circle()
                        .stroke(lineWidth: 15)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Circle()
                        .trim(from: 0.0, to: calorieProgress)
                        .stroke(AngularGradient(gradient: Gradient(colors: [.green, .yellow, .red]), center: .center), lineWidth: 15)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: calorieProgress)
                    
                    VStack {
                        Text("\(Int(dailyCalories))")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("calories")
                            .font(.headline)
                    }
                }
                .frame(width: 200, height: 200)
                .padding()
                VStack {
                    if false {
                        HStack {
                            // Carbs Circle (Top-right corner)
                            ZStack {
                                Circle()
                                    .stroke(lineWidth: 5)
                                    .opacity(0.3)
                                    .foregroundColor(.gray)
                                
                                Circle()
                                    .trim(from: 0.0, to: carbsProgress)
                                    .stroke(AngularGradient(gradient: Gradient(colors: [.green, .yellow, .red]), center: .center), lineWidth: 5)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut, value: carbsProgress)
                                
                                VStack {
                                    Text("\(Int(dailyCarbs))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Text("carbs")
                                        .font(.caption)
                                }
                            }
                            .frame(width: 75, height: 75)
                            
                            Spacer()
                            
                            // Fats Circle (Bottom-left corner)
                            ZStack {
                                Circle()
                                    .stroke(lineWidth: 5)
                                    .opacity(0.3)
                                    .foregroundColor(.gray)
                                
                                Circle()
                                    .trim(from: 0.0, to: fatsProgress)
                                    .stroke(AngularGradient(gradient: Gradient(colors: [.green, .yellow, .red]), center: .center), lineWidth: 5)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut, value: fatsProgress)
                                
                                VStack {
                                    Text("\(Int(dailyFats))")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                    Text("fats")
                                        .font(.caption)
                                }
                            }
                            .frame(width: 75, height: 75)
                            
                        }
                        .padding(.horizontal, 10)
                    }
                    Spacer()
                    
                    HStack {
                        // Sugars Circle (Bottom-right corner)
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 5)
                                .opacity(0.3)
                                .foregroundColor(.gray)
                            
                            Circle()
                                .trim(from: 0.0, to: sugarsProgress)
                                .stroke(AngularGradient(gradient: Gradient(colors: [.green, .yellow, .red]), center: .center), lineWidth: 5)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: sugarsProgress)
                            
                            VStack {
                                Text("\(Int(dailySugars))")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("sugars")
                                    .font(.caption)
                            }
                        }
                        .frame(width: 75, height: 75)

                        Spacer()
                        
                        // Protein Circle (Top-left corner)
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 5)
                                .opacity(0.3)
                                .foregroundColor(.gray)
                            
                            Circle()
                                .trim(from: 0.0, to: proteinProgress)
                                .stroke(AngularGradient(gradient: Gradient(colors: [.green, .yellow, .red]), center: .center), lineWidth: 5)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: proteinProgress)
                            
                            VStack {
                                Text("\(Int(dailyProtein))")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text("protein")
                                    .font(.caption)
                            }
                        }
                        .frame(width: 75, height: 75)
                    }
                    .padding(.horizontal, 10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 300)
            
            Button("+ Add Food") {
                isAddingFood = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            List(foodsEaten.reversed()) { food in
                HStack {
                    Text(food.name)
                    Spacer()
                    Text("\(String(format: "%.1f", food.calories)) kcal")
                }
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $isAddingFood) {
            AddFoodView(foodsEaten: $foodsEaten, dailyCalories: $dailyCalories, dailyProtein: $dailyProtein)
        }
    }
}

struct AddFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var foodsEaten: [FoodItem]
    @Binding var dailyCalories: Double
    @Binding var dailyProtein: Double
    
    @State private var isScannerPresented = false
    @State private var scannedBarcode: String = ""
    @State private var nutritionData: FoodItem? = nil
    @State private var servings: Int = 1
    
    @State private var searchText = ""
    @State private var searchResults: [FoodItem] = []

    var body: some View {
        VStack(spacing: 20) {
            TextField("Search for food...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Search") {
                fetchFoodByName(searchText) { results in
                    searchResults = results
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            if !searchResults.isEmpty {
                List(searchResults) { food in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(food.name)
                                .font(.headline)
                            Text("\(food.calories, specifier: "%.1f") kcal, \(food.protein, specifier: "%.1f")g protein")
                                .font(.subheadline)
                        }
                        Spacer()
                        Button("+") {
                            foodsEaten.append(food)
                            dailyCalories += food.calories
                            dailyProtein += food.protein
                            UserDefaultsManager.saveFoods(foodsEaten)
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                    }
                }
            }
            
            Button("Scan Barcode") {
                isScannerPresented = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            if let food = nutritionData {
                VStack(alignment: .leading, spacing: 10) {
                    Text(food.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Calories: \(String(format: "%.0f", food.calories * Double(servings))) kcal")
                    Text("Protein: \(String(format: "%.1f", food.protein * Double(servings))) g")
                    
                    HStack {
                        Button("-") {
                            if servings > 1 { servings -= 1 }
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        
                        Text("Servings: \(servings)")
                            .font(.headline)
                            
                        Button("+") {
                            servings += 1
                        }
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                    }
                    
                    Button("Add to Daily Total") {
                        let adjustedFood = FoodItem(name: food.name, calories: food.calories * Double(servings), protein: food.protein * Double(servings), scans: 0)
                        foodsEaten.append(adjustedFood)
                        dailyCalories += adjustedFood.calories
                        dailyProtein += adjustedFood.protein
                        UserDefaultsManager.saveFoods(foodsEaten)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding()
            }
        }
        .sheet(isPresented: $isScannerPresented) {
            BarcodeScannerView(isPresented: $isScannerPresented) { scannedValue in
                fetchNutritionData(for: scannedValue)
            }
        }
    }
    
    func fetchFoodByName(_ name: String, completion: @escaping ([FoodItem]) -> Void) {
        let urlString = "https://world.openfoodfacts.net/cgi/search.pl?search_terms=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&json=true"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let products = json["products"] as? [[String: Any]] {
                    
                    let foodItems = products.compactMap { product -> FoodItem? in
                        guard let name = product["product_name"] as? String,
                              let nutriments = product["nutriments"] as? [String: Any],
                              let calories = nutriments["energy-kcal_serving"] as? Double,
                              let protein = nutriments["proteins_serving"] as? Double,
                              let scans = product["unique_scans_n"] as? Int else { return nil }

                        let relevanceScore = name.lowercased().contains(searchText.lowercased()) ? 1_000_000 : 0
                        let rankingScore = scans + relevanceScore // Combine relevance + popularity

                        return FoodItem(name: name, calories: calories, protein: protein, scans: rankingScore)
                    }
                    .sorted { $0.scans > $1.scans } // Sort using the combined ranking score
                    
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
        let urlString = "https://world.openfoodfacts.net/api/v2/product/\(barcode)?fields=product_name,nutriments"
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let product = json["product"] as? [String: Any],
                  let name = product["product_name"] as? String,
                  let nutriments = product["nutriments"] as? [String: Any],
                  let calories = nutriments["energy-kcal_serving"] as? Double,
                  let protein = nutriments["proteins_serving"] as? Double else { return }
            
            DispatchQueue.main.async {
                nutritionData = FoodItem(name: name, calories: calories, protein: protein, scans: 0)
            }
        }.resume()
    }
}

struct FoodItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let scans: Int
}

class UserDefaultsManager {
    static let key = "foodsEaten"
    
    static func saveFoods(_ foods: [FoodItem]) {
        if let encoded = try? JSONEncoder().encode(foods) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    static func loadFoods() -> [FoodItem] {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) {
            return decoded
        }
        return []
    }
}
