# If-Then-Else
Conditional operator IF-Then-Else you to execution ether one or another block of statements depending on the outcome of logical condition. If-Then-Else in ShortHand has the following syntax:  

    
       
    IF <condition> THEN
       <statements>
    END IF
| 
    
       
      IF <condition> THEN 
         <statements1>
      ELSE
         <statements2>
      END IF
| 
    
       
      IF <condition1> THEN  
         <statements1>
      ELSEIF <condition2>
         <statements2>
      ELSEIF <condition3>
         <statements3>
      ....
      END IF  
---|---|---  
ELSE part is optional. If condition is not satisfied, nothing is executed.  
You can also use any number ELSEIF clauses to specify additional branches. Last ELSEIF also may optionally be followed by ELSE.  
  
Some Examples: 
    
    
       if ccType = "MC" then   
           ccTypeName = "MasterCard"  
           ccDigist = 16
       elseif ccType = "VI" then
           ccTypeName = "Visa"
           ccDigits = 16
       elseif ccType = "AE" then
           ccTypeName = "American Express"    
           ccDigits = 15 
       else
           ccTypeName = "Unknown"
       end if 
     
       ' another example
       session_id = GetCookie("sid")
       if user_id = 0 AND session_id = NULL then
           session_id = GenerateSessionID()
           SetCookie(new Cookie("sid", session_id))
       end if  
---
