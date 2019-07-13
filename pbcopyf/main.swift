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
Pasteboard copy file: put files into pasteboard.

Usage:
    pbcopyf [options] <files ...>

Options:
    -h --help    Show this message
"""

func main() {
    do {
        let filePathArray = try getFilePaths()
        try putFilesToPasteboard(files: filePathArray)
    } catch ProgramError.Terminate() {
        return
    } catch {
        print(error)
    }
}

main()
