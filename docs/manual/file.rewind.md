# File.Rewind
Rewinds file pointer to the beginning of the file.  

#### Syntax
file**.Rewind**\(\)
#### Parameters
    none
#### Return Value
    none
#### Remarks
    Use `Rewind()` method to move file pointer to the beginning of file so that you can restart read operations as though the file was just opened. `Rewind` doesn't have any effect on write operations.  

#### Example
    
    
    f = new File(fileName, "r")
    b1 = findSomething(f)
    f.**rewind**()
    b2 = findSomethingDifferent(f)
    f.close()
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [File.Close](file.close.md)[](builtin.addseconds.md)
