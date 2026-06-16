# urlencode
Encodes string using "URL-Encoding" scheme   

#### Syntax
**urlencode**\(string\)
#### Parameters
_string_
    any string expression
#### Return Value
    new encoded string
#### Remarks
    `urlencode()` encodes string using "URL Encoding" so that it can be used as part of URL.  
  
This type of encoding is normally used to pass HTML forms fields or other data in HTTP URL requests.  
  
Examples of URL-encoded data \(encoded strings are bold\):   

    
    **Quick+Brown+Fox**  ("Quick Brown Fox")
    **http%3a%2f%2fwww%2fshorthand%2forg**  ("http://www.shorthand.org")
      
---  
  
Use `urldecode()` function when you need to some pass some data containing spaces or other invalid URL characters through an URL or hyperlink.  
  
For example:   

    
    <~  
        if not authenticate() then
             ' variable errorText may contain spaces, newlines, etc.    
             redirect("login.shh?errorText=" & **urlencode**(errorText))
        end if
    ~>
      
---  
  
`urldecode() `translates space characters into '**+** ', and all non-alphanumeric character into **%NN** sequences \(except comma, dot and underscore\) where **NN** is hexadecimal code of the character. For example, newline character becomes **%0a** , dash\(-\) becomes **%2d** , and percent sign \(**%**\) becomes **%25**.  
  
Be careful not to apply `urlencode()` transformation twice. 
#### Example
    
    
        errorText = "Transaction declined:\n" & reason
        url = "declined.shh?error=" & urlencode(errorText)
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [urldecode](builtin.urldecode.md), [Q\(\)](builtin.q.md), [F\(\)](builtin.f.md)
