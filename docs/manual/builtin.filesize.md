# FileSize
Determines size of a file.  

#### Syntax
**FileSize**\(filename\)
#### Parameters
_filename_
    any string expression that specifies file name.
#### Return Value
    size of the specified file in bytes. If file doesn't exist or is not readable by your application, function returns \(-1\).
#### Remarks
     `FileSize()` will work only for regular files \(that are not directories and not special files, named pipes, etc\).  
  
You should always use absolute file names in ShortHand programs, because relative names rely on the current directory of the OS process running ShortHand engine, which value cannot be predicted in most cases.
#### Example
    
    
        size = GetFileSize(fileName)
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [FileExists\(\)](builtin.fileexists.md), [File Object](object.file.md)
