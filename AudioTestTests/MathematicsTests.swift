//
//  MathematicsTests.swift
//  AudioTestTests
//
//  Created by hirochin on 2018/11/27.
//  Copyright © 2018 Thel. All rights reserved.
//

import Accelerate
import XCTest

class MathematicsTests: XCTestCase {
    
    private var dfu: DaymoFrequencyUtility!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        dfu = DaymoFrequencyUtility(sampleCount: 5)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        dfu = nil
    }
    
    func testUpdate() {
        let dfu = DaymoFrequencyUtility(sampleCount: 3)
        XCTAssertEqual(
            [0, 0, 0],
            MathematicsTests.convertPointerToArray(p: dfu.scalePointer, count: dfu.N)
            )
        
        dfu.update(xs: [0.1, 0.2, 0.3])
        XCTAssertEqual(
            [0.1, 0.2, 0.3],
            MathematicsTests.convertPointerToArray(p: dfu.scalePointer, count: dfu.N)
        )
        
        dfu.update(xs: [0.8, 0.8, 0.8])
        XCTAssertEqual(
            [0.9, 1.0, 1.1],
            MathematicsTests.convertPointerToArray(p: dfu.scalePointer, count: dfu.N)
        )
        
        dfu.update(xs: [0.8, 0.8, 0.8])
        XCTAssertEqual(
            [1.7, 1.8, 1.9],
            MathematicsTests.convertPointerToArray(p: dfu.scalePointer, count: dfu.N)
        )
    }
    
    func testRest() {
        let actual = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        cblas_sasum(5, actual, 1)
        XCTAssertEqual(0, actual.pointee)
        
        dfu.update(xs: [0.1, 0.4, 0.3, 0.1, 0])
        dfu.update(xs: [0.1, 0.5, 0.4, 0.1, 0])
        dfu.reset()
        let actual2 = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        cblas_sasum(5, actual2, 1)
        XCTAssertEqual(0, actual2.pointee)
    }
    
    func testMultiply() {
        let iden = Array<Float>(repeating: 1, count: 5)
        let a1 = UnsafeMutablePointer<Float>(mutating: iden)
        XCTAssertEqual(MathematicsTests.convertPointerToArray(p: a1, count: 5), [1,1,1,1,1])
        let a2 = UnsafeMutablePointer<Float>(mutating: iden)

        vDSP_vadd(a1, 1, a2, 1, a1, 1, 5)
        XCTAssertEqual(MathematicsTests.convertPointerToArray(p: a1, count: 5), [2,2,2,2,2])
    }
    
    func testGetScales() {
        dfu.reset()
//        let dfu = DaymoFrequencyUtility(sampleCount: 5)
        
        let d1 = MathematicsTests.convertPointerToArray(p: dfu.getScales(), count: dfu.N)
        XCTAssertEqual(
            Array<Float>(repeating: 1, count: 5),
            d1
        )
        
        dfu.update(xs: [0.1, 0.4, 0.3, 0.1, 0])
        let d2 = MathematicsTests.convertPointerToArray(p: dfu.getScales(), count: dfu.N)
        XCTAssertEqual(
            [0.9, 0.6, 0.7, 0.9, 1.0],
            d2
        )
        print(d1)
        print(d2)
        
        dfu.update(xs: [0.1, 0.5, 0.4, 0.1, 0])
        let expected:[Float] = [0.9, 0.55, 0.65, 0.9, 1]
        let actual = MathematicsTests.convertPointerToArray(p: dfu.getScales(), count: dfu.N)
        XCTAssertEqual(expected, actual)
    }
    
    func testFoo() {
        let origin: [Float] = [0.1, 0.2, 0.3]
        let originPointer = UnsafeMutablePointer<Float>(mutating: origin)
        let actualValue = DaymoFrequencyUtility.foo(xp: originPointer, count: 3)
        let expected: [Float] = [0.1, 0.2, 0.3]
        XCTAssertEqual(expected, origin)
        
        let expectedValue: Float = 0.2
        XCTAssert((actualValue - expectedValue) < 0.0000001)
    }
    
    func testGetSoundScore() {
        let xp = UnsafeMutablePointer<Float>(mutating: [1,1,1])
        let actual = DaymoFrequencyUtility.foo(xp: xp, count: 3)
        let expected: Float = 1
        XCTAssertEqual(expected, actual)
        
        let xp2 = UnsafeMutablePointer<Float>(mutating: [0.1,0.5,0])
        let actual2 = DaymoFrequencyUtility.foo(xp: xp2, count: 3)
        let expected2: Float = 0.2
        XCTAssertEqual(expected2, actual2)
        
        dfu.reset()
        dfu.update(xs: [0.9, 0.4, 0.3, 0.1, 0])
        dfu.update(xs: [0.9, 0.5, 0.4, 0.1, 0])
        // [1.8, 0.9, 0.7, 0.2, 0] -> [0.9, 0.45, 0.35, 0.1, 0] => [0.1, 0.55, 0.65, 0.9, 1]
        // 0.9 * 0.1 + 0.5 * 0.55 + 0.0 * 0.65 + 0.1 * 0.9 + 0 * 1
        let input: [Float] = [0.9, 0.5, 0.0, 0.1, 0.0]
        let expected3: Float = 0.091000006
        let actual3 = dfu.getSoundScore(xp: UnsafeMutablePointer<Float>(mutating: input))
        XCTAssertEqual(expected3, actual3)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    static func setupVector(p: UnsafeMutablePointer<Float>, count: Int) -> () {
        for i in 0..<count {
            p.advanced(by: i).pointee = 1
        }
    }
    
    static func convertPointerToArray(p: UnsafeMutablePointer<Float>, count: Int) -> [Float] {
//        return Array(UnsafeBufferPointer(start: p, count: count))
        var rs = [Float]()
        for i in 0..<count {
            rs.append(p.advanced(by: i).pointee)
        }
        return rs
    }
    
}
