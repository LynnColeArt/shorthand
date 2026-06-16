# DDL Object
DDL object represents SQL statement that doesn't return any rows. These statement include Data Manipulation Language \(DML - INSERT,UPDATE,DELETE\), Data Definition language \(DDL - things like CREATE TABLE\) and any other commands or administrative statements supported by the underlying DBMS \(GRANT, EXPLAIN PLAN, etc\).  
  
DDL constructor has the following syntax:  

    
       new **DDL**(ConnectionObject, Statement)
    
#### Constructor Parameters:
`_ConnectionObject_`
    An object of type [Connection](object.connection.md) that defines on which database connection the statement will be executed.
`_Statement_`
    Any text that is arbitrary SQL/DML/DDL statement valid in terms of underlying DBMS.  
In addition, SQL Statement may contain special patterns that are preprocessed by ShortHand engine \- see remarks below.
DDL object is implemented as a lightweight version of [RecordSet](object.recordset.md) object that doesn't have overhead of results processing. DDL parameter subsitution and construction works the same as for RecordSet and DDL shares method [Execute](sql.execute.md) with `RecordSet` object.  
  
Typically usage of DDL object looks like this: 
    
       ...
       inserter = new **DDL**(shopConnection, "INSERT INTO product(id,name,price) VALUES(?,?,?)") 
       inserter.execute(1, 'Product One', 39.99)
       inserter.execute(2, 'Product Two', 49.99)
      
---  
  
  
SQL Statement passed to DDL object may contain two types of special patterns that are recognized and replaced by ShortHand engine: 
  * Question Marks:  

           query = new DDL(db, "UPDATE orders SET status = **?** WHERE id = **?** ")
       query.execute(status, id)
      
---  
For each question mark you'll have to pass one parameter to `execute()` method.   

  * Host Variables: 
           query = new DDL(db, "UPDATE orders SET status = **:status** WHERE id = **:id** ")
       query.execute()
      
---  
All `:variable` sequences are replaced by values of corresponding variables at the time of statement execution. 

[Parametrized SQL](sql.param.md) section describes in details how this substution works.   
  
DDL objects are automatically destroyed when current ShortHand program finishes. 
#### Methods
    DDL object exposes the following methods:
     **·** | [execute](sql.execute.md) | Executes the statement  
---|---|---  
#### Properties
     **·** | [statement](sql.statement.md) | Text of SQL statement   
---|---|---
