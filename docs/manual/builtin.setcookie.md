# SetCookie
Sets outgoing HTTP cookie.  

#### Syntax
**SetCookie**\(cookieObject\)
#### Parameters
_cookieObject_
    Object of type [Cookie](object.cookie.md).
#### Return Value
    none.  
if HTTP headers have already been sent, exception is thrown.  

#### Remarks
    `setCookie()` adds new cookie to be sent to the client browser. The actual sending of cookie is not performed at the moment when you invoke `setCookie`\(\) function. All cookies together with HTTP response headers are internally accumulated by ShortHand engine and are written to the output stream only when it encounters first block of HTML code or PRINT statement.  
  
[Cookies](object.cookie.md) section of this manual contains detailed information on how to create Cookie object.  
  
Cookies are identified by their names \(which you define when you construct `Cookie` object or later by changing its `name` propety\). ShortHand doesn't enforce uniqueness of these names. It's up to you to make sure that only one cookie with unique name is set. Once you called `setCookie()` there is no way to "remove" it.  
  
One important thing to understand about cookies is that you have to set them **before** any HTML output is produced. Every HTTP response that is sent to the client browser is preceeded with HTTP headers - special piece of information that describes status of request and the content \(if there is any\) that would follow. Once the header block went out, it is impossible to change its contents \- client browser reads it only once.  
  
Outgoing cookies are set using multiple "Set-Cookie" HTTP response headers. Normally you cannot use [header\(\)](builtin.header.md) function directly to set cookies because headers are identified by names and subsequent calls to header\(\) with the same name will overwrite each other.  
  
You have to handle cookies, redirections in first `<~ ~>` block that is located in the beginning of ShortHand file or in other file that is [included](lang.include.md) in such block.  
  
For example \(correct way\):   

    
    <~
      include "session.shh"
      sessionCookie = new Cookie("sessionid", getSessionID(), AddMinutes(now(), 30)
      **setCookie**(sessionCookie)
    ~>
    <HTML>
    <HEAD>
       <TITLE>Welcome</HTML>
    </HEAD>
     ....
    </HTML>  
---  
  
**Wrong** way - an exception will be generated:   

    
    <~
      include "session.shh"
    ~>
    <HTML>
    <HEAD>
       <TITLE>Welcome</HTML>
    </HEAD>
    <~
      ' wrong - will not work
      sessionCookie = new Cookie("sessionid", getSessionID(), AddMinutes(now(), 30)
      **setCookie**(sessionCookie)
    ~>
     ....
    </HTML>  
---  
This second example will **not** work because by the time you have called `setCookie()`, some HTML text has already been sent to the client - the piece of raw HTML between `<HTML>` and `</HEAD>` tags \(and HTTP response headers have been sent right before this first chunk of content\).  
  
A cookie that you send will persist in client's browser until expiration date/time that you define \(or until browser session ends\). The browser will send the value of this cookie back to you site or to any site in the cookie domain until it expires.   
  
To force client browser to "forget" about particular cookie \(and do not send it anymore\), send a cookie with that name and expiration time in the past:  
  
For example:   

    
       setCookie(new Cookie("sessionid", "", date(1980,1,1)))  
      
---  
#### Example
    
    
        **setCookie**(new Cookie("sessionid", getSessionID(), AddMinutes(now(), 30))
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [Cookies](cookies.md), [header\(\)](builtin.header.md)
