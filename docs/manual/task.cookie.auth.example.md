# Cookies Authentication Example
The following example assumes that tables users and user\_session exist in the database. To create these tables, use the following SQL statements \(this particular example uses MySQL syntax\):  
  

    
    CREATE TABLE users (
        id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, -- user ID  
        name VARCHAR(20), -- user account name
        first VARCHAR(40), -- first name
        last VARCHAR(40), -- last name
        password VARCHAR(16), -- password
        email VARCHAR(60) -- user e-mail address
    );
    CREATE TABLE user_session (
        id BIGINT NOT NULL AUTO_INCREMENT primary key, -- internal ID of session record  
        sid VARCHAR(40) NOT NULL, -- external session ID stored in the cookie
        uid BIGINT REFERENCES users(id), - user ID
        created DATETIME, -- creation date
        expires DATETIME -- expiration date
    );
      
---  
  
  
ShortHand source of login page looks like this:   
login.shh 
    
    <~
    include "auth.shh"
    if F("FormAction") = "login" THEN
        ' login attempt
        userName = F("login")
        password = F("password")
        ' retrieve information about the user by name
        loginSQL = new RecordSet(authDB, "select id, name, password FROM users where name = :userName")
        loginSQL.execute()
        if loginSQL.next() then
           ' found user
           if password = loginSQL.value("password") then
               ' authentication succeeded - create new session in the database and
               ' redirect browser to the secured area
               userID = loginSQL.value("id")
               loginDDL = new DDL(authDB, "INSERT INTO user_session(sid,uid,created,expires) VALUES(?,?,?,?)")
               loginDDL.execute( sid, userID, now(), addMinutes(now(), 30) )
               redirect("index.shh")
               exit()
           else
               errorText = "Incorrect password"
           end if
        else
           errorText = "User name "&userName&" is not valid"
        end if
    end if
    ~>
      <html>
      <head>
      <title>Secure site Login</title>
    </head>
      <body>
      <form name=LoginForm method="POST" action="login.shh">
      <input type=hidden name="FormAction" value="login">
      <table border=0 cellspacing=0 cellpadding=0 width=100% height=100%>
         <tr><td align=middle valign=center>
         <table border=0 cellspacing=2 cellpadding=2>
      <~  if (errorText != "") then ~>
      <tr>
         <td colspan=2><b><font color=red><~@errorText~></font></b></td>
      </tr>
      <~ end if ~>
      <tr>
         <td align=left>Login:&nbsp;</td>
         <td align=left><input type="text" name="login" maxlength="20" 
      size="30" value="<~@ Q("login") ~>">&nbsp;</td>
      </tr>
      <tr>
         <td align=left>Password:&nbsp;</td>
         <td align=left><input type="password" name="password" maxlength="20" 
      size="30" value="">&nbsp;</td>
      </tr>
      <tr>
     <td colspan=2 align=right><input type="submit" name="Submit"
    value="Login "></td>
      </tr>
      </table>
    </tr></td>
      </table>
    </form>
      </body>
    </html>
      
---  
  
  
Included file auth.shh contains different service functions:  
auth.shh  

    
    <~
    ' DATABASE CONNECTION
    authdb = NEW CONNECTION("MySQL", "database=auth;server=.")
    
    ' GLOBAL VARIABLES
    sid = "" ' session ID from cookie
    uid = 0 ' user ID (zero if not authenticated)
    gUserName = ""  ' user name
    gRealUserName = "" ' real user name (first + last names)
    
    ' generates randomly-based 24-digit session ID
    function generateSessionID()
         local sid = ""
         while (length(sid) < 24)
              sid = sid & (1000000+rand(999999))
         end while
         if length(sid) > 24 then
             sid = substring(sid, 0, 24)
         end if
         return sid
    end function
    
    ' Redirects to the login page
    function redirectToLogin()
       redirect("login.shh")
    end function
    
    ' Performs authentication by checking value of the session-id cookie 
    ' and by matching this value against sessions table.
    ' If session is valid, global variable uid is set to numeric user ID
    ' and global variables gUserName and gRealUserName are also set
    '
    ' If session is invalid, uid is set to zero
    '
    function authenticate()
       local session_id = getCookie("shhsid")
       local authSQL = new RecordSet(authDB, "SELECT uid,id FROM user_session WHERE sid = ?")
       authSQL.execute(session_id)
       if authSQL.next() then
           uid = authSQL.uid
           sid = authSQL.id
           local userSQL = new RecordSet(authDB, "SELECT name,first,last FROM users WHERE id=:uid")
           userSQL.execute()
           if userSQL.next() then
               gUserName = userSQL.value("name")
               gRealUserName = userSQL.value("first") & " " & userSQL.value("last")
            end if
       end if
    end function
    
    ' Reports whether or not current session is authenticated.
    function isAuthenticated()
       if (uid != 0) then
          return 1
       else
          return 0
       end if
    end function
    
    ' Checks if session identified by cookie is valid.
    ' If session is valid, this method sets global variables uid, gUserName and gRealUserName.
    ' If session is invalid, redirects to the login page
    function requireAuthentication()
       authenticate()
       if not isAuthenticated() then
          redirectToLogin()
       end if
    end function
    
    '
    ' Destroys current session in the database, which is equivalent of logout.
    '
    function logout()
       local logoutSQL = new DDL(authDB, "DELETE FROM user_session WHERE sid = :sid")
       logoutSQL.execute()
       redirectToLogin()
    end function
    
    ' extract session ID; generate new one if session did not exist before
    ' this is a function, this is global action that is performed in any file that
    ' includes this file, so that session ID is globally available across scripts
    sid = getCookie("shhsid")
    if length(sid) != 24 then
       sidExpires = AddMinutes(now(), 10)
       sid = generateSessionID()
       sidCookie = new Cookie("shhsid", sid, sidExpires)
       setCookie(sidCookie)
    end if
    ~>  
---  
  
  
A page in secure are looks like this:  

    
    
    <~
    ' This header must be included into every page in secure are:
    **include "auth.shh"
    requireAuthentication()** ~>
      <html>
      <head>
      <title>Secure Page 1</title>
    </head>
      <body>
    <H1>This is Page One in secured area</H1>
      Welcome, <b><~@gRealUserName~></b>! Click <a href="logout.shh"> here 
      </a>to logout.<br><br>
    <a href="index.shh">Link to Secured Area Home</a>
      <br>
      <br>
      <a href="page2.shh">Link to Secured Page 2</a>
      </body>
      
---  
  
Logout page:  
  
logout.shh: 
    
    <~
    include "auth.shh"
    logout()
    exit()
    ~>  
---
