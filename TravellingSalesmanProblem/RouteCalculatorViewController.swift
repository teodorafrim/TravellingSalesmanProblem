//
//  RouteCalculatorViewController.swift
//  TravellingSalesmanProblem
//
//  Created by Teodor Afrim on 27.04.18.
//  Copyright © 2018 Teodor Afrim. All rights reserved.
//

import UIKit
import MapKit


class RouteCalculatorViewController: UIViewController, MKMapViewDelegate, ErrorDelegate {
    // Catch the error from RouteCalculator and show it
    func passError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: "An error has occured: \(error)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {[unowned self] action in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true)
    }
    /**
     
     An array with all places that need to be visited.
 */
    var mapItems = [MKMapItem]()
    
    var tableViewNames = [String]()
    var tableViewRoutes = [MKRoute]()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        // Place annotations on map
        for index in 0..<mapItems.count {
            let mapItem = mapItems[index]
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2DMake(mapItem.placemark.coordinate.latitude, mapItem.placemark.coordinate.longitude)
            annotation.title = mapItem.name
            self.mapView.addAnnotation(annotation)
        }
        
        configureTableView()
        activityIndicator.startAnimating()
        
        // Calculate the path and show the results
        let engine = RouteCalculator(with: mapItems)
        engine.errorDelegate = self
        engine.calculateBestPath(completionHandler: {
            (routes, names) in
            
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            for index in 0..<names.count {
                self.tableViewNames.append(names[index])
            }
           
            for index in 0..<routes.count {
                let route = routes[index]
                self.tableViewRoutes.append(route)
                self.mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            }
            
            self.centerMap()
            self.tableView.isHidden = false
            self.tableView.reloadData()
            
            
        })

    }
    
    func configureTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.rowHeight = 150
    tableView.layoutMargins = UIEdgeInsets.zero
    tableView.separatorInset = UIEdgeInsets.zero
    tableView.separatorColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    tableView.tableFooterView = UIView()
    tableView.isHidden = true
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 4.0
        return renderer
    }
    
    /**

     Center the mapView according to the places coordinates.
     */
    func centerMap() {
        var averageLatitude = 0.0
        var averageLongitude = 0.0
        var minLatitude = 90.0
        var maxLatitude = -90.0
        var minLongitude = 180.0
        var maxLongitude = -180.0
        for index in 0..<mapItems.count {
            let mapItem = mapItems[index]
            let latitude =  mapItem.placemark.coordinate.latitude
            let longitude =  mapItem.placemark.coordinate.longitude
            
            averageLatitude += latitude
            averageLongitude += longitude
            
            if latitude < minLatitude {
                minLatitude = latitude
            }
            if latitude > maxLatitude {
                maxLatitude = latitude
            }
            
            if longitude < minLongitude {
                minLongitude = longitude
            }
            if longitude > maxLongitude {
                maxLongitude = longitude
            }
            
        }
        
        averageLatitude /= Double(mapItems.count)
        averageLongitude /= Double(mapItems.count)
        
        let center = CLLocationCoordinate2DMake(averageLatitude, averageLongitude)
        let latitudeDelta = (maxLatitude - minLatitude)*1.5
        let longitudeDelta = (maxLongitude - minLongitude)*1.5
        let span = MKCoordinateSpan.init(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
    }

}

extension RouteCalculatorViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewRoutes.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "routeCellIdentifier", for: indexPath) as! RouteCell
        cell.layoutMargins = UIEdgeInsets.zero
        cell.selectionStyle = .none
        cell.sourceLabel.text = "From: " + tableViewNames[indexPath.row]
        cell.destinationLabel.text = "To: " + tableViewNames[indexPath.row+1]
        
        cell.distanceLabel.text = "Distance: "
        let distanceInKm = tableViewRoutes[indexPath.row].distance/1000
        cell.distanceLabel.text?.append(String(format: "%.2f", distanceInKm))
        cell.distanceLabel.text?.append(" km")
        
        cell.timeLabel.text = "Time: "
        let timeInSeconds = tableViewRoutes[indexPath.row].expectedTravelTime
        if timeInSeconds < 60 {
            cell.timeLabel.text?.append("\(timeInSeconds)seconds ")
        }
        else if timeInSeconds < 3600 {
            let minutes = Int(timeInSeconds/60)
            let remainingSeconds = Int(timeInSeconds) - minutes*60
            cell.timeLabel.text?.append("\(minutes) minutes and \(remainingSeconds) seconds ")
        }
        else {
            let hours = Int(timeInSeconds/3600)
            let remainingSeconds = Int(timeInSeconds) - hours*3600
            cell.timeLabel.text?.append("\(hours) hours ")
            if remainingSeconds < 60 {
                cell.timeLabel.text?.append("\(remainingSeconds) seconds ")
            }
            else {
                let minutes = Int(remainingSeconds/60)
                let remainingSeconds = Int(remainingSeconds) - minutes*60
                cell.timeLabel.text?.append("\(minutes) minutes and \(remainingSeconds) seconds ")
            }        }
        return cell
    }
}
