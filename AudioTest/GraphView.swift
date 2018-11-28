//
//  GraphView.swift
//  AudioTest
//
//  Created by hirochin on 08/12/2017.
//  Copyright © 2017 Thel. All rights reserved.
//

import Cocoa

class GraphView: NSView {
    
    var data: [Float] = []

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        let context = NSGraphicsContext.current?.cgContext
        drawGraphInContext(context: context, rect: self.bounds)
    }
    
    private func drawGraphInContext(context: CGContext?, rect: CGRect) -> () {
        let path = CGMutablePath()

        for (i, v) in data.enumerated() {
            let width = rect.width / CGFloat(data.count)
            let height = rect.height * CGFloat(fabs(v))
            let x = CGFloat(i) * width
            let y: CGFloat = 0//v > 0 ? rect.height / 2 : rect.height / 2 - height
            path.addRect(CGRect(x: x, y: y, width: width, height: height))
        }

        context?.setLineWidth(1.0)
        context?.setFillColor(CGColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0))
        
        context?.addPath(path)
        context?.drawPath(using: .fillStroke)
    }
    
}
