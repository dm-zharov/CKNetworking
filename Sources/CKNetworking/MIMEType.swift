//
//  MIMEType.swift
//
//
//  Created by Dmitriy Zharov on 13.08.2020.
//

import Foundation

public struct MIMEType: RawRepresentable, Hashable, Equatable, Codable {
    public typealias RawValue = String
    
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
    
    public static func == (lhs: MIMEType, rhs: MIMEType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    /// Directory
    public static let directory = MIMEType(rawValue: "httpd/unix-directory")
    
    // Archive and Binary
    
    /// Binary stream and unknown types
    public static let stream = MIMEType(rawValue: "application/octet-stream")
    /// Protable document format
    public static let pdf = MIMEType(rawValue: "application/pdf")
    /// Zip archive
    public static let zip = MIMEType(rawValue: "application/zip")
    /// Rar archive
    public static let rarArchive = MIMEType(rawValue: "application/x-rar-compressed")
    /// 7-zip archive
    public static let lzma = MIMEType(rawValue: "application/x-7z-compressed")
    /// Adobe Flash
    public static let flash = MIMEType(rawValue: "application/x-shockwave-flash")
    /// ePub book
    public static let epub = MIMEType(rawValue: "application/epub+zip")
    /// Java archive (jar)
    public static let javaArchive = MIMEType(rawValue: "application/java-archive")
    
    // Texts
    
    /// Text file
    public static let plainText = MIMEType(rawValue: "text/plain")
    /// Coma-separated values
    public static let csv = MIMEType(rawValue: "text/csv")
    /// Hyper-text markup language
    public static let html = MIMEType(rawValue: "text/html")
    /// Common style sheet
    public static let css = MIMEType(rawValue: "text/css")
    /// eXtended Markup language
    public static let xml = MIMEType(rawValue: "text/xml")
    /// Javascript code file
    public static let javascript = MIMEType(rawValue: "application/javascript")
    /// Javascript notation
    public static let json = MIMEType(rawValue: "application/json")
    
    // Documents
    
    /// Rich text file (RTF)
    public static let richText = MIMEType(rawValue: "application/rtf")
    /// Excel 2013 (OOXML) document
    public static let excel = MIMEType(rawValue: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    /// Powerpoint 2013 (OOXML) document
    public static let powerpoint = MIMEType(rawValue: "application/vnd.openxmlformats-officedocument.presentationml.slideshow")
    /// Word 2013 (OOXML) document
    public static let word = MIMEType(rawValue: "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    
    // Images
    
    /// Bitmap
    public static let bmp = MIMEType(rawValue: "image/bmp")
    /// Graphics Interchange Format photo
    public static let gif = MIMEType(rawValue: "image/gif")
    /// JPEG photo
    public static let jpeg = MIMEType(rawValue: "image/jpeg")
    /// Portable network graphics
    public static let png = MIMEType(rawValue: "image/png")
    
    // Audio & Video
    
    /// MPEG Audio
    public static let mpegAudio = MIMEType(rawValue: "audio/mpeg")
    /// MPEG Video
    public static let mpeg = MIMEType(rawValue: "video/mpeg")
    /// MPEG4 Audio
    public static let mpeg4Audio = MIMEType(rawValue: "audio/mp4")
    /// MPEG4 Video
    public static let mpeg4 = MIMEType(rawValue: "video/mp4")
    /// OGG Audio
    public static let ogg = MIMEType(rawValue: "audio/ogg")
    /// Advanced Audio Coding
    public static let aac = MIMEType(rawValue: "audio/x-aac")
    /// Microsoft Audio Video Interleaved
    public static let avi = MIMEType(rawValue: "video/x-msvideo")
    /// Microsoft Wave audio
    public static let wav = MIMEType(rawValue: "audio/x-wav")
    /// Apple QuickTime format
    public static let quicktime = MIMEType(rawValue: "video/quicktime")
    /// 3GPP
    public static let threegp = MIMEType(rawValue: "video/3gpp")
    /// Adobe Flash video
    public static let flashVideo = MIMEType(rawValue: "video/x-flv")
    /// Adobe Flash video
    public static let flv = MIMEType.flashVideo
    
    // Google Drive
    
    /// Google Drive: Folder
    public static let googleFolder = MIMEType(rawValue: "application/vnd.google-apps.folder")
    /// Google Drive: Document (word processor)
    public static let googleDocument = MIMEType(rawValue: "application/vnd.google-apps.document")
    /// Google Drive: Sheets (spreadsheet)
    public static let googleSheets = MIMEType(rawValue: "application/vnd.google-apps.spreadsheet")
    /// Google Drive: Slides (presentation)
    public static let googleSlides = MIMEType(rawValue: "application/vnd.google-apps.presentation")
    /// Google Drive: Drawing (vector draw)
    public static let googleDrawing = MIMEType(rawValue: "application/vnd.google-apps.drawing")
    /// Google Drive: Audio
    public static let googleAudio = MIMEType(rawValue: "application/vnd.google-apps.audio")
    /// Google Drive: Video
    public static let googleVideo = MIMEType(rawValue: "application/vnd.google-apps.video")
}
