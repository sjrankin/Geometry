//
//  SurfaceWindow.swift
//  Geometry
//
//  Created by Stuart Rankin on 10/16/21.
//

import Foundation
import UIKit

class SurfaceWindow: UIView
{
    var GridGap = 16
    var CX: CGFloat = 0.0
    var CY: CGFloat = 0.0
    
    var RotateFrame: Bool = false
    {
        didSet
        {
            if RotateFrame
            {
                self.layer.backgroundColor = UIColor.white.cgColor
            }
            else
            {
                self.layer.backgroundColor = UIColor.systemYellow.cgColor
            }
        }
    }
    
    var OriginalPoints = [CGPoint]()
    var InLoopMode: Bool = false
    var ShowDistances: Bool = false
    var Decorate: Bool = false
    var Closest: CGPoint? = nil
    var MinusOne: CGPoint? = nil
    var PlusOne: CGPoint? = nil
    var TestPoint: CGPoint? = nil
    var PointType: PointTypes = .None
    var Callback: Messages? = nil
    var LoopCallback: LoopData? = nil
    
    typealias LoopData = (CGPoint, Int, Int, Int, (Int, Int), CGFloat, CGFloat) -> ()
    typealias Messages = (String) -> ()
    func Initialize(_ Callback: Messages? = nil, _ LoopDataCallback: LoopData? = nil)
    {
        self.Callback = Callback
        self.LoopCallback = LoopDataCallback
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
        if RotateFrame
        {
            return
        }
        if InLoopMode
        {
            HandleLoopModePans(With: Recognizer)
            return
        }
        let RawLocation = Recognizer.location(in: self)
        let Location = CGPoint(x: RawLocation.x - CX,
                               y: CY - RawLocation.y)
        switch PointType
        {
            case .None:
                return
                
            case .Closest:
                Closest = Location
                
            case .Minus1:
                MinusOne = Location
                
            case .Plus1:
                PlusOne = Location
                
            case .Test:
                TestPoint = Location
        }
        PlotSurface()
    }
    
    func HandleLoopModePans(With: UIPanGestureRecognizer)
    {
        switch With.state
        {
            case .began, .changed:
                let RawLocation = With.location(in: self)
                let Location = CGPoint(x: RawLocation.x - CX,
                                       y: CY - RawLocation.y)
                if let ClosePoint = ClosestTo(Point: Location)
                {
                    OriginalPoints[ClosePoint.PointIndex] = Location
                    PlotSurface()
                }
                
            default:
                break
        }
    }
    
    func ClosestTo(Point: CGPoint) -> (PointIndex: Int, PointDistance: CGFloat)?
    {
        if OriginalPoints.isEmpty
        {
            return nil
        }
        var Index = 0
        var ClosestIndex: Int = -1
        var PDistance: CGFloat = 10000000.0
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
        return (ClosestIndex, PDistance)
    }
    
    @objc func HandleTaps(_ Recognizer: UITapGestureRecognizer)
    {
        if RotateFrame
        {
            return
        }
        if InLoopMode
        {
            HandleLoopModeTaps(With: Recognizer)
            return
        }
        if PointType == .None
        {
            return
        }
        let RawLocation = Recognizer.location(in: self)
        let Location = CGPoint(x: RawLocation.x - CX,
                               y: CY - RawLocation.y)
        switch PointType
        {
            case .None:
                return
                
            case .Closest:
                Closest = Location
                
            case .Minus1:
                MinusOne = Location
                
            case .Plus1:
                PlusOne = Location
                
            case .Test:
                TestPoint = Location
        }
        PlotSurface()
    }
    
    var MLocation: CGPoint? = nil
    var MClosest: Int? = nil
    var MAngle: CGFloat? = nil
    
