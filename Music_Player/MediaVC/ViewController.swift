//
//  ViewController.swift
//  Music_Player
//
//  Created by urvashi on 05/03/20.
//  Copyright © 2020 urvashi. All rights reserved.
//

import Cocoa
import AVKit
import FirebaseStorage
import Foundation
import Firebase
import FirebaseDatabase
import FirebaseFirestore

struct TrackInfo {
    var trackName: String
    var artistName: String
    var trackImage: NSImage
    var isDownloaded: Bool
    var trackUrl: URL
    var isPlaying: Bool
}

class ViewController: NSViewController, AVAudioPlayerDelegate {
    
    // MARK: Interface Builder Outlets
    
    @IBOutlet weak var tracksTblVw: NSTableView!
    @IBOutlet weak var volSlider: NSSlider!
    @IBOutlet weak var seekSlider: NSSlider!
    @IBOutlet weak var trackLabel: NSTextField!
    @IBOutlet weak var artistLabel: NSTextField!
    @IBOutlet weak var seekMinlabel: NSTextField!
    @IBOutlet weak var seekMaxlabel: NSTextField!
    @IBOutlet weak var playPauseBtn: NSButton!
    @IBOutlet weak var nextBtn: NSButton!
    @IBOutlet weak var previousBtn: NSButton!
    @IBOutlet weak var loadImageVw: NSImageView!
    @IBOutlet weak var listVw: NSView!
    @IBOutlet weak var expandColapseListVwWidth: NSLayoutConstraint!
    
    // MARK: Interface Builder Properties
    
