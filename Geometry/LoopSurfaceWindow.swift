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
    
    var RotateFrame: Bool = false
    {
        didSet
        {
            PlotSurface()
        }
    }
    
    var OriginalPoints = [CGPoint]()
    
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
    
    var HighlightIndex: Int? = nil
    
    @objc func HandlePans(_ Recognizer: UIPanGestureRecognizer)
    {
        switch Recognizer.state
        {
            case .began, .changed:
                let Location = Recognizer.location(in: self)
                let ClosePoint = ClosestTo2(Point: Location)
                let ClosestOther = ClosestOtherPoint(TestIndex: ClosePoint)
                if ClosestOther > -1
                {
                    HighlightIndex = ClosestOther
                }
                else
                {
                    HighlightIndex = nil
                }
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
    var Rect1: CGRect? = nil
    var Rect2: CGRect? = nil
    var NewPointRect: CGRect? = nil
    var IRect: CGRect? = nil
    
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
        let (Previous, Next) = GetAdjacentPoints(To: CloseIndex)
        Rect1 = CGRect.MakeRect(Point1: OriginalPoints[CloseIndex],
                                Point2: OriginalPoints[Previous])
        Rect2 = CGRect.MakeRect(Point1: OriginalPoints[CloseIndex],
                                Point2: OriginalPoints[Next])
        NewPointRect = CGRect.MakeRect(Point1: OriginalPoints[CloseIndex],
                                Point2: Location)
        let R1R3 = Rect1!.intersection(NewPointRect!)
        let R2R3 = Rect2!.intersection(NewPointRect!)
        var InsertionIndex = -1
        if R1R3.NonZeroSize()
        {
            InsertionIndex = Previous
            print("A: In Rect1 {pink}=\(InsertionIndex)")
        }
        if R2R3.NonZeroSize()
        {
            InsertionIndex = CloseIndex
            print("A: In Rect2 {teal}=\(InsertionIndex)")
        }
        if (R1R3.width == 0.0 || R1R3.height == 0.0) && (R2R3.width == 0.0 || R2R3.height == 0.0)
        {
            let R1R3Max = max(R1R3.width, R1R3.height)
            let R2R3Max = max(R2R3.width, R2R3.height)
            if R1R3Max > R2R3Max
            {
                InsertionIndex = Previous
                print("B: In Rect1 {pink}=\(InsertionIndex)")
            }
            else
            {
                InsertionIndex = CloseIndex
                print("B: In Rect2 {teal}=\(InsertionIndex)")
            }
        }
        OriginalPoints.insert(Location, at: InsertionIndex + 1)
        PlotSurface()
    }
    
    var NewestIndex = -1
    
    func Distance(From Point1: CGPoint, To Point2: CGPoint) -> CGFloat
    {
        let DeltaX = Point1.x - Point2.x
        let DeltaY = Point1.y - Point2.y
        let DeltaX2 = DeltaX * DeltaX
        let DeltaY2 = DeltaY * DeltaY
        let Final = sqrt(DeltaX2 + DeltaY2)
        return Final
    }
    
    func ClosestOtherPoint(TestIndex: Int) -> Int
    {
        if OriginalPoints.isEmpty
        {
            return -1
        }
        var ShortestDistance = CGFloat.greatestFiniteMagnitude
        var ShortestIndex = 0
        for Index in 0 ..< OriginalPoints.count
        {
            let Point = OriginalPoints[Index]
            if Index == TestIndex
            {
                continue
            }
            let Dist = Distance(From: Point, To: OriginalPoints[TestIndex])
            if Dist < ShortestDistance
            {
                ShortestDistance = Dist
                ShortestIndex = Index
            }
        }
        return ShortestIndex
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
            print("No points to draw")
            return
        }
        if NewestIndex > -1
        {
            MakePoint(OriginalPoints[NewestIndex], Color: UIColor.systemPurple,
                      Tag: "\(NewestIndex) ")
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
            if NewestIndex > -1
            {
                if Point == OriginalPoints[NewestIndex]
                {
                    Index = Index + 1
                    continue
                }
            }
            var PointColor = UIColor.systemIndigo
            if let HighlightSpot = HighlightIndex
            {
                if HighlightSpot <= OriginalPoints.count - 1
                {
                    if Point == OriginalPoints[HighlightSpot]
                    {
                        PointColor = UIColor.red
                    }
                }
            }
            MakePoint(Point,
                      Color: PointColor,
                      Tag: "\(Index) ")
            Index = Index + 1
        }
        if let R1 = Rect1
        {
            let R1Rect = UIBezierPath(rect: R1)
            R1Rect.lineWidth = 6.0
            UIColor.systemPink.setStroke()
            R1Rect.stroke()
        }
        if let R2 = Rect2
        {
            let R2Rect = UIBezierPath(rect: R2)
            R2Rect.lineWidth = 6.0
            UIColor.systemTeal.setStroke()
            R2Rect.stroke()
        }
        if let R3 = NewPointRect
        {
            let R3Rect = UIBezierPath(rect: R3)
            R3Rect.lineWidth = 6.0
            UIColor.cyan.setStroke()
            R3Rect.stroke()
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

extension CGRect
{
    static func MakeRect(Point1: CGPoint, Point2 : CGPoint) -> CGRect
    {
        var P1: CGPoint = .zero
        var P2: CGPoint = .zero
        switch (Point1.x < Point2.x, Point1.y < Point2.y)
        {
            case (true, true):
                P1 = Point1
                P2 = Point2
                
            case (true, false):
                P1 = CGPoint(x: Point1.x, y: Point2.y)
                P2 = CGPoint(x: Point2.x, y: Point1.y)
                
            case (false, true):
                P1 = CGPoint(x: Point2.x, y: Point1.y)
                P2 = CGPoint(x: Point1.x, y: Point2.y)
                
            case (false, false):
                P1 = Point2
                P2 = Point1
        }
        let Width = abs(P1.x - P2.x)
        let Height = abs(P1.y - P2.y)
        let Final = CGRect(origin: P1, size: CGSize(width: Width, height: Height))
        return Final
    }
    
    func NonZeroSize() -> Bool
    {
        return self.width > 0.0 && self.height > 0.0
    }
}
