//
//  fft.swift
//  AudioTest
//
//  Created by hirochin on 2018/11/26.
//  Copyright © 2018 Thel. All rights reserved.
//

import Accelerate
import Foundation


struct FFT {
    static func fft(_ xs: [Double], sampleRate: Int) -> [Double] {
        let N = xs.count
        let N2 = vDSP_Length(N/2)
        let LOG_N = vDSP_Length(log2(Float(xs.count)))
        
        let fftSetup: FFTSetup = vDSP_create_fftsetupD(LOG_N, FFTRadix(kFFTRadix2))!
        defer {
            vDSP_destroy_fftsetupD(fftSetup)
        }
        
        // We need complex buffers in two different formats!
        var tempSplitComplexReal : [Double] = [Double](repeating: 0.0, count: N/2)
        var tempSplitComplexImag : [Double] = [Double](repeating: 0.0, count: N/2)
        var tempSplitComplex : DSPDoubleSplitComplex = DSPDoubleSplitComplex(realp: &tempSplitComplexReal, imagp: &tempSplitComplexImag)
        
        var valuesAsComplex : UnsafeMutablePointer<DSPDoubleComplex>? = nil
        
        valuesAsComplex = xs.withUnsafeBytes { (x: UnsafeRawBufferPointer) -> UnsafeMutablePointer<DSPDoubleComplex>? in
            guard let rawPointer = x.baseAddress
                else { return nil }
            let unsafePointer: UnsafePointer<DSPDoubleComplex> = rawPointer.bindMemory(to: DSPDoubleComplex.self, capacity: xs.count)
            return UnsafeMutablePointer(mutating: unsafePointer)
        }
        // Scramble-pack the real data into complex buffer in just the way that's
        // required by the real-to-complex FFT function that follows.
        vDSP_ctozD(valuesAsComplex!, 2, &tempSplitComplex, 1, N2);
        
        // Do real->complex forward FFT
        vDSP_fft_zripD(fftSetup, &tempSplitComplex, 1, LOG_N, FFTDirection(FFT_FORWARD));
        
        // ----------------------------------------------------------------
        // Get the Frequency Spectrum
        // ----------------------------------------------------------------
        
        var fftMagnitudes = [Double](repeating: 0.0, count: N/2)
        vDSP_zvmagsD(&tempSplitComplex, 1, &fftMagnitudes, 1, N2);
        
        // vDSP_zvmagsD returns squares of the FFT magnitudes, so take the root here
        let roots = sqrt(fftMagnitudes)
        
        // Normalize the Amplitudes
        var fullSpectrum = [Double](repeating: 0.0, count: N/2)
        vDSP_vsmulD(roots, vDSP_Stride(1), [1.0 / Double(N)], &fullSpectrum, 1, N2)
        
        return fullSpectrum
    }
    
    // MARK: - Math functions on Arrays
    static func mul(_ x: [Double], y: [Double]) -> [Double] {
        var results = [Double](repeating: 0.0, count: x.count)
        vDSP_vmulD(x, 1, y, 1, &results, 1, vDSP_Length(x.count))
        
        return results
    }
    
    static func sqrt(_ x: [Double]) -> [Double] {
        var results = [Double](repeating: 0.0, count: x.count)
        vvsqrt(&results, x, [Int32(x.count)])
        
        return results
    }
    
    static func max(_ x: [Double]) -> (Double, Int) {
        var result: Double = 0.0
        var idx : vDSP_Length = vDSP_Length(0)
        vDSP_maxviD(x, 1, &result, &idx, vDSP_Length(x.count))
        
        return (result, Int(idx))
    }
}
