# Basic Syntax
When ShortHand executes the file, it simply prints the contents of the file untill it encounters specially marked pieces of text having ShortHand statements inside. Such statements are parsed and executed as commands of ShortHand language. The most common use for ShortHand is to produce dynamic HTML pages, but nothing prevents from using it for any other similar task.  
  
ShortHand language commands are delimited from the outside text by _escape tags_. Supported escape tags include <~ ~>, <% %> and <? ?>. Everything included between such tags is treated by ShortHand as the actual program, and everything outside is printed as is.   
  
Further in this manual, we will use <~ ~> notation in all examples.  
  
For example:   

    
    <~ include "mydb.shh" ~>
    <% productCount = Q("SELECT COUNT(*) FROM products") %>
    <? print "Number of products: "&productCount ?>  
---  
  
You can use any of three types of tags, but opening and closing tag must match. For example, you cannot start a piece of program by <~ and finish it by ?>.   
  
In examples above, the statements within <~ ~> and other tags are _executed_ and nothing is printed unless actual statements contain explicit PRINT commands.   
  
Very common task for any pre-processing language like ShortHand is printing of the value of a variable or expression in the middle of a text block. ShortHand has special kind of tags that provide such functionality: <~@ ~>.  
Similar tags exist for % and ? styles: <%= %> and <?= ?>.   
  
For example:  

    
    <html>
    <head>
       <title><~@ "ShortHand Demo: " & getPageTitle() ~><title>
    </head>
    ...
    <input name="login" type="text" value="<~@ Q("LOGIN") ~>">  
---  
  
In this example, everything included in <~@ ~> is treated as _expression_ , the value of which is _printed_ rather than just executed.
