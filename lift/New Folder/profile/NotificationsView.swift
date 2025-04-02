import SwiftUI

struct NotificationsView: View {
    @State private var pushNotificationsEnabled = true
    @State private var emailNotificationsEnabled = false
    @State private var workoutRemindersEnabled = true
    @State private var reminderTime = Date()
    
    var body: some View {
        Form {
            Section(header: Text("Notification Preferences")) {
                Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                
                Toggle("Email Notifications", isOn: $emailNotificationsEnabled)
                
                Toggle("Workout Reminders", isOn: $workoutRemindersEnabled)
                    .onChange(of: workoutRemindersEnabled) { enabled in
                        if enabled {
                            // Schedule reminder notification
                        } else {
                            // Cancel reminder notification
                        }
                    }
                
                if workoutRemindersEnabled {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section(header: Text("Recent Notifications")) {
                NotificationRow(icon: "flame.fill", color: .orange, title: "Workout Completed", message: "You finished 'Leg Day' workout", time: "2 hours ago")
                
                NotificationRow(icon: "trophy.fill", color: .yellow, title: "New Achievement", message: "You set a new PR for Bench Press", time: "1 day ago")
                
                NotificationRow(icon: "calendar", color: .blue, title: "Reminder", message: "You have a workout scheduled for today", time: "Yesterday")
            }
            
            Section {
                Button("Clear All Notifications") {
                    // Clear notifications action
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct NotificationRow: View {
    let icon: String
    let color: Color
    let title: String
    let message: String
    let time: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}