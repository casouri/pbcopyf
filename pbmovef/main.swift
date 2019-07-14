//
//  main.swift
//  pbcopyf
//
//  Created by Yuan Fu on 2019/7/12.
//  Copyright © 2019 Yuan Fu. All rights reserved.
//

import Foundation
import Cocoa

let helpMessage = """
Pasteboard move file: move files currently in pasteboard to target directory.

Usage:
    pbmovef [options] <target directory>

Options:
    -h --help    Show this message
    -f --force   force overwrite files that exist
"""

func main() {
    do {
        let (destDirectory, force) = try destDirectoryAndForce()
        guard let filePathArray = getFilesFromPasteboard() else {
            return
        }
        try moveFiles(filePathArray: filePathArray, to: destDirectory, forcefully: force)
    } catch ProgramError.Terminate {
        return
    } catch {
        print(error)
    }
}

main()
