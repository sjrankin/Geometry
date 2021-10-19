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
        PointPicker.layer.cornerRadius = 5.0
        PointPicker.layer.borderColor = UIColor.gray.cgColor
        PointPicker.layer.borderWidth = 1.0
        CallbackLabel.text = ""
        LoopDataContainer.layer.borderColor = UIColor.gray.cgColor
        LoopDataContainer.layer.borderWidth = 1.0
        LoopDataContainer.layer.cornerRadius = 5.0
        LoopDataContainer.isHidden = true
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
            DrawSurface.Initialize(FromSurface, NewPoint)
            DrawSurface.PlotSurface()
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
    }
    
    @IBAction func RotateButtonHandler(_ sender: Any)
    {
        DrawSurface.RotateFrame = !DrawSurface.RotateFrame
        PointPicker.isHidden = DrawSurface.RotateFrame
        DrawSurface.PlotSurface()
    }
    
    @IBAction func DistanceButtonHandler(_ sender: Any)
    {
        DrawSurface.ShowDistances = !DrawSurface.ShowDistances
        DrawSurface.PlotSurface()
    }
    
    @IBAction func InsertLoopHandler(_ sender: Any)
    {
        ClearButtonHandler(sender)
        ClearNewPointData()
        DrawSurface.InLoopMode = !DrawSurface.InLoopMode
        PointPicker.isHidden = DrawSurface.InLoopMode
        LoopDataContainer.isHidden = !DrawSurface.InLoopMode
        if !DrawSurface.InLoopMode
        {
            return
        }
        OriginalPoints.removeAll()
#if true
        OriginalPoints.append(CGPoint(x: 0, y: 150))
        OriginalPoints.append(CGPoint(x: -150, y: -150.0))
        OriginalPoints.append(CGPoint(x: 150, y: -150.0))
        #else
        OriginalPoints.append(CGPoint(x: -150, y: -150))
        OriginalPoints.append(CGPoint(x: 150, y: -150))
        OriginalPoints.append(CGPoint(x: 150, y: 150))
        OriginalPoints.append(CGPoint(x: -150, y: 150))
        #endif
        DrawSurface.OriginalPoints = OriginalPoints
        DrawSurface.PlotSurface()
    }
    
    var OriginalPoints = [CGPoint]()
    
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
}

enum PointTypes: String, CaseIterable
{
    case None = "None"
    case Closest = "Closest Point"
    case Minus1 = "Index - 1"
    case Plus1 = "Index + 1"
    case Test = "Test Point"
}
