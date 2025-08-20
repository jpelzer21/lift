
//  NotificationsView.swift
//  lift
//
//  Created by Josh Pelzer on 4/2/25.


import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @State private var pushNotificationsEnabled = true
    @State private var emailNotificationsEnabled = false
    @State private var workoutRemindersEnabled = true
    @State private var reminderTime = Date()
    @State private var showingPermissionAlert = false
    @State private var notificationPermissionDenied = false
    @State private var notifications: [AppNotification] = mockNotifications
    
    var body: some View {
        Form {
            Section(header: Text("Notification Preferences")) {
                Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                    .onChange(of: pushNotificationsEnabled) { oldValue, newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                    }
                
                Toggle("Email Notifications", isOn: $emailNotificationsEnabled)
                
                Toggle("Workout Reminders", isOn: $workoutRemindersEnabled)
                    .onChange(of: workoutRemindersEnabled) { oldValue, newValue in
                        if newValue {
                            requestNotificationPermission()
                            scheduleDailyReminder()
                        } else {
                            cancelDailyReminder()
                        }
                    }
                
                if workoutRemindersEnabled {
                    DatePicker("Reminder Time",
                               selection: $reminderTime,
                               displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { oldValue, newValue in
                        if workoutRemindersEnabled {
                            scheduleDailyReminder()
                        }
                    }
                }
            }
            
            Section(header: Text("Recent Notifications")) {
                if notifications.isEmpty {
                    Text("No notifications yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(notifications) { notification in
                        NotificationRow(notification: notification)
                    }
                }
            }
            
            Section {
                Button("Clear All Notifications") {
                    notifications.removeAll()
                    // In a real app, you would also clear from your data store
                }
                .foregroundColor(.red)
                .disabled(notifications.isEmpty)
            }
        }
        .navigationTitle("Notifications")
        .alert("Notifications Disabled",
               isPresented: $notificationPermissionDenied) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please enable notifications in Settings to use this feature")
        }
        .onAppear {
            checkNotificationSettings()
            loadNotifications()
        }
    }
    
    // MARK: - Notification Functions
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    notificationPermissionDenied = true
                    pushNotificationsEnabled = false
                    workoutRemindersEnabled = false
                }
            }
        }
    }
    
    private func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                pushNotificationsEnabled = settings.authorizationStatus == .authorized
                if settings.authorizationStatus == .denied {
                    notificationPermissionDenied = true
                    workoutRemindersEnabled = false
                }
            }
        }
    }
    
    private func scheduleDailyReminder() {
        guard workoutRemindersEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Workout Reminder"
        content.body = "Time to go workout!"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "dailyWorkoutReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyWorkoutReminder"])
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyWorkoutReminder"])
    }
    
    private func loadNotifications() {
        // In a real app, you would load from your data store
        // This is just mock data for demonstration
        notifications = mockNotifications
    }
}

// MARK: - Notification Model and Views

struct AppNotification: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let message: String
    let time: String
    let date: Date
}

struct NotificationRow: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: notification.icon)
                .foregroundColor(notification.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(relativeTimeString(from: notification.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Mock Data

let mockNotifications = [
    AppNotification(icon: "flame.fill", color: .orange,
                   title: "Workout Completed",
                   message: "You finished 'Leg Day' workout",
                   time: "2 hours ago",
                   date: Date().addingTimeInterval(-7200)),
    AppNotification(icon: "trophy.fill", color: .yellow,
                   title: "New Achievement",
                   message: "You set a new PR for Bench Press",
                   time: "1 day ago",
                   date: Date().addingTimeInterval(-86400)),
    AppNotification(icon: "calendar", color: .blue,
                   title: "Reminder",
                   message: "You have a workout scheduled for today",
                   time: "Yesterday",
                   date: Date().addingTimeInterval(-172800))
]
