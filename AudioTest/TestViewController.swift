//
//  TestViewController.swift
//  AudioTest
//
//  Created by hirochin on 2018/11/26.
//  Copyright © 2018 Thel. All rights reserved.
//

import Accelerate
import Cocoa

class TestViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
     
        matrixMultiplyTest()
    }
    
    func matrixMultiplyTest() -> () {
        var a: [Float] = [1,2,3,4,5]
        var b: [Float] = [0,0,1,0,0]
        let c = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        
        vDSP_mmul(&a, vDSP_Stride(1), &b, vDSP_Stride(1), c, vDSP_Stride(1), 1, 1, 5)
        
        print(c.pointee)
        assert(c.pointee == 3)
    }
    
}
