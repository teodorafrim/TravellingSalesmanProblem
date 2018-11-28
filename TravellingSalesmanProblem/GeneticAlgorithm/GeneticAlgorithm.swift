//
//  GeneticAlgorithm.swift
//  TravellingSalesmanProblem
//
//  Created by Teodor Afrim on 28.04.18.
//  Algorithm inspired from https://github.com/dagostini/DAPathfinder.
//  Copyright © 2018 Teodor Afrim. All rights reserved.
//

import Foundation
import MapKit


/**
 The genetic algorithm takes an array of waypoints and a matrix with the distances needed to go from each waypoint to every other one and returns a path, which contains the order in which these waypoints(places) need to be visited, so that the distance is minimum.
 
 Every individual is represented by a path. The algorithm generates at the beginning random paths and then it takes only the "fit" ones (in our case, it means with the effort required to complete the path as small as possible) and combines them, creating a new, better generation.
 
 */
class GeneticAlgorithm {
    
    static var GADistancesMatrix = [[Double]]()
    
    let populationSize = 750
    let mutationProbability = 0.1
    
    private var population = [GAPath]()
    let waypoints: [GAWaypoint]
    
    var onNewGeneration: ((GAPath, Int) -> ())?
    
    
    
    init(for waypoints: [GAWaypoint], with distancesMatrix: [[Double]]) {
        self.waypoints = waypoints
        GeneticAlgorithm.GADistancesMatrix = distancesMatrix
        self.population = self.randomPopulation(from: self.waypoints)
    }
    
    private func randomPopulation(from waypoints: [GAWaypoint]) -> [GAPath] {
        var result = [GAPath]()
        for _ in 0..<populationSize {
            let randomisedWaypoints = waypoints.shuffle()
            result.append(GAPath(waypoints: randomisedWaypoints))
        }
        return result
    }
    
    private var evolving = false
    private var generation = 1
    func startEvolution() {
        evolving = true
        DispatchQueue.global().async {
            while self.evolving {
                
                let currentTotalEffort = self.population.reduce(0.0, { $0 + $1.distance })
                let sortByFitnessDESC: (GAPath, GAPath) -> Bool =
                { $0.fitness(with: currentTotalEffort) > $1.fitness(with: currentTotalEffort)}
                let currentGeneration = self.population.sorted(by: sortByFitnessDESC)
                
                var nextGeneration = [GAPath]()
                
                for _ in 0..<self.populationSize {
                    guard
                        let parentOne = self.getParent(from: currentGeneration, with: currentTotalEffort),
                        let parentTwo = self.getParent(from: currentGeneration, with: currentTotalEffort)
                    else { continue }
                    
                    let child = self.produceOffspring(parentOne, parentTwo)
                    let finalChild = self.mutate(child)
                    
                    nextGeneration.append(finalChild)
                }
                
                self.population = nextGeneration
                
                if let bestPath = self.population.sorted(by: sortByFitnessDESC).first {
                    self.onNewGeneration?(bestPath, self.generation)
                }
                self.generation += 1
                
                if self.generation > GeneticAlgorithm.numberOfGenerationsLimit {
                    self.stopEvolution()
                }
            }
        }
    }
    
    public func stopEvolution() {
        evolving = false
    }
    
    private func getParent(from generation: [GAPath], with totalDistance: Double) -> GAPath? {
        let fitness = drand48()
        var currentFitness = 0.0
        var result: GAPath?
        generation.forEach { (path) in
            if currentFitness <= fitness {
                currentFitness += path.fitness(with: totalDistance)
                result = path
            }
        }
        return result
    }
    
    private func produceOffspring(_ firstParent: GAPath, _ secondParent: GAPath) -> GAPath {
        let sliceIndex = Int(arc4random_uniform(UInt32(firstParent.waypoints.count)))
        var childWaypoints = [GAWaypoint]()
        
        for index in 0..<sliceIndex {
            childWaypoints.append(firstParent.waypoints[index])
        }
        
        var index = sliceIndex
        while childWaypoints.count < secondParent.waypoints.count {
            let waypointToAdd = secondParent.waypoints[index]
            if !childWaypoints.contains(waypointToAdd) {
                childWaypoints.append(waypointToAdd)
            }
            index = (index + 1) % secondParent.waypoints.count
        }
        return GAPath(waypoints: childWaypoints)
    }
    
    private func mutate(_ child: GAPath) -> GAPath {
        if self.mutationProbability >= drand48() {
            let firstIndex = Int(arc4random_uniform(UInt32(child.waypoints.count)))
            let secondIndex = Int(arc4random_uniform(UInt32(child.waypoints.count)))
            var mutatedWaypoints = child.waypoints
            mutatedWaypoints.swapAt(firstIndex, secondIndex)
            return GAPath(waypoints: mutatedWaypoints)
        }
        return child
    }
    
    
    
}

extension Array {
    public func shuffle() -> [Element] {
        return sorted(by: { (_, _) -> Bool in
            return arc4random() < arc4random()
        })
    }
}

extension GeneticAlgorithm {
    static let numberOfGenerationsLimit = 3
}
