# File.Close
Closes file.  

#### Syntax
file**.Close**\(\)
#### Parameters
    _none_
#### Return Value
    none
#### Remarks
    `Close` method closes opened file. If file was opened for writing, file buffers are flushes to disk.  
  
Always use `Close` when you finished working with the file. This will ensure that OS file handle is released. Number of file handles available in OS and per individual process is not infinite. When your application that uses files runs in web server that receives a lot of requests, a limit on the number of file handles may quickly become an issue if you don't close files. 
#### Example
    
    
    f = new File(templateFileName)
    content = f.read()
    f.**close**()
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
