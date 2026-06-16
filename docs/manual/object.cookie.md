# Cookie Object
Cookie Object represents ougoing HTTP cookie that may be sent to client browser as part of HTTP response.  
  
Cookie constructor has the following syntax:  

    
       new **Cookie**(name [, value [, expires [,path [, domain [,secure]]]]])
    
#### Constructor Parameters:
`_name_`
    Logical name of the cookie under which is will be stored by client browser and sent back.
`_value_`
    Optional cookie value. Arbitrary text string. Client browser may have limit on the length of cookie value that it is able to accept. Netscape specification suggests the maximum amount of data per cookie can be 4 Kb. 
`_expires_`
    Optional expiration date/time, specified as date expression. When not specified or is `NULL`, the cookie lives for the duration of browser session. \(In most cases until all browser windows are closed\). When this date is in the past, client browser is supposed to delete any existing cookies with this name and domain that it had before.
`_path_`
    Optional URL path. If defined, path specifies virtual directory on your site/domain to which this cookie is supposed to be sent back. If not specified, the browser will assume path of the request URL.   
For example, if you set path to `/secure`, the cookie will be sent back only if request URL is under this path \(`http://site/secure/...`\).
`_domain_`
    Optional host name or domain to which the cookie is supposed to be sent back. You can set it to something like `www.mysite.com` or `.mysite.com`. The domain cannot be to-level domain \(`.us`, `.com`, `.org`\) or "extended" top-level domain like `.co.uk` or `.ny.us`. In addition, this domain must match the domain on which your web server resides. ShortHand doesn't enforce these restrictions. You can set domain to whatever you like, but the client browser will just not accept cookie with invalid domain.  
If this parameter is not defined or is NULL, the client browser will use host name to which it has made the request. 
`_secure_`
    Optional flag that can be non-zero to indicate that this cookie can only be sent over secure \(https\) connection. Cookies with this flag sent over regular connections will be rejected by browsers and will not be sent back.
#### Description
     Cookie object represents HTTP cooke that can be sent to client's Web browser.  
  
In the constructor described above, all parameters are optional except for cookie name. You can either specify all necessary parameters in constructor or create a cookie using just name and then change its parameters using properties syntax:  
  

    
      c1 = new Cookie("sid", sessionID, now()+1, "/protected")
    
      c1 = new Cookie("sid")
      c1.value   = sessionID
      c1.expires = now() + 1
      c1.domain  = "/protected"
      
---  
  
  
The cookie is not being sent when it is constructed. Therefore, once you created cookie object, you can modify its properties before sending it out.  
  
To instruct ShortHand engine to send the cookie, use [setCookie\(\)](builtin.setcookie.md) built-in function that takes cookie object as argument.  
  

    
       ...
       sidCookie = new Cookie("sid", sessionID, AddMinutes(now(), 30))
       setCookie(sidCookie)  
---  
  
  
Once you have told ShortHand to send the cookie using `setCookie` function, the engine copies cookie fields into internal area containing HTTP headers, and any futher modifications to this `Cookie` object will not have any effect on what will be sent to the client.  
  
ShortHand doesn't enforce uniqueness of cookie names when you call `setCookie()`. Theoretically you can send multiple cookies with the same name \(or use `setCookie()` for the same object twice\), but the result will be unpredictable.   
  
ShortHand doesn't check validity of cookie domain, path, secure flag or value length. It is your responsibility to supply correct values for these fields \(or leave them blank\). Browsers will just reject invalid cookies. There will be no error, but the cookie will not be processed by client.
#### Methods
    Cookie object doesn't have any methods.
    
#### Properties
    Cookie object has six properties that have the same meaning as corresponding parameters passed to the constructor. All properties can assigned to.
     **·** | name | Cookie name  
---|---|---  
**·** | value | Cookie value \(payload\)  
**·** | expires | Expiration date and time  
**·** | path | URL Path  
**·** | domain | Cookie domain or host name  
**·** | secure | Indicates requirement for secure connection
