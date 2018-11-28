//
//  ViewController.swift
//  TravellingSalesmanProblem
//
//  Created by Teodor Afrim on 15.04.18.
//  Copyright © 2018 Teodor Afrim. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

/**
 
 A delegate-protocol used to pass map items between view controllers.
 */
protocol MapPlaceDelegate: class {
    func passMapPlace(_ mapPlace: MKMapItem, at index: Int)
}

class AddressChooserViewController: UIViewController {

    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var suggestionsTableView: UITableView!
    @IBOutlet weak var currentAddressLabel: UILabel!
    @IBOutlet weak var saveAddressButton: UIButton!
    
    @IBAction func saveAddress(_ sender: UIButton) {
        // Pass the mapPlace to the root view controller and perform a back segue.
        if let mapPlace = currentChosenMapPlace {
            mapPlaceDelegate?.passMapPlace(mapPlace, at: currentAddressIndex)
        }
        navigationController?.popViewController(animated: true)
    }
    
    weak var mapPlaceDelegate: MapPlaceDelegate?
    var currentAddressIndex : Int!
    var currentChosenMapPlace : MKMapItem! {
        didSet {
            if saveAddressButton != nil {
            enableButton(saveAddressButton)
            }
        }
    }
    
    private lazy var searchCompleter = MKLocalSearchCompleter()
    private var searchResults = [MKLocalSearchCompletion]()
    private let locationManager = CLLocationManager()
    private var tapGestureRecognizer = UITapGestureRecognizer()
    private var doubleTapGesture = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if currentAddressIndex == 0 {
            navigationController?.topViewController?.navigationItem.title = "Starting point"
        }
        else {
            navigationController?.topViewController?.navigationItem.title = "Address Nr.\(currentAddressIndex as Int)"
        }
        if currentChosenMapPlace != nil {
           updateCurrentAddress(at: currentChosenMapPlace.placemark.coordinate, with: currentChosenMapPlace.name!)
        }
        navigationController?.delegate = self as? UINavigationControllerDelegate
        configureSearchBarAndCompleter()
        configureTableView()
        configureLocationManager()
        self.hideKeyboardWhenTappedAround()
        updateLabelText()
        disableButton(saveAddressButton)
        saveAddressButton.layer.cornerRadius = 4.0
        configureGestureRecognition()
    }
    
    
    
    func getPlacemarkFromCoordinate(_ coordinate: CLLocationCoordinate2D, completionHandler: @escaping (CLPlacemark?)
        -> Void ) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(location,
                                        completionHandler: { (placemarks, error) in
                                            if error == nil {
                                                let firstLocation = placemarks?[0]
                                                completionHandler(firstLocation)
                                            }
                                            else {
                                                // An error occurred during geocoding.
                                                completionHandler(nil)
                                            }
        })
        
    }
    
    /**
 
     Switch between the table view and the map view.
 */
    
    func switchTableViewAndMapView() {
        suggestionsTableView.isHidden = !suggestionsTableView.isHidden
        mapView.isHidden = !mapView.isHidden
    }
    
    func launchSearchRequest(with completion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            if let searchResponse = response?.mapItems[0].placemark {
                self.searchBar.text = completion.title
                self.updateCurrentAddress(at: searchResponse.coordinate, with: searchResponse.name!)
            }
            
        }
    }
    
    func updateCurrentAddress(at coordinates: CLLocationCoordinate2D, with title: String) {
        showLocationOnMap(at: coordinates, with: title)
        currentChosenMapPlace = MKMapItem(placemark: MKPlacemark(coordinate: coordinates))
        currentChosenMapPlace?.name = title
        updateLabelText()
    }
    
    /**
     
     Replace the pin according to the new chosen address.
 */
    func showLocationOnMap(at coordinates: CLLocationCoordinate2D, with title: String) {
        mapView.removeAnnotations(mapView.annotations)
        let center = CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let span = MKCoordinateSpan.init(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(coordinates.latitude, coordinates.longitude)
        annotation.title = title
        mapView.addAnnotation(annotation)
    }
    
    func configureSearchBarAndCompleter() {
        searchBar.delegate = self
        searchCompleter.delegate = self
        searchBar.placeholder = "Search for a place or address"
    }
    
    func configureTableView() {
        suggestionsTableView.dataSource = self
        suggestionsTableView.delegate = self
        suggestionsTableView.tableFooterView = UIView()
        suggestionsTableView.isHidden = true
    }
    
    func configureLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestLocation()
        }
    }
    
    func configureGestureRecognition() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(sender:)))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.numberOfTapsRequired = 1
        mapView.addGestureRecognizer(tapGestureRecognizer)
        doubleTapGesture.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTapGesture)
    }
    
    func updateLabelText() {
        let centeredParagraphStyle = NSMutableParagraphStyle()
        centeredParagraphStyle.alignment = .center
        let leadingParagraphStyle = NSMutableParagraphStyle()
        leadingParagraphStyle.alignment = .left
        let bold = UIFont.boldSystemFont(ofSize: AddressChooserViewController.defaultSearchResultTitleSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle : centeredParagraphStyle,
            .foregroundColor : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
            .font : bold
        ]
        
        let attributedString = NSMutableAttributedString(string: "Current address:\n\n \(currentChosenMapPlace?.name ?? "")", attributes: attributes)
        let normal = UIFont.systemFont(ofSize: AddressChooserViewController.defaultSearchResultTitleSize)
        attributedString.addAttribute(NSAttributedString.Key.font, value: normal, range: NSMakeRange(0, 15))
        currentAddressLabel.numberOfLines = 4
        currentAddressLabel.lineBreakMode = .byWordWrapping
        currentAddressLabel.attributedText = attributedString
    }
}

