//
//  CheckVoiceRecognitionManager.swift
//  ChickenVoiceRecognition
//
//  Created by Phineas.Huang on 02/02/2018.
//  Copyright © 2018 SunXiaoShan. All rights reserved.
//

import UIKit
import Speech

protocol ChickenVoiceRecognitionDelegate : class {
    func ChickenVRManagerStart(_ manager: ChickenVoiceRecognitionManager)
    func ChickenVRManagerWaitKeyword(_ manager: ChickenVoiceRecognitionManager)
    func ChickenVRManagerWaitCommand(_ manager: ChickenVoiceRecognitionManager)
    func ChickenVRManagerTimeout(_ manager: ChickenVoiceRecognitionManager, _ ret: String)
    func ChickenVRManagerOnFinal(_ manager: ChickenVoiceRecognitionManager, _ ret: String)
}

@available(iOS 10.0, *)
class ChickenVoiceRecognitionManager: NSObject {
    enum ChickenStatus {
        case ChickenNone
        case ChickenReady
        case ChickenListening
        case ChickenProcessing
    }
    
    fileprivate let speechRecognizer = SFSpeechRecognizer()!
    fileprivate var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    var audioEngine = AVAudioEngine()
    
    fileprivate var locale: String = "en_US"
    fileprivate var recognizedText : String = ""
    
    fileprivate var recognitionLimiter: Timer?
    /** Speech recognition time limit (maximum time 60 seconds is Apple's limit time) */
    fileprivate var recognitionLimitSec: Int = 15
    
    fileprivate var noAudioDurationTimer: Timer?
    /** Threshold for judging period of silence */
    fileprivate var noAudioDurationLimitSec: Int = 2
    
    fileprivate var commandKeyword: String = "chicken"
    fileprivate var chickenStatus: ChickenStatus = .ChickenNone
    
    fileprivate var status : String = ""
    
    fileprivate var localeIdentifier: String?
    
    internal var delegate: ChickenVoiceRecognitionDelegate?
    
    override init() {
        super.init()
        setup()
    }
    
    func setup() {
        audioEngine = AVAudioEngine()
        self.initializeAVAudioSession()
    }
    
    open func setRecognitionLimitSec(_ v : Int) -> Void {
        self.recognitionLimitSec = v%60;
    }
    
    open func setCommandKeyword(_ keyword : String) {
        self.commandKeyword = keyword
    }
    
    open func setLocale(_ locale : String) {
        self.locale = locale
    }
    
    open func isEnabled() -> Bool {
        if (self.status != "authorized") {
            SFSpeechRecognizer.requestAuthorization { authStatus in
                OperationQueue.main.addOperation {
                    switch authStatus {
                    case .authorized:
                        self.status = "authorized"
                    case .denied:
                        self.status = "denied"
                    case .restricted:
                        self.status = "restricted"
                    case .notDetermined:
                        self.status = "notDetermined"
                    }
                }
            }
        }
        return self.status == "authorized"
    }
    
