# Object Constructor
To use an _object_ in ShortHand, you need first to _construct_ it - i.e. create an _instance_ of an object. Object constructor has the the following syntax:  

    
        **NEW** ObjectType( [ param1, param2, ... ] )
    
Where `ObjectType` is the name of object type \(like `Cookie`, `File` or `RecordSet`\). Object constructor can have any number of parameters that need to be passed to it. Check documentation for concrete object types to see what parameters object constructor expects. Some objects may not require any parameters to be passed to constuctors, but you still have to use parenthesis.  
  
`NEW` expression can be used as any other expression - you can assign it to some variable, pass it to some function, or return it from function.   
  
For example:   

    
      conn = new Connection("MySQL", "database=demo") 
    
      products = new RecordSet(conn, "SELECT * FROM product")
    
      RETURN new RecordSet(conn, "SELECT * FROM " & tableName)
    
      processFile( new File(fileName, "r") )
       
      
---  
#### See Also
    [Objects](lang.objects.md)
