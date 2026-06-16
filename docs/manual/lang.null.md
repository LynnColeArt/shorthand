# NULL Value
**NULL values** are actively used everywhere in ShortHand. When global or local variable or function parameter or return value was not explicitly initialized, it has NULL value. When object property was not explicitly defined, it has NULL value. When you use function call in expression and function doesn't return anything, you get NULL value. When you retrieve data from database column that has NULL value in SQL sense, you will receive the same NULL value.
You can also expicitly use NULL keyword to produce NULL value.  
  
Think of NULL value as an empty string. When printed or otherwise used in string context, it will yield empty string. When evaluated in numeric context, it will produce zero. If used as boolean condition, NULL value will evaluate to FALSE.   
  

Example \(assuming the text below makes entire program\):   

    
    <~  
       print x  _' prints nothing - x was not initialized_ 
       if x = 0 then 
          println "x is zero" _' prints 'x is zero'_
       end if 
    ~>
      
---  
If you need to check if expression is null or not null, you can compare it to NULL or to empty string:  

    
    <~  
       if x != "" then 
           ....
       end if 
       
       ' the same thing  
       if x != NULL then 
          ...
       end if
    ~>
      
---  
Similarily, if you wish to explicitly assign NULL value to a variable, assign NULL or empty string to it.
