//
//  HomeViewModel.swift
//  BongoCat
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var title: String = "Home"

    func increment(_ count: inout Int) {
        count += 1
    }
}