    var audioPlayer:AVAudioPlayer = AVAudioPlayer()
    let playerView = AVPlayerView()
    var player : AVPlayer!
    let playableItemsArray = ["Cool", "Fanaa", "Old"]
    var tracksArray = [TrackInfo]()
    var currentIndex = 0
    var firebaseAudios = [[String: Any]]()
    
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIElements()
    }
    
    // MARK: Helper Functions
    
    func setupUIElements() {
        trackLabel.textColor = .white
        trackLabel.isBezeled = false
        trackLabel.isEditable = false
        trackLabel.sizeToFit()
        artistLabel.textColor = .white
        artistLabel.isBezeled = false
        artistLabel.isEditable = false
        artistLabel.sizeToFit()
        seekMinlabel.stringValue = "00.00"
        seekMinlabel.textColor = .white
        seekMinlabel.isBezeled = false
        seekMinlabel.isEditable = false
        seekMinlabel.sizeToFit()
        seekMaxlabel.stringValue = "00.00"
        seekMaxlabel.textColor = .white
        seekMaxlabel.isBezeled = false
        seekMaxlabel.isEditable = false
        seekMaxlabel.sizeToFit()
        seekSlider.isContinuous = true
        
        fetchAudioFiles()
        
        for item in playableItemsArray {
            let path = Bundle.main.path(forResource: item, ofType: "mp3")
            let soundUrl = URL(fileURLWithPath: path!)
            let playerItem = AVPlayerItem(url: soundUrl)
            let metaDataAsset = playerItem.asset.metadata
            var artistName = ""
            var trackName = ""
            var trackThumbnail = #imageLiteral(resourceName: "cover.jpg")
            for metadata in metaDataAsset {
                guard let key = metadata.commonKey?.rawValue, let value = metadata.value else{
                    continue
                }
                switch key {
                case "title" : trackName = value as? String ?? "Unknown"
                case "artist": artistName = value as? String ?? "Unknown"
                case "artwork" where value is Data : trackThumbnail = NSImage(data: value as! Data) ?? NSImage(named: "cover")!
                default:
                    continue
                }
            }
            let modelItem = TrackInfo(trackName: trackName, artistName: artistName, trackImage: trackThumbnail, isDownloaded: false, trackUrl: soundUrl, isPlaying: false)
            tracksArray.append(modelItem)
        }
        
        print("TRACKS >>>>>>>>>>>>>>>>>>>>>", tracksArray)
        tracksTblVw.reloadData()
    }
    
    func playMusic(atIndex: Int) {
        trackLabel.stringValue = tracksArray[atIndex].trackName
        artistLabel.stringValue = tracksArray[atIndex].artistName
        self.loadImageVw.image = tracksArray[atIndex].trackImage
        initializePlayer(playableItem: tracksArray[atIndex].trackUrl)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.playPauseBtn.image = NSImage(named: NSImage.touchBarPauseTemplateName)
            self.player.play()
        }
    }
    
    func initializePlayer(playableItem: URL) {
        if player != nil {
            player = nil
        }
        player = AVPlayer(url: playableItem)
        self.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main, using: { (time) in
            if self.player!.currentItem?.status == .readyToPlay {
                self.updateTime()
            }
        })
    }
    
    func updateTime() {
        // Access current item
        if let currentItem = self.player.currentItem {
            // Get the current time in seconds
            let playhead = currentItem.currentTime().seconds
            let duration = currentItem.duration.seconds
            // Format seconds for human readable string
            seekSlider.minValue = 0
            seekSlider.doubleValue = playhead
            seekSlider.maxValue = duration
            self.seekMinlabel.stringValue = formatTimeFor(seconds: playhead)
            self.seekMaxlabel.stringValue = formatTimeFor(seconds: duration)
            
            if self.seekMinlabel.stringValue == self.seekMaxlabel.stringValue {
                nextBtnAction(nextBtn)
            }
        }
    }
    
    // MARK: Handel Duration
    
    func getHoursMinutesSecondsFrom(seconds: Double) -> (hours: Int, minutes: Int, seconds: Int) {
        let secs = Int(seconds)
        let hours = secs / 3600
        let minutes = (secs % 3600) / 60
        let seconds = (secs % 3600) % 60
        return (hours, minutes, seconds)
    }
    
    func formatTimeFor(seconds: Double) -> String {
        let result = getHoursMinutesSecondsFrom(seconds: seconds)
        let hoursString = "\(result.hours)"
        var minutesString = "\(result.minutes)"
        if minutesString.count == 1 {
            minutesString = "0\(result.minutes)"
        }
        var secondsString = "\(result.seconds)"
        if secondsString.count == 1 {
            secondsString = "0\(result.seconds)"
        }
        var time = "\(hoursString):"
        if result.hours >= 1 {
            time.append("\(minutesString):\(secondsString)")
        }
        else {
            time = "\(minutesString):\(secondsString)"
        }
        return time
    }
    
    // MARK: Interface Builder Actions
    
    @IBAction func playPauseButton(sender: NSButton) {
        if player != nil {
            if player.timeControlStatus == .playing {
                playPauseBtn.image = NSImage(named: NSImage.touchBarPlayTemplateName)
                player.pause()
            } else {
                playPauseBtn.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                player.play()
            }
        } else {
            self.playMusic(atIndex: currentIndex)
        }
    }
    
    @IBAction func expandColapseButton(sender: NSButton) {
        if expandColapseListVwWidth.constant == 0 {
            self.listVw.isHidden = false
            NSAnimationContext.runAnimationGroup { (_) in
                NSAnimationContext.current.duration = 0.3
                expandColapseListVwWidth.animator().constant = 320
            }
        } else {
            NSAnimationContext.runAnimationGroup({ (_) in
                NSAnimationContext.current.duration = 0.3
                expandColapseListVwWidth.animator().constant = 0
            }) {
                self.listVw.isHidden = true
            }
        }
    }
    
    @IBAction func volumeSliderAction(_ sender: NSSlider) {
        player.volume = Float(sender.integerValue)/10
    }
    
    @IBAction func nextBtnAction(_ sender: NSButton) {
        if playableItemsArray.count > 0 && currentIndex < playableItemsArray.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
        self.playMusic(atIndex: currentIndex)
    }
    
    @IBAction func previousBtnAction(_ sender: NSButton) {
        if playableItemsArray.count > 0 && currentIndex > 0 {
            currentIndex -= 1
        } else {
            currentIndex = playableItemsArray.count - 1
        }
        self.playMusic(atIndex: currentIndex)
    }
    
    @IBAction func seekSlider(_ sender: NSSlider) {
        if player != nil {
            if let _ = self.player.currentItem {
                let seconds = sender.integerValue
                player.seek(to: CMTimeMakeWithSeconds(Float64(seconds), preferredTimescale: 1), toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }
    
    @IBAction func tableViewAction(sender: NSTableView) {
        if tracksArray.count > 0 {
            let row = tracksTblVw.selectedRow
            currentIndex = row
            self.playMusic(atIndex: row)
            print("SELECTED DATA >>>>>>>>>>>>>>>>>>>>>>", tracksArray[row])
        }
    }
}

extension ViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tracksArray.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "MediaFile")
        guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? MediaFile else { return nil }
        cellView.setCellData(trackDetail: tracksArray[row])
        return cellView
    }
}


extension ViewController {
    
    // Mark: fetch Audio From URL
    
    func fetchAudioFiles() {
        FirebaseApp.configure()
        //let databaseReference = Database.database().reference()
        let new = Firestore.firestore().collection("Audios")
        
//        databaseReference.observe(.childAdded, with: { (snapshot) -> Void in
//         print("SNAPSHOT >>>>>>>>>>", snapshot.value)
//        })
        
//        let rootRef = databaseReference.child("Audios")
//        rootRef.observe(.value, with: { snapshot in
//
//        })
        new.getDocuments { (snapShot, error) in
           for document in snapShot!.documents {
                print("VALUE >>>>>>>>>>>>", document)
            }
        }
        
    }
    
    private func downloadAudioFile(audioPath: String) {
        FirebaseApp.configure()
        let storage = Storage.storage()
        let storageReference = storage.reference(forURL: audioPath)
        storageReference.downloadURL { url, error in
            if error != nil {
            } else {
                let player = AVPlayer(url: url!)
                self.playerView.player = player
                player.rate = 1.0;
                player.play()
            }
        }
    }
    
    // MARK: Download From URL Session
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
}
