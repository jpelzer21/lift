//
//  MeasurementsView.swift
//  lift
//
//  Created by Josh Pelzer on 3/25/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Charts

struct MeasurementsView: View {
    @State private var weight: String = ""
    @State private var height: Int? = nil
    @State private var waist: Int? = nil
    @State private var chest: Int? = nil
    @State private var measurements: [MeasurementEntry] = []
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    // Stores last weight entry for the day
    @State private var lastStoredWeight: Double?
    @State private var lastStoredDate: Date?
    
    @State private var showOverwriteAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // **Weight Progress Graph**
                    VStack {
                        Text("Weight Progress")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        
                        if !measurements.isEmpty {
                            let minWeight = measurements.map { $0.weight }.min() ?? 0
                            let maxWeight = measurements.map { $0.weight }.max() ?? 100
                            let padding = (maxWeight - minWeight) * 2  // 50% padding for better spacing
                            let lowerBound = minWeight - padding
                            let upperBound = maxWeight + padding
//                            let sortedMeasurements = measurements.sorted { $0.date < $1.date }

                            Chart(measurements) { entry in
                                PointMark(
                                    x: .value("Date", entry.date, unit: .day),
                                    y: .value("Weight", entry.weight)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.pink)
                                LineMark(
                                    x: .value("Date", entry.date, unit: .day),
                                    y: .value("Weight", entry.weight)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(.pink)
                            }
                            .chartXAxis {
                                
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .automatic)
                            }
                            .chartYScale(domain: lowerBound...upperBound) // Dynamically set Y-axis range
                            .frame(height: 200)
                            .padding(.horizontal)
                        } else {
                            Text("No data yet.")
                                .frame(height: 200)
                                .padding(.horizontal)
                        }
                        
                        // Weight Input Field
                        WeightInput(title: "Weight:", value: $weight)
                            .padding(.top, 10)
                        
                        // Save Weight Button
                        Button(action: saveWeight) {
                            Text("Save Weight")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pink)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        .disabled(isUpdating)
                        
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                    }
                    .padding()
                    .cornerRadius(15)
                    .padding(.horizontal, 20)
                    
                    Text("Body Measurements:")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    VStack(spacing: 5) {
                        MeasurementPicker(title: "Height (inches)", value: $height, range: 48...84)
                        MeasurementPicker(title: "Waist (inches)", value: $waist, range: 20...60)
                        MeasurementPicker(title: "Chest (inches)", value: $chest, range: 30...60)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal, 20)
                    
                    
                    Button(action: saveMeasurements) {
                        Text(isUpdating ? "Saving..." : "Save Measurements")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .disabled(isUpdating)
                }
                .padding()
                .navigationTitle("Measurements")
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onAppear {
                fetchMeasurements()
            }
            .alert(isPresented: $showOverwriteAlert) {
                Alert(
                    title: Text("Overwrite Today's Weight?"),
                    message: Text("You already logged a weight (\(String(format: "%.1f", lastStoredWeight ?? 0.0)) lbs) for today. Do you want to overwrite it?"),
                    primaryButton: .destructive(Text("Overwrite")) {
                        if let weightValue = Double(weight) {
                            saveNewWeight(weightValue: weightValue)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // **Fetch user measurements from Firestore**
    private func fetchMeasurements() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(userID)

        userDoc.getDocument { document, error in
            if let error = error {
                errorMessage = "Error loading measurements: \(error.localizedDescription)"
                return
            }

            if let data = document?.data(),
               let measurementsArray = data["measurements"] as? [[String: Any]] {
                DispatchQueue.main.async {
                    for entry in measurementsArray {
                        if let type = entry["type"] as? String, let value = entry["value"] as? Int {
                            switch type {
                            case "height": self.height = value
                            case "waist": self.waist = value
                            case "chest": self.chest = value
                            default: break
                            }
                        }
                    }
                }
            }
        }

        // Fetch weight history from the "measurements" subcollection
        userDoc.collection("measurements").order(by: "date", descending: true).getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Error loading weight data: \(error.localizedDescription)"
                return
            }

            DispatchQueue.main.async {
                self.measurements = snapshot?.documents.compactMap { doc in
                    guard let weight = doc.data()["weight"] as? Double,
                          let timestamp = doc.data()["date"] as? Timestamp else { return nil }
                    return MeasurementEntry(weight: weight, date: timestamp.dateValue())
                } ?? []

                // Store last recorded weight for quick validation
                if let latest = self.measurements.first {
                    self.lastStoredWeight = latest.weight
                    self.lastStoredDate = latest.date
                }
            }
        }
    }
    
    // **Save body measurements to Firestore**
    private func saveMeasurements() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(userID)

        // Create an array of measurement entries
        let measurementsArray: [[String: Any]] = [
            ["type": "height", "value": height ?? NSNull()],
            ["type": "waist", "value": waist ?? NSNull()],
            ["type": "chest", "value": chest ?? NSNull()]
        ]

        isUpdating = true

        userDoc.setData(["measurements": measurementsArray], merge: true) { error in
            DispatchQueue.main.async {
                isUpdating = false
                if let error = error {
                    errorMessage = "Error saving measurements: \(error.localizedDescription)"
                }
            }
        }
    }

