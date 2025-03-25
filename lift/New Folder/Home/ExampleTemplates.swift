//
//  ExampleTemplates.swift
//  lift
//
//  Created by Josh Pelzer on 3/16/25.
//


//
//  ExampleTemplates.swift
//  lift
//
//  Created by Josh Pelzer on 3/15/25.
//

import Foundation

struct ExampleTemplates {
    static let templates: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "the_big_3",
            name: "The Big 3",
            exercises: [
                Exercise(name: "Bench Press", sets: [
                    ExerciseSet(number: 1, weight: 135, reps: 10),
                    ExerciseSet(number: 2, weight: 155, reps: 8),
                    ExerciseSet(number: 3, weight: 175, reps: 6)
                ]),
                Exercise(name: "Squat", sets: [
                    ExerciseSet(number: 1, weight: 50, reps: 10),
                    ExerciseSet(number: 2, weight: 55, reps: 8)
                ]),
                Exercise(name: "Deadlift", sets: [
                    ExerciseSet(number: 1, weight: 30, reps: 12),
                    ExerciseSet(number: 2, weight: 35, reps: 10)
                ])
            ]
        ),
        WorkoutTemplate(
            id: "back_and_biceps",
            name: "Back and Biceps",
            exercises: [
                Exercise(name: "Pull Ups", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
                Exercise(name: "Lat Pulldowns", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
                Exercise(name: "Seated Rows", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
                Exercise(name: "Bicep Curls", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
                Exercise(name: "Preacher Curls", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
            ]
        ),
        WorkoutTemplate(
            id: "chest_and_triceps",
            name: "Chest and Triceps",
            exercises: [
                Exercise(name: "Bench Press", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
                Exercise(name: "Incline Bench Press", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
                Exercise(name: "Tricep Extensions", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
                Exercise(name: "Overhead Tricep Extensions", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
                Exercise(name: "Chest Flys", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
                Exercise(name: "Weighted Dips", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 3, weight: 0, reps: 8)
                ]),
            ]
        ),
        WorkoutTemplate(
            id: "legs",
            name: "Legs",
            exercises: [
                Exercise(name: "Squats", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 1, weight: 0, reps: 8)
                ]),
                Exercise(name: "Leg Press", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 1, weight: 0, reps: 8)
                ]),
                Exercise(name: "Leg Extensions", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 1, weight: 0, reps: 8)
                ]),
                Exercise(name: "Hamstring Curls", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 1, weight: 0, reps: 8)
                ]),
                Exercise(name: "Calf Raises", sets: [
                    ExerciseSet(number: 1, weight: 0, reps: 8),
                    ExerciseSet(number: 2, weight: 0, reps: 8),
                    ExerciseSet(number: 1, weight: 0, reps: 8)
                ])
            ]
        )
    ]
}
