# RecordSet.Statement, DDL.Statement
Property of `RecordSet` or `DDL` object that holds text of SQL statement  

#### Syntax
rs.**Statement**  
ddl.**Statement**
#### Remarks
    You can read `Statement` property of `RecordSet` or `DDL` object to learn which SQL statement was assigned to it.  
  
You can also assign new value to this property, in which case next time [Execute\(\)](sql.execute.md) method is invoked, it will use this new statement. If new statement has question marks or host variables, they will take effect during next execution.  
  
There is no performance advantage in reassigning SQL statement rather than creating new `RecordSet` or `DDL` object. Re-assign statement property only if is more convenient for your program than creation of new object.
#### Example
    
    
        function debugSQL( rs )
             debugTrace("Executing SQL statement: " & **rs.Statement** )
             rs.execute()
             return rs.next()
        end function
    
        insert = new DDL("DELETE FROM table1")
        insert.execute()
        insert.**statement** = "DELETE FROM table2"
        insert.execute()
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [RecordSet.Execute\(\)](sql.execute.md)[](builtin.addseconds.md)
