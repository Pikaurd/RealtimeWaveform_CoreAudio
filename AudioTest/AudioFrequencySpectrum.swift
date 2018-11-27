//
//  AudioFrequencySpectrum.swift
//  AudioTest
//
//  Created by hirochin on 2018/11/27.
//  Copyright © 2018 Thel. All rights reserved.
//

import Accelerate
import Foundation


class AudioFrequencySpectrum {
    
    private let sampleRate: Int
    private let N: Int
    private let N2: UInt
    private let LOG_N: UInt
    private let fftSetup: FFTSetup
    
    init(sampleRate: Int, sampleCountPerInvoke: Int) {
        self.sampleRate = sampleRate
        self.N = sampleCountPerInvoke
        self.N2 = vDSP_Length(N/2)
        self.LOG_N = vDSP_Length(log2(Float(N)))
        self.fftSetup = vDSP_create_fftsetup(LOG_N, FFTRadix(kFFTRadix2))!
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    func fft(xs: [Int16]) -> [Float] {
        return fft(xs: xs.map(AudioFrequencySpectrum.convertToFloat))
    }
    
    func fft(xs: [Float]) -> [Float] {
        assert(xs.count == N)
        // We need complex buffers in two different formats!
        var tempSplitComplexReal : [Float] = [Float](repeating: 0.0, count: N/2)
        var tempSplitComplexImag : [Float] = [Float](repeating: 0.0, count: N/2)
        var tempSplitComplex : DSPSplitComplex = DSPSplitComplex(realp: &tempSplitComplexReal, imagp: &tempSplitComplexImag)
        
        var valuesAsComplex : UnsafeMutablePointer<DSPComplex>? = nil
        
        valuesAsComplex = xs.withUnsafeBytes { (x: UnsafeRawBufferPointer) -> UnsafeMutablePointer<DSPComplex>? in
            guard let rawPointer = x.baseAddress
                else { return nil }
            let unsafePointer: UnsafePointer<DSPComplex> = rawPointer.bindMemory(to: DSPComplex.self, capacity: xs.count)
            return UnsafeMutablePointer(mutating: unsafePointer)
        }
        // Scramble-pack the real data into complex buffer in just the way that's
        // required by the real-to-complex FFT function that follows.
        vDSP_ctoz(valuesAsComplex!, 2, &tempSplitComplex, 1, N2);
        
        // Do real->complex forward FFT
        vDSP_fft_zrip(fftSetup, &tempSplitComplex, 1, LOG_N, FFTDirection(FFT_FORWARD));
        
        // ----------------------------------------------------------------
        // Get the Frequency Spectrum
        // ----------------------------------------------------------------
        
        var fftMagnitudes = [Float](repeating: 0.0, count: N/2)
        vDSP_zvmags(&tempSplitComplex, 1, &fftMagnitudes, 1, N2);
        
        // vDSP_zvmagsD returns squares of the FFT magnitudes, so take the root here
        let roots = sqrt(fftMagnitudes)
        
        // Normalize the Amplitudes
        var fullSpectrum = [Float](repeating: 0.0, count: N/2)
        vDSP_vsmul(roots, vDSP_Stride(1), [1.0 / Float(N)], &fullSpectrum, 1, N2)
        
        return fullSpectrum
    }
    
    // MARK: - Math functions on Arrays
    
    func sqrt(_ x: [Float]) -> [Float] {
        var results = [Float](repeating: 0.0, count: x.count)
        vvsqrtf(&results, x, [Int32(x.count)])
        
        return results
    }
    
    static func convertToFloat(x: Int16) -> Float {
        let r = Float(x) / Float(Int16.max)
        if r > 1.0 { return 1 }
        if r < -1.0 { return -1 }
        return r
    }
    
}
