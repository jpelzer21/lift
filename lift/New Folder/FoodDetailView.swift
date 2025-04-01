struct FoodDetailView: View {
    let food: FoodItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(food.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text("Calories: \(String(format: "%.0f", food.calories)) kcal")
            Text("Protein: \(String(format: "%.1f", food.protein)) g")
            Text("Fats: \(String(format: "%.1f", food.fats ?? 0)) g")
            Text("Carbs: \(String(format: "%.1f", food.carbs ?? 0)) g")
            Text("Sugars: \(String(format: "%.1f", food.sugars ?? 0)) g")

            Spacer()
            
            Button("Add to Daily Total") {
                // Handle adding the food
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .navigationTitle("Food Details")
    }
}