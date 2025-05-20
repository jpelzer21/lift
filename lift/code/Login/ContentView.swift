//
//  ContentView.swift
//  lift
//
//  Created by Josh Pelzer on 2/23/25.
//
import SwiftUI

struct ContentView: View {
    @State private var selectedIndex: Int = 1
    @StateObject private var userViewModel = UserViewModel.shared

    var body: some View {
        TabView(selection: $selectedIndex) {
            
            
            
            NavigationStack() {
                NutritionView()
                    .navigationTitle("Nutrition")
            }
            .tabItem {
                Text("Nutrition")
                Image(systemName: "fork.knife.circle")
            }
            .tag(0)
            .environmentObject(userViewModel)

            
            NavigationStack {
                HomePageView()
                    .navigationTitle("Home")
            }
            .tabItem {
                Text("Home")
                Image(systemName: "dumbbell.fill")
                    .renderingMode(.template)
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
