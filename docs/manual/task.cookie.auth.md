# Cookies Authentication
One of common tasks that [cookies](cookies.md) can be used for is user authentication.  
  
HTTP protocol itself provides some means to perform authentication, but for a variety of reasons, this mechanism is not widely spread. One of the reasons is that web browser sends user name and password in clear text format with every HTTP request being made to your server after the user has entered name and password. Also, when using HTTP authentication, the browser takes over name and password entry and shows its own dialog box. Authentication mechanism provided by HTTP protocol is more oriented for operating system-based authentication and is usually more difficult to control from server-side applications, especially in hosted environments. You can use secure version of HTTP protocol \(HTTPS\) with HTTP-based authentication to make sure passwords are not sent over the wire in clear text, but this means that entire secure area of you site must be accessed over HTTPS, which is slower in many cases is just overkill.   
  
Cookies-based authentication works like this:  

  * User enters his name and password in HTML form. HTML form can itself be served over HTTPS and/or submitted over HTTPS protocol for added security.   
  

  * You server application evaluates supplied credentials using OS or database or any other information to make decision on whether or not to allow access.   
  

  * If access is granted, your application creates persistent **session** object backed by database table or a file, that contains at least Session ID and user name. Session ID must be big random number or string \(for example, `4f1c597a4837557a0c7b8d1e18d4d3c8)` that is **not sequential** , not based on current date and is impossible to guess by any means. It is absolutely essential that session ID is completely random. Few major web sites have been exposed to "Predictable Session ID" attacks recently because users could deduce session IDs of other users \(and access other users' data\) just by changing few last digits of their own session ID.   
  
Your server application creates and sends to the client browser a cookie that contains session ID and redirects client browser to some page in secure area of your site. You can define expiration period of this cookie \(for example, 30 minutes, or 30 days\) which will define how long this session will exist until the user has to authenticate himself again using name and password.  
  

  * Next time client browser makes request to any page in secure area of your site, it sends a cookie containing session ID. First thing **every** page in secure area must do is to evaluate this cookie and see if it matches existing session previously stored in a database of file. If it matches, the user name/ID is derived from the session record and processing continues.  
  
If session is not found or is expired, a page in secure are should [redirect](builtin.redirect.md) client browser to login page.  
  

  * When user explicitly logs out of secure area of your web site, your application must delete corresponding session record from database or file. To handle sessions that were not explicitly terminated using logout feature, some kind of background process can be implemented that periodically \(once a week for example\) goes through all sessions stored in a database or file system and removes records that were not active for some period of time. 

[A separate section](task.cookie.auth.example.md) of this manual provides example of database-backed cookie-based authentication implemented using ShortHand.