    func HandleLoopModeTaps(With: UITapGestureRecognizer)
    {
        let RawLocation = With.location(in: self)
        let Location = CGPoint(x: RawLocation.x - CX,
                               y: CY - RawLocation.y)
        guard let (CloseIndex, CloseDistance) = ClosestTo(Point: Location) else
        {
            return
        }
         MLocation = CGPoint(x: Location.x + CX,
                y: CY - Location.y)
        var NewAngle = Angle3(Point2: Location, Point3: OriginalPoints[CloseIndex])
        NewAngle = NewAngle * 180.0 / CGFloat.pi
        MAngle = NewAngle
        let CloseAngle = PointAngles[CloseIndex] * 180.0 / CGFloat.pi
        print("NewAngle=\(Int(NewAngle))°, CloseAngle{\(CloseIndex)}=\(Int(CloseAngle))°")
        PlotSurface()
        /*
        var MinusOne = CloseIndex - 1
        if MinusOne < 0
        {
            MinusOne = OriginalPoints.count - 1
        }
        var PlusOne = CloseIndex + 1
        if PlusOne > OriginalPoints.count - 1
        {
            PlusOne = 0
        }
        let InsertionIndex = ReturnSegment(Closest: CloseIndex, MinusOne: MinusOne,
                                           PlusOne: PlusOne, New: Location)
        LoopCallback?(Location, CloseIndex, MinusOne, PlusOne,
                      (CloseIndex, InsertionIndex),
                      Distance(From: Location, To: OriginalPoints[MinusOne]),
                      Distance(From: Location, To: OriginalPoints[PlusOne]))
        PlotSurface()
        OriginalPoints.insert(Location, at: InsertionIndex)
         */
    }
    
    func GetClosePointAngle(Closest: Int) -> CGFloat
    {
        let ClosestPoint = OriginalPoints[Closest]
        var ClosestAngle = AngleFrom(Origin: .zero,
                                 To: ClosestPoint)
        ClosestAngle = 360.0 - ClosestAngle
        ClosestAngle = ClosestAngle + 90.0
        if ClosestAngle > 360.0
        {
            ClosestAngle = ClosestAngle - 360.0
        }
        let NormalizingAngle = 90.0 - ClosestAngle
        return NormalizingAngle
    }
    
    func ReturnSegment(Closest: Int, MinusOne: Int, PlusOne: Int, New: CGPoint) -> Int
    {
        var ClosestPoint = OriginalPoints[Closest]
        let RotationalAngle = GetClosePointAngle(Closest: Closest)
        var MinusOnePoint = OriginalPoints[MinusOne]
        var PlusOnePoint = OriginalPoints[PlusOne]
        var NewPoint = New
        print("Unrotated ClosestPoint=\(ClosestPoint)")
        print("          MinusOnePoint=\(MinusOnePoint)")
        print("          PlusOnePoint=\(PlusOnePoint)")
        print("          NewPoint=\(NewPoint)")
        
        print(">>> RotationAngle = \(RotationalAngle)")
        ClosestPoint = ClosestPoint.Rotate(By: RotationalAngle)
        MinusOnePoint = MinusOnePoint.Rotate(By: RotationalAngle)
        PlusOnePoint = PlusOnePoint.Rotate(By: RotationalAngle)
        NewPoint = NewPoint.Rotate(By: RotationalAngle)
        
        print("Rotated ClosestPoint=\(ClosestPoint)")
        print("        MinusOnePoint=\(MinusOnePoint)")
        print("        PlusOnePoint=\(PlusOnePoint)")
        print("        NewPoint=\(NewPoint)")
        
        let RotatedNewDistance = Distance(From: ClosestPoint, To: NewPoint)
        let RotatedM1Distance = Distance(From: ClosestPoint, To: MinusOnePoint)
        let RotatedP1Distance = Distance(From: ClosestPoint, To: PlusOnePoint)
        print("Distance New=\(RotatedNewDistance)")
        print("         MinusOne=\(RotatedM1Distance)")
        print("         PlusOne=\(RotatedP1Distance)")
        print("         MinusOne to New=\(Distance(From: NewPoint, To: MinusOnePoint))")
        print("         PlusOne to New=\(Distance(From: NewPoint, To: PlusOnePoint))")
        
        if Distance(From: NewPoint, To: MinusOnePoint) < Distance(From: NewPoint, To: PlusOnePoint)
        {
            print("Returning Minus \(MinusOne)")
            return MinusOne
        }
        else
        {
            print("Returning Plus \(PlusOne)")
            return PlusOne
        }
        
        if RotatedM1Distance < RotatedP1Distance
        {
            if RotatedNewDistance < RotatedM1Distance
            {
                print("-Closest to Minus One")
                return MinusOne
            }
            else
            {
                print("-Closest to Plus One")
                return PlusOne
            }
        }
        else
        {
            if RotatedNewDistance < RotatedP1Distance
            {
                print("+Closest to Plus One")
                return PlusOne
            }
            else
            {
                print("+Closest to Minus One")
                return MinusOne
            }
        }
        
        #if false
        let MinusIsHigh = MinusOnePoint.y < PlusOnePoint.y
        //Be very careful to make sure which way lower Y values are!
        if NewPoint.y < ClosestPoint.y
        {
            if MinusIsHigh
            {
                Callback?("MinusIsHigh, NewPoint < ClosestPoint")
                return PlusOne//MinusOne
            }
            else
            {
                Callback?("MinusIsLow, NewPoint < ClosestPoint")
               return MinusOne//PlusOne
            }
        }
        else
        {
            if MinusIsHigh
            {
                Callback?("MinusIsHigh, NewPoint >= ClosestPoint")
                return MinusOne//PlusOne
            }
            else
            {
                Callback?("MinusIsLow, NewPoint >= ClosestPoint")
                return PlusOne//MinusOne
            }
        }
        #else
        //The first conditional determines if the new point is over or under the
        //closest point. The second condition determines which adjacent point is
        //lower. Be careful of coordinate space to make sure you take into account
        //which direction has lower Y values. In this case, lower Y values are
        //spatially "down" in the display.
        switch (NewPoint.y < ClosestPoint.y, MinusOnePoint.y < PlusOnePoint.y)
        {
            case (true, true):
                return PlusOne
                
            case (true, false):
                return MinusOne
                
            case (false, true):
                return MinusOne
                
            case (false, false):
                return PlusOne
        }
        #endif
    }
    
