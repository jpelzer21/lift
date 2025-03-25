import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CalendarView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDate: Date? = nil
    @State private var navigateToDetail = false
    
    private let calendar = Calendar.current
    private let year: Int = Calendar.current.component(.year, from: Date())
    
    // Store workout days from Firestore
    @State private var workoutDates: Set<Date> = []
    
    // Track scroll position
//    @State private var scrollViewProxy: ScrollViewProxy?
    private let currentMonth: Int = Calendar.current.component(.month, from: Date())

    private var months: [Int: [Date]] {
        var groupedMonths: [Int: [Date]] = [:]
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        
        var currentDate = startOfYear
        while currentDate <= endOfYear {
            let month = calendar.component(.month, from: currentDate)
            groupedMonths[month, default: []].append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return groupedMonths
    }

    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(1...12, id: \.self) { month in
                        if let days = months[month] {
                            VStack(alignment: .leading) {
                                Text(verbatim: "\(monthName(for: month)) \(year)")
                                    .font(.title2)
                                    .bold()
                                    .padding(.horizontal)
                                    .id(month)

                                // Days of the week header
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                                    ForEach(daysOfWeek, id: \.self) { day in
                                        Text(day)
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                
                                // Generate empty spaces for alignment
                                let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
                                let weekday = calendar.component(.weekday, from: firstDayOfMonth) - 1

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                                    ForEach(0..<weekday, id: \.self) { _ in
                                        Spacer()
                                            .frame(width: 40, height: 40)
                                    }
                                    
                                    ForEach(days, id: \.self) { date in
                                        Text("\(calendar.component(.day, from: date))")
                                            .frame(width: 40, height: 40)
                                            .background(workoutDates.contains(date) ? Color.pink.opacity(0.8) : Color.gray.opacity(0.2)) // Highlight workout days
                                            .clipShape(Circle())
                                            .onTapGesture {
                                                selectedDate = date
                                                print(date)
                                            }
                                    }
                                }
                            }
                            .padding(.bottom)
                        }
                    }
                }
                .padding()
                .onAppear {
                    print("View Appeared")
                    fetchWorkoutDates()
                    DispatchQueue.main.async {
                        proxy.scrollTo(currentMonth, anchor: .center)
                    }
                }
            }
        }
        .navigationTitle(Text(verbatim: "\(year) Calendar"))

    }


    private func fetchWorkoutDates() {
        print("FETCH WORKOUT DATES() CALLED")
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        let db = Firestore.firestore()
        let workoutsRef = db.collection("users").document(userID).collection("workouts")

        workoutsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching workouts: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("No workout data found")
                return
            }
            
            var fetchedDates: Set<Date> = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                if let timestamp = data["timestamp"] as? Timestamp {
                    let workoutDate = timestamp.dateValue() // Convert Firestore Timestamp to Date
                    let normalizedDate = calendar.startOfDay(for: workoutDate) // Normalize to start of day
                    fetchedDates.insert(normalizedDate)
                    print("Fetched workout date: \(normalizedDate)")
                } else {
                    print("No valid date found in document: \(document.documentID)")
                }
            }
            
            DispatchQueue.main.async {
                self.workoutDates = fetchedDates
                print("Workout dates updated: \(self.workoutDates)")
            }
        }
    }
    
    private func monthName(for month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        return dateFormatter.string(from: date)
    }
}
