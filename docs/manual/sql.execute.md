# RecordSet.Execute, DDL.Execute
Executes RecordSet SQL statement or DDL statement.  
[RecordSet](object.recordset.md) and [DDL](object.ddl.md) objects have this method and it has exactly the same semantics for both these objects. 
#### Syntax
recordSetObject.**Execute**\(\[parameters\]\)  
---  
ddlObject.**Execute**\(\[parameters\]\)  
#### Parameters
_parameters_
    A list of values that should fill all question-mark parameters specified in SQL text. If original SQL statement contained question marks, you **must** supply at least as many parameters to `execute` method.  
  
Parameters can be any expressions that are converted to strings during substitution. You have to make sure that database server will accept these values. 
#### Return Value
    none  
  
if SQL statement contains errors, or there are missing parameters, exception is generated.
#### Remarks
    `Execute` method performs actual execution of SQL statement of `RecordSet` or `DDL` object. If SQL statement contained any question marks or **:variable** patterns, this method performs substitution of all such parameters. [Parametrized SQL](sql.param.md) section describes how this substitution works in more details.  
  
Note that when you deal with `RecordSet` object, `Execute()` **does not** automatically fetches first row of data. Unless you use [GRID](lang.grid.md) statement, you have to call method `Next()` to fetch first and all subsequent rows:  
  
For example:   
Correct Way:  | 
    
       prod = new RecordSet(cdb, "SELECT * FROM product")
       prod.**execute()**
       prod.next() 
       ....
       id = prod.value("id")
       ....
      
---  
Incorrect:  | 
    
       prod = new RecordSet(cdb, "SELECT * FROM product")
       prod.**execute()**
       id = prod.value("id") _' wrong - need next()_
       ...
       prod.next() 
       ....
      
---  
  

    You can execute one RecordSet or DDL object multiple times \(possibly with different parameters\). You can also change SQL statement between executions using [Statement](sql.statement.md) property. In this case new, reassigned statement will be executed when you invoke `execute `next time.
#### Example
    
    
        rs = new RecordSet(db, "SELECT data FROM preference WHERE uid = :uid AND name = ?")
        rs.**execute**( preferenceName )
        if rs.next() then
           preferenceValue = rs.value("data") 
        end if
    
        ddl = new DDL(db, "INSERT INTO preference(uid,name,data) VALUES(:uid, ?, ?)")
        ddl.**execute**( pName, pData )
    
        ddl = new DDL(db, "CREATE TABLE foo (id INT)")
        ddl.**execute**()
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [GRID](lang.grid.md)
