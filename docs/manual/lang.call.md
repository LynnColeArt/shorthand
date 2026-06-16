# Function Calls
You can use calls to built-in or user-defined functions both as expressions or as a standalone instructions. Function may or may not return value and if you use function call in expression, the function is executed, but the value of such expression is [NULL](lang.null.md).  
  
To call a function, just put its name and follow it by parenthesis. Inside parenthesis you can put any number of arguments or no arguments. Even if you don't pass any arguments to the function, you still have to put parenthesis after function name. This applies to both built-in functions and to functions that you define yourself.  
  
Examples of function calls:   

    
    <~ 
        _' call function that returns connection object_
        conn = createNewConnection()    
    
        _' call function that does something with cookies
        ' but doesn't return any value_
        processCookies()  
    
        _' call function that finds and returns a product by ID_
        prod = findProduct(product_id)    
    
    _' call function that formats current date
        ' one of arguments is itself function call and the result
        ' is used in expression_    println "Today is " & FormatDate(now(), "%A, %B %d, %Y")     
     
    _' call function with arguments that performs credit card
        ' processing and returns boolean value_    if (processCreditCard(ccnum,ccexp,ccname)) then
             ....
        end if
    ~>
      
---  
  
The number and types of parameters that you pass to the function depend entirely on the function itself. Function may or may not check number and types of parameters. Most built-in functions perform this check and generate an error if parameters are invalid.
Function names have different namespace from variables. Though it is not recommended, you can define a function with the same name as some variable and define a variable that has the same name as existing function. ShortHand distinguishes function calls from variable references by presence of parentheses after the name.
