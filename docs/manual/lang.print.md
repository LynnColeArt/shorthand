# Print Statement
**Print** and **println** statements print their argument as string to the _standard output_. When ShortHand engine is used as CGI script or Web server module \(which is the primary use of ShortHand\) _standard output_ is dynamically produced HTML document into which ShortHand code is included.  
PRINT statement will print its argument in the place where escaped ShortHand block was included into HTML code.   
  
When ShortHand interpeter is invoked from command line, print statement outputs to the operating system _standard output_.   
  
For example, the following pieces of HTML mixed with ShortHand will produce the same result:   

    
    <~ 
        print "<title>" & "Example" & "</title> 
    ~>
      
---  
  

    
    <title> <~ print "Example" ~> </title>
      
---  
  
The difference between PRINT and PRINTLN is that PRINTLN also prints new-line character after it has printed its argument. `PRINTLN s` s is equivalent of `PRINT s & "\n"`.  
Normally, new-line characters are ignored by Web browsers unless generated text is within `<PRE> ... </PRE> `  
HTML block. When you print multiple lines of text within <PRE> tag, PRINTLN can provide more neat and compact code.  
  
For example, the following piece of HTML code with ShortHand inclusions prints contents of text file into <PRE> block using **PRINTLN** operator:  
  

    
    <~  f = new File(fileName, "r") ~>
    File Contents:<BR>  
    <PRE>  
    <~ while not f.eof()
          **println** urlescape(f.readln())  
       end while ~>
    </PRE>
      
---
