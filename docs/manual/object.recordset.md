# RecordSet Object
RecordSet object encapsulates SQL result set, normally produced by SELECT statement or stored procedure. ShortHand RecordSet constructor has the following syntax:  

    
       new **RecordSet**(ConnectionObject, SQLStatement)
    
#### Constructor Parameters:
`ConnectionObject`
    An object of type [Connection](object.connection.md) that defines on which database connection the statement will be executed.
`SQLStatement`
    Any text that is arbitrary SQL statement valid in terms of underlying DBMS.  
In addition, SQL Statement may contain special patterns that are preprocessed by ShortHand engine \- see remarks below.
RecordSet objects provides a number of methods that allow to execute it, iterate through rows, query different properties and extract row data.  
  
Typically usage of RecordSet object looks like this: 
    
       ...
       usersSQL = new **RecordSet**(shopConnection, "SELECT * FROM users ORDER BY name")
       usersSQL.execute()
       while not usersSQL.eof()
           usersSQL.next()
           ....
           print usersSQL.value("id")
           ....
       end while
      
---  
  
SQL Statement is not executed when you construct RecordSet object. Actual execution is deferred until you explicitly invoke `execute()` method or until [GRID](lang.grid.md) loop executes the statement implicitly.   
  
You can any SQL statement with RecordSet, not necessarily `SELECT`. In this case the statement will be executed when RecordSet is executed, but no results will be produced if you use `INSERT` for example.  
For `INSERT`, `UPDATE`, `CREATE TABLE`, and other DML or DDL statements that do not return any data, use [DDL](object.ddl.md) object that is similar to `RecordSet`, but optimized specifically for such statements.   
  
SQL Statement passed to RecordSet or DDL objects may contain two types of special patterns that are recognized and replaced by ShortHand engine: 
  * Question Marks:  

           query = new RecordSet(db, "SELECT * FROM order WHERE id = **?** AND status = **?** ")
      
---  
For each question mark you'll have to pass one parameter to `execute()` method.   

  * Variable Names 
           query = new RecordSet(db, "SELECT * FROM order WHERE id = **:OrderID** AND status = **:OrderStatus** ")
      
---  
All `:variable` sequences are replaced by values of corresponding variables at the time of statement execution. 

[Parametrized SQL](sql.param.md) section describes in details how this substution works.   
  
RecordSet objects are automatically destroyed when current ShortHand program finishes. 
#### Methods
    RecordSet object has the following methods:
     **·** | [execute](sql.execute.md) | Executes the statement  
---|---|---  
**·** | [next](sql.next.md) | Fetches next row   
**·** | [more](sql.more.md) | Tells whether or not there are more rows to fetch  
**·** | [rownum](sql.rownum.md) | Returns sequential number of current row  
**·** | [count](sql.count.md) | Returns total number of rows in result set  
**·** | [eof](sql.eof.md) | Tells whether or not there are more rows to fetch  
**·** | [value](sql.value.md) | Returns value of particular column  
#### Properties
     **·** | [statement](sql.statement.md) | Text of SQL statement   
---|---|---
