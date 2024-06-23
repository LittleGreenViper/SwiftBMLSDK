/*
© Copyright 2020-2024, Recovrr.org Inc.
*/

import UIKit
import MapKit
import RVS_UIKit_Toolbox
import RVS_Generic_Swift_Toolbox
import SwiftBMLSDK

class SwiftMLSDK_Map_AnnotationPopover_ViewController_TableCell: UITableViewCell {
    /* ################################################################## */
    /**
     */
    static let reuseID = "SwiftMLSDK_Map_AnnotationPopover_ViewController_TableCell"
    
    /* ################################################################## */
    /**
     */
    static let rowHeight = CGFloat(48)
    
    /* ################################################################## */
    /**
     */
    @IBOutlet var meetingNameLabel: UILabel?
    
    /* ################################################################## */
    /**
     */
    @IBOutlet var startTimeLabel: UILabel?
}

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
    var meetings: [MeetingInstance] = []
    
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
        get { CGSize(width: Self._popoverWidthInDisplayUnits, height: SwiftMLSDK_Map_AnnotationPopover_ViewController_TableCell.rowHeight * CGFloat(meetings.count) + Self._paddingInDisplayUnits) }
        set { super.preferredContentSize = newValue }
    }
    
    /* ################################################################## */
    /**
     Called after the view hierarchy is set up.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        tableView?.rowHeight = SwiftMLSDK_Map_AnnotationPopover_ViewController_TableCell.rowHeight
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
     
     - parameter: The table view
     - parameter cellForRowAt: The index path of the cell we want.
     */
    func tableView(_ inTableView: UITableView, cellForRowAt inIndexPath: IndexPath) -> UITableViewCell {
        guard let ret = inTableView.dequeueReusableCell(withIdentifier: SwiftMLSDK_Map_AnnotationPopover_ViewController_TableCell.reuseID, for: inIndexPath) as? SwiftMLSDK_Map_AnnotationPopover_ViewController_TableCell else { return UITableViewCell() }
        ret.backgroundColor = .clear
        guard (0..<meetings.count).contains(inIndexPath.row) else { return ret }
        var meeting = meetings[inIndexPath.row]
        let nextDate = meeting.getNextStartDate(isAdjusted: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: nextDate)
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: nextDate)
        let dayTime = String(format: "SLUG-WEEKDAY-TIME-FORMAT".localizedVariant, weekday, time)
        ret.meetingNameLabel?.text = meeting.name
        ret.startTimeLabel?.text = dayTime
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
