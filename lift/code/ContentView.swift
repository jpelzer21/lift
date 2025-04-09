//
//  ContentView.swift
//  lift
//
//  Created by Josh Pelzer on 2/23/25.
//
import SwiftUI

struct ContentView: View {
    @State private var selectedIndex: Int = 0
//    @State private var templates: [WorkoutTemplate] = [] // Store templates
//    @State private var isTemplatesLoaded = false // Track if templates are loaded
    @StateObject private var userViewModel = UserViewModel.shared

    var body: some View {
        TabView(selection: $selectedIndex) {
            NavigationStack {
                HomePageView()
                    .navigationTitle("Home")
            }
            .tabItem {
                Text("Home")
                Image(systemName: "house.fill")
                    .renderingMode(.template)
            }
            .tag(0)
            .environmentObject(userViewModel)
            
            
            NavigationStack() {
                NutritionView()
                    .navigationTitle("Nutrition")
            }
            .tabItem {
                Text("Nutrition")
                Image(systemName: "fork.knife.circle")
            }
            .tag(1)
            .environmentObject(userViewModel)

            
            
            NavigationStack() {
                ProfileView()
                    .navigationTitle("Profile")
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
            .tag(2)
            .environmentObject(userViewModel)
            
        }
        .tint(.pink)
        .onAppear(perform: {
            let appearance = UITabBarAppearance()
            UITabBar.appearance().backgroundColor = UIColor.systemBackground
            UITabBar.appearance().unselectedItemTintColor = .systemBrown
            UITabBarItem.appearance().badgeColor = .systemPink
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.systemPink]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        })
    }
}
