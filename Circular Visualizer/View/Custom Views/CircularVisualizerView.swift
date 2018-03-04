//
//  CircularVisualizerView.swift
//  Circular Visualizer
//
//  Created by Alwin Lazar on 04/03/18.
//  Copyright © 2018 zaconic. All rights reserved.
//

import UIKit

class CircularVisualizerView: UIView {

    let animateDuration = 0.30
    let visualizerColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    var barsNumber = 0
    let barWidth = 4 // width of bar
    let radius: CGFloat = 40
    
    var radians = [CGFloat]()
    var barPoints = [CGPoint]()
    
    private var rectArray = [UIView]()
    private var waveFormArray = [Int]()
    private var initialBarHeight: CGFloat = 0.0
    
    private let mainLayer: CALayer = CALayer()
    
    // draw circle
    var midViewX: CGFloat!
    var midViewY: CGFloat!
    var circlePath = UIBezierPath()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        self.layer.addSublayer(mainLayer)
        barsNumber = 30
    }
    
    override func layoutSubviews() {
        mainLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        drawVisualizer()
    }
    
    //-----------------------------------------------------------------
    // MARK: - Drawing Section
    //-----------------------------------------------------------------
    
    func drawVisualizer() {
        midViewX = self.mainLayer.frame.midX
        midViewY = self.mainLayer.frame.midY
        
        // Draw Circle
        let arcCenter = CGPoint(x: midViewX, y: midViewY)
        let circlePath = UIBezierPath(arcCenter: arcCenter, radius: radius, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
        let circleShapeLayer = CAShapeLayer()
        
        circleShapeLayer.path = circlePath.cgPath
        circleShapeLayer.fillColor = #colorLiteral(red: 0.5490196078, green: 0.8129847646, blue: 0.6160266995, alpha: 0.5).cgColor
        circleShapeLayer.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        circleShapeLayer.lineWidth = 1.0
        mainLayer.addSublayer(circleShapeLayer)
        
        // This will ensure to only add the bars once:
        guard rectArray.count == 0 else { return } // If we already have bars, just return
        
        // Draw Bars
        rectArray = [UIView]()
        
        for i in 0..<barsNumber {
            let angle = ((360 / barsNumber) * i) - 90
            let point = calculatePoints(angle: angle, radius: radius)
            let radian = angle.degreesToRadians
            radians.append(radian)
            barPoints.append(point)
            
            let rectangle = UIView(frame: CGRect(x: barPoints[i].x, y: barPoints[i].y, width: CGFloat(barWidth), height: CGFloat(barWidth)))
            
            initialBarHeight = CGFloat(self.barWidth)
            print("BEFORE : width: \(rectangle.frame.width), height: \(rectangle.frame.height)")
            rectangle.setAnchorPoint(anchorPoint: CGPoint.zero)
            let rotationAngle = (CGFloat(( 360/barsNumber) * i)).degreesToRadians + 180.degreesToRadians
            
            rectangle.transform = CGAffineTransform(rotationAngle: rotationAngle)
            
            print("AFTER : width: \(rectangle.frame.width), height: \(rectangle.frame.height)")
            rectangle.backgroundColor = visualizerColor
            rectangle.layer.cornerRadius = CGFloat(rectangle.bounds.width / 2)
            rectangle.tag = i
            self.addSubview(rectangle)
            rectArray.append(rectangle)
            
            var values = [5, 10, 15, 10, 5, 1]
            waveFormArray = [Int]()
            var j: Int = 0
            for _ in 0..<barsNumber {
                waveFormArray.append(values[j])
                j += 1
                if j == values.count {
                    j = 0
                }
            }
        }
    }
    
    //-----------------------------------------------------------------
    // MARK: - Animation Section
    //-----------------------------------------------------------------
    
    func animateAudioVisualizerWithChannel(level0: Float, level1: Float ) {
        DispatchQueue.main.async {
            UIView.animateKeyframes(withDuration: self.animateDuration, delay: 0, options: .beginFromCurrentState, animations: {
                
                for i in 0..<self.barsNumber {
                    let channelValue: Int = Int(arc4random_uniform(2))
                    
                    let wavePeak: Int = Int(arc4random_uniform(UInt32(self.waveFormArray[i])))
                    let barViewUn: UIView = self.rectArray[i]
                    
                    let barH = (self.frame.height / 2 ) - self.radius
                    let scaled0 = (CGFloat(level0) * barH) / 60
                    let scaled1 = (CGFloat(level1) * barH) / 60
                    let calc0 = barH - scaled0
                    let calc1 = barH - scaled1
                    
                    if channelValue == 0 {
                        barViewUn.bounds.size.height = calc0
                    } else {
                        barViewUn.bounds.size.height = calc1
                    }
                    
                    if barViewUn.bounds.height < CGFloat(4) || barViewUn.bounds.height > ((self.bounds.size.height / 2) - self.radius) {
                        barViewUn.bounds.size.height = self.initialBarHeight + CGFloat(wavePeak)
                    }
                }
                
            }, completion: nil)
        }
    }
    
    
    func stop() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: self.animateDuration, delay: 0, options: .beginFromCurrentState, animations: {
                for i in 0..<self.barsNumber {
                    let barView = self.rectArray[i]
                    barView.bounds.size.height = self.initialBarHeight
                    barView.bounds.origin.y = 120 - barView.bounds.size.height
                }
            }, completion: nil)
        }
    }
    
    func calculatePoints(angle: Int, radius: CGFloat) -> CGPoint {
        let barX = midViewX + cos((angle).degreesToRadians) * radius
        let barY = midViewY + sin((angle).degreesToRadians) * radius
        
        return CGPoint(x: barX, y: barY)
    }
}

