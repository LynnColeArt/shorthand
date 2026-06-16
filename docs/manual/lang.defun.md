# Function Definition
ShortHand allows programmers to define their own functions. Function definition has the following syntax:  

    
       **FUNCTION** functionName **(**[arg1, arg2, ....]**)**
            ....
            statements
            ....
       **END FUNCTION**
    
Where `functionName` is any valid identifier; `arg1, arg2, ...` is optional list of formal parameters and statements is a sequence of any valid ShortHand [statements](lang.statements.md).  
  
Function name must follow the same rules as variable name \(See [Variables](lang.variables.md)\) \- i.e. contain only Latin alphanumeric characters, underscore, and you cannot be one of [reserved words](apx.keywords.md). ShortHand allows you to define function having the same name as one of [built-in](lib.functions-list.md) functions, though it is not recommended, because your definition will hide built-in function. You may not define function with the same name twice - interpreter will generate an error.  
  
You can optionally declare a list of formal parameter names \(arguments\) within parenthesis after function name. Parameter names can be any valid identifiers. Parameters work as variables visible only within function definition. If you don't declare any parameters, you still have to use parenthesis.  
  
Some examples:   

    
    
    ****function** sum**(a, b)   
        return a + b
    **end function**
    
    **function redirectToLogin**()
       redirect("login.shh")
    **end function**
    
    **function requireAuthentication**()
       authenticate()
       if not isAuthenticated() then 
           redirectToLogin()
       end if
    **end function**  
---  
  
Function must be defined _before_ it can be used. If one of your functions uses another function, that function must be declared before - like `redirectLogin()` in the example above.  
  
Operators within function body will have access to all the same variables that are visible in the code outside function definition. If you write ` a = 5 ` within function, this operator will change the value of global variable `a`.  
  
To avoid possible conflicts, you should always declare local variables within function body for internal calculations. [Local Variables](lang.local.md) topic contains detailed description of local declarations.   
  

    
    function generateSessionID(size)
       **local** sid = ""
       while (length(sid) < size)
         sid = sid & (1000000+rand(999999))  
       end while
       if length(sid) > size then
          sid = substring(sid, 0, size)
       end if
       return sid
    end function  
---  
  
In the example above, variable `sid` is explicitly declared as local, and even if global variable `sid` exists in current scope, this function will not change its value. Local declarations hide global objects with the same name for operators within function body. Parameter names behave the same way. Parameter `size` in the example above has nothing to do with global variable \(or function\) called `size` if such exists.   
  
The function can call itself recursively:   
  

    
    _' reverse the string_
    function **reverse**(s)
      local len = length(s)
      if len <= 1 then
          return s
      else
          return substring(s, -1) & **reverse**(substring(s, 0, len-1))
      end if
    end function
    
      
---  
  
Note that for every call, local variable `len` and formal parameter `s` are created that exist only within the scope of current function \(they are not propagated into other functions that you call from your function\).   
  
For user-defined functions, ShortHand doesn't enforce number and types of parameters or return values. If you pass more values to the function than the number of parameters it declares, extra parameters will be evaluated, but discarded. If you pass less values, missing parameters will assume NULL values:  
  

    
    function sum3(a, b, c)  
       print "a=" & a & "; "
       print "b=" & b & "; "
       print "c=" & c & ";"
    end function  
      
    sum3(10, 20)          _' will print_ "a=10; b=20; c=;"
    sum3(10, 20, 30, 40)  _' will print_ "a=10; b=20; c=30;"    
---  
  
A common practice is to gather all function definitions that are used within some application into reusable "libraries" - one ore more ShortHand files that you [include](lang.include.md) into your ShortHand programs.
