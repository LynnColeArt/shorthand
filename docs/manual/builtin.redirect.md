# redirect
Performs HTTP redirection.  

#### Syntax
**redirect**\(url\)
#### Parameters
_url_
    URL of the new page or resource that client browser should be pointed to.
#### Return Value
    none. if redirection is successfull, this function does not return.   
if redirection cannot be performed \(because HTTP headers have already been sent\), exception is thrown.
#### Remarks
    `redirect()` function performs HTTP redirection - it sends special resonse code that instructs client browser to take resource \(web page\) from address different from the originally requested address. When client browser receives such response, it automatically performs new HTTP request to the new URL that you specified during redirection.  
  
if ShortHand successfully sent redirection response, further execution of current ShortHand program is aborted, as though the end of program has been reached or [exit\(\)](builtin.exit.md) function was invoked.   
  
If you don't specify complete URL when doing redirection \(i.e. address that starts with `http://, ``https://`, `ftp://`, etc and contain complete server name\), new URL would be relative to the orginal URL of the current request \(if page `http://www.mysite.com/subdir/index.shh` redirects to `/login.shh`, new URL would be `http://www.mysite.com/login.shh`\).  
  
New URL does not have to be in the same domain or server where your server resides. You can redirect client browser to `http://www.yahoo.com`, for example \(unless you are `www.yahoo.com`, in such case you will not receive second request, of course\).   
  
There are thousands of possible uses of HTTP redirections. For example, when client browser tries to access the page in restricted area of you web site and client's identity canot be verified, you would redirect client browser to the login page. If you offer web site in different languages, you would redirect client browser to the page in appropriate language based on previously chosen client's preference saved in a cookie.  
  
One important thing to understand about HTTP redirections is that you have to send redirection **before** any HTML output is produced. Every HTTP response that is sent to the client browser is preceeded with HTTP headers - special piece of information that describes status of request and the content \(if there is any\) that would follow. Once the header block went out, it is impossible to change its contents \- client browser reads it only once.  
  
ShortHand holds any headers that need to be sent until the moment it encounters first unescaped HTML block or [print](lang.print.md) command which produces HTML content. Headers are sent out right before ShortHand processes this first block of unescaped HTML or `print` command.   
  
You have to handle redirections, cookies, and other things that require changing of HTTP headers in first `<~ ~>` block that is located in the beginning of ShortHand file or in other file that is [included](lang.include.md) in such block.  
  
For example \(correct way\):   

    
    <~  
      include "auth.shh" 
      if not authenticated() then
          redirect("/login.shh")  
      end if
    ~>
    <HTML>
    <HEAD>
       <TITLE>Welcome to secure area</HTML>  
    </HEAD>
     ....
    </HTML>  
---  
  
**Wrong** way - an exception will be generated:   

    
    <~  
      include "auth.shh" 
    ~>
    <HTML>
    <HEAD>
       <TITLE>Welcome to secure area</HTML>  
    </HEAD>
    <~
      ' wrong - will not work 
      if not authenticated() then
          redirect("/login.shh")  
      end if
    ~>
     ....
    </HTML>  
---  
This second example will **not** work because by the time you have called `redirect()`, some HTML text has already been sent to the client - the piece of raw HTML between `<HTML>` and `</HEAD>` tags \(and HTTP response headers have been sent right before this first chunk of content\).
#### Example
    
    
        redirect(ENV("SERVER_NAME") & "/login.shh")
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [JUMP](lang.jump.md), [Cookies](cookies.md)
