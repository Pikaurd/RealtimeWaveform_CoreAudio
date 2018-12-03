//
//  fft.swift
//  AudioTest
//
//  Created by hirochin on 2018/11/26.
//  Copyright © 2018 Thel. All rights reserved.
//

import Accelerate
import Foundation


class DaymoFrequencyUtility {
    
    // 参照88键钢琴能表现的频率范围 27.5Hz ~ 4186Hz
    // https://tw.yamaha.com/zh/products/contents/musical_instrument_guide/piano/trivia/trivia007.html
    // 又因为计算全部的频谱数值太小，考虑只计算这个范围内的频率数值
    
    //    private var scale: [Float]
    let scalePointer: UnsafeMutablePointer<Float>
    var averageBase: Int = 0
    private var calculatedScales: UnsafeMutablePointer<Float>?
    let N: Int
    
    init(sampleCount: Int) {
        N = sampleCount
        scalePointer = UnsafeMutablePointer<Float>.allocate(capacity: N)
        calculatedScales = .none
    }
    
    func update(xs: [Float]) -> () {
        assert(xs.count == N)
        let inputPointer = UnsafeMutablePointer<Float>(mutating: xs)
        vDSP_vadd(scalePointer, vDSP_Stride(1),
                  inputPointer, vDSP_Stride(1),
                  scalePointer, vDSP_Stride(1),
                  vDSP_Length(N))
        averageBase += 1
    }
    
    func getScales() -> UnsafeMutablePointer<Float> {
        let zeros = [Float](repeating: 0, count: N)
        let zerosPointer = UnsafeMutablePointer<Float>(mutating: zeros)
        if averageBase == 0 {
            return zerosPointer
        }
        
//        let result = UnsafeMutablePointer<Float>.allocate(capacity: N)
        let rawScales = DaymoFrequencyUtility.copy(origin: scalePointer, capacity: N)
        cblas_sscal(Int32(N), 1.0 / Float(averageBase), rawScales, 1)
        return rawScales
//        vDSP_vsub(rawScales, vDSP_Stride(1),
//                  identityPointer, vDSP_Stride(1),
//                  result, vDSP_Stride(1),
//                  vDSP_Length(N))
//        return result
    }
    
    func reset() -> () {
        cblas_sscal(Int32(N), 0, scalePointer, 0)
        averageBase = 0
    }
    
    func getSoundScore(xp: UnsafeMutablePointer<Float>) -> Float {
        let scales: UnsafeMutablePointer<Float>
        if let ss = calculatedScales {
            scales = ss
        }
        else {
            scales = getScales()
            calculatedScales = scales
        }
        let result = DaymoFrequencyUtility.soundScore(xp: xp, scales: scales, count: N)
        return result
    }
    
    static func foo(xp: UnsafeMutablePointer<Float>, count: Int32) -> Float {
        let copied = DaymoFrequencyUtility.copy(origin: xp, capacity: Int(count))
        
        cblas_sscal(count, 1 / Float(count), copied, 1)
        let result = UnsafeMutablePointer<Float>.allocate(capacity: 0)
        vDSP_sve(copied, vDSP_Stride(1), result, vDSP_Length(count))
        var resultValue = result.pointee
        if resultValue < 0 {
            resultValue = 0
        }
        else if resultValue > 1 {
            resultValue = 1
        }
        return resultValue
    }
    
    static func soundScore(xp: UnsafeMutablePointer<Float>, scales: UnsafeMutablePointer<Float>, count: Int) -> Float {
        let copied = DaymoFrequencyUtility.copy(origin: xp, capacity: count)
        let r = UnsafeMutablePointer<Float>.allocate(capacity: count)
        // 通过scale来降低权重
//        vDSP_mmul(
//            copied, vDSP_Stride(1),
//            scales, vDSP_Stride(1),
//            r, vDSP_Stride(1),
//            vDSP_Length(1), vDSP_Length(1), vDSP_Length(count)
//        )
        
        // 直接消去相关区域能量
        vDSP_vsub(
            scales, vDSP_Stride(1),
            copied, vDSP_Stride(1),
            r, vDSP_Stride(1),
            vDSP_Length(count)
        )
        
        for i in 0..<count {
            let p = r.advanced(by: i)
            let x = p.pointee
            if x < 0 {
                p.pointee = 0
            }
        }
        
        let result = cblas_sasum(Int32(count), r, 1) / Float(count)
        return result
    }
    
    static func copy<T>(origin: UnsafeMutablePointer<T>, capacity: Int) -> UnsafeMutablePointer<T> {
        let result = UnsafeMutablePointer<T>.allocate(capacity: capacity)
        for i in 0..<capacity {
            result.advanced(by: i).pointee = origin.advanced(by: i).pointee
        }
        return result
    }

}
