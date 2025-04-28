import SwiftUI
import Charts
import FirebaseFirestore
import FirebaseAuth

struct GraphView: View {
//    @State private var viewModel: ExerciseViewModel
    @State private var exerciseSets: [ExerciseSet] = []
    @State private var selectedMetric: Metric = .volume
    @State private var isLoading = true
    @State private var showInfo = false
    @State private var showEditExerciseView = false
    @State private var showFirstSets: Bool = true
    
    @State private var barType: String = ""
    let exerciseName: String // name passed through
    
    @State private var listener: ListenerRegistration?
    
    enum Metric: String, CaseIterable {
            case weight = "Weight"
            case reps = "Reps"
            case volume = "Volume"
        }
    
    private var maxYAxisValue: Double {
        let maxValue = exerciseSets.map { metricValue(for: $0) }.max() ?? 0
        return maxValue * 1.25
    }

    private var minYAxisValue: Double {
        let minValue = exerciseSets.map { metricValue(for: $0) }.min() ?? 0
        return max(0, minValue-(minValue*0.25))
    }
    
    // Calculate workout statistics
    private var heaviestWeight: Double {
        exerciseSets.map { $0.weight }.max() ?? 0
    }
    
    private var bestSet: (weight: Double, reps: Int)? {
        exerciseSets.max(by: { ($0.weight * Double($0.reps)) < ($1.weight * Double($1.reps)) })
            .map { ($0.weight, $0.reps) }
    }
    
    private var oneRepMax: Double {
        guard let bestSet = bestSet else { return 0 }
        return bestSet.weight * (1 + Double(bestSet.reps) / 30)
    }
    
