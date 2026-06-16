# GetCookie
Returns value of a cookie received from the client browser.  

#### Syntax
**GetCookie**\(name\)
#### Parameters
_name_
    string expression that specifies cookie name \(cookie names are case-sensitive\).
#### Return Value
    the value of the cookie, or empty string if such cookie has not been received.
#### Remarks
    [Cookies](cookies.md) section of this manual contains detailed discussion of HTTP cookies.   
`GetCookie()` function just looks for cookie with specified name that has been received from the client browser as part of current HTTP request and returns its value if the cookie was found.  
  
Any URL-encoded characters in cookie values are decoded by ShortHand. For example, if client browser set the value of a cookie to `http%3a%2f%2fwww%2fshorthand%2forg`, `GetCookie()` function will automatically decode it and return value `http://www.shorthand.org`.  

#### Example
    
    
        preferredLang = GetCookie("lang")
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [SetCookie\(\)](builtin.setcookie.md), [Cookie Object](object.cookie.md), [Cookies](cookies.md)
