# q
Returns the value of GET request variable.  

#### Syntax
**q**\(name\)
#### Parameters
_name_
    name of the the request variable. GET variable names are case-sensitive, no matter what operating system is used. 
#### Return Value
    Value of the corresponding GET variable from HTTP request. Empty string if such variable was not passed.
#### Remarks
    GET variables correspond to `name=value` pairs passed to the current HTTP request as part of request URL after first question mark \(**?**\) character. For example, the following URL request to google.com:   
  

    
    http://www.google.com/search?hl=en&ie=UTF-8&oe=UTF-8&q=hedgehog
      
---  
  
will produce the following GET variables: **hl** \(value `"en"`\), **ie** \(value `"UTF-8"`\), **oe** \(value `"UTF-8"`\) and **q** \(value `"hedgehog"`\).  
  
Web servers normally pre-parse request URL and provide environment variable `QUERY_STRING` to CGI programs that contains everything after **?** in the passed URL. Even if web server does not automatically do this, ShortHand takes care about processing of GET variables.  
  
Usually \(but not necessarily\) URLs like in the example above are produced when the user submits HTML form having method GET \(`<form ... method="GET">`\). Web browser in this case constructs new URL that contains names and values of all fields mentioned in HTML form and their values chosen or entered by the user.  
  
Note that HTTP request doesn't necessarily have to be GET request in HTTP sense in order to have GET variables. You can receive POST requests to URLs containing **?**. In such cases you will have both GET and POST variables \(ShortHand function [F\(\)](builtin.f.md) deals with POST variables\).   
  
Function `Q()` automatically takes care about unescaping of variable names and values. For example, For the following URL:  
  

    
     http://www.myserver.com/search?&q=Quick+Brown+Fox&site=http%3a%2f%2fwww%2fshorthand%2forg 
      
---  
  
function `q` will produce the following results:  

    
    q("q") = "Quick Brown Fox"
    q("site") = "http://www.shorthand.org"
    
  

#### Example
    
    
        userName = q("login")
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [F\(\)](builtin.f.md), [urlencode\(\)](builtin.urlencode.md), [urldecode\(\)](builtin.urldecode.md)
