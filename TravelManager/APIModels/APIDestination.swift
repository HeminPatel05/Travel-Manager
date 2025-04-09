//
//  APIDestination.swift
//  TravelManager
//
//  Created by Hemin Patel on 3/31/25.
//


struct APIDestination: Codable {
    let id: String?
    let city: String
    let country: String
    let destinationImageURL: String
    
    enum CodingKeys: String, CodingKey {
        case id, city, country
        case destinationImageURL = "destinationImageURL"
    }
}