    fileprivate func startRecording() throws {
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = self.getInputNode()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: (self.localeIdentifier)!))
        
        recognizer?.recognitionTask(with: recognitionRequest, delegate: self)
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    fileprivate func recordButtonTapped() {
        self.recordButtonTapped(locale)
    }
    
    open func recordButtonTapped(_ locale: String) -> String {
        var ret = ""
        self.localeIdentifier = locale
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            ret = self.recognizedText
            let inputNode = self.getInputNode()
            inputNode.removeTap(onBus: 0)
            self.stopTimer()
        } else {
            self.delegate?.ChickenVRManagerStart(self)
            self.recognizedText = ""
            try! startRecording()
            self.startTimer()
            ret = "recognizeNow"
        }
        return ret
    }
    
    open func supportedLocales() -> Set<Locale> {
        let ret : Set = SFSpeechRecognizer.supportedLocales()
        return ret
    }
    
    func startTimer() {
        recognitionLimiter = Timer.scheduledTimer(
            timeInterval: TimeInterval(self.recognitionLimitSec),
            target: self,
            selector:#selector(InterruptEvent),
            userInfo: nil,
            repeats: false
        )
    }
    
    func stopTimer() {
        if recognitionLimiter != nil {
            recognitionLimiter?.invalidate()
            recognitionLimiter = nil
        }
    }
    
    func startNoAudioDurationTimer() {
        self.stopTimer()
        noAudioDurationTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(self.noAudioDurationLimitSec),
            target: self,
            selector:#selector(InterruptEvent),
            userInfo: nil,
            repeats: false
        )
    }
    
    func stopNoAudioDurationTimer() {
        if noAudioDurationTimer != nil {
            noAudioDurationTimer?.invalidate()
            noAudioDurationTimer = nil
        }
    }
    
    @objc func InterruptEvent() {
        var ret = ""
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            ret = self.recognizedText
        }
        let inputNode = self.getInputNode()
        inputNode.removeTap(onBus: 0)
        self.recognitionRequest = nil
        self.recognitionTask = nil
        recognitionLimiter = nil
        noAudioDurationTimer = nil
        self.resetAVAudioSession()
        delegate?.ChickenVRManagerTimeout(self, ret)
    }
    
    /** AVAudioSession initialize. */
    func initializeAVAudioSession() {
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        try! AVAudioSession.sharedInstance().setActive(false)
    }
    
    /** AVAudioSession End processing. */
    func resetAVAudioSession() {
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
    }
    
    func getInputNode() -> AVAudioInputNode {
        return audioEngine.inputNode
    }
    
    func resetSRMethod() {
        stopNoAudioDurationTimer()
        stopTimer()
        InterruptEvent()
        chickenStatus = .ChickenReady
        recordButtonTapped()
    }
    
}

extension ChickenVoiceRecognitionManager : SFSpeechRecognizerDelegate {
    // MARK: SFSpeechRecognizerDelegate
    open func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {}
    
    // Tells the delegate when the task first detects speech in the source audio.
    // @see https://developer.apple.com/reference/speech/sfspeechrecognitiontaskdelegate/1649206-speechrecognitiondiddetectspeech
    open func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {}
    
    // Tells the delegate that the task has been canceled.
    // @see https://developer.apple.com/reference/speech/sfspeechrecognitiontaskdelegate/1649200-speechrecognitiontaskwascancelle
    open func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {}
}

extension ChickenVoiceRecognitionManager : SFSpeechRecognitionTaskDelegate {
    // Tells the delegate that a hypothesized transcription is available.
    // @see https://developer.apple.com/reference/speech/sfspeechrecognitiontaskdelegate/1649210-speechrecognitiontask
    open func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        self.recognizedText = transcription.formattedString
        
        if chickenStatus == .ChickenReady {
            if (transcription.formattedString.lowercased().range(of: self.commandKeyword) != nil) {
                // Stop voice recognition
                // Create new voice recognition
                self.stopNoAudioDurationTimer()
                self.stopTimer()
                self.InterruptEvent()
                print("test - CCCC")
                return
            }
        }
        print("test - DDDD")
        // Start judgment of silent time
        self.stopNoAudioDurationTimer()
        self.startNoAudioDurationTimer()
    }
    
    // Tells the delegate when the task is no longer accepting new audio input, even if final processing is in progress.
    // @see https://developer.apple.com/reference/speech/sfspeechrecognitiontaskdelegate/1649193-speechrecognitiontaskfinishedrea
    open func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {}
    
    // Tells the delegate when the final utterance is recognized.
    // @see https://developer.apple.com/reference/speech/sfspeechrecognitiontaskdelegate/1649214-speechrecognitiontask
    open func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        self.recognizedText = recognitionResult.bestTranscription.formattedString
    }
    
    // Tells the delegate when the recognition of all requested utterances is finished.
    // @see https://developer.apple.com/reference/speech/sfspeechrecognitiontaskdelegate/1649215-speechrecognitiontask
    open func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        if chickenStatus == .ChickenReady {
            if (self.recognizedText.lowercased().range(of: self.commandKeyword) != nil) {
                chickenStatus = .ChickenListening
                self.recordButtonTapped()
                print("test - BBBB")
                self.delegate?.ChickenVRManagerWaitCommand(self)
                return
            }
        }
        
        self.stopNoAudioDurationTimer()
        self.delegate?.ChickenVRManagerOnFinal(self, self.recognizedText)
        print("test - AAAA")
        resetSRMethod()
        self.delegate?.ChickenVRManagerWaitKeyword(self)
    }
}
