//
//  ViewController.swift
//  Geometry
//
//  Created by Stuart Rankin on 10/16/21.
//

import Foundation
import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        DrawSurface.layer.cornerRadius = 5.0
        DrawSurface.layer.borderColor = UIColor.gray.cgColor
        DrawSurface.layer.borderWidth = 1.0
        DrawSurface.layer.zPosition = 1000
        DrawSurface.isUserInteractionEnabled = true
        PointPicker.layer.cornerRadius = 5.0
        PointPicker.layer.borderColor = UIColor.gray.cgColor
        PointPicker.layer.borderWidth = 1.0
        CallbackLabel.text = ""
        LoopDataContainer.layer.borderColor = UIColor.gray.cgColor
        LoopDataContainer.layer.borderWidth = 1.0
        LoopDataContainer.layer.cornerRadius = 5.0
        LoopDataContainer.isHidden = true
        LoopDrawSurface.layer.cornerRadius = 5.0
        LoopDrawSurface.layer.borderColor = UIColor.gray.cgColor
        LoopDrawSurface.layer.borderWidth = 1.0
        LoopDrawSurface.layer.zPosition = -1000
        LoopDrawSurface.isUserInteractionEnabled = false
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        let TapType = PointTypes.allCases[row]
        DrawSurface.SetPointType(To: TapType)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return PointTypes.allCases[row].rawValue
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return PointTypes.allCases.count
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        if !DidInitialSetup
        {
            DidInitialSetup = true
            DrawSurface.Initialize(FromSurface)
            DrawSurface.PlotSurface()
            
            LoopDrawSurface.Initialize(LoopDataCallback: NewPoint, FromSurface)
            LoopDrawSurface.PlotSurface()
        }
    }
    
    func FromSurface(_ Message: String)
    {
        CallbackLabel.text = Message
    }
    
    func NewPoint(Coordinates: CGPoint, ClosestIndex: Int, MinusOneIndex: Int,
                  PlusOneIndex: Int, Inbetween: (Int, Int),
                  M1ToNew: CGFloat, P1ToNew: CGFloat)
    {
        ClearNewPointData()
        InbetweenLabel.text = "[\(Inbetween.0)] ⌁ [\(Inbetween.1)]"
        PlusOneLabel.text = "\(PlusOneIndex)"
        MinusOneLabel.text = "\(MinusOneIndex)"
        ClosestIndexLabel.text = "\(ClosestIndex)"
        NewPointCoordinateLabel.text = "(\(Int(Coordinates.x)),\(Int(Coordinates.y)))"
        NewToP1Label.text = "\(Int(P1ToNew))"
        NewToM1Label.text = "\(Int(M1ToNew))"
    }
    
    func ClearNewPointData()
    {
        InbetweenLabel.text = ""
        PlusOneLabel.text = ""
        MinusOneLabel.text = ""
        ClosestIndexLabel.text = ""
        NewPointCoordinateLabel.text = ""
        NewToP1Label.text = ""
        NewToM1Label.text = ""
    }
    
    var DidInitialSetup = false
    var GridGap = 16
    
    @IBAction func DecorateButtonHandler(_ sender: Any)
    {
        DrawSurface.Decorate = !DrawSurface.Decorate
        DrawSurface.PlotSurface()
    }
    
    @IBAction func ClearButtonHandler(_ sender: Any)
    {
        DrawSurface.OriginalPoints.removeAll()
        DrawSurface.Closest = nil
        DrawSurface.MinusOne = nil
        DrawSurface.PlusOne = nil
        DrawSurface.TestPoint = nil
        DrawSurface.RotateFrame = false
        DrawSurface.PlotSurface()
        
        LoopDrawSurface.OriginalPoints.removeAll()
        LoopDrawSurface.MClosest = nil
        LoopDrawSurface.MLocation = nil
        LoopDrawSurface.NewestIndex = -1
        LoopDrawSurface.HighlightIndex = nil
        LoopDrawSurface.RotateFrame = false
        LoopDrawSurface.Rect1 = nil
        LoopDrawSurface.Rect2 = nil
        LoopDrawSurface.NewPointRect = nil
        LoopDrawSurface.PlotSurface()
    }
    
    @IBAction func RotateButtonHandler(_ sender: Any)
    {
        if InLoopMode
        {
            LoopDrawSurface.RotateFrame = !LoopDrawSurface.RotateFrame
        }
        else
        {
            DrawSurface.RotateFrame = !DrawSurface.RotateFrame
            PointPicker.isHidden = DrawSurface.RotateFrame
            DrawSurface.PlotSurface()
        }
    }
    
    @IBAction func DistanceButtonHandler(_ sender: Any)
    {
        DrawSurface.ShowDistances = !DrawSurface.ShowDistances
        DrawSurface.PlotSurface()
    }
    
    var InLoopMode: Bool = false
    
    @IBAction func ModeButtonHandler(_ sender: Any)
    {
        InLoopMode = !InLoopMode
        let Title = InLoopMode ? "3 Point Mode" : "Loop Mode"
        LoopModeButton.setTitle(Title, for: .normal)
        DrawSurface.isUserInteractionEnabled = !InLoopMode
        DrawSurface.layer.zPosition = InLoopMode ? -1000 : 1000
        LoopDrawSurface.isUserInteractionEnabled = InLoopMode
        LoopDrawSurface.layer.zPosition = InLoopMode ? 1000 : -1000
        
        if InLoopMode
        {
            LoopDrawSurface.MLocation = nil
            LoopDrawSurface.MAngle = nil
            LoopDrawSurface.MClosest = nil
            LoopDrawSurface.OriginalPoints.removeAll()
            LoopDrawSurface.PlotSurface()
        }
        else
        {
        ClearButtonHandler(sender)
        ClearNewPointData()
            DrawSurface.OriginalPoints.removeAll()
        PointPicker.isHidden = InLoopMode
        LoopDataContainer.isHidden = !InLoopMode
            DrawSurface.PlotSurface()
        }
    }
    
    @IBAction func ShapeSegmentChangeHandler(_ sender: Any)
    {
        if !InLoopMode
        {
            print("Not in loop mode")
            return
        }
        
        LoopDrawSurface.MClosest = nil
        LoopDrawSurface.NewestIndex = -1
        LoopDrawSurface.HighlightIndex = nil
        LoopDrawSurface.RotateFrame = false
        
        let CenterX = LoopDrawSurface.frame.size.width / 2.0
        let CenterY = LoopDrawSurface.frame.size.height / 2.0
        let Center = CGPoint(x: CenterX, y: CenterY)
        switch SideCount.selectedSegmentIndex
        {
            case 0: //3 sides
                OriginalPoints = RadialPoints(Center: Center, Radius: 150.0, Count: 3)
                
            case 1: //4 sides
                OriginalPoints = RadialPoints(Center: Center, Radius: 150.0, Count: 4)
                
            case 2: //4 sides rotated 90°
                OriginalPoints.removeAll()
                OriginalPoints.append(CGPoint(x: CenterX - 150, y: CenterY - 150))
                OriginalPoints.append(CGPoint(x: CenterX + 150, y: CenterY - 150))
                OriginalPoints.append(CGPoint(x: CenterX + 150, y: CenterY + 150))
                OriginalPoints.append(CGPoint(x: CenterX - 150, y: CenterY + 150))
                
            case 3: //5 sides
                OriginalPoints = RadialPoints(Center: Center, Radius: 150.0, Count: 5)
                
            case 4: //6 sides
                OriginalPoints = RadialPoints(Center: Center, Radius: 150.0, Count: 6)
                
            case 5: //7 sides
                OriginalPoints = RadialPoints(Center: Center, Radius: 150.0, Count: 7)
                
            case 6: //8 sides
                OriginalPoints = RadialPoints(Center: Center, Radius: 150.0, Count: 8)
                
            case 7: //9 sides
                OriginalPoints = RadialPoints(Center: Center, Radius: 150.0, Count: 9)
                
            case 8: //random points
                let RCount = Int.random(in: 6 ... 10)
                OriginalPoints.removeAll()
                let Increment = 360.0 / CGFloat(RCount)
                for Index in 0 ..< RCount
                {
                    var RRadius = 150
                    RRadius = RRadius + Int.random(in: -10 ... 10)
                    var Radial = Increment * CGFloat(Index)
                    Radial = Radial + CGFloat.random(in: -Increment * 0.3 ... Increment * 0.3)
                    Radial = Radial * CGFloat.pi / 180.0
                    let Point = RadialPoint(Center: Center,
                                            Radius: CGFloat(RRadius),
                                            Radial: Radial)
                    OriginalPoints.append(Point)
                }
                
            default:
                return
        }
        
        LoopDrawSurface.OriginalPoints = OriginalPoints
        LoopDrawSurface.PlotSurface()
    }
    
    func RadialPoints(Center: CGPoint, Radius: CGFloat, Count: Int) -> [CGPoint]
    {
        var Points = [CGPoint]()
        if Count < 3
        {
            return Points
        }
        let AngleIncrement = 360.0 / CGFloat(Count)
        for Index in 0 ..< Count
        {
            let Degrees = AngleIncrement * CGFloat(Index)
            let Radians = Degrees * CGFloat.pi / 180.0
            let X = Radius * cos(Radians)
            let Y = Radius * sin(Radians)
            let Point = CGPoint(x: X + Center.x, y: Y + Center.y)
            Points.append(Point)
        }
        return Points
    }
    
    func RadialPoint(Center: CGPoint, Radius: CGFloat, Radial: CGFloat) -> CGPoint
    {
        let X = Radius * cos(Radial)
        let Y = Radius * sin(Radial)
        let Point = CGPoint(x: X + Center.x, y: Y + Center.y)
        return Point
    }
    
    var OriginalPoints = [CGPoint]()
    
    @IBOutlet weak var LoopModeButton: UIButton!
    @IBOutlet weak var SideCount: UISegmentedControl!
    @IBOutlet weak var NewToP1Label: UILabel!
    @IBOutlet weak var NewToM1Label: UILabel!
    @IBOutlet weak var InbetweenLabel: UILabel!
    @IBOutlet weak var PlusOneLabel: UILabel!
    @IBOutlet weak var MinusOneLabel: UILabel!
    @IBOutlet weak var ClosestIndexLabel: UILabel!
    @IBOutlet weak var NewPointCoordinateLabel: UILabel!
    @IBOutlet weak var LoopDataContainer: UIView!
    @IBOutlet weak var CallbackLabel: UILabel!
    @IBOutlet weak var PointPicker: UIPickerView!
    @IBOutlet weak var DrawSurface: SurfaceWindow!
    @IBOutlet weak var LoopDrawSurface: LoopSurfaceWindow!
}

enum PointTypes: String, CaseIterable
{
    case None = "None"
    case Closest = "Closest Point"
    case Minus1 = "Index - 1"
    case Plus1 = "Index + 1"
    case Test = "Test Point"
}
