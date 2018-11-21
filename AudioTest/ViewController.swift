//
//  ViewController.swift
//  AudioTest
//
//  Created by hirochin on 08/12/2017.
//  Copyright © 2017 Thel. All rights reserved.
//

import AVFoundation
import CoreMedia
import CoreAudio
import Cocoa

class ViewController: NSViewController {
    
    let captureSession = AVCaptureSession()
    let audioOutput = AVCaptureAudioDataOutput()

    @IBOutlet weak var graphView: GraphView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let devices = AVCaptureDevice.devices().filter { $0.hasMediaType(AVMediaType.audio) }
        if let captureDevice = devices.first {
            try! captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
            assert(captureSession.canAddOutput(audioOutput))
            captureSession.addOutput(audioOutput)
            audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        captureSession.startRunning()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        captureSession.stopRunning()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

extension ViewController: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let bufferListSizeNeeded = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        
        var bufferList = AudioBufferList()

        let listSize: Int = MemoryLayout<AudioBufferList>.size
        
        var blockBuffer: CMBlockBuffer?
        
        let allocator = kCFAllocatorDefault
        
        let result = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeeded,
            &bufferList,
            listSize,
            allocator,
            allocator,
            kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            &blockBuffer
        )
        
        if (result == kCMSampleBufferError_ArrayTooSmall) {
            // Read twice. ref => https://lists.apple.com/archives/quicktime-api/2013/Apr/msg00015.html
            let code = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                sampleBuffer,
                bufferListSizeNeeded,
                &bufferList,
                bufferListSizeNeeded.pointee,
                allocator,
                allocator,
                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                &blockBuffer
            )
            assert(code == 0 && blockBuffer != nil)
        }
        
        assert(blockBuffer != nil)
        
        let buffers = UnsafeBufferPointer<AudioBuffer>(start: &bufferList.mBuffers, count: Int(bufferList.mNumberBuffers))
        
        switch foo(samplebuffer: sampleBuffer) {
        case .Float:
            for buffer in buffers {
                
                let samplesCount = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
                let samplesPointer = bufferList.mBuffers.mData!.bindMemory(to: Float.self, capacity: samplesCount)
                let samples = UnsafeMutableBufferPointer<Float>(start: samplesPointer, count: samplesCount)
                
                let rawValues = samples.compactMap { $0 }
                var rrr = 0 as Float
                for vv in rawValues {
                    rrr = rrr + Float(vv)
                }
                let avg = Double(rrr) / Double(rawValues.count)
                print(String(format: "Double: %.4f", avg))
                
                graphView.data = rawValues
                DispatchQueue.main.async {
                    self.graphView.setNeedsDisplay(self.graphView.bounds)
                }
                
            }
        
        case .Integer:
            for buffer in buffers {
                
                let samplesCount = Int(buffer.mDataByteSize) / MemoryLayout<Int16>.size
                let samplesPointer = bufferList.mBuffers.mData!.bindMemory(to: Int16.self, capacity: samplesCount)
                let samples = UnsafeMutableBufferPointer<Int16>(start: samplesPointer, count: samplesCount)
                
                let rawValues = samples.compactMap { $0 }
                var rrr = 0 as Int64
                for vv in rawValues {
                    rrr = rrr + Int64(vv)
                }
                let avg = Double(rrr) / Double(rawValues.count)
                print("Integer: \(avg)")
                
                let rr: [Float] = rawValues.map({ abs(Float($0) / Float(Int16.max)) })
                graphView.data = rr
                DispatchQueue.main.async {
                    self.graphView.setNeedsDisplay(self.graphView.bounds)
                }
                
            }
        
        default:
            print("Failed")
        }
        
        
        
    }
    
    func foo(samplebuffer: CMSampleBuffer) -> Format {
        let formatDescription = CMSampleBufferGetFormatDescription(samplebuffer)!
        let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)!.pointee
        
        assert(asbd.mFormatID == kAudioFormatLinearPCM)
//        assert((asbd.mFormatFlags & kLinearPCMFormatFlagIsSignedInteger) != 0)
        
        print(asbd.mFormatFlags)
        
        if (asbd.mFormatFlags & kLinearPCMFormatFlagIsSignedInteger) > 0 {
            return .Integer
        }
        else if (asbd.mFormatFlags & kLinearPCMFormatFlagIsFloat) > 0 {
            return .Float
        }
        else {
            assert(false)
        }
        return .Unknow
    }
    
    enum Format {
        case Float
        case Integer
        case Unknow
    }
}

