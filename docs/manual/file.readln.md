# File.Readln
Reads one line of text from the file  

#### Syntax
file**.Readln**\(\)
#### Parameters
_none_
#### Return Value
    Next line of text from the file, with any trailing new-line characters stripped from it.
#### Remarks
    `Readln` reads data from the file starting at current position until next end-of-line character is encountered or until the end of file if new-line character is found.  
`Readln` uses symbol **\n** \(LF - ASCII code 10\) to detect end of line, but it also strips any **\r** characters \(CR - ASCII code 13\) directly preceeding LF. This ensures that files created using both "DOS" \(CR-LF\) and Unix \(LF\) end-of-line convensions are handled the same way. 
#### Example
    
    
      ' iterate file lines
      f = new File(fileName, "r")
      println "<pre>"
      while not f.eof()
          s = f.**readln**()
          println "Line "&i&": "&s
          i = i + 1
      end while
      f.close()
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [File.Read](file.read.md)