//-----------------------------------------------------------------
// MARK: - Extesnsions
//-----------------------------------------------------------------

extension BinaryInteger {
    var degreesToRadians: CGFloat { return CGFloat(Int(self)) * .pi / 180 }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension UIView {
    func setAnchorPoint(anchorPoint: CGPoint) {
        
        var newPoint = CGPoint(x: self.bounds.size.width * anchorPoint.x, y: self.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPoint(x: self.bounds.size.width * self.layer.anchorPoint.x, y: self.bounds.size.height * self.layer.anchorPoint.y)
        
        newPoint = newPoint.applying(self.transform)
        oldPoint = oldPoint.applying(self.transform)
        
        var position : CGPoint = self.layer.position
        
        position.x -= oldPoint.x
        position.x += newPoint.x;
        
        position.y -= oldPoint.y;
        position.y += newPoint.y;
        
        self.layer.position = position;
        self.layer.anchorPoint = anchorPoint;
    }
}

extension UIView {
    /// Helper to get pre transform frame
    var originalFrame: CGRect {
        let currentTransform = transform
        transform = .identity
        let originalFrame = frame
        transform = currentTransform
        return originalFrame
    }
    
    /// Helper to get point offset from center
    func centerOffset(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x - center.x, y: point.y - center.y)
    }
    
    /// Helper to get point back relative to center
    func pointRelativeToCenter(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x + center.x, y: point.y + center.y)
    }
    
    /// Helper to get point relative to transformed coords
    func newPointInView(_ point: CGPoint) -> CGPoint {
        // get offset from center
        let offset = centerOffset(point)
        // get transformed point
        let transformedPoint = offset.applying(transform)
        // make relative to center
        return pointRelativeToCenter(transformedPoint)
    }
    
    var newTopLeft: CGPoint {
        return newPointInView(originalFrame.origin)
    }
    
    var newTopRight: CGPoint {
        var point = originalFrame.origin
        point.x += originalFrame.width
        return newPointInView(point)
    }
    
    var newBottomLeft: CGPoint {
        var point = originalFrame.origin
        point.y += originalFrame.height
        return newPointInView(point)
    }
    
    var newBottomRight: CGPoint {
        var point = originalFrame.origin
        point.x += originalFrame.width
        point.y += originalFrame.height
        return newPointInView(point)
    }
}