    private var bestSession: Double {
        let sessionVolumes = Dictionary(grouping: exerciseSets, by: { Calendar.current.startOfDay(for: $0.date) })
            .mapValues { sets in sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) } }
        return sessionVolumes.values.max() ?? 0
    }
    
    // find max number of sets
    private var maxSetsInSession: Int {
        let sessionSets = Dictionary(grouping: exerciseSets, by: { Calendar.current.startOfDay(for: $0.date) })
            .mapValues { $0.count }
        return sessionSets.values.max() ?? 0
    }

    var body: some View {
        let firstSets = exerciseSets.filter { $0.number == 1 }
//        let lastSets = exerciseSets.filter { set in
//            let maxSetNumber = exerciseSets.max(by: { $0.number < $1.number })?.number ?? 0
//            return set.number == maxSetNumber
//        }
//        ScrollView{
            VStack (spacing: 5) {
                Spacer()
                ZStack {
                    HStack {
                        Spacer()
                        Text(exerciseName.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.largeTitle)
                            .bold()
                            .lineLimit(nil)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    HStack {
//                        Button(action: {
//                            showEditExerciseView = true
//                        }) {
//                            Image(systemName: "pencil")
//                                .font(.title2)
//                                .foregroundColor(.blue)
//                        }
//                        .padding(.horizontal, 20)
                        Spacer()
                        Button(action: {
                            showInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(Metric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if isLoading {
                    ProgressView("Loading exercise data...")
                        .padding()
                } else {
                    if exerciseSets.isEmpty {
                        VStack {
                            Spacer()
                            Text("No recorded sets for this exercise.")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        if firstSets.count > 1 {
                            Chart {
                                ForEach(exerciseSets) { set in
                                    PointMark(
                                        x: .value("Date", set.date),
                                        y: .value(selectedMetric.rawValue,
                                                  selectedMetric == .weight ? set.weight :
                                                    selectedMetric == .reps ? Double(set.reps) :
                                                    set.weight * Double(set.reps))
                                    )
                                    .symbol(.circle)
                                    .opacity(1/Double(set.number))
                                    .foregroundStyle(Color.pink)
                                }
                                
                                ForEach(Array(firstSets.enumerated()), id: \.element.id) { index, set in
                                    LineMark(
                                        x: .value("Date", set.date),
                                        y: .value(selectedMetric.rawValue, metricValue(for: set))
                                    )
                                    .foregroundStyle(Color.pink)
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                                }
                            }
                            .chartXAxis {
                                AxisMarks(position: .bottom) {
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .trailing)
                            }
                            .chartYScale(domain: minYAxisValue...maxYAxisValue)
                            .frame(height: 250)
                            .padding()
                        } else {
                            VStack {
                                Spacer()
                                Text("Not enough data to display a trend.")
                                    .foregroundColor(.gray)
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Heaviest Weight:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(heaviestWeight > 0 ? "\(Int(heaviestWeight))lbs" : "N/A")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("1 Rep Max:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(oneRepMax > 0 ? "\(Int(oneRepMax))lbs" : "N/A")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Best Set:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(bestSet != nil ? "\(Int(bestSet!.weight))lbs x \(bestSet!.reps)" : "N/A")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Best Session:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text(bestSession > 0 ? "\(Int(bestSession))lbs" : "N/A")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showEditExerciseView) {
//                Text("TODO: add editExercise View")
                EditExerciseView(exerciseName: exerciseName)
            }
            .sheet(isPresented: $showInfo) {
                GraphInfoView()
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                fetchSets(name: exerciseName)
            }
            .onDisappear {
                listener?.remove()
            }
            .padding(.bottom, 20)
//        }
    }
    
    private func metricValue(for set: ExerciseSet) -> Double {
        switch selectedMetric {
        case .weight: return set.weight
        case .reps: return Double(set.reps)
        case .volume: return set.weight * Double(set.reps)
        }
    }
    
    private func fetchSets(name: String) {
        print("FETCH SETS() CALLED for \(name)")
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User not logged in")
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let exerciseRef = db.collection("users").document(userID)
            .collection("exercises").document(name.lowercased().replacingOccurrences(of: " ", with: "_"))
        
        // First get the barType (one-time read)
        exerciseRef.getDocument { docSnapshot, error in
            if let error = error {
                print("Error getting document: \(error)")
                return
            }
            guard let document = docSnapshot, document.exists else {
                print("Document does not exist")
                return
            }
            if let barType = document.data()?["barType"] as? String {
                self.barType = barType
                if barType == "BodyWeight" {
                    self.selectedMetric = .reps
                }
            }
        }
        
        // Calculate date thresholds
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        
        // Remove any existing listener to avoid duplicates
        self.listener?.remove()
        
        // Add snapshot listener for sets collection
        self.listener = exerciseRef.collection("sets")
            .order(by: "date")
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("Error listening to sets: \(error.localizedDescription)")
                        self.exerciseSets = []
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No sets found for \(name)")
                        self.exerciseSets = []
                        return
                    }
                    
                    // Process all documents
                    let allSets = documents.compactMap { doc -> ExerciseSet? in
                        let data = doc.data()
                        let set = ExerciseSet(
                            number: data["setNum"] as? Int ?? 1,
                            weight: data["weight"] as? Double ?? 0,
                            reps: data["reps"] as? Int ?? 0,
                            date: (data["date"] as? Timestamp)?.dateValue() ?? Date()
                        )
                        return set
                    }
                    
                    // Filter sets:
                    // 1. Keep all sets from last 7 days
                    // 2. For older dates, keep only first sets (setNum == 1)
                    self.exerciseSets = allSets.filter { set in
                        let isRecent = set.date > sevenDaysAgo
                        let isFirstSet = set.number == 1
                        return isRecent || isFirstSet
                    }
                    
                    print("Loaded \(self.exerciseSets.count) filtered sets (showing all recent sets + first sets for older dates).")
                }
            }
    }
}


struct GraphInfoView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 16) {
            Text("Graph Explanation")
                .font(.title)
                .bold()
            
            Text("**Dots** represent individual sets, with opacity decreasing for later sets in the same session.\n\n**Line** represents the trend of first sets in each session.\n\n **Y-Axis** depends on the selected metric: Weight, Reps, or Volume (Weight × Reps).")
                .font(.body)
                .multilineTextAlignment(.leading)
                .padding()
            
            Spacer()
            
            Button("Got it!") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
