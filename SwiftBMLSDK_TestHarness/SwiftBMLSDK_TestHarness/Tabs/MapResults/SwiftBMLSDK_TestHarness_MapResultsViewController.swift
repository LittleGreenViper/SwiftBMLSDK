/*
 © Copyright 2024, Little Green Viper Software Development LLC
 LICENSE:
 
 MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import MapKit
import RVS_Generic_Swift_Toolbox
import RVS_UIKit_Toolbox
import SwiftBMLSDK

/* ###################################################################################################################################### */
// MARK: - MKCoordinateRegion Equatable Extension -
/* ###################################################################################################################################### */
/**
 Allows comparison of two regions.
 */
extension MKCoordinateRegion: Equatable {
    /* ################################################################## */
    /**
     This allows comparing two regions for equality.
     - parameter lhs: The left-hand side region
     - parameter rhs: The right-hand side region
     - returns: true, if the two regions are equal.
     */
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center.longitude == rhs.center.longitude
            && lhs.center.latitude == rhs.center.latitude
            && lhs.span.longitudeDelta == rhs.span.longitudeDelta
            && lhs.span.latitudeDelta == rhs.span.latitudeDelta
    }
    
    /* ################################################################## */
    /**
     Returns the Northwest corner to Southeast corner size, as absolute meters.
     */
    public var diagonalSizeInMeters: CLLocationDistance {
        let point1 = CLLocation(latitude: center.latitude - (span.latitudeDelta * 0.5), longitude: center.longitude - (span.longitudeDelta * 0.5))
        let point2 = CLLocation(latitude: center.latitude + (span.latitudeDelta * 0.5), longitude: center.longitude + (span.longitudeDelta * 0.5))
        return CLLocationDistance(abs(point1.distance(from: point2)) / 2)
    }

    /* ################################################################## */
    /**
     This defines the function that we use to "normalize" coordinates that might have negative numbers.
     */
    private typealias _Transform = (CLLocationCoordinate2D) -> (CLLocationCoordinate2D)
    
    /* ################################################################## */
    /**
     This is used to "normalize" longitudes that might be negative.
     
     We want our coordinates to all be positive.
     
     This remaps negative longitudes to be over 180.
     
     - parameter c: The coordinate to normalize.
     - returns: The normalized coordinate.
     */
    private static func _transform(c inCoord: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard 0 >= inCoord.longitude else { return inCoord }
        
        return CLLocationCoordinate2D(latitude: inCoord.latitude, longitude: 360 + inCoord.longitude)
    }
    
    /* ################################################################## */
    /**
     This is used to "invert" longitudes that might be over 180.
     
     We revert longitudes over 180, back to their original negative values.
     
     - parameter c: The coordinate to normalize.
     - returns: The normalized coordinate.
     */
    private static func _inverseTransform(c inCoord: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard 180 <= inCoord.longitude else { return inCoord }
        
        return CLLocationCoordinate2D(latitude: inCoord.latitude, longitude: -360 + inCoord.longitude)
    }
    
    /* ################################################################## */
    /**
     This is the basic workhorse function for the extension.
     
     - parameters:
     - for: The array of corrdinates to be used to generate the region
     - transform: The function to "normalize" all longitudes into the positive number set.
     - inverseTransform: The function to invert the normalization.
     - returns: A new coordinate region, enclosing all the given coordinates.
     */
    private static func _region(for inCoordinateArray: [CLLocationCoordinate2D], transform inTransform: _Transform, inverseTransform inInverseTransform: _Transform) -> MKCoordinateRegion? {
        // We must have two or more.
        guard 1 < inCoordinateArray.count else {
            if 1 == inCoordinateArray.count {   // If just one, we center a 1Km-square region around it.
                return MKCoordinateRegion(center: inCoordinateArray[0], latitudinalMeters: 1000, longitudinalMeters: 1000)
            } else {
                return nil
            }
        }
        
        let transformed = inCoordinateArray.map(inTransform)
        
        // find the span
        guard let minLat = transformed.min(by: { $0.latitude < $1.latitude })?.latitude,
              let maxLat = transformed.max(by: { $0.latitude < $1.latitude })?.latitude,
              let minLon = transformed.min(by: { $0.longitude < $1.longitude })?.longitude,
              let maxLon = transformed.max(by: { $0.longitude < $1.longitude })?.longitude
        else { return nil }
        
        let span = MKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLon - minLon)
        
        // find the center of the span. We invert the region, so we get the correct center.
        let center = inInverseTransform(CLLocationCoordinate2D(latitude: (maxLat - span.latitudeDelta / 2), longitude: maxLon - span.longitudeDelta / 2))
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    /* ################################################################## */
    /**
     This initializes a region to encompass all of the given coordinates.
     
     - parameter coordinates: This is an array of long/lat coordinates.
     */
    public init?(coordinates inCoordinateArray: [CLLocationCoordinate2D]) {
        // first create a region centered around the Prime Meridian (longitude 0). We don't transform.
        let primeRegion = MKCoordinateRegion._region(for: inCoordinateArray, transform: { $0 }, inverseTransform: { $0 })
        // next create a region centered around the International Date Line (longitude 180). We transform.
        let transformedRegion = MKCoordinateRegion._region(for: inCoordinateArray, transform: MKCoordinateRegion._transform, inverseTransform: MKCoordinateRegion._inverseTransform)
        // We might now have two regions, that stretch across two parts of the globe.
        // If we have two regions, then return the region that has the smallest longitude delta
        if let a = primeRegion,
           let b = transformedRegion,
           let min = [a, b].min(by: { $0.span.longitudeDelta < $1.span.longitudeDelta }) {
            self = min
        } else if let a = primeRegion { // Otherwise, if we only have one region, we return that.
            self = a
        } else if let b = transformedRegion {
            self = b
        } else {
            return nil
        }
    }
    
    /* ################################################################## */
    /**
     Adapted from here: https://stackoverflow.com/a/35321619/879365
     
     This simply returns the coordinate region as a MKMapRect
     */
    var asRect: MKMapRect {
        let topLeft = CLLocationCoordinate2D(latitude: center.latitude + (span.latitudeDelta / 2), longitude: center.longitude - (span.longitudeDelta / 2))
        let bottomRight = CLLocationCoordinate2D(latitude: center.latitude - (span.latitudeDelta / 2), longitude: center.longitude + (span.longitudeDelta / 2))

        let a = MKMapPoint(topLeft)
        let b = MKMapPoint(bottomRight)
        
        return MKMapRect(origin: MKMapPoint(x: min(a.x, b.x), y: min(a.y, b.y)), size: MKMapSize(width: abs(a.x - b.x), height: abs(a.y - b.y)))
    }
}

