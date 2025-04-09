//
//  TripAPIModel.swift
//  TravelManager
//
//  Created by Hemin Patel on 3/31/25.
//


struct TripAPIModel: Codable {
    let id: String
    let title: String
    let startDate: Int
    let endDate: Int
    let destinationId: String
}
