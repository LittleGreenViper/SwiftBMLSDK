/*
 © Copyright 2024 - 2025, Little Green Viper Software Development LLC
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
import RVS_Generic_Swift_Toolbox
import SwiftBMLSDK
import MapKit

/* ###################################################################################################################################### */
// MARK: - Date Extension for Localized Strings -
/* ###################################################################################################################################### */
fileprivate extension Date {
    /* ################################################################## */
    /**
     Localizes the time (not the date).
     */
    var localizedTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none

        var ret = ""
        
        let hour = Calendar.current.component(.hour, from: self)
        let minute = Calendar.current.component(.minute, from: self)

        if let am = dateFormatter.amSymbol {
            if 0 == hour {
                if 0 == minute {
                    ret = "SLUG-MIDNIGHT-TIME".localizedVariant
                } else {
                    ret = String(format: "12:%02d %@", minute, am)
                }
            } else if 12 == hour,
                      0 == minute {
                ret = "SLUG-NOON-TIME".localizedVariant
            } else {
                ret = dateFormatter.string(from: self)
            }
        } else {
            if 12 == hour,
               0 == minute {
                ret = "SLUG-NOON-TIME".localizedVariant
            } else if 0 == hour,
                      0 == minute {
                ret = "SLUG-MIDNIGHT-TIME".localizedVariant
            } else {
                ret = String(format: "%d:%02d", hour, minute)
            }
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Server Single Meeting Inspector View Controller -
/* ###################################################################################################################################### */
/**
 This handles the display of the meeting inspector screen.
 */
class SwiftBMLSDK_TestHarness_MeetingViewController: SwiftBMLSDK_TestHarness_BaseViewController {
    /* ################################################################## */
    /**
     The ID for the segue to display a single meeting
     */
    private static let _showMeetingSegueID = "show-meeting"
    
    /* ################################################################## */
    /**
     This is the meeting associated with this screen.
     */
    var meeting: MeetingInstance? {  didSet { updateUI() } }
    
    /* ################################################################## */
    /**
     True, if we are viewing in a time that has been cast to our local time.
     */
    var isNormalizedTime: Bool = false
    
    /* ################################################################## */
    /**
     This is set to true, if the view is embedded.
     */
    var hideBackgound = false
    
    /* ################################################################## */
    /**
     The label for the time and day.
     */
    @IBOutlet weak var timeDayLabel: UILabel?
    
    /* ################################################################## */
    /**
     The label for the timezone.
     */
    @IBOutlet weak var timeZoneLabel: UILabel?
    
    /* ################################################################## */
    /**
     The label that displays when the next meeting will be.
     */
    @IBOutlet weak var meetsNextLabel: UILabel?
    
    /* ################################################################## */
    /**
     The label that displays comments.
     */
    @IBOutlet weak var commentsLabel: UILabel?
    
    /* ################################################################## */
    /**
     A simple separator view.
     */
    @IBOutlet weak var virtualSeparatorImageView: UIImageView?
    
    /* ################################################################## */
    /**
     The header for the virtual section.
     */
    @IBOutlet weak var virtualInfoHeaderLabel: UILabel?

    /* ################################################################## */
    /**
     The label for the direct video link.
     */
    @IBOutlet weak var videoLinkLabel: UILabel?

    /* ################################################################## */
    /**
     The label that displays the "extra info" for the virtual meeting.
     */
    @IBOutlet weak var virtualExtraInfoLabel: UILabel?
    
    /* ################################################################## */
    /**
     A simple separator view
     */
    @IBOutlet weak var locationSeparatorImageView: UIImageView?
    
    /* ################################################################## */
    /**
     The header for the in-person section.
     */
    @IBOutlet weak var locationHeaderLabel: UILabel?

    /* ################################################################## */
    /**
     The map view that displays the meeting location.
     */
    @IBOutlet weak var mapView: MKMapView?

    /* ################################################################## */
    /**
     The label for the address.
     */
    @IBOutlet weak var addressLabel: UILabel?

    /* ################################################################## */
    /**
     The stack view that holds the formats.
     */
    @IBOutlet weak var formatsStackView: UIStackView?
}

/* ###################################################################################################################################### */
// MARK: Base Class Overrides
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MeetingViewController {
    /* ################################################################## */
    /**
     Called when the view hierarchy has loaded.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if hideBackgound {
            backgroundImageView?.removeFromSuperview()
            watermarkImageView?.removeFromSuperview()
            view?.backgroundColor = .clear
        }
        
        guard let meeting = meeting else { return }
        myNavItem?.title = meeting.name
    }
    
    /* ################################################################## */
    /**
     Called just before the view is displayed.
     
     - parameter inIsAnimated: True, if the appearance is animated.
     */
    override func viewWillAppear(_ inIsAnimated: Bool) {
        super.viewWillAppear(inIsAnimated)
        updateUI()
    }
}

/* ###################################################################################################################################### */
// MARK: Instance Methods
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MeetingViewController {
    /* ################################################################## */
    /**
     This just updates all the screen UI elements.
     */
    func updateUI() {
        setTimeAndDay()
        setMeetingTimeZone()
        setMeetsNext()
        setComments()
        setVideoLink()
        setLocation()
        setFormats()
    }
    
    /* ################################################################## */
    /**
     Set the time and day label.
     */
    func setTimeAndDay() {
        guard var meeting = meeting else { return }
        
        let nextStart = meeting.getNextStartDate(isAdjusted: isNormalizedTime)
        var nextEnd: Date?
        var displayString: String = ""
        
        if 0 < meeting.duration {
            nextEnd = nextStart.addingTimeInterval(TimeInterval(meeting.duration))
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE")
        let weekday = dateFormatter.string(from: nextStart)

        if let nextEnd = nextEnd {
            let startTime = nextStart.localizedTime
            let endTime = nextEnd.localizedTime
            displayString = String(format: "SLUG-MEETING-DAY-AND-TIME-RANGE-LABEL-FORMAT".localizedVariant, weekday, startTime, endTime)
        } else {
            let startTime = nextStart.localizedTime
            displayString = String(format: "SLUG-MEETING-DAY-AND-TIME-LABEL-FORMAT".localizedVariant, weekday, startTime)
        }
        
        if !displayString.isEmpty {
            timeDayLabel?.text = displayString
        } else {
            timeDayLabel?.isHidden = true
        }
    }

    /* ################################################################## */
    /**
     Set the next meeting label.
     */
    func setMeetsNext() {
        guard var meeting = meeting else { return }

        guard !meeting.isMeetingInProgress() else {
            meetsNextLabel?.isHidden = false
            meetsNextLabel?.text = "SLUG-MEETING-IN-PROGRESS".localizedVariant
            return
        }

        var newText = ""
        
        let nextStart = Int(ceil(meeting.meetingStartsIn() / 60))
        switch nextStart {
        case 0:
            newText = "SLUG-STARTING-NOW".localizedVariant

        case 1:
            newText = "SLUG-STARTS-IN-ONE-MINUTE".localizedVariant

        case 2..<60:
            newText = String(format: "SLUG-STARTS-IN-MINUTES-FORMAT".localizedVariant, nextStart)

        case 60:
            newText = "SLUG-STARTS-IN-ONE-HOUR".localizedVariant

        case 61:
            newText = "SLUG-STARTS-IN-ONE-HOUR-ONE-MINUTE".localizedVariant

        case 61..<120:
            let hours = Int(nextStart / 60)
            let minutes = Int(nextStart) - (hours * 60)
            newText = String(format: "SLUG-STARTS-IN-ONE-HOUR-MINUTES-FORMAT".localizedVariant, minutes)

        case 120..<1440:
            let hours = Int(nextStart / 60)
            let minutes = Int(nextStart) - (hours * 60)
            if 0 == minutes {
                newText = String(format: "SLUG-STARTS-IN-HOURS-FORMAT".localizedVariant, hours)
            } else {
                newText = String(format: "SLUG-STARTS-IN-HOURS-MINUTES-FORMAT".localizedVariant, hours, minutes)
            }

        default:
            break
        }
        
        if newText.isEmpty {
            meetsNextLabel?.isHidden = true
        } else {
            meetsNextLabel?.isHidden = false
            meetsNextLabel?.text = newText
        }
    }

    /* ################################################################## */
    /**
     This sets the label that displays the meeting timezone.
     */
    func setMeetingTimeZone() {
        guard var meetingInstance = meeting else { return }
        let nativeTime = meetingInstance.getNextStartDate(isAdjusted: false)
        
        if let myCurrentTimezoneName = TimeZone.current.localizedName(for: .standard, locale: .current),
           let zoneName = meetingInstance.timeZone.localizedName(for: .standard, locale: .current),
           !zoneName.isEmpty,
           myCurrentTimezoneName != zoneName {
            timeZoneLabel?.isHidden = false
            if isNormalizedTime {
                timeZoneLabel?.text = String(format: "SLUG-TIMEZONE-FORMAT".localizedVariant, zoneName, nativeTime.localizedTime)
            } else {
                timeZoneLabel?.text = String(format: "SLUG-TIMEZONE-NO-TIME-FORMAT".localizedVariant, zoneName)
            }
        } else {
            timeZoneLabel?.isHidden = true
        }
    }
    
    /* ################################################################## */
    /**
     This sets up the comments label.
     */
    func setComments() {
        if let comments = meeting?.comments,
           !comments.isEmpty {
            commentsLabel?.isHidden = false
            commentsLabel?.text = comments
        } else {
            commentsLabel?.isHidden = true
        }
    }

    /* ################################################################## */
    /**
     Callback for the URL touch handler
     */
    @objc func urlHit(_: Any) {
        guard let url = meeting?.directAppURI ?? meeting?.virtualURL else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    /* ################################################################## */
    /**
     Set the video link label.
     */
    func setVideoLink() {
        if let url = meeting?.virtualURL {
            virtualSeparatorImageView?.isHidden = false
            virtualInfoHeaderLabel?.text = virtualInfoHeaderLabel?.text?.localizedVariant
            virtualInfoHeaderLabel?.isHidden = false
            videoLinkLabel?.text = url.absoluteString
            videoLinkLabel?.gestureRecognizers?.forEach { videoLinkLabel?.removeGestureRecognizer($0) }
            videoLinkLabel?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(urlHit)))
            videoLinkLabel?.isHidden = false
            if let extraInfo = meeting?.virtualInfo,
               !extraInfo.isEmpty {
                virtualExtraInfoLabel?.text = extraInfo
                virtualExtraInfoLabel?.isHidden = false
            } else {
                virtualExtraInfoLabel?.isHidden = true
            }
        } else {
            virtualSeparatorImageView?.isHidden = true
            virtualInfoHeaderLabel?.isHidden = true
            videoLinkLabel?.isHidden = true
            virtualExtraInfoLabel?.isHidden = true
        }
    }

    /* ################################################################## */
    /**
     This sets up the in-person location stuff.
     */
    func setLocation() {
        setMapView()
        setAddress()
        locationSeparatorImageView?.isHidden = (mapView?.isHidden ?? true) && (addressLabel?.isHidden ?? true)
        locationHeaderLabel?.text = locationHeaderLabel?.text?.localizedVariant
        locationHeaderLabel?.isHidden = (virtualInfoHeaderLabel?.isHidden ?? true) || (locationSeparatorImageView?.isHidden ?? true)
    }
    
    /* ################################################################## */
    /**
     This sets up the map view.
     */
    func setMapView() {
        if let meeting = meeting,
           let coords = meeting.coords,
           !meeting.basicInPersonAddress.isEmpty,
           CLLocationCoordinate2DIsValid(coords) {
            locationHeaderLabel?.isHidden = false
            mapView?.isHidden = false
            mapView?.setRegion(MKCoordinateRegion(center: coords, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)), animated: false)
            mapView?.addAnnotation(SwiftBMLSDK_MapAnnotation(coordinate: coords, meetings: [meeting], myController: nil))
        } else {
            mapView?.isHidden = true
        }
    }

    /* ################################################################## */
    /**
     This establishes the in-person address.
     */
    func setAddress() {
        if let postalAddress = meeting?.inPersonAddress {
            var txt = ""
            addressLabel?.isHidden = false
            let locationName = meeting?.inPersonVenueName ?? ""
            
            if !locationName.isEmpty {
                txt = locationName
            }
            
            var address = ""
            
            if !postalAddress.street.isEmpty {
                if !txt.isEmpty {
                    txt += "\n"
                }
                address += postalAddress.street
                
                if !postalAddress.city.isEmpty {
                    if !address.isEmpty {
                        address += "\n"
                    }
                    address += postalAddress.city
                }
                
                if !postalAddress.state.isEmpty {
                    if !address.isEmpty {
                        address += ", "
                    }
                    address += postalAddress.state
                }
                
                if !postalAddress.postalCode.isEmpty {
                    if !address.isEmpty {
                        address += " "
                    }
                    address += postalAddress.postalCode
                }
                txt += address
                if let extraInfo = meeting?.locationInfo,
                   !extraInfo.isEmpty {
                    if !txt.isEmpty {
                        txt += "\n"
                    }
                    txt += "(\(extraInfo))"
                }
                addressLabel?.text = txt
            }
        } else {
            addressLabel?.isHidden = true
        }
    }
    
    /* ################################################################## */
    /**
     Set the format display
     */
    func setFormats() {
        formatsStackView?.subviews.forEach { $0.removeFromSuperview() }
        meeting?.formats.forEach {
            let keyLabel = UILabel()
            keyLabel.text = $0.key
            keyLabel.font = .boldSystemFont(ofSize: 20)
            keyLabel.adjustsFontSizeToFitWidth = true
            keyLabel.minimumScaleFactor = 0.5
            let nameLabel = UILabel()
            nameLabel.text = $0.name
            nameLabel.adjustsFontSizeToFitWidth = true
            nameLabel.minimumScaleFactor = 0.5
            keyLabel.font = .systemFont(ofSize: 20)
            let descriptionLabel = UILabel()
            descriptionLabel.font = .italicSystemFont(ofSize: 17)
            descriptionLabel.text = $0.description
            descriptionLabel.numberOfLines = 0
            let formatHeaderStackView = UIStackView(arrangedSubviews: [keyLabel, nameLabel])
            formatHeaderStackView.axis = .horizontal
            keyLabel.translatesAutoresizingMaskIntoConstraints = false
            keyLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
            formatsStackView?.addArrangedSubview(formatHeaderStackView)
            formatsStackView?.addArrangedSubview(descriptionLabel)
        }
    }
}

/* ###################################################################################################################################### */
// MARK: MKMapViewDelegate Conformance
/* ###################################################################################################################################### */
extension SwiftBMLSDK_TestHarness_MeetingViewController: MKMapViewDelegate {
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
}
