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

func completePath(of filePathArray:[String], relativeTo directory:String) throws -> [(URL, URL)] {
    let directoryURL: URL
    if !directory.starts(with: "/") {
        directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(directory)
    } else {
        directoryURL = URL(fileURLWithPath: directory)
    }
    if !FileManager.default.fileExists(atPath: directoryURL.path) {
        throw FileError.FileNotFound("\(directoryURL) does not exist")
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

func destDirectoryAndForce() -> (String, Bool)? {
    guard let argument = CommandLine.arguments[safe: 1] else {
        print("Not enough arguments")
        return nil
    }
    var force = false
    var destDirectory = ""
    
    switch argument {
    case "-h", "--help":
        print(helpMessage)
        return nil
    case "-f", "--force":
        force = true
        if let directory = CommandLine.arguments[safe: 2] {
            destDirectory = directory
        } else {
            print("Not enough arguments")
            return nil
        }
    default:
        destDirectory = argument
    }
    return (destDirectory, force)
}

func getFilesFromPasteboard() -> [String]? {
    let pasteboard = NSPasteboard.general
    guard let items =  pasteboard.pasteboardItems else {
        print("No files in pasteboard")
        return nil
    }
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
