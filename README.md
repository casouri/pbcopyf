#  pbcopyf

Copy, paste and move files from command line for macOS. For example, you can put some files to
pasteboard by `pbcopyf` and use <kbd>⌘+V<\kbd> in Finder to paste it. Basically:
```
 ⌘C = pbcopyf
 ⌘V = pbpastef
⌥⌘V = pbmovef
```

`pbcopy` and `pbpaste` can only handle text, not files. Hence these tools.

NOTICE: these tools haven't gone through extensive tests, so don't use them on important files!

## pbcopyf
```
Pateboard copy file: put files into pasteboard.

Usage:
pbcopyf [options] <files ...>

Options:
-h --help    Show this message
```

## pbpastef
```
Pateboard paste file: paste files currently in pasteboard to target directory.

Usage:
pbpastef [options] <target directory>

Options:
-h --help    Show this message
-f --force   force overwrite files that exists
```

## pbmovef
```
Pateboard move file: move files currently in pasteboard to target directory.

Usage:
pbpastef [options] <target directory>

Options:
-h --help    Show this message
-f --force   force overwrite files that exists
```
