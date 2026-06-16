# header
Sets value of HTTP response header.  

#### Syntax
**header**\(name, value\)
#### Parameters
_name_
    string expression that specifies header name 
_value_
    string expression that specifies header value \(can be empty or NULL\)
#### Return Value
    none. 
#### Remarks
    `header()` function gives you ability to override HTTP response headers sent to the client browser at the beginning of HTTP response.  
  
If you don't know anything about HTTP headers, don't use this function.  
  
If header with specified name is already defined in current context, its previous value is overriden by `header()` function. If it didn't exist before, new header is created. Header names are case-sensitive. You can override any header using this function, though use caution and make sure you know what you are doing. If you override `Content-Length` header for example, and do not send required number of bytes to the HTTP output stream, this would cause client browser to hang.  
  
ShortHand and its hosting web server software automatically take care about processing of HTTP headers and there is rarely any need for this function. However, there may be legitimate reasons why you would want to use it - for example to change content type of the response. By default, ShortHand sets content type to `text/html` which instructs client browser to treat output as HTML document. If you know that whatever you are sending to the client is not HTML document \(it is GIF image, for example, obtained from file\), you can use `header` function to override default value:  
  

    
    header("Content-Type", "image/gif")
      
---  
  
  
You can use `header()` function and few other functions that indirectly affect HTTP headers only **before** anything is sent to the client browser. Normally you should have header\(\) function within initial `<~ ~>` block in the beginning of you ShortHand file. HTTP headers are sent at the moment when first chunk of HTML \(or other\) text is printed to the standard output stream. After headers have already been sent, you cannot override them, and exception will be generated if you try to call `header()` after that. 
#### Example
    
    
        header("P3P", "CP=\"NOI OTC OTP OUR NOR\"")
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [SetCookie](builtin.setcookie.md)[](builtin.addseconds.md)
