//
//  AKSquareWaveOscillator.swift
//  AudioKit
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright (c) 2016 Aurelius Prochazka. All rights reserved.
//

import AVFoundation

/// This is a bandlimited square oscillator ported from the "square" function
/// from the Faust programming language.
///
/// - parameter frequency: In cycles per second, or Hz.
/// - parameter amplitude: Output amplitude
/// - parameter pulseWidth: Duty cycle width (range 0-1).
/// - parameter detuningOffset: Frequency offset in Hz.
/// - parameter detuningMultiplier: Frequency detuning multiplier
///
public class AKSquareWaveOscillator: AKVoice {

    // MARK: - Properties

    internal var internalAU: AKSquareWaveOscillatorAudioUnit?
    internal var token: AUParameterObserverToken?


    private var frequencyParameter: AUParameter?
    private var amplitudeParameter: AUParameter?
    private var pulseWidthParameter: AUParameter?
    private var detuningOffsetParameter: AUParameter?
    private var detuningMultiplierParameter: AUParameter?




    /// Ramp Time represents the speed at which parameters are allowed to change
    public var rampTime: Double = AKSettings.rampTime {
        willSet {
            if rampTime != newValue {
                internalAU?.rampTime = newValue
                internalAU?.setUpParameterRamp()
            }
        }
    }
    
    /// In cycles per second, or Hz.
    public var frequency: Double = 440 {
        willSet {
            if frequency != newValue {
                if internalAU!.isSetUp() {
                    frequencyParameter?.setValue(Float(newValue), originator: token!)
                } else {
                    internalAU?.frequency = Float(newValue)
                }
            }
        }
    }
    
    /// Output Amplitude.
    public var amplitude: Double = 1 {
        willSet {
            if amplitude != newValue {
                if internalAU!.isSetUp() {
                    amplitudeParameter?.setValue(Float(newValue), originator: token!)
                } else {
                    internalAU?.amplitude = Float(newValue)
                }
            }
        }
    }
    
    /// Frequency offset in Hz.
    public var detuningOffset: Double = 0 {
        willSet {
            if detuningOffset != newValue {
                if internalAU!.isSetUp() {
                    detuningOffsetParameter?.setValue(Float(newValue), originator: token!)
                } else {
                    internalAU?.detuningOffset = Float(newValue)
                }
            }
        }
    }
    
    /// Frequency detuning multiplier
    public var detuningMultiplier: Double = 1 {
        willSet {
            if detuningMultiplier != newValue {
                if internalAU!.isSetUp() {
                    detuningMultiplierParameter?.setValue(Float(newValue), originator: token!)
                } else {
                    internalAU?.detuningMultiplier = Float(newValue)
                }
            }
        }
    }
    
    /// Duty cycle width (range 0-1).
    public var pulseWidth: Double = 0.5 {
        willSet {
            if pulseWidth != newValue {
                pulseWidthParameter?.setValue(Float(newValue), originator: token!)
                if internalAU!.isSetUp() {
                    pulseWidthParameter?.setValue(Float(newValue), originator: token!)
                } else {
                    internalAU?.pulseWidth = Float(newValue)
                }
            }
        }
    }
    
    /// Tells whether the node is processing (ie. started, playing, or active)
    override public var isStarted: Bool {
        return internalAU!.isPlaying()
    }

    // MARK: - Initialization
    
    /// Initialize the oscillator with defaults
    override public convenience init() {
        self.init(frequency: 440)
    }

    /// Initialize this oscillator node
    ///
    /// - parameter frequency: In cycles per second, or Hz.
    /// - parameter amplitude: Output amplitude
    /// - parameter pulseWidth: Duty cycle width (range 0-1).
    /// - parameter detuningOffset: Frequency offset in Hz.
    /// - parameter detuningMultiplier: Frequency detuning multiplier
    ///
    public init(
        frequency: Double,
        amplitude: Double = 1.0,
        pulseWidth: Double = 0.5,
        detuningOffset: Double = 0,
        detuningMultiplier: Double = 1) {


        self.frequency = frequency
        self.amplitude = amplitude
        self.pulseWidth = pulseWidth
        self.detuningOffset = detuningOffset
        self.detuningMultiplier = detuningMultiplier

        var description = AudioComponentDescription()
        description.componentType         = kAudioUnitType_Generator
        description.componentSubType      = 0x7371726f /*'sqro'*/
        description.componentManufacturer = 0x41754b74 /*'AuKt'*/
        description.componentFlags        = 0
        description.componentFlagsMask    = 0

        AUAudioUnit.registerSubclass(
            AKSquareWaveOscillatorAudioUnit.self,
            as: description,
            name: "Local AKSquareWaveOscillator",
            version: UInt32.max)

        super.init()
        AVAudioUnit.instantiate(with: description, options: []) {
            avAudioUnit, error in

            guard let avAudioUnitGenerator = avAudioUnit else { return }

            self.avAudioNode = avAudioUnitGenerator
            self.internalAU = avAudioUnitGenerator.auAudioUnit as? AKSquareWaveOscillatorAudioUnit

            AudioKit.engine.attach(self.avAudioNode)
        }

        guard let tree = internalAU?.parameterTree else { return }

        frequencyParameter          = tree.value(forKey: "frequency")          as? AUParameter
        amplitudeParameter          = tree.value(forKey: "amplitude")          as? AUParameter
        pulseWidthParameter         = tree.value(forKey: "pulseWidth")         as? AUParameter
        detuningOffsetParameter     = tree.value(forKey: "detuningOffset")     as? AUParameter
        detuningMultiplierParameter = tree.value(forKey: "detuningMultiplier") as? AUParameter
        
        let observer: AUParameterObserver = {
            address, value in
            
            let executionBlock = {
                if address == self.frequencyParameter!.address {
                    self.frequency = Double(value)
                } else if address == self.amplitudeParameter!.address {
                    self.amplitude = Double(value)
                } else if address == self.pulseWidthParameter!.address {
                    self.pulseWidth = Double(value)
                } else if address == self.detuningOffsetParameter!.address {
                    self.detuningOffset = Double(value)
                } else if address == self.detuningMultiplierParameter!.address {
                    self.detuningMultiplier = Double(value)
                }
            }
            
            DispatchQueue.main.async(execute: executionBlock)
        }
        
        token = tree.token(byAddingParameterObserver: observer)
        internalAU?.frequency = Float(frequency)
        internalAU?.amplitude = Float(amplitude)
        internalAU?.pulseWidth = Float(pulseWidth)
        internalAU?.detuningOffset = Float(detuningOffset)
        internalAU?.detuningMultiplier = Float(detuningMultiplier)
    }

    /// Function create an identical new node for use in creating polyphonic instruments
    override public func duplicate() -> AKVoice {
        let copy = AKSquareWaveOscillator(frequency: self.frequency, amplitude: self.amplitude, pulseWidth: self.pulseWidth, detuningOffset: self.detuningOffset, detuningMultiplier: self.detuningMultiplier)
        return copy
    }

    /// Function to start, play, or activate the node, all do the same thing
    override public func start() {
        self.internalAU!.start()
    }

    /// Function to stop or bypass the node, both are equivalent
    override public func stop() {
        self.internalAU!.stop()
    }
}
