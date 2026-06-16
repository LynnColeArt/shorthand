# Boolean Expressions
Boolean expressions \(also known as _conditions_ or _predicates_\) are expressions that have two possible values - TRUE and FALSE. ShortHand uses boolean expressions in conditional \(IF-THEN-ELSE\) operators and all types of loops. Any expression can be used as boolean expession by itself, and you can combine one or more expressions into conditions.  
  
You can combine regular numeric, string and other expressions into boolean conditions by comparing them to each other. Here is the list of possible comparisons:  
  
expression < expression | Less than  
---|---  
expression > expression | Greate than  
expression = expression | Equals  
expression \!= expression  
expression <> expression | Not equals  
expression <= expression | Less than or equals  
expression >= expression | Greater than or equals  
The exact sense of comparison depends on the type of compared expressions. See notes below about comparison rules.   

Conditions themselves, in turn, can be combined into complex conditions by using logical operators AND, OR, NOT:  

condition1 AND condition2 | TRUE if both condition1 and condition2 are TRUE  
---|---  
condition1 OR condition2 | TRUE if at least one of condition1 or condition2 is TRUE  
NOT condition | TRUE if condition is FALSE  
  
AND operator has the highest priority over OR, and NOT operator has lower priority than OR. Use parenthesis to explicitly group conditions in complex expressions.  
  
ShortHand uses "short" scheme for evaluating conditions combined using AND or OR operators, which means that if after evaluation of left operand of AND/OR expression the result of entire expression is already known, the right operand is not evaluated \(and if the right part contains function calls, these functions will **not** be called\).  
  
For example:   

    
    <~  
        _' FileIsGood() is user-defined function_
        **if** FileExists(fileName) **AND** FileIsGood(fileName) **then**  
            ....
        **end if** ~>
      
---  
  
If function FileExists\(\) in this example returns FALSE, the outcome of entire comparison is already known, and the function FileIsGood\(\) will not be executed.  
  
You can also use any numeric or string expression as condition. In this case the expression will be converted to number and will evaluate to TRUE if the number is not zero. String "ABC" for example, will evaluate to zero which means condition will be FALSE. 
    
        i = 4  
        **if** i **then**  
           _' condition is TRUE_    
           ....  
        **end if**
      
        x = "ABC"
        **if** x **then** 
            ... _' condition is FALSE_  
        **end if**  
---  
  

# Comparing different types
There are few important rules that you should be aware of when you compare values of different data types.  
  
When both compared expressions are of the same type, comparison is straightforward - ShortHand does what you normally would expect - numbers are compared as numbers and strings are compared using common alphanumeric comparison like in most programming languages. When you use any standard omparison operator mentioned in this section, strings are compared case-sensitively - i.e. strings `"User"` and `"user"` are not equal.  
One date is considered to be less than other date if it comes earlier in calendar sense. If any of date expressions contains time part \(hours, minutes, seconds\), these parts are also used in comparison - i.e. the date expression `October 1st, 2002 4:10pm` is **less** than `October 1st, 2002 8:55pm.`
If two expressions used in comparison have different types, the following rules apply: 
  * If one operand is numeric and other is not, non-numeric operand is converted to number \(integer of float depending on the type of numeric operand\).  
  

  * If one operand is date and other is not, the date is converted to the type of other operand \(number or string\). Dates convert to numbers as Julian Day Numbers \(JDN\) - see [Dates](lang.dates.md), and to strings using default date format which is `"22 Jul 2002, 6:17 AM"`.   
  

  * You can use objects in comparisons to check if two variables refer to the same object \(`object1 != object2`\) or to test if object is NULL or is not NULL \(`cookie1 != NULL`\).  
All other comparisons involving objects \(>,<, etc\) are allowed but don't have any practical meaning.
