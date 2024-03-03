/**
 © Copyright 2020-2024, Recovrr.org, Inc.
 */

import MapKit
import RVS_UIKit_Toolbox
import SwiftBMLSDK

/* ###################################################################################################################################### */
// MARK: - Annotation Class -
/* ###################################################################################################################################### */
/**
 This handles the marker annotation for the main center.
 */
class SwiftBMLSDK_MapAnnotation: NSObject, MKAnnotation {
    /* ################################################################## */
    /**
     The coordinate for this annotation.
     */
    let coordinate: CLLocationCoordinate2D
    
    /* ################################################################## */
    /**
     The controller that "owns" this annotation.
     */
    weak var myController: SwiftBMLSDK_TestHarness_MapResultsViewController?
    
    /* ################################################################## */
    /**
     This is any meetings associated with this instance. This can be modified after instantiation.
     */
    var meetings: [SwiftBMLSDK_Parser.Meeting]
    
    /* ################################################################## */
    /**
     Default initializer.
     
     - parameter coordinate: the coordinate for this annotation.
     */
    init(coordinate inCoordinate: CLLocationCoordinate2D,
         meetings inMeetings: [SwiftBMLSDK_Parser.Meeting],
         myController inMyController: SwiftBMLSDK_TestHarness_MapResultsViewController? = nil) {
        coordinate = inCoordinate
        meetings = inMeetings
        myController = inMyController
    }
}

/* ###################################################################################################################################### */
// MARK: - Marker Class -
/* ###################################################################################################################################### */
/**
 This handles our map marker.
 */
class SwiftBMLSDK_MapMarker: MKAnnotationView {
    /* ################################################################## */
    /**
     Marker Height and Width, in Display Units
     */
    static let sMarkerSizeInDisplayUnits = CGFloat(40)

    /* ################################################################## */
    /**
     The reuse ID for this view class.
     */
    static let reuseID: String = "SwiftBMLSDK_MapMarker"
    
    /* ################################################################## */
    /**
     The gesture recognizer that reacts to taps.
     */
    var tapGestureRecognizer: UITapGestureRecognizer?
    
    /* ################################################################## */
    /**
     We override, so we can set the image.
     
     - parameter annotation: The annotation instance.
     - parameter reuseIdentifier: The reuse ID.
     */
    override init(annotation inAnnotation: MKAnnotation?, reuseIdentifier inReuseID: String?) {
        super.init(annotation: inAnnotation, reuseIdentifier: inReuseID)
        if var imageTemp = UIImage(named: "Marker-Single")?.withRenderingMode(.alwaysOriginal).resized(toMaximumSize: Self.sMarkerSizeInDisplayUnits) {
            let count = meetings.count
            if 1 < count {
                let imageSize = imageTemp.size
                
                UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
                imageTemp.draw(in: CGRect(origin: .zero, size: imageSize))
                let offset = imageSize.width * 0.1
                let width = imageSize.width * 0.8
                let height = width
                
                var containerRect = CGRect(x: offset, y: offset, width: width, height: height)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                
                var stringSize = CGFloat(20)
                
                while 4.0 < stringSize {
                    let attributes = [
                        NSAttributedString.Key.paragraphStyle: paragraphStyle,
                        NSAttributedString.Key.font: UIFont.systemFont(ofSize: stringSize),
                        NSAttributedString.Key.foregroundColor: UIColor.white
                    ]
                    
                    let attributedString = NSAttributedString(string: String(count), attributes: attributes)
                    let stringRect = attributedString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: [], context: nil)
                    
                    if containerRect.size.width >= stringRect.size.width,
                       containerRect.size.height >= stringRect.size.height {
                        containerRect.origin.y += (containerRect.size.height - stringRect.size.height) / 2
                        attributedString.draw(in: containerRect)
                        break
                    } else {
                        stringSize *= 0.9
                    }
                }

                let imageTempOptional = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                imageTemp = imageTempOptional ?? imageTemp
            }
            
            image = imageTemp

            centerOffset = CGPoint(x: 0, y: imageTemp.size.height / -2)
            
            if nil == tapGestureRecognizer,
               nil != (annotation as? SwiftBMLSDK_MapAnnotation)?.myController {
                let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(markerTapped))
                tapGestureRecognizer = gestureRecognizer
                addGestureRecognizer(gestureRecognizer)
            }
        }
    }
    
    /* ################################################################## */
    /**
     Called when the marker gesture recognizer is fired.
     
     - parameter: The gesture recognizer (ignored).
     */
    @objc func markerTapped(_: UIGestureRecognizer) {
        guard let annotation = (annotation as? SwiftBMLSDK_MapAnnotation) else { return }
        
        annotation.myController?.annotationHit(meetings: annotation.meetings, view: self)
    }
    
    /* ################################################################## */
    /**
     Required NSCoding conformance
     
     - parameter inDecoder: The decoder instance.
     */
    required init?(coder inDecoder: NSCoder) {
        super.init(coder: inDecoder)
    }
}

/* ###################################################################################################################################### */
// MARK: Computed Instance Properties
/* ###################################################################################################################################### */
extension SwiftBMLSDK_MapMarker {
    /* ################################################################## */
    /**
     The annotation coordinate
     */
    var coordinate: CLLocationCoordinate2D { annotation?.coordinate ?? kCLLocationCoordinate2DInvalid }
    
    /* ################################################################## */
    /**
     This is any user associated with this instance
     */
    var meetings: [SwiftBMLSDK_Parser.Meeting] { (annotation as? SwiftBMLSDK_MapAnnotation)?.meetings ?? [] }
}