    func SetPointType(To: PointTypes)
    {
        PointType = To
    }
    
    func PlotSurface()
    {
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect)
    {
        let Width = rect.size.width
        let Height = rect.size.height
        var Pattern: [CGFloat] = [4.0, 2.0]
        if GridGap > 0
        {
            let VLines = UIBezierPath()
            for H in stride(from: 0, to: Width, by: CGFloat.Stride(GridGap))
            {
                VLines.move(to: CGPoint(x: H, y: 0))
                VLines.addLine(to: CGPoint(x: H, y: Height))
            }
            VLines.lineWidth = 1.0
            UIColor.orange.setStroke()
            VLines.stroke()
            let HLines = UIBezierPath()
            for V in stride(from: 0, to: Height, by: CGFloat.Stride(GridGap))
            {
                HLines.move(to: CGPoint(x: 0, y: V))
                HLines.addLine(to: CGPoint(x: Width, y: V))
            }
            HLines.lineWidth = 1.0
            UIColor.orange.setStroke()
            HLines.stroke()
        }
        
        CX = Width / 2.0
        CX = CX - fmod(CX, CGFloat(GridGap))
        CY = Height / 2.0
        CY = CY - fmod(CY, CGFloat(GridGap))
        
        let CMLine = UIBezierPath()
        CMLine.lineWidth = 3.0
        UIColor.systemTeal.setStroke()
        CMLine.move(to: CGPoint(x: CX, y: 0))
        CMLine.addLine(to: CGPoint(x: CX, y: Height))
        CMLine.move(to: CGPoint(x: 0, y: CY))
        CMLine.addLine(to: CGPoint(x: Width, y: CY))
        CMLine.setLineDash(&Pattern, count: Pattern.count, phase: 0)
        CMLine.stroke()

        if InLoopMode
        {
            DrawInLoopMode()
            return
        }
        
        var AdjustedMinusOne = CGPoint()
        var AdjustedPlusOne = CGPoint()
        var AdjustedTest = CGPoint()
        var AdjustedClosest = CGPoint()
        
        var ClosestAngle: CGFloat = 0.0
        var NormalizingAngle: CGFloat = 0.0
        var ClosestPoint = CGPoint()
        if let CP = Closest
        {
            ClosestPoint = CP
            ClosestAngle = AngleFrom(Origin: .zero,
                                     To: ClosestPoint)
            ClosestAngle = 360.0 - ClosestAngle
            ClosestAngle = ClosestAngle + 90.0
            if ClosestAngle > 360.0
            {
                ClosestAngle = ClosestAngle - 360.0
            }
            NormalizingAngle = 90.0 - ClosestAngle
        }
        
        MakePoint(MinusOne, Normalizer: NormalizingAngle,
                  Color: UIColor.systemRed, Adjusted: &AdjustedMinusOne,
                  Tag: "↓")
        
        MakePoint(PlusOne, Normalizer: NormalizingAngle,
                  Color: UIColor.systemRed, Adjusted: &AdjustedPlusOne,
                  Tag: "↑")
        
        MakePoint(TestPoint,
                  Normalizer: NormalizingAngle,
                  Color: UIColor.systemGreen, Adjusted: &AdjustedTest)
        
        if MinusOne != nil && PlusOne != nil && Decorate
        {
            var M1 = CGPoint(x: MinusOne!.x + CX,
                             y: CY - MinusOne!.y)
            var P1 = CGPoint(x: PlusOne!.x + CX,
                             y: CY - PlusOne!.y)
            if RotateFrame
            {
                M1 = M1.Rotate(By: NormalizingAngle)
                P1 = P1.Rotate(By: NormalizingAngle)
            }
            let Dec = UIBezierPath()
            Dec.move(to: M1)
            Dec.addLine(to: CGPoint(x: M1.x, y: P1.y))
            Dec.addLine(to: P1)
            Dec.addLine(to: CGPoint(x: P1.x, y: M1.y))
            Dec.addLine(to: M1)
            Dec.lineWidth = 2.0
            UIColor.black.setStroke()
            Dec.stroke()
            
            let Dec2 = UIBezierPath()
            Dec2.setLineDash(&Pattern, count: Pattern.count, phase: 0)
            Dec2.lineWidth = 2.0
            UIColor.systemIndigo.setStroke()
            Dec2.move(to: M1)
            Dec2.addLine(to: P1)
            Dec2.move(to: CGPoint(x: P1.x, y: M1.y))
            Dec2.addLine(to: CGPoint(x: M1.x, y: P1.y))
            Dec2.stroke()
            
            var P1X = PlusOne!.x + CX
            var P1Y = (CY - PlusOne!.y)
            var M1X = MinusOne!.x + CX
            var M1Y = (CY - MinusOne!.y)
            if RotateFrame
            {
                let PVal = CGPoint(x: P1X, y: P1Y).Rotate(By: NormalizingAngle)
                let MVal = CGPoint(x: M1X, y: M1Y).Rotate(By: NormalizingAngle)
                P1X = PVal.x
                P1Y = PVal.y
                M1X = MVal.x
                M1Y = MVal.y
            }
            let BiggestX = P1X > M1X ? P1X : M1X
            let BiggestY = P1Y > M1Y ? P1Y : M1Y
            let XHalf = abs(P1X - M1X) / 2
            let YHalf = abs(P1Y - M1Y) / 2
            let RX = BiggestX - XHalf
            let RY = BiggestY - YHalf
            let P = UIBezierPath(ovalIn: CGRect(x: RX - 8,
                                                y: RY - 8,
                                                width: 16,
                                                height: 16))
            P.lineWidth = 5.0
            UIColor.yellow.setStroke()
            P.stroke()
            let NiceX = "\(Int(RX))"
            let NiceY = "\(Int(RY))"
            let PrettyLabel = "(\(NiceX),\(NiceY))" as NSString
            let TextRect = CGRect(x: RX + 12.0,
                                  y: RY - 12.0,
                                  width: 120,
                                  height: 20)
            let Attributes: [NSAttributedString.Key : Any] =
            [
                .foregroundColor: UIColor.systemGray as Any,
                .font: UIFont.boldSystemFont(ofSize: 18.0) as Any
            ]
            PrettyLabel.draw(in: TextRect, withAttributes: Attributes)
        }
        
        MakePoint(Closest, Normalizer: NormalizingAngle,
                  Color: UIColor.systemBlue, Adjusted: &AdjustedClosest)
        
        if RotateFrame
        {
            if MinusOne != nil && PlusOne != nil
            {
                let M1Line = UIBezierPath()
                M1Line.lineWidth = 2
                UIColor.systemIndigo.setStroke()
                M1Line.move(to: CGPoint(x: 0, y: AdjustedMinusOne.y))
                M1Line.addLine(to: CGPoint(x: Width, y: AdjustedMinusOne.y))
                M1Line.stroke()
                let P1Line = UIBezierPath()
                P1Line.lineWidth = 2
                UIColor.systemIndigo.setStroke()
                P1Line.move(to: CGPoint(x: 0, y: AdjustedPlusOne.y))
                P1Line.addLine(to: CGPoint(x: Width, y: AdjustedPlusOne.y))
                P1Line.stroke()
            }
            let HLine = UIBezierPath()
            HLine.lineWidth = 4.0
            UIColor.systemIndigo.setStroke()
            HLine.move(to: CGPoint(x: 0, y: AdjustedClosest.y))
            HLine.addLine(to: CGPoint(x: Width, y: AdjustedClosest.y))
            HLine.stroke()
        }
        
        if TestPoint != nil && RotateFrame
        {
            //See if the previous point is higher (closer to the top) than the
            //succeeding point.
            let MinusIsHigh = AdjustedMinusOne.y < AdjustedPlusOne.y
            if AdjustedTest.y < AdjustedClosest.y
            {
                if MinusIsHigh
                {
                    DrawLine(From: AdjustedTest, To: AdjustedMinusOne)
                    Callback?("Between Minus 1 and Closest {A}")
                }
                else
                {
                    DrawLine(From: AdjustedTest, To: AdjustedPlusOne)
                    Callback?("Between Plus 1 and Closest {A}")
                }
            }
            else
            {
                if MinusIsHigh
                {
                    DrawLine(From: AdjustedTest, To: AdjustedPlusOne)
                    Callback?("Between Plus 1 and Closest {B}")
                }
                else
                {
                    DrawLine(From: AdjustedTest, To: AdjustedMinusOne)
                    Callback?("Between Minus 1 and Closest {B}")
                }
            }
        }
        
        if ShowDistances
        {
            if TestPoint != nil && Closest != nil && MinusOne != nil && PlusOne != nil
            {
                let Dist = UIBezierPath()
                Dist.lineWidth = 2.0
                UIColor.gray.setStroke()
                Dist.move(to: AdjustedClosest)
                Dist.addLine(to: AdjustedPlusOne)
                Dist.move(to: AdjustedClosest)
                Dist.addLine(to: AdjustedMinusOne)
                Dist.move(to: AdjustedClosest)
                Dist.addLine(to: AdjustedTest)
                Dist.move(to: AdjustedTest)
                Dist.addLine(to: AdjustedPlusOne)
                Dist.move(to: AdjustedTest)
                Dist.addLine(to: AdjustedMinusOne)
                Dist.stroke()
                
                let (MidTM, TMinusDistance) = HalfWay(Between: AdjustedTest, And: AdjustedMinusOne)
                let (MidPM, TPlusDistance) = HalfWay(Between: AdjustedTest, And: AdjustedPlusOne)
                let (MidMinus, MinusDistance) = HalfWay(Between: AdjustedClosest, And: AdjustedMinusOne)
                let (MidPlus, PlusDistance) = HalfWay(Between: AdjustedClosest, And: AdjustedPlusOne)
                let (MidNew, NewDistance) = HalfWay(Between: AdjustedClosest, And: AdjustedTest)
                
                let MinusRect = CGRect(x: MidMinus.x + 12.0,
                                       y: MidMinus.y - 12.0,
                                       width: 100,
                                       height: 20)
                let Attributes: [NSAttributedString.Key : Any] =
                [
                    .foregroundColor: UIColor.cyan as Any,
                    .font: UIFont.boldSystemFont(ofSize: 18.0) as Any
                ]
                let MinusLabel = "\(Int(MinusDistance))"
                MinusLabel.draw(in: MinusRect, withAttributes: Attributes)
                
                let PlusRect = CGRect(x: MidPlus.x + 12.0,
                                      y: MidPlus.y - 12.0,
                                      width: 100,
                                      height: 20)
                let PlusLabel = "\(Int(PlusDistance))"
                PlusLabel.draw(in: PlusRect, withAttributes: Attributes)
                
                let TestRect = CGRect(x: MidNew.x + 12.0,
                                      y: MidNew.y - 12.0,
                                      width: 100,
                                      height: 20)
                let TestLabel = "\(Int(NewDistance))"
                TestLabel.draw(in: TestRect, withAttributes: Attributes)
                
                let TestToMinusRect = CGRect(x: MidTM.x + 12.0,
                                      y: MidTM.y - 12.0,
                                      width: 100,
                                      height: 20)
                let TMLabel = "\(Int(TMinusDistance))"
                TMLabel.draw(in: TestToMinusRect, withAttributes: Attributes)
                
                let TestToPlusRect = CGRect(x: MidPM.x + 12.0,
                                             y: MidPM.y - 12.0,
                                             width: 100,
                                             height: 20)
                let PMLabel = "\(Int(TPlusDistance))"
                PMLabel.draw(in: TestToPlusRect, withAttributes: Attributes)
            }
        }
    }
    
