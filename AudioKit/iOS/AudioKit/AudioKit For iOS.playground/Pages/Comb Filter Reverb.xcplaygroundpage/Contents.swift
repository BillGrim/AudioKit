//: [TOC](Table%20Of%20Contents) | [Previous](@previous) | [Next](@next)
//:
//: ---
//:
//: ## Comb Filter Reverb
//:
import PlaygroundSupport
import AudioKit

let bundle = Bundle.main()
let file = bundle.pathForResource("drumloop", ofType: "wav")
var player = AKAudioPlayer(file!)
player.looping = true
var filter = AKCombFilterReverb(player, loopDuration: 0.1)

//: Set the parameters of the Comb Filter here
filter.reverbDuration = 1

AudioKit.output = filter
AudioKit.start()
player.play()

//: User Interface Set up

class PlaygroundView: AKPlaygroundView {
    
    var durationLabel: Label?
    
    override func setup() {
        addTitle("Comb Filter Reverb")
        
        addLabel("Audio Playback")
        addButton("Drums", action: #selector(startDrumLoop))
        addButton("Bass", action: #selector(startBassLoop))
        addButton("Guitar", action: #selector(startGuitarLoop))
        addButton("Lead", action: #selector(startLeadLoop))
        addButton("Mix", action: #selector(startMixLoop))
        addButton("Stop", action: #selector(stop))
        
        durationLabel = addLabel("Duration: \(filter.reverbDuration)")
        addSlider(#selector(setDuration), value: filter.reverbDuration, minimum: 0, maximum: 5)
    }
    
    func startLoop(_ part: String) {
        player.stop()
        let file = bundle.pathForResource("\(part)loop", ofType: "wav")
        player.replaceFile(file!)
        player.play()
    }
    
    func startDrumLoop() {
        startLoop("drum")
    }
    
    func startBassLoop() {
        startLoop("bass")
    }
    
    func startGuitarLoop() {
        startLoop("guitar")
    }
    
    func startLeadLoop() {
        startLoop("lead")
    }
    
    func startMixLoop() {
        startLoop("mix")
    }
    
    func stop() {
        player.stop()
    }
    
    func setDuration(slider: Slider) {
        filter.reverbDuration = Double(slider.value)
        durationLabel!.text = "Duration: \(String(format: "%0.3f", filter.reverbDuration))"
        filter.reverbDuration // to plot value history
    }
    
}

let view = PlaygroundView(frame: CGRect(x: 0, y: 0, width: 500, height: 300))
PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = view

//: [TOC](Table%20Of%20Contents) | [Previous](@previous) | [Next](@next)