/* ###################################################################################################################################### */
// MARK: - Map Results Main Tab View Controller -
/* ###################################################################################################################################### */
/**
 This manages the main tab controller for the search results.
 */
class SwiftBMLSDK_TestHarness_MapResultsViewController: SwiftBMLSDK_TestHarness_TabBaseViewController {
    /* ################################################################## */
    /**
     The ID for the segue to display a single meeting
     */
    private static let _showMeetingSegueID = "show-meeting"
    
    /* ################################################################## */
    /**
     This is the maximum region size (corner-to-corner) we allow. It is how we clamp the zoom.
     */
    private static let _maximumRegionSizeInMeters: CLLocationDistance = 250000
    
    /* ################################################################## */
    /**
     This is a flag that is set while the region is being explicitly set (as opposed to being dragged or zoomed).
     */
    private var _ignoreRegionChange: Bool = false

    /* ################################################################## */
    /**
     The main map view
     */
    @IBOutlet weak var mapView: MKMapView?
    
    /* ################################################################## */
    /**
     True, once the first load is done.
     */
    var firstLoadDone: Bool = false
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapResultsViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /* ################################################################## */
    /**
     Called just before the view is displayed.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewDidAppear(_ inIsAnimated: Bool) {
        super.viewDidAppear(inIsAnimated)
        mapView?.delegate = self
        _ignoreRegionChange = true
        print("1");
        mapView?.region = MKCoordinateRegion()
        _ignoreRegionChange = false
        firstLoadDone = false
    }
    
    /* ################################################################## */
    /**
     Called before we switch to the meeting inspector.
     
     - parameter for: The segue we are executing.
     - parameter sender: The meeting instance.
     */
    override func prepare(for inSegue: UIStoryboardSegue, sender inMeeting: Any?) {
        guard let destination = inSegue.destination as? SwiftBMLSDK_TestHarness_MeetingViewController,
              let meetingInstance = inMeeting as? MeetingInstance
        else { return }
        
        destination.meeting = meetingInstance
    }
}

