//
//  TestViewController.swift
//  AudioTest
//
//  Created by hirochin on 2018/11/26.
//  Copyright © 2018 Thel. All rights reserved.
//

import Cocoa

class TestViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        print(Int16.max)
        
        let fft = FFT_example()
        
        let n = 512 // Should be power of two for the FFT
        let frequency1 = 4.0
        let phase1 = 0.0
        let amplitude1 = 8.0
        let seconds = 2.0
        let fps = Double(n)/seconds
        
        // x1 =np.sin(15 * np.pi * t1)
        let sineWave = (0..<n).map {
//            amplitude1 *
                sin(2.0 * .pi * Double($0) / fps * frequency1 + phase1)
        }
        
        fft.calculate(sineWave, fps: fps)
//        let sineWave2 = (0..<n).map {
//            sin(2.0 * .pi * Double($0) / Double(fps * frequency1))
//        }
        let xs = FFT.fft(sineWave, sampleRate: Int(fps))
        print(xs)
    }
    
}