    // **Save weight to Firestore**
    private func saveWeight() {
        guard let userID = Auth.auth().currentUser?.uid,
              let weightValue = Double(weight) else {
            errorMessage = "Invalid weight input"
            return
        }

        let today = Calendar.current.startOfDay(for: Date())
        let db = Firestore.firestore()
        let measurementCollection = db.collection("users").document(userID).collection("measurements")

        // Query Firestore for today's weight entry
        measurementCollection
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: today))
            .whereField("date", isLessThan: Timestamp(date: Calendar.current.date(byAdding: .day, value: 1, to: today)!))
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Error checking today's entry: \(error.localizedDescription)"
                    return
                }

                if let document = snapshot?.documents.first {
                    // If an entry exists for today, prompt for overwrite
                    lastStoredWeight = document.data()["weight"] as? Double
                    lastStoredDate = today
                    showOverwriteAlert = true
                } else {
                    // No entry exists, save new weight directly
                    saveNewWeight(weightValue: weightValue)
                }
            }
    }

    private func saveNewWeight(weightValue: Double) {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not found"
            return
        }

        let today = Calendar.current.startOfDay(for: Date())
        let db = Firestore.firestore()
        let measurementCollection = db.collection("users").document(userID).collection("measurements")

        let newEntry = [
            "weight": weightValue,
            "date": Timestamp(date: today)
        ] as [String : Any]

        isUpdating = true

        measurementCollection.addDocument(data: newEntry) { error in
            DispatchQueue.main.async {
                isUpdating = false
                if let error = error {
                    errorMessage = "Error saving weight: \(error.localizedDescription)"
                } else {
                    lastStoredWeight = weightValue
                    lastStoredDate = today
                    measurements.insert(MeasurementEntry(weight: weightValue, date: today), at: 0)
                }
            }
        }
    }
}

// **Model for Measurement Entry**
struct MeasurementEntry: Identifiable {
    let id = UUID()
    let weight: Double
    let date: Date
}

// **Custom Input for Weight**
struct WeightInput: View {
    var title: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            TextField("Today's \(title.lowercased())", text: $value)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

// **Custom Picker for Height, Waist, Chest**
struct MeasurementPicker: View {
    var title: String
    @Binding var value: Int?
    var range: ClosedRange<Int>
    @State private var isPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            Button(action: { isPresented.toggle() }) {
                HStack {
                    Text(value != nil ? "\(value!)" : "Not Set") // Show "Not Set" if nil
                        .foregroundColor(value != nil ? .primary : .gray)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
            }
            .sheet(isPresented: $isPresented) {
                VStack {
                    Text("Select \(title)")
                        .font(.headline)
                        .padding()
                    
                    Picker(title, selection: Binding(
                        get: { value ?? range.lowerBound },
                        set: { value = $0 }
                    )) {
                        ForEach(range, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 200)
                    .clipped()

                    Button("Done") {
                        isPresented = false
                    }
                    .padding()
                }
            }
        }
        .padding(.horizontal)
    }
}


struct MeasurementsView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementsView()
    }
}