/* ###################################################################################################################################### */
// MARK: Callbacks
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapResultsViewController {
    /* ################################################################## */
    /**
     Called to show a meeting details page.
     
     - parameter inMeeting: The meeting instance.
     */
    func selectMeeting(_ inMeeting: MeetingInstance) {
        performSegue(withIdentifier: Self._showMeetingSegueID, sender: inMeeting)
    }
    
    /* ################################################################## */
    /**
     This is called when one of the annotations is tapped.
     
     - parameter users: The array of users, associated with the annotation.
     - parameter view: The annotation marker view (anchor for the popover).
     */
    func annotationHit(meetings inMeetings: [MeetingInstance], view inView: UIView) {
        guard let view = inView as? SwiftBMLSDK_MapMarker else { return }
        makeAMarkerPopover(view)
    }
    
    /* ################################################################## */
    /**
     Creates an instance of a map marker popover controller (blank) for presentation.
     */
    func makeAMarkerPopover(_ inMarker: SwiftBMLSDK_MapMarker) {
        if let annotation = inMarker.annotation as? SwiftBMLSDK_MapAnnotation,
           let popover = storyboard?.instantiateViewController(withIdentifier: SwiftMLSDK_Map_AnnotationPopover_ViewController.storyboardID) as? SwiftMLSDK_Map_AnnotationPopover_ViewController {
            popover.meetings = annotation.meetings.sorted { a, b in a.name.lowercased() < b.name.lowercased() }
            popover.myController = self
            popover.modalPresentationStyle = .popover
            popover.popoverPresentationController?.delegate = self
            popover.popoverPresentationController?.sourceView = inMarker
            present(popover, animated: true)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapResultsViewController {
    /* ################################################################## */
    /**
     This just clears the original markers.
     */
    func clearAnnotations() {
        guard let annotations = mapView?.annotations,
              !annotations.isEmpty
        else { return }
        
        mapView?.removeAnnotations(annotations)
    }

    /* ################################################################## */
    /**
     This creates all the annotations (which become markers).
     */
    func createAnnotations() {
        clearAnnotations()
        
        guard let searchResults = prefs.searchResults?.inPersonMeetings,
              !searchResults.isEmpty
        else { return }
        
        mapView?.delegate = self
        mapView?.addAnnotations(createMeetingAnnotations(searchResults))
    }
    
    /* ################################################################## */
    /**
     This creates annotations for the meeting search results.
     
     - returns: An array of annotations (may be empty).
     */
    func createMeetingAnnotations(_ inMeetings: [MeetingInstance]) -> [SwiftBMLSDK_MapAnnotation] {
        clusterAnnotations(inMeetings.compactMap {
            if let location = $0.coords {
                return SwiftBMLSDK_MapAnnotation(coordinate: location, meetings: [$0], myController: self)
            }
            
            return nil
        })
    }
    
     /* ################################################################## */
     /**
      This creates clusters (multi) annotations, where markers would be close together.
      
      - parameter inAnnotations: The annotations to test.
      - returns: A new set of annotations, including any clusters.
      */
     func clusterAnnotations(_ inAnnotations: [SwiftBMLSDK_MapAnnotation]) -> [SwiftBMLSDK_MapAnnotation] {
         guard let mapRect = mapView?.visibleMapRect,
               let mapBounds = mapView?.bounds,
               let centerLat = mapView?.centerCoordinate.latitude
         else { return [] }
       
         let thresholdDistanceInMeters = (SwiftBMLSDK_MapMarker.sMarkerSizeInDisplayUnits / 2) * ((MKMetersPerMapPointAtLatitude(centerLat) * mapRect.size.width) / mapBounds.size.width)
         
         guard 0 < thresholdDistanceInMeters else { return [] }
         
         return inAnnotations.reduce([SwiftBMLSDK_MapAnnotation]()) { current, next in
             var ret = current
             var append = true
             
             let nextLocation = CLLocation(latitude: next.coordinate.latitude, longitude: next.coordinate.longitude)
             
             var count = -1
             
             for annotation in ret where thresholdDistanceInMeters >= CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude).distance(from: nextLocation) {
                 annotation.meetings.append(contentsOf: next.meetings)
                 count += 1
                 append = false
                 break
             }
             
             if append {
                 ret.append(next)
             }
             
             return ret
         }
     }
    
    /* ################################################################## */
    /**
     This sets the map to a region enclosing all the results, and creates the annotations.
     */
    func setMapToResults() {
        firstLoadDone = true
        _ignoreRegionChange = true
        guard let allCoords = prefs.searchResults?.inPersonMeetings.allCoords,
              !allCoords.isEmpty
        else { return }
        
        guard let mapRegion = MKCoordinateRegion(coordinates: allCoords),
              let newRegion = mapView?.regionThatFits(mapRegion) else { return }
        
        print("2");
        mapView?.setVisibleMapRect(newRegion.asRect, animated: false)
        _ignoreRegionChange = false
    }
}

/* ###################################################################################################################################### */
// MARK: MKMapViewDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapResultsViewController: MKMapViewDelegate {
    /* ################################################################## */
    /**
     This is called to fetch an annotation (marker) for the map.
     
     - parameter: The map view (ignored)
     - parameter viewFor: The annotation we're getting the marker for.
     - returns: The marker view for the annotation.
     */
    func mapView(_: MKMapView, viewFor inAnnotation: MKAnnotation) -> MKAnnotationView? {
        var ret: MKAnnotationView?
        
        if let myAnnotation = inAnnotation as? SwiftBMLSDK_MapAnnotation {
            ret = SwiftBMLSDK_MapMarker(annotation: myAnnotation, reuseIdentifier: SwiftBMLSDK_MapMarker.reuseID)
        }
        
        return ret
    }
    
    /* ################################################################## */
    /**
     This is called when the map will change its region.
     
     - parameter: The map view (ignored)
     - parameter regionWillChangeAnimated: True, if the change is animated (ignored)
     */
    func mapView(_: MKMapView, regionWillChangeAnimated: Bool) {
    }
    
    /* ################################################################## */
    /**
     This is called when the map has changed its region.
     
     - parameter: The map view (ignored)
     - parameter regionDidChangeAnimated: True, if the change is animated (ignored)
     */
    func mapView(_ inMapView: MKMapView, regionDidChangeAnimated: Bool) {
        if firstLoadDone,
           !_ignoreRegionChange {
            let center = inMapView.region.center
            let radius = inMapView.region.diagonalSizeInMeters
            prefs.locationRadius = radius
            prefs.locationCenter = center
            prefs.locationRegion = inMapView.region
            prefs.performSearch {
                self.createAnnotations()
            }
        } else {
            createAnnotations()
        }
    }
    

    /* ################################################################## */
    /**
     This is called when the map has completed loading.
     
     - parameter: The map view (ignored)
     */
    func mapViewDidFinishLoadingMap(_: MKMapView) {
        if !firstLoadDone {
            setMapToResults()
        }
    }
}

/* ###################################################################################################################################### */
// MARK: UIPopoverPresentationControllerDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MapResultsViewController: UIPopoverPresentationControllerDelegate {
    /* ################################################################## */
    /**
     Called to ask if there's any possibility of this being displayed in another way.
     
     - parameter for: The presentation controller we're talking about.
     - returns: No way, Jose.
     */
    func adaptivePresentationStyle(for: UIPresentationController) -> UIModalPresentationStyle { .none }
    
    /* ################################################################## */
    /**
     Called to ask if there's any possibility of this being displayed in another way (when the screen is rotated).
     
     - parameter for: The presentation controller we're talking about.
     - parameter traitCollection: The traits, describing the new orientation.
     - returns: No way, Jose.
     */
    func adaptivePresentationStyle(for: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle { .none }

    /* ################################################################## */
    /**
     Called to allow us to do something before dismissing a popover.
     
     - parameter: ignored.
     
     - returns: True (all the time).
     */
    func popoverPresentationControllerShouldDismissPopover(_: UIPopoverPresentationController) -> Bool { true }
}
