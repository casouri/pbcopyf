//
//  common.swift
//  pbcopyf
//
//  Created by Yuan Fu on 2019/7/12.
//  Copyright © 2019 Yuan Fu. All rights reserved.
//

import Foundation
import Cocoa


extension Array {
    subscript (safe index: UInt) -> Element? {
        return Int(index) < count ? self[Int(index)] : nil
    }
}

extension String {
    func removePrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

enum FileError: Error {
    case PathInvalid(String)
    case FileNotFound(String)
    case FileCannotWrite(String)
    case FileCannotDelete(String)
    case FileCannotRead(String)
}

enum ProgramError: Error {
    case NotEnoughArguments(String)
    case Terminate()
}

enum PasteboardError: Error {
    case FailedToWritePasteboard()
}

func completePath(of filePathArray:[String], relativeTo directory:String) throws -> [(URL, URL)] {
    let directoryURL = URL(fileURLWithPath: directory).standardizedFileURL
    if !FileManager.default.fileExists(atPath: directoryURL.path) {
        throw FileError.FileNotFound("\(directoryURL.path) does not exist")
    }
    return filePathArray.map { path -> (URL, URL) in
        let sourceFile = URL(fileURLWithPath: path)
        let sourceFilename = sourceFile.lastPathComponent
        let destFile = directoryURL.appendingPathComponent(sourceFilename)
        return (sourceFile, destFile)
    }
}

func pasteFilesInternal(filePairArray:[(URL, URL)], forcefully force:Bool) throws {
    // check for possible errors
    for (sourceFile, destFile) in filePairArray {
        if FileManager.default.fileExists(atPath: destFile.path) && !force {
            throw FileError.FileCannotWrite("\(destFile.path) already exists, try enable --force (-f) option")
        }
        if !FileManager.default.fileExists(atPath: sourceFile.path) {
            throw FileError.FileNotFound(sourceFile.path)
        }
        if !FileManager.default.isReadableFile(atPath: sourceFile.path) {
            throw FileError.FileCannotRead(sourceFile.path)
        }
    }
    // paste files
    for (sourceFile, destFile) in filePairArray {
        do {
            let destExists = FileManager.default.fileExists(atPath: destFile.path)
            if !destExists {
                try FileManager.default.copyItem(at: sourceFile, to: destFile)
            } else if destExists && force{
                try FileManager.default.trashItem(at: destFile, resultingItemURL: nil)
                try FileManager.default.copyItem(at: sourceFile, to: destFile)
            } else {
                throw FileError.FileCannotWrite("\(destFile.path) already exists, try enable --force option")
            }
        }
    }
}

func pasteFiles(filePathArray:[String], to destDirectory:String, forcefully force:Bool) throws {
    let fileArray = try completePath(of: filePathArray, relativeTo: destDirectory)
    try pasteFilesInternal(filePairArray: fileArray, forcefully: force)
}

func moveFilesInternal(filePairArray:[(URL, URL)], forcefully force:Bool) throws {
    // check for possible errors
    for (sourceFile, destFile) in filePairArray {
        if FileManager.default.fileExists(atPath: destFile.path) && !force {
            throw FileError.FileCannotWrite("\(destFile.path) already exists, try enable --force (-f) option")
        }
        if !FileManager.default.fileExists(atPath: sourceFile.path) {
            throw FileError.FileNotFound(sourceFile.path)
        }
        if !FileManager.default.isReadableFile(atPath: sourceFile.path) {
            throw FileError.FileCannotRead(sourceFile.path)
        }
        if !FileManager.default.isDeletableFile(atPath: sourceFile.path) {
            throw FileError.FileCannotDelete(sourceFile.path)
        }
    }
    // first copy files
    for (sourceFile, destFile) in filePairArray {
        do {
            try FileManager.default.copyItem(at: sourceFile, to: destFile)
        } catch CocoaError.fileWriteFileExists {
            if force {
                try FileManager.default.trashItem(at: destFile, resultingItemURL: nil)
            } // if file exists and foce is false, the program has thrown already
        }
    }
    // then remove source files
    for (sourceFile, _) in filePairArray {
        try FileManager.default.trashItem(at: sourceFile, resultingItemURL: nil)
    }
}

func moveFiles(filePathArray:[String], to destDirectory:String, forcefully force:Bool) throws {
    let fileArray = try completePath(of: filePathArray, relativeTo: destDirectory)
    try moveFilesInternal(filePairArray: fileArray, forcefully: force)
}

func destDirectoryAndForce() throws -> (String, Bool) {
    let errorMessage = "Need target directory"
    // get arguments
    let argumentArray = CommandLine.arguments.dropFirst()
    var force = false
    var destDirectory:String? = nil
    // handle options
    if argumentArray.count == 0 {
        throw ProgramError.NotEnoughArguments(errorMessage)
    }
    for argument in argumentArray {
        switch argument {
        case "-h", "--help":
            print(helpMessage)
            throw ProgramError.Terminate()
        case "-f", "--force":
            force = true
        default:
            destDirectory = argument
            break
        }
    }
    if !(destDirectory != nil) {
        throw ProgramError.NotEnoughArguments(errorMessage)
    } else {
       return (destDirectory!, force)
    }
}

func getFilesFromPasteboard() -> [String]? {
    // get items
    let pasteboard = NSPasteboard.general
    guard let items =  pasteboard.pasteboardItems else {
        print("No files in pasteboard")
        return nil
    }
    // transform to file paths
    var filePathArray: [String] = []
    for item in items {
        let string = item.string(forType: NSPasteboard.PasteboardType("public.file-url"))
        if string != nil {
            let path = string!.removePrefix("file://").removingPercentEncoding!
            filePathArray.append(path)
        }
    }
    return filePathArray
}

func putFilesToPasteboard(files fileArray:[String]) throws {
    // check for possible errors
    for path in fileArray {
        if !FileManager.default.fileExists(atPath: path) {
            throw FileError.FileNotFound(path)
        }
    }
    // create items
    let pasteboardItems = try fileArray.map { path -> NSPasteboardItem in
        let item = NSPasteboardItem()
        let filename = URL(fileURLWithPath: path).lastPathComponent
        guard let formatedPath = (path as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) else {
            throw FileError.PathInvalid(path)
        }
        item.setString("file://" + formatedPath, forType: NSPasteboard.PasteboardType("public.file-url"))
        item.setString(filename, forType: NSPasteboard.PasteboardType("public.utf8-plain-text"))
        return item
    }
    // write to pasteboard
    NSPasteboard.general.clearContents() // you have to clear before write
    if !NSPasteboard.general.writeObjects(pasteboardItems) {
        throw PasteboardError.FailedToWritePasteboard()
    }
}

func getFilePaths() throws -> [String] {
    // handle options (--help)
    let errorMessage = "Need at least one file path"
    let arguments = Array(CommandLine.arguments.dropFirst())
    var pathArray:[String] = []
    switch arguments[safe: 0] {
    case nil:
        throw ProgramError.NotEnoughArguments(errorMessage)
    case "-h", "--help":
        throw ProgramError.Terminate()
    default:
        pathArray = arguments
    }
    // complete paths
    pathArray = pathArray.map {path -> String in
        return URL(fileURLWithPath: path).standardizedFileURL.path
    }
    if pathArray.count == 0 {
        throw ProgramError.NotEnoughArguments(errorMessage)
    } else {
        return pathArray
    }
}
