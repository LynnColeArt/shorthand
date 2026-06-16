# File.Read
Reads data from the file  

#### Syntax
file**.Read**\(\[count\]\)
#### Parameters
_count_
    specifies maximum number of bytes to read from the file.  
if this parameter is not specified or is zero, everything from current position up to the end of file is read.  

#### Return Value
    String containing a piece of data read from the file.
#### Remarks
    Though ShortHand reads file in binary mode, Read method returns string. It doesn't perform any translations, but if a piece of data returned from `Read` contains zero bytes \(null-terminator\), the resulting string will be truncated at first null terminator.  
  
You can use Read method to read contents of entire file if you use it right after you opened the file.  
  

#### Example
    
    
    f = new File("/usr/local/myapp/template.html", "r")
    templateContents = f.**read**()
    f.close()
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [File.Readln](file.readln.md)
