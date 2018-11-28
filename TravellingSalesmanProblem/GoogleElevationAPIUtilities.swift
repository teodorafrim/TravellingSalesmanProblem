//
//  GoogleElevationAPIUtilities.swift
//  TravellingSalesmanProblem
//
//  Created by Teodor Afrim on 28.04.18.
//  Copyright © 2018 Teodor Afrim. All rights reserved.
//

import Foundation
import CoreLocation

struct Elevation: Codable {
    let results: [Result]
    let status: String
}

struct Result: Codable {
    let elevation: Double
    let location: Location
    let resolution: Double
}

struct Location: Codable, Equatable {
    let lat, lng: Double
}

/**
 
 Get the altitudes for two locations and return them through a completion handler, using the Google Elevation API.
 */

func getAltitude(_ source: CLLocationCoordinate2D,_ destination: CLLocationCoordinate2D ,completionHandler: @escaping ((Double),(Double)) -> Void) {
    let sourceLatitude = source.latitude
    let sourceLongitude = source.longitude
    let destinationLatitude = destination.latitude
    let destinationLongitude = destination.longitude
    let string = "https://maps.googleapis.com/maps/api/elevation/json?locations=\(sourceLatitude),\(sourceLongitude)|\(destinationLatitude),\(destinationLongitude)&key=AIzaSyBUfNhK9rMErARvXg5vph-mVVWei8dM8V0"
    guard let urlString = string.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else { return }
    guard let url = URL(string: urlString) else { return }
    URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else { return }
        do {
            let decoder = JSONDecoder()
            let elevationData = try decoder.decode(Elevation.self, from: data)
            if !elevationData.results.isEmpty {
                completionHandler(elevationData.results[0].elevation, elevationData.results[1].elevation)
            }
            else {
                completionHandler(-1,-1)
            }
        } catch let error {
            print("Error", error)
        }
        }.resume()
    
}
