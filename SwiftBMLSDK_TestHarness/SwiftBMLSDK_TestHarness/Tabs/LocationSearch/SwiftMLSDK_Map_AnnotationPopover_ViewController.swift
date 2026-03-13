/*
 © Copyright 2024 - 2026, Little Green Viper Software Development LLC
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

import UIKit
import MapKit
import RVS_UIKit_Toolbox
import RVS_Generic_Swift_Toolbox
import SwiftBMLSDK

/* ###################################################################################################################################### */
// MARK: - Custom Table Cell -
/* ###################################################################################################################################### */
/**
 This is a custom cell class, for our table view.
 */
class SwiftMLSDK_Map_AnnotationPopover_ViewController_TableCell: UITableViewCell {
    /* ################################################################## */
    /**
     The table cell reuse ID.
     */
    static let reuseID = "SwiftMLSDK_Map_AnnotationPopover_ViewController_TableCell"
    
    /* ################################################################## */
    /**
     The standard row height.
     */
    static let rowHeight = CGFloat(48)
    
    /* ################################################################## */
    /**
     The label that displays the meeting name.
     */
    @IBOutlet var meetingNameLabel: UILabel?
    
    /* ################################################################## */
    /**
     The label that displays the start time.
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
     - parameter inCompletion: The tail completion proc, with a list of placemarks, and any error that occurred. This may be called in any thread.
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
     
     - parameter inTableView: The table view (ignored)
     - parameter numberOfRowsInSection: The section (also ignored)
     - returns: An integer, with the number of rows.
     */
    func tableView(_ inTableView: UITableView, numberOfRowsInSection: Int) -> Int { meetings.count }
    
    /* ################################################################## */
    /**
     Returns one cell. We use regular default cells.
     
     - parameter inTableView: The table view
     - parameter inIndexPath: The index path of the cell we want.
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
