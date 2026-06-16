# f
Returns the value of POST request variable.  

#### Syntax
**f**\(name\)
#### Parameters
_name_
    any valid string expression that specifies POST variable name. Names of POST request variables are always case-sensitive, no matter what operating system ShortHand is running on.
#### Return Value
    The value of requested POST request variable. Empty string if such variable was not defined.
#### Remarks
    POST variable names are always case-sensitive and have nothing to do with OS environment variables. Normally \(though not necessarily\) POST variables are the values of HTML Form fields received by ShortHand engine when client browser submits HTML form using `POST` method.   
  
For example, when the the following HTML form:  

    
    <FORM name=LoginForm Form method="POST">
      <INPUT type=hidden name=uid value="23582357275">
      <INPUT type="checkbox" name="remember" value="7523535255134052072547" checked> Rememer login<br>
      <table>  
        <tr><td>Login:</td><td><INPUT type=text name="name"></td></tr>
        <tr><td>Password:</td><td><INPUT type=password name="pwd"></td></tr>
      ...
    </FORM>  
---  
is submitted to Shorthand program, the following POST variables will be available:  
`uid`, `remember`, `name` and `pwd`. 
#### Example
    
    
        userName = F("name")
        password = F("pwd")
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [Q\(\)](builtin.q.md) function.
