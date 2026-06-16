# FileExists
Reports whether or the file with specified name exists.  

#### Syntax
**FileExists**\(name\)
#### Parameters
_name_
    any valid string expression that specifies file name.
#### Return Value
    non-zero value \(TRUE\) if file exists and is readable  
zero \(FALSE\) if file doesn't exist
#### Remarks
    Even if some file exists, it may be not readable by ShortHand application because it may not have all required permissions or it may be locked by other application.  
  
You should always use absolute file names in ShortHand programs, because relative names rely on the current directory of the OS process running ShortHand engine, which value cannot be predicted in most cases.
#### Example
    
    
        if not FileExists("/usr/local/myapp/myapp.cfg")
            ....
        end if
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [FileSize\(\)](builtin.filesize.md), [File object](object.file.md)
