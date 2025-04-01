import SwiftUI

struct NutritionView: View {
    @State private var foodsEaten: [FoodItem] = UserDefaultsManager.loadFoods()
    @State private var showAddFoodView: Bool = false
    @State private var isPopupPresented: Bool = false
    @State private var selectedFood: FoodItem? = nil
    @State private var servings: Int = 1
    
    // Nutrition Goals (could be user-specific in the future)
    @State private var calorieGoal: Double = 2000
    @State private var proteinGoal: Double = 200
    @State private var fatsGoal: Double = 50
    @State private var sugarsGoal: Double = 36
    @State private var carbsGoal: Double = 200
    
    // Daily Intake Values
    @State private var dailyCalories: Double = 0
    @State private var dailyProtein: Double = 0
    @State private var dailyFats: Double = 0
    @State private var dailySugars: Double = 0
    @State private var dailyCarbs: Double = 0
    
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        ZStack {
            VStack {
                TabView(selection: $selectedIndex) {
                    Page3(dailyCalories: $dailyCalories, dailyProtein: $dailyProtein, dailyCarbs: $dailyCarbs, dailyFats: $dailyFats, calorieGoal: calorieGoal, proteinGoal: proteinGoal, fatsGoal: fatsGoal, carbsGoal: carbsGoal)
                    
                    Page1(dailyCalories: $dailyCalories, dailyProtein: $dailyProtein, dailyCarbs: $dailyCarbs, dailyFats: $dailyFats, dailySugars: $dailySugars, calorieGoal: calorieGoal, proteinGoal: proteinGoal, fatsGoal: fatsGoal, carbsGoal: carbsGoal, sugarsGoal: sugarsGoal, showingTop: false)
                    
                    Page1(dailyCalories: $dailyCalories, dailyProtein: $dailyProtein, dailyCarbs: $dailyCarbs, dailyFats: $dailyFats, dailySugars: $dailySugars, calorieGoal: calorieGoal, proteinGoal: proteinGoal, fatsGoal: fatsGoal, carbsGoal: carbsGoal, sugarsGoal: sugarsGoal, showingTop: true)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: selectedIndex, { oldValue, newValue in
                    print("selected tab = \(newValue)")
                })
                
                Button("+ Add Food") {
                    showAddFoodView = true
                }
                .padding()
                .background(Color.pink)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                if foodsEaten.isEmpty {
                    Text("Add a food by tapping the button above").font(.headline).padding()
                } else {
                    List {
                        ForEach(foodsEaten.reversed(), id: \.id) { food in
                            HStack {
                                Text("\(food.servings) x ")
                                Text(food.name)
                                Spacer()
                                Text("\(String(format: "%.1f", (food.calories ?? 0.0) * Double(food.servings))) cal")
                            }
                            .onTapGesture {
                                selectedFood = food
                                print(food.servings)
//                                servings = 1
                                isPopupPresented = true
                            }
                        }
                        .onDelete(perform: deleteFood)
                    }
                    
                }
            }
            .sheet(isPresented: $showAddFoodView) {
                AddFoodView(onFoodAdded: addFoodToDailyTotal)
            }
            .onAppear {
                foodsEaten = UserDefaultsManager.loadFoods()
                recalculateNutrition()
            }
            
            if isPopupPresented, let index = foodsEaten.firstIndex(where: { $0.id == selectedFood?.id }) {
                FoodDetailPopup(
                    updatefood: true, // or false depending on your use case
                    foodItem: $foodsEaten[index], // Pass a binding to the actual item
                    isPresented: $isPopupPresented,
                    onAddFood: { updatedFood in
                        // Update the food item in your array
                        if let index = foodsEaten.firstIndex(where: { $0.id == updatedFood.id }) {
                            foodsEaten[index] = updatedFood
                            UserDefaultsManager.saveFoods(foodsEaten)
                            recalculateNutrition()
                        }
                    }
                )
                .zIndex(1)
                .transition(.opacity)
            }
        }
    }
    
    private func deleteFood(at offsets: IndexSet) {
        // Convert reversed indices to original indices
        let reversedOffsets = IndexSet(offsets.map { foodsEaten.count - 1 - $0 })
        foodsEaten.remove(atOffsets: reversedOffsets)
        UserDefaultsManager.saveFoods(foodsEaten)
        recalculateNutrition()
    }
    
    private func addFoodToDailyTotal(_ food: FoodItem) {
        foodsEaten.append(food)
        UserDefaultsManager.saveFoods(foodsEaten)
        recalculateNutrition()
    }
    
    private func recalculateNutrition() {
        dailyCalories = foodsEaten.reduce(0) { $0 + ($1.calories ?? 0)*(Double($1.servings)) }
        dailyProtein = foodsEaten.reduce(0) { $0 + ($1.protein ?? 0)*(Double($1.servings)) }
        dailyFats = foodsEaten.reduce(0) { $0 + ($1.fats ?? 0)*(Double($1.servings)) }
        dailySugars = foodsEaten.reduce(0) { $0 + ($1.sugars ?? 0)*(Double($1.servings)) }
        dailyCarbs = foodsEaten.reduce(0) { $0 + ($1.carbs ?? 0)*(Double($1.servings)) }
    }
}




struct Page1: View {
    @Binding var dailyCalories: Double
    @Binding var dailyProtein: Double
    @Binding var dailyCarbs: Double
    @Binding var dailyFats: Double
    @Binding var dailySugars: Double
    
    @State var calorieGoal: Double
    @State var proteinGoal: Double
    @State var fatsGoal: Double
    @State var carbsGoal: Double
    @State var sugarsGoal: Double
    
    @State var showingTop: Bool = true
    
