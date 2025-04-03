import SwiftUI
struct FoodDetailPopup: View {
    
    @State var updatefood: Bool
    @Binding var foodItem: FoodItem
    @Binding var isPresented: Bool

    var onAddFood: (FoodItem) -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                if let imageUrl = foodItem.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(10)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                VStack {
                    Text(foodItem.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text("Serving Size: \(foodItem.servingSize)")
                        .font(.caption)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Calories:")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(String(format: "%.0f", (foodItem.calories ?? 0) * Double(foodItem.servings))) cal")
                    }
                    HStack {
                        Text("Protein:")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(String(format: "%.0f", (foodItem.protein ?? 0) * Double(foodItem.servings))) cal")
                    }
                    HStack {
                        Text("Fats:")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(String(format: "%.0f", (foodItem.fats ?? 0) * Double(foodItem.servings))) cal")
                    }
                    HStack {
                        Text("Carbs:")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(String(format: "%.0f", (foodItem.carbs ?? 0) * Double(foodItem.servings))) cal")
                    }
                    HStack {
                        Text("Sugars:")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(String(format: "%.0f", (foodItem.sugars ?? 0) * Double(foodItem.servings))) cal")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 60)
                HStack {
                    Button(action: {
                        if foodItem.servings > 1 {
                            foodItem.servings -= 1
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.75))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    Text("Servings: \(foodItem.servings)")
                        .font(.headline)
                    Button(action: {
                        foodItem.servings += 1
                        print(foodItem.servings)
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.75))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                HStack(spacing: 20) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    if updatefood {
                        Button("Save") {
                            onAddFood(foodItem)
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Button("Add to Daily Total") {
                            onAddFood(foodItem)
                            isPresented = false
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    
                }
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.height * 0.75)
            .background(Color(.systemGray6))
            .cornerRadius(25)
            .shadow(radius: 10)
        }
        .transition(.move(edge: .bottom))
//        .animation(.spring(), value: isPresented)
    }
    
    
    
}


