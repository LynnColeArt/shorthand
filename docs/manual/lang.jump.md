# JUMP
`JUMP` operator transfers control to another ShortHand file without returning to the current file. It works exactly like `[INCLUDE](lang.include.md)`, only execution of current file is not resumed after included file is finished. `JUMP` operator has the following syntax:  

    
       **JUMP** fileName
    
Where `fileName` is quoted string or expression that specifies target file to perform `JUMP` to. The rules that apply to file name and file search algorithm are the same as for [INCLUDE](lang.include.md) command.  
  
`JUMP` works like server-side redirection in Web server/client model. Behavior of `JUMP` is somewhat similar to HTTP redirection \(see [redirect](builtin.redirect.md)\). Only `JUMP` transfers control to another ShortHand file \(dynamically produced web page\) within current HTTP request.  
  
One possible use of `JUMP` is to provide different versions of web page to the client browser under the same URL preserving current ShortHand environment and without revealing any details to the client browser.   
  
For example, the following `JUMP` command provides English, Spanish or French version of web page depending on the value of cookie received from the client browser:   

    
    <~  
       lang = getCookie("lang")
       if lang = "es" then
           jump "directions.es.html"
       elseif lang = "fr" then
           jump "directions.fr.html"
       else 
           jump "directions.en.html"
       end if
    ~>
      
---  
  
Note that above example can be implemented as HTTP redirection using built-in [redirect\(\)](builtin.redirect.md) function.   
  
The choice of whether to use server-side `JUMP` or HTTP redirection highly depends on the application. `JUMP` can be more efficient in some situations, because it preserves ShortHand execution environment including variables and database connections. For example, when your ShortHand page uses database connection and you want to transfer control to another ShortHand page that uses the same database connection, `JUMP` can speed things up be eliminating the need to re-establish ShortHand environment including database connections \(comparing to HTTP redirection\).   
  
In other cases, however, it may be more favorable to use HTTP redirection. 
#### See Also:
    [INCLUDE](lang.include.md)
