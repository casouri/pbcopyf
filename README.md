#  pbcopyf

Copy, paste and move files from command line for macOS. For example, you can put some files to
pasteboard by `pbcopyf` and use <kbd>⌘+V</kbd> in Finder to paste it. Basically:
```
 ⌘C = pbcopyf
 ⌘V = pbpastef
⌥⌘V = pbmovef
```

`pbcopy` and `pbpaste` can only handle text, not files. Hence these tools.

NOTICE: these tools haven't gone through extensive tests, so don't use them on important files!

# Install

## Binary

Grab the binaries from [here](https://github.com/casouri/pbcopyf/releases)

## Compile from source

Clone the repository, open with Xcode, select each target and build them.

# Usage

## pbcopyf
```
Pasteboard copy file: put files into the pasteboard.

Usage:
pbcopyf [options] <files ...>

Options:
-h --help    Show this message
```

## pbpastef
```
Pasteboard paste file: paste files in the pasteboard to target directory.

Usage:
pbpastef [options] <target directory>

Options:
-h --help    Show this message
-f --force   force overwrite files that exists
```

## pbmovef
```
Pasteboard move file: move files in the pasteboard to target directory.

Usage:
pbmovef [options] <target directory>

Options:
-h --help    Show this message
-f --force   force overwrite files that exists
```

