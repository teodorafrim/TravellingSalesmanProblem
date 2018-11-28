//
//  Waypoint.swift
//  TravellingSalesmanProblem
//
//  Created by Teodor Afrim on 28.04.18.
//  Copyright © 2018 Teodor Afrim. All rights reserved.
//

import Foundation

/**
 
 A waypoint represents a characteristic from an individual in the genetic algorithm.
 */
struct GAWaypoint: Equatable {
    
    static func ==(lhs: GAWaypoint, rhs: GAWaypoint) -> Bool {
        return lhs.position == rhs.position
    }
    
    let position: Int
    
    func effort(to waypoint: GAWaypoint) -> Double {
        return GeneticAlgorithm.GADistancesMatrix[self.position][waypoint.position]
    }
    
}
