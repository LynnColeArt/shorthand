# Variables
Variable in a ShortHand is a named object that has some value. A variable name consists of alphanumeric characters and undescrore character \('\_'\). Only Latin characters are allowed, and a name must start with a letter or underscore \(not digit\). The case of characters in variable names doesn't matter. Terms `TableName`, `tablename` and `TABLENAME` all refer to the same variable. Variable name can be any valid identifier with exception of few [reserved words](apx.keywords.md). 
With exception of local variables, you do not need to declare variables before you use them. All variables are treated as global unless they are marked as local inside [user-defined functions](lang.udf.md).   
  
For example:   

    
    BGCOLOR = "#FFFFFF" 
    print "i=" & i   
      
---  
Internally, the variable is created first time it is referenced in the statement that is executed. If the variable didn't have any value assigned to it before, the variable is considered to have [NULL](lang.null.md) value. You set or change variable name by performing assignment:
    
    BGCOLOR = "#FFFFFF" 
    size = width * height   
      
---  
Though it is not required, we recommend to initialize all variables by assigning some value to them before using them in the program.
  

#### See Also
    [Predefined Variables](lang.predefined-vars.md)
