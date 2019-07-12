//
//  main.swift
//  pbcopyf
//
//  Created by Yuan Fu on 2019/7/11.
//  Copyright © 2019 Yuan Fu. All rights reserved.
//

import Foundation
import Cocoa

let helpMessage = """
Pateboard paste file: paste files currently in pasteboard to target directory.

Usage:
pbpastef [options] <target directory>

Options:
-h --help    Show this message
-f --force   force overwrite files that exists
"""

func main() {
    guard let (destDirectory, force) = destDirectoryAndForce() else {
        return
    }
    guard let filePathArray = getFilesFromPasteboard() else {
        return
    }
    do {
        try pasteFiles(filePathArray: filePathArray, to: destDirectory, forcefully: force)
    } catch {
        print(error)
    }
}

main()
