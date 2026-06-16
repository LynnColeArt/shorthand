# ENV
Returns the value of operating system environment variable.  

#### Syntax
**ENV**\(name\)
#### Parameters
_name_
    any string expression that specifies variable name.  
Remember that on Unix names of environment variables are case-sensitive \(`PATH_TRANSLATED` and `path_translated` refer to different variables\) and on Windows they are not \(`PATH_TRANSLATED` and `path_translated` refer to the same variable\).
#### Return Value
    the string value of requested environment variable, which is empty string if variable is not defined.
#### Remarks
    The set of environment variables available to ShortHand engine highly depends on operating system and web server software under which ShortHand runs. Web server, depending on its configuration, may decide to hide some variables normally provided by OS or reveal some additional variables not normally defined by OS. Different web servers may do this differently.  
  
Normally, when ShortHand engine is running as CGI script or web server module \(Apache module, for example\), the following standard CGI environment variables are available \(typical values are mentioned where appropriate\):  
  
**Variable Name** | **Meaning**  
---|---  
`SERVER_SOFTWARE` | The name and version of the information server software answering the request.  
Examples:  
`Apache/1.3.26 (Win32) mod_ssl/2.8.10 OpenSSL/0.9.6f`  
`Apache/1.3.20 (Linux/SuSE) PHP/4.0.6 mod_perl/1.26`  
`Microsoft-IIS/5.0`  
`SERVER_NAME` | The server's hostname, DNS alias, or IP address as it would appear in self-referencing URLs. For example: `24.1.100.15`, `boulder`, `www.mysite.com`, `www.mysite.co.uk`.  
`GATEWAY_INTERFACE` | The revision of the CGI specification to which this server complies. Format: CGI/revision.  
Example: `CGI/1.1`  
`SERVER_PROTOCOL ` | The name and revision of the information protcol this request came in with.  
Format: protocol/revision.  
Example: `HTTP/1.1`  
`SERVER_PORT ` | The port number to which the request was sent.  
Example: `80`  
`REQUEST_METHOD ` | The method with which the request was made. For HTTP, this is `GET`, `HEAD`, `POST`, etc.  
`PATH_INFO ` | The extra path information, as given by the client. In other words, scripts can be accessed by their virtual pathname, followed by extra information at the end of this path. The extra information is sent as PATH\_INFO. This information should be decoded the by the server if it comes from a URL before it is passed to the CGI script.  
Example: `/cgi-bin/index.shh`  
  
`PATH_TRANSLATED ` | The server provides a translated version of PATH\_INFO, which takes the path and does any virtual-to-physical mapping to it. For ShortHand, this variable typically contains full name of top-level ShortHand file in the terms of operating system.  
Example: `/usr/local/sites/mysite/html_root/index.shh`  
`SCRIPT_NAME ` | A virtual path to the script being executed, used for self-referencing URLs.  
Example: `/admin/products.shh`  
`QUERY_STRING ` | The information which follows the `?` in the URL which referenced this script. Normally contains encoded fields of GET form request if current request is response to form submission. ShortHand automatically parses this environment variable \(if it is available\) and makes all values encoded in it available through built-in[ Q\(\)](builtin.q.md) function.   
Example: `start=10&count=50&refreshButton=Refresh+Table`  
`REMOTE_HOST` | The name of the client host making the request. If the server does not have this information, it should set REMOTE\_ADDR and leave this unset.  
Example: `24.90.118.147.nyc.rr.com`  
`REMOTE_ADDR ` | The IP address of the remote host making the request.  
Example: `24.90.118.147`  
`AUTH_TYPE ` | If the server supports user authentication, and the script is protects, this is the protocol-specific authentication method used to validate the user.  
`REMOTE_USER ` | If the server supports user authentication, and the script is protected, this is the username they have authenticated as.  
`REMOTE_IDENT ` | If the HTTP server supports RFC 931 identification, then this variable will be set to the remote user name retrieved from the server. Usage of this variable should be limited to logging only.  
`CONTENT_TYPE` | For queries which have attached information, such as HTTP POST and PUT, this is the content type of the data.  
ShortHand automatically processes this variable to determine POST variables \(see [F\(\)](builtin.f.md) function\).  
`CONTENT_LENGTH ` | The length of the said content as given by the client.  
ShortHand automatically processes this variable to determine POST variables \(see [F\(\)](builtin.f.md) function\).   
`HTTP_ACCEPT ` | The MIME types which the client will accept, as given by HTTP headers. Other protocols may need to get this information from elsewhere. Each item in this list should be separated by commas as per the HTTP spec. Format: type/subtype, type/subtype.  
Example:   
`image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/msword, application/x-gsarcade-launch, application/x-quickviewplus, */*`  
`HTTP_USER_AGENT` | The browser the client is using to send the request. You can normally use this variable to determine client's browser type \(Internet Explorer, Netscape Navigator, Opera, etc\) and version in order to perform some actions \(produce different HTML code\) differently for different browsers.  
Examples:  
`Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)`,  
`Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.0rc1) Gecko/20020417`,  
`Opera/6.01 (Windows 2000; U) [en]`,  
`Mozilla/4.79 [en] (Windows NT 5.0; U)`,  
`Scooter/3.3`,  
`FAST-WebCrawler/3.6 (atw-crawler at fast dot no; http://fast.no/support/crawler.asp)`  
  
The above list includes standard variables mentioned in CGI specification. Your web server may or may not support some of these variables or may provide additional variables. Consult your web server software manual before using any of these environment variables in ShortHand programs. 
#### Example
    
    
        browserSpec = ENV("HTTP_USER_AGENT")
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [Q\(\) function](builtin.q.md), [F\(\) function](builtin.f.md)