    var body: some View {
        VStack {
            ZStack {
                ProgressCircleView(progress: dailyCalories / calorieGoal, amount: dailyCalories, label: "Calories", size: 175, showingInfo: true)
                    .frame(width: 175, height: 175)
                    .padding()
                VStack {
                    if showingTop {
                        HStack {
                            ProgressCircleView(progress: dailySugars / sugarsGoal, amount: dailySugars, label: "Sugars", size: 75, showingInfo: true)
                                .padding()
                            Spacer()
                            ProgressCircleView(progress: dailyFats / fatsGoal, amount: dailyFats, label: "Fats", size: 75, showingInfo: true)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        .padding()
                    }
                    Spacer()
                    HStack {
                        ProgressCircleView(progress: dailyProtein / proteinGoal, amount: dailyProtein, label: "Protein", size: 75, showingInfo: true)
                            .padding()
                        Spacer()
                        ProgressCircleView(progress: dailyCarbs / carbsGoal, amount: dailyCarbs, label: "Carbs", size: 75, showingInfo: true)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .padding()
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: 300)
            Spacer()
        }
    }
}



struct Page3: View {
    @Binding var dailyCalories: Double
    @Binding var dailyProtein: Double
    @Binding var dailyCarbs: Double
    @Binding var dailyFats: Double
    
    @State var calorieGoal: Double
    @State var proteinGoal: Double
    @State var fatsGoal: Double
    @State var carbsGoal: Double
    
    var calorieProgress: Double {
        min(dailyCalories / calorieGoal, 1.0)
    }
    
    var proteinProgress: Double {
        min(dailyProtein / proteinGoal, 1.0)
    }
    
    var fatsProgress: Double {
        min(dailyFats / fatsGoal, 1.0)
    }
    
    var carbsProgress: Double {
        min(dailyCarbs / carbsGoal, 1.0)
    }
    
    var caloriesConsumed: Double {
        dailyCalories
    }
    
    var caloriesRemaining: Double {
        max(calorieGoal - dailyCalories, 0)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // **Calories Section**
            HStack {
                VStack {
                    Text("\(Int(caloriesRemaining))")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Remaining")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                ProgressCircleView(progress: calorieProgress, amount: dailyCalories, label: "Calories", size: 100, showingInfo: false)
                
                Spacer()
                
                VStack {
                    Text("\(Int(caloriesConsumed))")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Consumed")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            
            // **Other Macros Section**
            HStack(spacing: 15) {
                ProgressLineView(value: $dailyProtein, total: $proteinGoal, label: "Protein")
                ProgressLineView(value: $dailyCarbs, total: $carbsGoal, label: "Carbs")
                ProgressLineView(value: $dailyFats, total: $fatsGoal, label: "Fats")
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ProgressLineView: View {
    @Binding var value: Double
    @Binding var total: Double
    var label: String
    
    var progress: Double {
        guard total > 0 else { return 0 } // Prevent division by zero
        return min(max(value / total, 0), 1) // Ensure progress is between 0 and 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.capitalized)
                .font(.caption)
                .bold()
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .frame(height: 10)
                    .foregroundColor(Color.gray.opacity(0.3))
                
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: max(progress * 100, 0), height: 10) // Match parent width
                    .foregroundStyle(value < 1 ? .green : .pink)
//                    .foregroundStyle(LinearGradient(colors: [.red, .yellow, .green], startPoint: .leading, endPoint: .trailing))
            }
            .frame(width: 100)

            Text("\(Int(value))/\(Int(total))g")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}


struct ProgressCircleView: View {
    var progress: Double
    var amount: Double
    var label: String
    var size: CGFloat
    var showingInfo: Bool
    
    var lineWidth: CGFloat {
        size * 0.1
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            Circle()
                .trim(from: 0.0, to: min(max(progress, 0), 1))
                .stroke(AngularGradient(gradient: Gradient(colors: [.red, .yellow, . green]), center: .center), lineWidth: lineWidth)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            VStack {
                if showingInfo {
                    Text("\(Int(amount))")
                        .font(size > 100 ? .largeTitle : .subheadline)
                        .fontWeight(.bold)
                }
                Text(label)
                    .font(size > 100 ? .headline : .caption)
            }
        }
        .frame(width: size, height: size)
    }
}



class UserDefaultsManager {
    static let foodKey = "foodsEaten"
    static let dateKey = "lastSavedDate"
    
    static func saveFoods(_ foods: [FoodItem]) {
        if let encoded = try? JSONEncoder().encode(foods) {
            UserDefaults.standard.set(encoded, forKey: foodKey)
            saveCurrentDate() // Save the date whenever food is updated
        }
    }

    static func loadFoods() -> [FoodItem] {
        checkForNewDay() // Check if it's a new day before loading foods

        if let data = UserDefaults.standard.data(forKey: foodKey),
           let decoded = try? JSONDecoder().decode([FoodItem].self, from: data) {
            return decoded
        }
        return []
    }

    static func saveCurrentDate() {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: today)
        UserDefaults.standard.set(dateString, forKey: dateKey)
    }

    static func checkForNewDay() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let todayString = formatter.string(from: Date())
        let lastSavedDate = UserDefaults.standard.string(forKey: dateKey) ?? ""

        if todayString != lastSavedDate {
            resetFoods() // Reset the food list if it's a new day
        }
    }

    static func resetFoods() {
        UserDefaults.standard.removeObject(forKey: foodKey)
        saveCurrentDate() // Update date to today so reset happens only once per day
    }
}






struct FoodItem: Identifiable, Codable {
    var id = UUID()
    let servingSize: String
    let name: String
    let calories: Double?
    let protein: Double?
    let fats: Double?
    let carbs: Double?
    let sugars: Double?
    let imageUrl: String?
    var servings: Int = 1
}
