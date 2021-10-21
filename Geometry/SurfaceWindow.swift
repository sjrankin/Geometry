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
            if RotateFrame
            {
                self.backgroundColor = UIColor.white
            }
            else
            {
                self.backgroundColor = UIColor.systemYellow
            }
        }
    }
    
    var OriginalPoints = [CGPoint]()
    var ShowDistances: Bool = false
    var Decorate: Bool = false
    var Closest: CGPoint? = nil
    var MinusOne: CGPoint? = nil
    var PlusOne: CGPoint? = nil
    var TestPoint: CGPoint? = nil
    var PointType: PointTypes = .None
    var Callback: Messages? = nil
    
    typealias Messages = (String) -> ()
    func Initialize(_ Callback: Messages? = nil)
    {
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
        if RotateFrame
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
    
    func ClosestTo(Point: CGPoint) -> (PointIndex: Int, PointDistance: CGFloat)?
    {
        if OriginalPoints.isEmpty
        {
            return nil
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
        return (ClosestIndex, PDistance)
    }
    
    @objc func HandleTaps(_ Recognizer: UITapGestureRecognizer)
    {
        if RotateFrame
        {
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
        self.backgroundColor = UIColor.systemYellow
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
        let NiceX = "\(Int(Point.x - CX))"
        let NiceY = "\(Int(CY - Point.y))"
        var Trailing = ""
        if let FinalTag = TrailingTag
        {
            Trailing = " \(FinalTag)"
        }
        let PrettyLabel = "\(Tag)(\(NiceX),\(NiceY))\(Trailing)" as NSString
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
