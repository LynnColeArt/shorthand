# File Object
File object represents operating system file and exposes methods and properties to perform different file operations.  
  
`File` object constructor has the following syntax:  

    
       new **File**(FileName [, OpenMode])
    
#### Constructor Parameters:
`_FileName_`
    Full name of the file. File names on Unix must use slashes to separate path components. On Windows, you can use both slashes and backslashes \(but if you use backslashes, you have to duplicate them - like in `C:\\Program Files\\ShortHand\\file.txt`\). 
`_OpenMode_`
    Optional parameter that tells in what mode to open the file \(read-only, write-only or read/write\) and what to do if file doesn't exist. Mode is a string expression that have the same meaning as in standard C `fopen()` function. Possible values are:  `"r"` | Open file in read-only mode. If file doesn't exist, operation will fail.  
---|---  
`"r+"` | Open file for reading and writing. If file doesn't exist, operation will fail.  
`"w"` | Open file for writing only. If file exists, its contents are destroyed. If file doesn't exists, it will be created.  
`"w+"` | Open file for reading and writing. If file exists, its contents are destroyed. If file doesn't exists, it will be created.  
`"a"` | Open file for writing only. File pointer is placed at the end of the file. If file doesn't exists, it will be created.  
`"a+"` | Open for reading and writing. File pointer is placed at the end of the file. If the file does not exist, attempt to create it.  
if you omit `OpenMode` parameter, `"r"` is assumed.  

ShortHand tries to open \(or create\) file at the moment when you construct `File` object. Unlike other objects, no error is generated if file operation fails, including open operation. Error condition can be checked by examining `error` property of file object \(which is NULL if there is no error and contains error message if there is an error\).  
  

    
       ...
       f = new **File**("/usr/local/shorthand/file.txt", "r") 
       if f**.error** != NULL then
          return f**.error**
       end if  
---  
  
You can also use [FileExists](builtin.fileexists.md) builtin function to check if file exists.  
  
Windows file I/O functions normally make distinction between so called "text" and "binary" file open modes. If file is opened in "text" mode \(which is default\), it undergoes translation of end-of-line characters. ShortHand opens all files in binary mode and always turns off "text" mode on Windows \(even if you add character "t" to open mode\). 
#### Methods
    File object exposes the following methods:
     **·** | [read](file.read.md) | Reads data from the file  
---|---|---  
**·** | [readln](file.readln.md) | Reads a line of text from the file  
**·** | [write](file.write.md) | Writes data to the file  
**·** | [close](file.close.md) | Closes file  
**·** | [eof](file.eof.md) | Reports end-of-file condition  
**·** | [rewind](file.rewind.md) | Rewinds file pointer to the beginning of the file.  
#### Properties
     **·** | **name ** | mirrors file name passed to the constructor. changing this property has no effect.  
---|---|---  
**·** | **mode** | mirrors open mode passed to the constructor. changing this property has no effect.  
**·** | **error** | contains status of the last I/O operation \(or construction\). if there was no error, this property has value NULL. otherwise it contains error messahe \(like "No such file or directory"\).  
#### See Also
    [FileSize](builtin.filesize.md), [FileExists](builtin.fileexists.md)
