//
//  AddressesViewController.swift
//  TravellingSalesmanProblem
//
//  Created by Teodor Afrim on 13.04.18.
//  Copyright © 2018 Teodor Afrim. All rights reserved.
//

import UIKit
import MapKit

class RootViewController: UIViewController, MapPlaceDelegate {
    func passMapPlace(_ mapPlace: MKMapItem, at index: Int) {
        savedPlaces[index] = mapPlace
    }
    
    @IBOutlet weak var placesTableView: UITableView!
    @IBOutlet weak var startingPointTextField: UITextField!
    @IBOutlet weak var addressCounterLabel: UILabel!
    @IBOutlet weak var calculateRouteButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    @IBAction func addAddress(_ sender: UIButton) {
        savedPlaces.append(MKMapItem())
        savedPlaces.last?.name = "Unknown Location"
        tableViewData.append("")
    }
    
    @IBAction func calculateRoute(_ sender: UIButton) {
    }
    
    
    /**
     
     The array passed to the routeCalculator, containing all saved places as MKMapItems.
     
     Will be passed to the routeCalculator.
     
     - note:  The starting point is stored at the position 0.
 
     */
    var savedPlaces = [MKMapItem]() {
        // Enable/disable the buttons depending on the number of places the user has given.
        didSet {
            if addButton.isEnabled && tableViewData.count == 5 {
                disableButton(addButton)
            }
            if !addButton.isEnabled && tableViewData.count < 5 {
                enableButton(addButton)
            }
            if calculateRouteButton.isEnabled && tableViewData.count < 1 {
                disableButton(calculateRouteButton)
            }
            if !calculateRouteButton.isEnabled
                && tableViewData.count > 0
                && savedPlaces[0].name != "" {
                enableButton(calculateRouteButton)
            }
        }
    }

    /**
     
     The data array for the table view, containing only the names of the saved places.
     */
    var tableViewData = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reservePositionForStartingPoint()
        configureTableView()
        calculateRouteButton.layer.cornerRadius = 4.0
        startingPointTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if savedPlaces.last?.name == "Unknown Location" {
            savedPlaces.removeLast()
            tableViewData.removeLast()
        }
        updateLabelText()
        updateTableViewData()
    }
    

    /**
     
     Update the table view data according to the savedPlaces array.
 */
    
    func updateTableViewData() {
        if savedPlaces[0].name != "" {
           startingPointTextField.text = savedPlaces[0].name
            
        }
        
        if !tableViewData.isEmpty {
            for index in 1...(savedPlaces.count-1) {
                if let name = savedPlaces[index].name {
                    tableViewData[index-1] = name
                }
            }
        }
        placesTableView.reloadData()
    }
    
    func reservePositionForStartingPoint() {
        if savedPlaces.isEmpty {
            savedPlaces.append(MKMapItem())
            savedPlaces[0].name = ""
        }
    }
    
    func configureTableView() {
        placesTableView.dataSource = self
        placesTableView.delegate = self
        placesTableView.layoutMargins = UIEdgeInsets.zero
        placesTableView.separatorInset = UIEdgeInsets.zero
        placesTableView.separatorColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        placesTableView.tableFooterView = UIView()
    }
    
    func updateLabelText() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle : paragraphStyle,
            .foregroundColor : #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
        ]
        let attributedString = NSAttributedString(string: "Number of addresses: \(tableViewData.count)", attributes: attributes)
        addressCounterLabel.attributedText = attributedString
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
                //segue from starting point
            case "startingPointSegue":
                if let seguedToVC = segue.destination as? AddressChooserViewController {
                    seguedToVC.currentAddressIndex = 0
                    let placeSavedInCell = savedPlaces[0]
                    if savedPlaces[0].name != "" {
                    seguedToVC.currentChosenMapPlace = placeSavedInCell
                    }
                    seguedToVC.mapPlaceDelegate = self
                }
                //segue from button
            case "addButtonSegue":
                if let seguedToVC = segue.destination as? AddressChooserViewController {
                    seguedToVC.currentAddressIndex = tableViewData.count
                    seguedToVC.mapPlaceDelegate = self
                }
                //segue from cell
            case "cellSegue":
                if let cell = sender as? AddressTableViewCell,
                    let indexPath = placesTableView.indexPath(for: cell),
                    let seguedToVC = segue.destination as? AddressChooserViewController {
                    seguedToVC.currentAddressIndex = indexPath.row + 1
                    let placeSavedInCell = savedPlaces[indexPath.row+1]
                    seguedToVC.currentChosenMapPlace = placeSavedInCell
                    seguedToVC.mapPlaceDelegate = self
                    
                }
            case "calculateRouteSegue":
                if let seguedToVC = segue.destination as? RouteCalculatorViewController {
                    seguedToVC.mapItems = savedPlaces
                }
                
            default: break
            }
        }
    }
}
extension RootViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier", for: indexPath) as! AddressTableViewCell
        cell.layoutMargins = UIEdgeInsets.zero
        cell.addressLabel.text = tableViewData[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableViewData.remove(at: indexPath.row)
            savedPlaces.remove(at: indexPath.row+1)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateLabelText()
        }
        else if editingStyle == .insert {
            
        }
    }
}

extension RootViewController: UITextFieldDelegate {
    // Don't take any input, instead perform the segue, when the user clicks on the text field.
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        performSegue(withIdentifier: "startingPointSegue", sender: textField)
        return false
    }
}

extension UIViewController {
    
    func disableButton(_ button: UIButton) {
        button.isEnabled = false
        button.backgroundColor? = UIColor.gray
        button.alpha = 0.2
    }
    
    func enableButton(_ button: UIButton) {
        button.isEnabled = true
        button.backgroundColor? = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
        button.alpha = 1
    }
}
