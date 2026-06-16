# urldecode
Decodes URL-encoded string into plain text.   

#### Syntax
**urldecode**\(string\)
#### Parameters
_string_
    any string expression
#### Return Value
    new decoded string
#### Remarks
    `urldecode()` converts string "encrypted" using "URL Encoding" algorithm to plain text.  
  
This type of encoding is normally used to pass HTML forms fields or other data in HTTP URL requests.  
  
Examples of URL-encoded data \(encoded strings are bold\):   

    
    **Quick+Brown+Fox**  ("Quick Brown Fox")
    **http%3a%2f%2fwww%2fshorthand%2forg**  ("http://www.shorthand.org")
      
---  
  
Note that when you deal with GET or POST request variables, you don't have to use urldecode\(\) to decode names or values of such variables - ShortHand does this automatically and corresponding [Q\(\)](builtin.q.md) and [F\(\)](builtin.f.md) functions return already decoded values.   
  
Use `urldecode()` function only when you need to decode values obtained elsewhere \(cookies, URLs, etc\), or if form variables underwent double encoding for some reason.  
  
`urldecode() `translates **+** to space character and **%NN** sequences \(where NN are hexadecimal digits\) to the corresponding ASCII-codes. 
#### Example
    
    
        url = "http%3a%2f%2fwww%2fshorthand%2forg"
        print urldecode(url)   ' prints "http://www.shorthand.org"
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [urlencode](builtin.urlencode.md), [Q\(\)](builtin.q.md), [F\(\)](builtin.f.md)
