//
//  ViewController.swift
//  Building.iOS.Apps
//
//  Created by Kamiya Takahiro on 2020/05/01.
//  Copyright © 2020 Kamiya Takahiro. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UIViewController {
 
    @IBOutlet weak var mapView: AGSMapView!
    
    let locationOverlay = AGSGraphicsOverlay()
    
    let locatorTask = AGSLocatorTask(url: URL(string:"https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer")!)
    
    fileprivate func makeMap() -> AGSMap {
        let map = AGSMap(basemapType: .navigationVector, latitude: 35.610318, longitude: 139.750434, levelOfDetail: 15)
        
        let featureTable = AGSServiceFeatureTable(url: URL(string:"https://services5.arcgis.com/HzGpeRqGvs5TMkVr/arcgis/rest/services/kankojohoShinagawa100kei/FeatureServer/0")!)
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        map.operationalLayers.add(featureLayer)
        
        return map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.map = makeMap()
        
        mapView.graphicsOverlays.add(locationOverlay)
        
        mapView.locationDisplay.start { (error) in
            if let error = error {
                print("Error starting the GPS: \(error.localizedDescription)")
                return
            }
        }
        
        mapView.touchDelegate = self
    }
}

extension ViewController:AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 20, returnPopupsOnly: false) { (results, error) in
            if let error = error {
                print("Error identifying: \(error.localizedDescription)")
                return
            }
            
            if let result = results?.first,
                let feature = result.geoElements.first as? AGSFeature {
                self.mapView.callout.title = feature.attributes["name"] as? String
                self.mapView.callout.detail = feature.attributes["description_ja"] as? String
                self.mapView.callout.show(for: feature, tapLocation: mapPoint, animated: true)
            } else {
                self.mapView.callout.dismiss()
            }
        }
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        
        locationOverlay.graphics.removeAllObjects()
        
        locatorTask.geocode(withSearchText: searchText) { [weak self] (results, error) in
            if let error = error {
                print("Error geocoding: \(error.localizedDescription)")
                return
            }
            
            guard let result = results?.first else { return }
            
            if let extent = result.extent {
                self?.mapView.setViewpoint(AGSViewpoint(targetExtent: extent))
            }
            
            if let location = result.displayLocation {
                let graphic = AGSGraphic(geometry: location, symbol: AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 12), attributes: nil)
                self?.locationOverlay.graphics.add(graphic)
            }
            
            searchBar.resignFirstResponder()
        }
    }
    
}

