# File.EOF
Returns column value of the current record of `RecordSet` object.  

#### Syntax
file**.EOF**\(\)
#### Parameters
    none
#### Return Value
    Non-zero if the end of file has been reached. Zero otherwise.
#### Remarks
    Use `EOF()` to detect the moment when you should stop reading file \(if you read it by chunks using [Read](file.read.md) or by lines using [Readln](file.readln.md)\). 
#### Example
    
    
    f = new File(fileName, "r")
    while not f.**eof**()
        processLine(f.readln())
    end while
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [File.Read](file.read.md), [File.Readln](file.readln.md)
