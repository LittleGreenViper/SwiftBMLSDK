/*
© Copyright 2020-2024, Recovrr.org Inc.
*/

import UIKit
import MapKit
import RVS_UIKit_Toolbox
import RVS_Generic_Swift_Toolbox
import SwiftBMLSDK

/* ###################################################################################################################################### */
// MARK: - Main View Controller -
/* ###################################################################################################################################### */
/**
 This is for the marker popovers in the map.
 */
class SwiftMLSDK_Map_AnnotationPopover_ViewController: UIViewController {
    /* ################################################################## */
    /**
     The width of the popover
     */
    static private let _popoverWidthInDisplayUnits = CGFloat(300)

    /* ################################################################## */
    /**
     The height of each table row
     */
    static private let _rowHeightInDisplayUnits = CGFloat(30)

    /* ################################################################## */
    /**
     The padding, above and below
     */
    static private let _paddingInDisplayUnits = CGFloat(32)

    /* ################################################################## */
    /**
     The background transparency, for alternating rows.
     */
    static private let _alternateRowOpacity = CGFloat(0.05)

    /* ################################################################## */
    /**
     The storyboard ID, for instantiation.
     */
    static let storyboardID = "SwiftMLSDK_Map_AnnotationPopover_ViewController"

    /* ################################################################## */
    /**
     The users associated with this popover.
     */
    var meetings: [SwiftBMLSDK_Parser.Meeting] = []
    
    /* ################################################################## */
    /**
     The controller that "owns" the popover.
     */
    weak var myController: SwiftBMLSDK_TestHarness_MapResultsViewController?
    
    /* ################################################################## */
    /**
     The table view that lists the meetings.
     */
    @IBOutlet weak var tableView: UITableView?
}

/* ###################################################################################################################################### */
// MARK: Static Functions
/* ###################################################################################################################################### */
extension SwiftMLSDK_Map_AnnotationPopover_ViewController {
    /* ################################################################## */
    /**
     Performs a reverse geocode.
     
     - parameter inCoords: The coordinate to reverse.
     - parameter completion: The tail completion proc, with a list of placemarks, and any error that occurred. This may be called in any thread.
     */
    static func reverseGeocode(_ inCoords: CLLocationCoordinate2D, completion inCompletion: @escaping (_: [CLPlacemark]?, _: Error?) -> Void)  {
        guard CLLocationCoordinate2DIsValid(inCoords)
        else {
            inCompletion(nil, nil)
            return
        }
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: inCoords.latitude, longitude: inCoords.longitude)) { inPlacemark, inError in
            guard let placemark = inPlacemark,
                  nil == inError
            else {
                inCompletion(nil, inError)
                return
            }
            inCompletion(placemark, nil)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftMLSDK_Map_AnnotationPopover_ViewController {
    /* ################################################################## */
    /**
     The dynamic size for this popover.
     */
    override var preferredContentSize: CGSize {
        get { CGSize(width: Self._popoverWidthInDisplayUnits, height: Self._rowHeightInDisplayUnits * CGFloat(meetings.count) + Self._paddingInDisplayUnits) }
        set { super.preferredContentSize = newValue }
    }
    
    /* ################################################################## */
    /**
     Called after the view hierarchy is set up.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.rowHeight = Self._rowHeightInDisplayUnits
        tableView?.reloadData()
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDataSource Conformance
/* ###################################################################################################################################### */
extension SwiftMLSDK_Map_AnnotationPopover_ViewController: UITableViewDataSource {
    /* ################################################################## */
    /**
     Returns one cell. We use regular default cells.
     
     - parameter: The table view (ignored)
     - parameter numberOfRowsInSection: The section (also ignored)
     - returns: An integer, with the number of rows.
     */
    func tableView(_: UITableView, numberOfRowsInSection: Int) -> Int { meetings.count }
    
    /* ################################################################## */
    /**
     Returns one cell. We use regular default cells.
     
     - parameter: The table view (ignored)
     - parameter cellForRowAt: The index path of the cell we want.
     */
    func tableView(_: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
        let ret = UITableViewCell()
        ret.backgroundColor = .clear
        guard (0..<meetings.count).contains(inIndexPath.row) else { return ret }
        let meeting = meetings[inIndexPath.row]
        ret.textLabel?.text = meeting.name
        ret.textLabel?.adjustsFontSizeToFitWidth = true
        ret.textLabel?.minimumScaleFactor = 0.5
        ret.textLabel?.lineBreakMode = .byTruncatingTail
        ret.backgroundColor = (1 == inIndexPath.row % 2) ? UIColor.label.withAlphaComponent(Self._alternateRowOpacity) : UIColor.clear
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: UITableViewDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftMLSDK_Map_AnnotationPopover_ViewController: UITableViewDelegate {
    /* ################################################################## */
    /**
     Called when a cell is selected. We will use this to open the user viewer.
     
     - parameter: The table view (ignored)
     - parameter willSelectRowAt: The index path of the cell we are selecting.
     - returns: nil (all the time).
     */
    func tableView(_: UITableView, willSelectRowAt inIndexPath: IndexPath) -> IndexPath? {
        if (0..<meetings.count).contains(inIndexPath.row) {
            let meeting = meetings[inIndexPath.row]
            dismiss(animated: true) {
                self.myController?.selectMeeting(meeting)
            }
        }
        return nil
    }
}