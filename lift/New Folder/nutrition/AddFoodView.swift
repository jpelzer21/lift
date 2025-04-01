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
                    NavigationLink(destination: FoodDetailView(food: food)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(food.name)
                                    .font(.headline)
                                Text("\(food.calories, specifier: "%.1f") kcal, \(food.protein, specifier: "%.1f")g protein")
                                    .font(.subheadline)
                            }
                        }
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
                        let adjustedFood = FoodItem(name: food.name,
                                                    calories: food.calories * Double(servings),
                                                    protein: food.protein * Double(servings),
                                                    fats: (food.fats ?? 0) * Double(servings),
                                                    carbs: (food.carbs ?? 0) * Double(servings),
                                                    sugars: (food.sugars ?? 0) * Double(servings),
                                                    scans: 0)
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
                              let protein = nutriments["proteins_serving"] as? Double else { return nil }
                        
                        let fats = nutriments["fat_serving"] as? Double ?? 0
                        let carbs = nutriments["carbohydrates_serving"] as? Double ?? 0
                        let sugars = nutriments["sugars_serving"] as? Double ?? 0
                        let scans = product["unique_scans_n"] as? Int ?? 0

                        return FoodItem(name: name, calories: calories, protein: protein, fats: fats, carbs: carbs, sugars: sugars, scans: scans)
                    }
                    .sorted { $0.scans > $1.scans }
                    
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
                  let protein = nutriments["proteins_serving"] as? Double,
                  let fats = nutriments["fat_serving"] as? Double,
                  let carbs = nutriments["carbohydrates_serving"] as? Double,
                  let sugars = nutriments["sugars_serving"] as? Double
            else { return }
            
            DispatchQueue.main.async {
                nutritionData = FoodItem(name: name, calories: calories, protein: protein, fats: fats, carbs: carbs, sugars: sugars, scans: 0)
            }
        }.resume()
    }
}

struct FoodItem: Identifiable, Codable {
    var id = UUID()
    let name: String
    let calories: Double
    let protein: Double
    let fats: Double?
    let carbs: Double?
    let sugars: Double?
    let scans: Int
}