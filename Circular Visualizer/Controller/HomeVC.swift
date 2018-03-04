//
//  HomeVC.swift
//  Circular Visualizer
//
//  Created by Alwin Lazar on 04/03/18.
//  Copyright © 2018 zaconic. All rights reserved.
//

import UIKit
import AVFoundation

class HomeVC: UIViewController {
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var circularVisualizer: CircularVisualizerView!
    
    var audioPlayer: STKAudioPlayer?
    let url = URL(string: "http://185.38.149.3:8010/lqstream")!
    
    let visualizerAnimationDuration = 0.15
    var lowPassReslts: Float = 0.0
    var lowPassReslts1: Float = 0.0
    var visualizerTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObservers()
        initAudioPlayer()
    }
    
    //-----------------------------------------------------------------
    // MARK: - Observers
    //-----------------------------------------------------------------
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterrupted),
                                               name: .AVAudioSessionInterruption,
                                               object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: .AVAudioSessionRouteChange,
                                               object: AVAudioSession.sharedInstance())
    }
    
    //-----------------------------------------------------------------
    // MARK: - Audio Player - Stream Kit
    //-----------------------------------------------------------------
    
    func initAudioPlayer() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            try AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            setupStreamKit()
        } catch {
            print("Audio Session setup error ")
        }
    }

    func setupStreamKit() {
        audioPlayer = STKAudioPlayer()
        audioPlayer?.meteringEnabled = true
        audioPlayer?.play(url)
        startAudioVisualizer()
        // update play image to pause
        playBtn.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
    }
    
    //-----------------------------------------------------------------
    // MARK: - Helper Methods
    //-----------------------------------------------------------------
    
    @objc func sessionInterrupted(notification: NSNotification) {
        if let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber{
            if let type = AVAudioSessionInterruptionType(rawValue: typeValue.uintValue){
                if type == .began {
                    print("LOG: interruption: began")
                    audioPlayer?.stop()
                    stopAudioVisualizer()

                } else {
                    print("LOG: interruption: ended")
                    let url = URL(string: "http://185.38.149.3:8010/lqstream")!
                    audioPlayer?.play(url)
                    startAudioVisualizer()
                }
            }
        }
    }

    @objc func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else {
                return
        }
        switch reason {
        case .newDeviceAvailable:
            for output in AVAudioSession.sharedInstance().currentRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
                print("Route Change Detected !!!!!!!!headphonesConnected!!!!!!!!!!")
            }
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
                    print("Route Change Detected !!!!!!!!headphones DISConnected!!!!!!!!!!")

                }
            }
        default: ()
        }
    }

    @objc func didEnterBackground() {
        print("Enter Back ground")
        stopAudioVisualizer()
    }

    @objc func didEnterForeground() {
        print("Enter to foreground")
        if playBtn.image(for: .normal) == #imageLiteral(resourceName: "pause") {
            startAudioVisualizer()
        }
//        if playOrPauseImg.image == #imageLiteral(resourceName: "pause") {
//            startAudioVisualizer()
//        }
    }
    
    
    func stopAudioVisualizer() {
        visualizerTimer?.invalidate()
        visualizerTimer = nil
        circularVisualizer.stop()
    }
    
    func startAudioVisualizer() {
        visualizerTimer?.invalidate()
        visualizerTimer = nil
        visualizerTimer = Timer.scheduledTimer(timeInterval: visualizerAnimationDuration, target: self, selector: #selector(self.visualizerTimerFunc), userInfo: nil, repeats: true)
    }
    
    @objc func visualizerTimerFunc(_ timer: CADisplayLink) {
        let ALPHA: Float = 1.05
        let averagePowerForChannel = pow(10, (0.05 * self.audioPlayer!.averagePowerInDecibels(forChannel:
            0)))
        lowPassReslts = ALPHA * averagePowerForChannel + (1.0 - ALPHA) * lowPassReslts
        let averagePowerForChannel1 = pow(10, (0.05 * self.audioPlayer!.averagePowerInDecibels(forChannel:
            1)))
        lowPassReslts1 = ALPHA * averagePowerForChannel1 + (1.0 - ALPHA) * lowPassReslts1
        
        let lowResults = self.audioPlayer!.averagePowerInDecibels(forChannel: 0)
        let lowResults1 = self.audioPlayer!.averagePowerInDecibels(forChannel: 1)
        circularVisualizer.animateAudioVisualizerWithChannel(level0: -lowResults, level1: -lowResults1)
    }
    
    func streamKitPlayOrPause() {
        
        if playBtn.image(for: .normal) == #imageLiteral(resourceName: "play") {
            playBtn.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            self.audioPlayer?.resume()
            startAudioVisualizer()
        } else {
            playBtn.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            self.audioPlayer?.pause()
            stopAudioVisualizer()
        }
        
//        if playOrPauseImg.image == #imageLiteral(resourceName: "play") {
//            playOrPauseImg.image = #imageLiteral(resourceName: "pause")
//            self.audioPlayer?.resume()
//            startAudioVisualizer()
//        } else {
//            playOrPauseImg.image = #imageLiteral(resourceName: "play")
//            self.audioPlayer?.pause()
//            stopAudioVisualizer()
//        }
    }
    
    //-----------------------------------------------------------------
    // MARK: - Actions
    //-----------------------------------------------------------------
    
    @IBAction func playBtnTapped(_ sender: Any) {
        streamKitPlayOrPause()
    }
}

//-----------------------------------------------------------------
// MARK: - STKAudioPlayer Extension
//-----------------------------------------------------------------

extension HomeVC: STKAudioPlayerDelegate {
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
        if state == .buffering {
            print("bffering")
            stopAudioVisualizer()
        } else if state == .disposed {
            print("disposed")
        } else if state == .error {
            print("error")
        } else if state == .paused {
            print("paused")
        } else if state == .playing {
            print("playing")
            startAudioVisualizer()
        } else if state == .stopped {
            print("stopped")
        } else {
            print("ELSE DETECT")
        }
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, logInfo line: String) {
        print("logInfo : ", line)
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        print("unexpectedError : ", errorCode)
    }
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didCancelQueuedItems queuedItems: [Any]) {
        
    }
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {
        
    }
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {
        
    }
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, with stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        
    }
}

