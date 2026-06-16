# RETURN
Return operator stops execution of current user-defined function and optionally _returns_ a value from it. It is valid only inside function definition. Return has the following syntax:  

    
        **RETURN** [expression]
    
where expression may be any valid ShortHand [expression](lang.expressions.md). Expression is optional. If you don't specify return value, the function will just stop execution and will return control to the caller.  
  
If you call function that didn't return anything in expression, [NULL](lang.null.md) value is assumed.  
  
For example:   

    
    function sum(a, b)   
       **return** a + b
    end function
    
    function requireAuthentication()   
      if isAuthenticated() then
         **return** 
      end if
      if not authenticate() then
         redirectToLogin()
      end if
    end function  
    
      
---  
  
See also [Function Definition](lang.defun.md).
