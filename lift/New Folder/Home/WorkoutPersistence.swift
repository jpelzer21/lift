import FirebaseFirestore
import Combine

class WorkoutPersistence: ObservableObject {
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // These maintain your existing binding structure
    @Published var workoutTitle: String = ""
    @Published var exercises: [Exercise] = []
    
    init() {
        loadOngoingWorkout()
    }
    
    func saveWorkout() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "title": workoutTitle,
            "exercises": exercises.map { exercise in
                return [
                    "name": exercise.name,
                    "sets": exercise.sets.map { set in
                        return [
                            "number": set.number,
                            "weight": set.weight,
                            "reps": set.reps,
                            "isCompleted": set.isCompleted
                        ]
                    }
                ]
            },
            "lastSaved": Timestamp(date: Date())
        ]
        
        db.collection("users")
          .document(userID)
          .collection("ongoingWorkouts")
          .document("current")
          .setData(data)
    }
    
    func loadOngoingWorkout() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
          .document(userID)
          .collection("ongoingWorkouts")
          .document("current")
          .getDocument { snapshot, _ in
              guard let data = snapshot?.data(),
                    let title = data["title"] as? String,
                    let exercisesData = data["exercises"] as? [[String: Any]] else { return }
              
              self.workoutTitle = title
              self.exercises = exercisesData.compactMap { exerciseData in
                  guard let name = exerciseData["name"] as? String,
                        let setsData = exerciseData["sets"] as? [[String: Any]] else { return nil }
                  
                  let sets = setsData.compactMap { setData in
                      ExerciseSet(
                          number: setData["number"] as? Int ?? 0,
                          weight: setData["weight"] as? Double ?? 0,
                          reps: setData["reps"] as? Int ?? 0,
                          isCompleted: setData["isCompleted"] as? Bool ?? false
                      )
                  }
                  
                  return Exercise(name: name, sets: sets)
              }
          }
    }
    
    func clearWorkout() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("users")
          .document(userID)
          .collection("ongoingWorkouts")
          .document("current")
          .delete()
    }
}