extension AddressChooserViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if suggestionsTableView.isHidden {
            switchTableViewAndMapView()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !searchResults.isEmpty {
            let autoCompletion = searchResults[0]
            launchSearchRequest(with: autoCompletion)
        }
        view.endEditing(true)
        if !suggestionsTableView.isHidden {
            switchTableViewAndMapView()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if suggestionsTableView.isHidden {
            switchTableViewAndMapView()
        }
        if !searchText.isEmpty {
            searchCompleter.queryFragment = searchText
        }
    }
}

extension AddressChooserViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier", for: indexPath)
        let searchResult = searchResults[indexPath.row]
        cell.textLabel?.attributedText = NSAttributedString.highlightedText(searchResult.title, ranges: searchResult.titleHighlightRanges, fontSize: AddressChooserViewController.defaultSearchResultTitleSize)
        cell.detailTextLabel?.attributedText = NSAttributedString.highlightedText(searchResult.subtitle, ranges: searchResult.subtitleHighlightRanges, fontSize: AddressChooserViewController.defaultSearchResultSubtitleSize)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let completion = searchResults[indexPath.row]
        launchSearchRequest(with: completion)
        view.endEditing(true)
        switchTableViewAndMapView()
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

extension AddressChooserViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        suggestionsTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension NSAttributedString {
    static func highlightedText(_ text: String, ranges: [NSValue], fontSize: CGFloat) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)
        var font = UIFont.preferredFont(forTextStyle: .body).withSize(fontSize)
        font = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
        attributedText.addAttribute(.font, value: font, range: NSMakeRange(0, text.count))
        let bold = UIFont.boldSystemFont(ofSize: fontSize)
        for value in ranges {
            attributedText.addAttribute(.font, value: bold, range: value.rangeValue)
        }
        return attributedText
    }
}

extension AddressChooserViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if currentChosenMapPlace == nil {
            let userLocationCoordinate = locations[0].coordinate
            getPlacemarkFromCoordinate(userLocationCoordinate, completionHandler: { (placemark) in
                if let userLocationPlacemark = placemark {
                    self.updateCurrentAddress(at: userLocationCoordinate, with: "\(userLocationPlacemark.name ?? "") ")
                }
            })
            
        }
    }
    

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error \(error)")
    }
    
}

extension AddressChooserViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Don't recognize a single tap until a double-tap fails.
        if gestureRecognizer == self.tapGestureRecognizer &&
            otherGestureRecognizer == self.doubleTapGesture {
            return true
        }
        return false
    }
    
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        // Place a pin where the user tapped on the map.
        switch sender.state {
        case .ended:
            searchBar.text = ""
            let tapLocation = sender.location(in: mapView)
            let coordinate = mapView.convert(tapLocation, toCoordinateFrom: mapView)
            getPlacemarkFromCoordinate(coordinate, completionHandler: { (placemark) in
                if let tapLocationPlacemark = placemark {
                    self.updateCurrentAddress(at: coordinate, with: "\(tapLocationPlacemark.name ?? "") ")
                }
            })
            
        default: break
        }
    }
}

extension AddressChooserViewController {
    static let defaultSearchResultTitleSize: CGFloat = 17.0
    static let defaultSearchResultSubtitleSize: CGFloat = 12.0
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
