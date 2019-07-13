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
    do {
        let (destDirectory, force) = try destDirectoryAndForce()
        guard let filePathArray = getFilesFromPasteboard() else {
            return
        }
        try pasteFiles(filePathArray: filePathArray, to: destDirectory, forcefully: force)
    } catch ProgramError.Terminate() {
        return
    } catch {
        print(error)
    }
}

main()
