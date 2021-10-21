//
//  LoopSurfaceWindow.swift
//  Geometry
//
//  Created by Stuart Rankin on 10/20/21.
//

import Foundation
import UIKit

class LoopSurfaceWindow: UIView
{
    var LoopCallback: LoopData? = nil
    var Callback: Messages? = nil
    
    var Center: CGPoint
    {
        get
        {
            return self.center
        }
    }
    
    var OriginalPoints = [CGPoint]()
    var PointAngles = [CGFloat]()
    
    typealias Messages = (String) -> ()
    typealias LoopData = (CGPoint, Int, Int, Int, (Int, Int), CGFloat, CGFloat) -> ()
    
    func Initialize(LoopDataCallback: LoopData? = nil, _ Callback: Messages? = nil)
    {
        self.backgroundColor = UIColor.lightGray
        self.LoopCallback = LoopDataCallback
        self.Callback = Callback
        let Tap = UITapGestureRecognizer(target: self,
                                         action: #selector(HandleTaps))
        Tap.numberOfTapsRequired = 1
        self.addGestureRecognizer(Tap)
        let Pan = UIPanGestureRecognizer(target: self,
                                         action: #selector(HandlePans))
        self.addGestureRecognizer(Pan)
    }
    
    @objc func HandlePans(_ Recognizer: UIPanGestureRecognizer)
    {
        switch Recognizer.state
        {
            case .began, .changed:
                let Location = Recognizer.location(in: self)
                let ClosePoint = ClosestTo2(Point: Location)
                if ClosePoint >= 0
                {
                    OriginalPoints[ClosePoint] = Location
                    PlotSurface()
                }
                
            default:
                break
        }
    }
    
    var MClosest: Int? = nil
    var MLocation: CGPoint? = nil
    var MAngle: CGFloat? = nil
    
    @objc func HandleTaps(_ Recognizer: UITapGestureRecognizer)
    {
        let Location = Recognizer.location(in: self)
        let CloseIndex = ClosestTo2(Point: Location)
        if CloseIndex < 0
        {
            print("No closest point found to \(Location)")
            return
        }
        MClosest = CloseIndex
        MLocation = Location
        var NewAngle = Angle3A(Point2: Location, Point3: OriginalPoints[CloseIndex])
        //NewAngle = NewAngle * 180.0 / CGFloat.pi
        MAngle = NewAngle
        let CloseAngle = PointAngles[CloseIndex]
        print("NewAngle=\(Int(NewAngle))°, CloseAngle{\(CloseIndex)}=\(Int(CloseAngle * 180.0 / CGFloat.pi))°")
        PlotSurface()
    }
    
    func Distance(From Point1: CGPoint, To Point2: CGPoint) -> CGFloat
    {
        let DeltaX = Point1.x - Point2.x
        let DeltaY = Point1.y - Point2.y
        let DeltaX2 = DeltaX * DeltaX
        let DeltaY2 = DeltaY * DeltaY
        let Final = sqrt(DeltaX2 + DeltaY2)
        return Final
    }
    
    func ClosestTo2(Point: CGPoint) -> Int
    {
        if OriginalPoints.isEmpty
        {
            return -1
        }
        var Index = 0
        var ClosestIndex: Int = -1
        var PDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        for SomePoint in OriginalPoints
        {
            let SDistance = Distance(From: Point, To: SomePoint)
            if SDistance < PDistance
            {
                PDistance = SDistance
                ClosestIndex = Index
            }
            Index = Index + 1
        }
        return ClosestIndex
    }
    
    func PlotSurface()
    {
        self.setNeedsDisplay()
    }
    
    func GetAdjacentPoints(To Center: Int) -> (Previous: Int, Next: Int)
    {
        if OriginalPoints.count < 3
        {
            fatalError("Not enough points")
        }
        var Previous = Center - 1
        var Next = Center + 1
        if Center == 0
        {
            Previous = OriginalPoints.count - 1
        }
        if Next > OriginalPoints.count - 1
        {
            Next = 0
        }
        return (Previous, Next)
    }
    
    override func draw(_ rect: CGRect)
    {
        if OriginalPoints.isEmpty
        {
            return
        }
        PointAngles.removeAll()
        if OriginalPoints.count > 2
        {
            for Index in 0 ..< OriginalPoints.count
            {
                var Previous = Index - 1
                var Next = Index + 1
                if Index == 0
                {
                    Previous = OriginalPoints.count - 1
                }
                if Next > OriginalPoints.count - 1
                {
                    Next = 0
                }
                var Angle = Angle3A(Point2: OriginalPoints[Previous],
                                    Point3: OriginalPoints[Next])
                //Angle = Angle + 90.0
                Angle = Angle * CGFloat.pi / 180.0
                PointAngles.append(Angle)
                let Degrees = Angle * 180.0 / CGFloat.pi
                //let Degrees = Angle
                //print("[\(Previous)]=\(OriginalPoints[Previous])")
                //print("[\(Index)]=\(OriginalPoints[Index]) Angle at index \(Index) = Int(\(Degrees))°")
                //print("[\(Next)]=\(OriginalPoints[Next])\n")
                let LinePath = UIBezierPath()
                let VP = OriginalPoints[Index]
                LinePath.move(to: VP)
                let P1 = RadialPoint(Center: VP,
                                     Angle: Degrees,
                                     Radius: 100.0)
                LinePath.addLine(to: P1)
                LinePath.move(to: VP)
                let OppositeAngle = fmod(abs(180.0 + Degrees), 360.0)
                let P2 = RadialPoint(Center: VP,
                                     Angle: OppositeAngle,
                                     Radius: 100.0)
                LinePath.addLine(to: P2)
                LinePath.lineWidth = 2
                UIColor.systemYellow.setStroke()
                LinePath.stroke()
            }
        }
        
        if let NewSpot = MLocation
        {
            var Trailing = ""
            if MAngle != nil
            {
                Trailing = "\(Int(MAngle!))°"
            }
            MakePoint(NewSpot, Color: UIColor.systemPurple, Tag: "▲ ",
                      TrailingTag: Trailing)
            if let ClosestSpot = MClosest
            {
                let Actual = OriginalPoints[ClosestSpot]
                print("ClosestSpot: \(ClosestSpot)=\(Actual)")
                DrawLine(From: NewSpot,
                         To: Actual,
                         Width: 4.0,
                         Color: UIColor.red.withAlphaComponent(0.5))
                let (Previous, Next) = GetAdjacentPoints(To: ClosestSpot)
                DrawLine(From: NewSpot,
                         To: OriginalPoints[Previous],
                         Width: 4.0,
                         Color: UIColor.systemOrange.withAlphaComponent(0.75))
                DrawLine(From: NewSpot,
                         To: OriginalPoints[Next],
                         Width: 4.0,
                         Color: UIColor.systemOrange.withAlphaComponent(0.75))
                let DistToPrevious = Distance(From: NewSpot, To: OriginalPoints[Previous])
                let DistToNext = Distance(From: NewSpot, To: OriginalPoints[Next])
                if DistToNext < DistToPrevious
                {
                    Callback?("Closest:Next, Insert at \(ClosestSpot)")
                    print("Insert between Closest and Next")
                }
                else
                {
                    Callback?("Closest:Previous, Insert at \(Previous)")
                    print("Insert between Closest and Previous")
                }
            }
        }
        for Index in 0 ..< OriginalPoints.count
        {
            let LastIndex = Index == OriginalPoints.count - 1 ? 0 : Index + 1
            DrawLine(From: OriginalPoints[Index],
                     To: OriginalPoints[LastIndex],
                     Width: 2.5,
                     Color: UIColor.systemIndigo)
        }
        var Index = 0
        for Point in OriginalPoints
        {
            let Degree = PointAngles[Index] * 180.0 / CGFloat.pi
            MakePoint(Point,
                      Color: UIColor.systemIndigo,
                      Tag: "\(Index) ",
                      TrailingTag: " \(Int(Degree))°")
            Index = Index + 1
        }
    }
    
    func DrawLine(From Point1: CGPoint, To Point2: CGPoint, Width: CGFloat = 4,
                  Color: UIColor = UIColor.red.withAlphaComponent(0.65))
    {
        let Line = UIBezierPath()
        Line.move(to: Point1)
        Line.addLine(to: Point2)
        Line.lineWidth = Width
        Color.setStroke()
        Line.stroke()
    }
    
    func Angle3(Point2: CGPoint, Point3: CGPoint) -> CGFloat
    {
        let A = Point2.x - Point3.x
        let B = Point2.y - Point3.y
        let Angle = atan2(A, B)
        return Angle
    }
    
    func Angle3A(Point2: CGPoint, Point3: CGPoint) -> CGFloat
    {
        let A = Point2.x - Point3.x
        let B = Point2.y - Point3.y
        var Degrees = atan2(A, B) * 180.0 / CGFloat.pi
        Degrees = fmod(Degrees + 360.0, 360.0)
        Degrees = fmod(450.0 - Degrees, 360.0)
        Degrees = Degrees + 90.0
        return Degrees
    }
    
    func RadialPoint(Center: CGPoint, Angle: CGFloat, Radius: CGFloat) -> CGPoint
    {
        let Radians = Angle * CGFloat.pi / 180.0
        let X = Radius * cos(Radians)
        let Y = Radius * sin(Radians)
        return CGPoint(x: X + Center.x, y: Y + Center.y)
    }
    
    func RadialPointA(Center: CGPoint, Angle: CGFloat, Radius: CGFloat) -> CGPoint
    {
        let Radians = Angle * CGFloat.pi / 180.0
        let X = Radius * cos(Radians)
        let Y = Radius * sin(Radians)
        return CGPoint(x: X + Center.x, y: Y + Center.y)
    }
    
    func MakePoint(_ DrawPoint: CGPoint,
                   Color: UIColor,
                   Tag: String = "", TrailingTag: String? = nil)
    {
        let P = UIBezierPath(ovalIn: CGRect(x: DrawPoint.x - 8,
                                            y: DrawPoint.y - 8,
                                            width: 16,
                                            height: 16))
        P.lineWidth = 5.0
        Color.setStroke()
        P.stroke()
        let NiceX = "\(Int(DrawPoint.x))"
        let NiceY = "\(Int(DrawPoint.y))"
        var Trailing = ""
        if let TrailingValue = TrailingTag
        {
            Trailing = TrailingValue
        }
        let PrettyLabel = "\(Tag)(\(NiceX),\(NiceY))\(Trailing)" as NSString
        let TextRect = CGRect(x: DrawPoint.x + 12.0,
                              y: DrawPoint.y - 12.0,
                              width: 200,
                              height: 20)
        let Attributes: [NSAttributedString.Key : Any] =
        [
            .foregroundColor: Color as Any,
            .font: UIFont.boldSystemFont(ofSize: 18.0) as Any
        ]
        PrettyLabel.draw(in: TextRect, withAttributes: Attributes)
    }
}
