//
//  Cat.swift
//  BongoCat
//

import Foundation

struct Cat: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var favoriteInstrument: String?

    init(id: UUID = UUID(), name: String, favoriteInstrument: String? = nil) {
        self.id = id
        self.name = name
        self.favoriteInstrument = favoriteInstrument
    }
}


