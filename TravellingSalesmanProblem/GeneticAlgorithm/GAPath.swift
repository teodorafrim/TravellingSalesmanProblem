//
//  GAPath.swift
//  TravellingSalesmanProblem
//
//  Created by Teodor Afrim on 29.04.18.
//  Copyright © 2018 Teodor Afrim. All rights reserved.
//

import Foundation

/**
 A path represents an individual in the genetic algorithm.
 
 */
class GAPath {
    
    var waypoints: [GAWaypoint]
    
    var distance: Double {
        return calculateDistance()
    }
    
    init(waypoints: [GAWaypoint]) {
        self.waypoints = waypoints
    }
    
    private func calculateDistance() -> Double {
        var result = 0.0
        var previousWaypoint: GAWaypoint?
        
        waypoints.forEach { (waypoint) in
            if let previous = previousWaypoint {
                result += previous.effort(to: waypoint)
            }
            previousWaypoint = waypoint
        }
        
        guard let first = waypoints.first, let last = waypoints.last else { return result }
        
        return result + first.effort(to: last)
    }
    
    func fitness(with totalEffort: Double) -> Double {
        return 1 - (distance/totalEffort)
    }
}
