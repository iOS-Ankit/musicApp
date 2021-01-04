
import Cocoa
import AVKit

class MediaFile: NSTableCellView {
    
    // MARK: Cell Interface Builder Outlets
    
    @IBOutlet weak var trackImageVw: NSImageView!
    @IBOutlet weak var trackName: NSTextField!
    @IBOutlet weak var artistName: NSTextField!
    @IBOutlet weak var downloadTrackBtn: NSButton!
    
    // MARK: Awake From Nib
    
    override func awakeFromNib() {
        trackImageVw.wantsLayer = true
        trackImageVw.layer?.cornerRadius = 10.0
        trackImageVw.layer?.masksToBounds = true
        artistName.textColor = .white
        artistName.isBezeled = false
        artistName.isEditable = false
        artistName.sizeToFit()
        trackName.textColor = .white
        trackName.isBezeled = false
        trackName.isEditable = false
        trackName.sizeToFit()
    }
    
    // MARK: Helper Functions
    
    func setCellData(trackDetail: TrackInfo) {
        trackName?.stringValue = trackDetail.trackName
        trackImageVw?.image = trackDetail.trackImage
        artistName?.stringValue = trackDetail.artistName
    }
}

