# File.Write
Writes data to the file.  

#### Syntax
file**.Write**\(data \[,length\]\)
#### Parameters
_data_
    a string that has to be written to the file
_length_
    maximum number of bytes to take from the string. if this parameter is not specified, entire string is written.
#### Return Value
    Actual number of bytes written to the file.
#### Remarks
    `Write()` method writes a piece of data into the file and advances file pointer. File must be opened with write access. If `Write` fails, return value is zero and error message is stored into `error` property.
#### Example
    
    
    ' dump result of SQL query into file
    
    rs = new RecordSet(db, "SELECT id,name FROM users")
    rs.execute()
    file = new File("/usr/myapp/tmp/users.txt", "w")
    while rs.next
        file.**write**(rs.id)
        file.**write**("|")
        file.**write**(rs.name)
        file.**write**("\n")
    end while
    file.close()
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [File.Read](file.read.md)[](builtin.addseconds.md)