    func DrawLine(From Point1: CGPoint, To Point2: CGPoint, Width: CGFloat = 4,
                  Color: UIColor = UIColor.red.withAlphaComponent(0.65),
                  AdjustPoints: Bool = false)
    {
        let Line = UIBezierPath()
        if AdjustPoints
        {
            let AdjustedX1 = Point1.x + CX
            let AdjustedY1 = (CY - Point1.y)
            let Adjusted1 = CGPoint(x: AdjustedX1, y: AdjustedY1)
            let AdjustedX2 = Point2.x + CX
            let AdjustedY2 = (CY - Point2.y)
            let Adjusted2 = CGPoint(x: AdjustedX2, y: AdjustedY2)
            Line.move(to: Adjusted1)
            Line.addLine(to: Adjusted2)
        }
        else
        {
            Line.move(to: Point1)
            Line.addLine(to: Point2)
        }
        Line.lineWidth = Width
        Color.setStroke()
        Line.stroke()
    }
    
    func MakePoint(_ DrawPoint: CGPoint?, Normalizer: CGFloat,
                   Color: UIColor, Adjusted: inout CGPoint,
                   Tag: String = "", TrailingTag: String? = nil)
    {
        if var Point = DrawPoint
        {
            if RotateFrame
            {
                Point = Point.Rotate(By: Normalizer)
            }
            let AdjustedX = Point.x + CX
            let AdjustedY = (CY - Point.y)
            Adjusted = CGPoint(x: AdjustedX, y: AdjustedY)
            let P = UIBezierPath(ovalIn: CGRect(x: AdjustedX - 8,
                                                y: AdjustedY - 8,
                                                width: 16,
                                                height: 16))
            P.lineWidth = 5.0
            Color.setStroke()
            P.stroke()
            let NiceX = "\(Int(Point.x))"
            let NiceY = "\(Int(Point.y))"
            var Trailing = ""
            if let TrailingValue = TrailingTag
            {
                Trailing = TrailingValue
            }
            let PrettyLabel = "\(Tag)(\(NiceX),\(NiceY))\(Trailing)" as NSString
            let TextRect = CGRect(x: AdjustedX + 12.0,
                                  y: AdjustedY - 12.0,
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
    
    func MakePoint2(_ DrawPoint: CGPoint, Color: UIColor, Tag: String = "",
                    TrailingTag: String? = nil)
    {
        let Point = DrawPoint
        let P = UIBezierPath(ovalIn: CGRect(x: Point.x - 8,
                                            y: Point.y - 8,
                                            width: 16,
                                            height: 16))
        P.lineWidth = 5.0
        Color.setStroke()
        P.stroke()
        let NiceX = "\(Int(Point.x))"
        let NiceY = "\(Int(Point.y))"
        var Trailing = ""
        if let FinalTag = TrailingTag
        {
            Trailing = " \(FinalTag)"
        }
            let PrettyLabel = "\(Tag)(\(NiceX),\(NiceY)\(Trailing)" as NSString
        let TextRect = CGRect(x: Point.x + 12.0,
                              y: Point.y - 12.0,
                              width: 200,
                              height: 20)
        let Attributes: [NSAttributedString.Key : Any] =
        [
            .foregroundColor: Color as Any,
            .font: UIFont.boldSystemFont(ofSize: 18.0) as Any
        ]
        PrettyLabel.draw(in: TextRect, withAttributes: Attributes)
    }
    
    /// Returns the angle between two points in degrees.
    /// - Note: [Angle between two points](https://stackoverflow.com/questions/6064630/get-angle-from-2-positions)
    /// - Important: 0° points due east.
    /// - Parameter Origin: The point that acts as the origin.
    /// - Parameter To: The point that is not the origin.
    /// - Returns: The angle, in degrees, between the two passed points.
    func AngleFrom(Origin: CGPoint, To Other: CGPoint) -> CGFloat
    {
        let OriginX = Other.x - Origin.x
        let OriginY = Other.y - Origin.y
        let BearingRadians = atan2f(Float(OriginY), Float(OriginX))
        var BearingDegrees = CGFloat(BearingRadians) * 180.0 / CGFloat.pi
        
        while BearingDegrees < 0
        {
            BearingDegrees += 360
        }
        
        return BearingDegrees
    }
    
    func HalfWay(Between Point1: CGPoint, And Point2: CGPoint) -> (CGPoint, CGFloat)
    {
        let Distance = hypot(Point1.x - Point2.x, Point1.y - Point2.y)
        let Mid = Point1.MidPoint(To: Point2)
        return (Mid, Distance)
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
    
    func DrawInLoopMode()
    {
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
                let Angle = Angle3(Point2: OriginalPoints[Previous],
                                   Point3: OriginalPoints[Next])
                PointAngles.append(Angle)
                let Degrees = Angle * 180.0 / CGFloat.pi
                //print("[\(Previous)]=\(OriginalPoints[Previous])")
                //print("[\(Index)]=\(OriginalPoints[Index]) Angle at index \(Index) = Int(\(Degrees))°")
                //print("[\(Next)]=\(OriginalPoints[Next])\n")
                let LinePath = UIBezierPath()
                let VP = CGPoint(x: OriginalPoints[Index].x + CX,
                                 y: CY - OriginalPoints[Index].y)
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
                UIColor.yellow.setStroke()
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
            MakePoint2(NewSpot, Color: UIColor.systemPurple, Tag: "▲ ",
            TrailingTag: Trailing)
            if let ClosestSpot = MClosest
            {
                DrawLine(From: NewSpot,
                         To: OriginalPoints[ClosestSpot],
                         Width: 4.0,
                         Color: UIColor.white,
                         AdjustPoints: false)
            }
        }
        for Index in 0 ..< OriginalPoints.count
        {
            let LastIndex = Index == OriginalPoints.count - 1 ? 0 : Index + 1
            DrawLine(From: OriginalPoints[Index],
                     To: OriginalPoints[LastIndex],
                     Width: 2.5,
                     Color: UIColor.systemIndigo,
            AdjustPoints: true)
        }
        var Index = 0
        for Point in OriginalPoints
        {
            var Unused = CGPoint()
            var Degree = PointAngles[Index] * 180.0 / CGFloat.pi
            MakePoint(Point,
                      Normalizer: 0.0,
                      Color: UIColor.systemIndigo,
                      Adjusted: &Unused,
                      Tag: "\(Index) ",
            TrailingTag: " \(Int(Degree))°")
            Index = Index + 1
        }
        
       
    }
    
    func RadialPoint(Center: CGPoint, Angle: CGFloat, Radius: CGFloat) -> CGPoint
    {
        let Radians = Angle * CGFloat.pi / 180.0
        let X = Radius * cos(Radians)
        let Y = Radius * sin(Radians)
        return CGPoint(x: X + Center.x, y: Y + Center.y)
    }
    
    var PointAngles = [CGFloat]()
    
    func Angle3(Point2: CGPoint, Point3: CGPoint) -> CGFloat
    {
        let A = Point2.x - Point3.x
        let B = Point2.y - Point3.y
        let Angle = atan2(A, B)
        return Angle
    }
}

extension CGPoint
{
    func Angle(To: CGPoint) -> CGFloat
    {
        return 0.0
    }
    
    func Rotate(By Degrees: CGFloat) -> CGPoint
    {
        let Radians = Degrees * CGFloat.pi / 180.0
        let NewX = self.x * cos(Radians) - self.y * sin(Radians)
        let NewY = self.x * sin(Radians) + self.y * cos(Radians)
        return CGPoint(x: NewX, y: NewY)
    }
    
    func WithOffset(_ X: CGFloat, _ Y: CGFloat) -> CGPoint
    {
        return CGPoint(x: self.x + X, y: self.y + Y)
    }
    
    func MidPoint(To: CGPoint) -> CGPoint
    {
        return CGPoint(x: (self.x + To.x) / 2.0,
                       y: (self.y + To.y) / 2.0)
    }
}
