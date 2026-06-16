# RecordSet.Value
Returns column value of the current record of `RecordSet` object.  

#### Syntax
rs**.value**\(name\)
#### Parameters
_name_
    name of the column \(column names are not case sensitive in MySQL and most other DBMS\)
#### Return Value
    The value of the corresponding column of result set as string.   
Exception is thrown if result set doesn't have column with specified name, or if RecordSet does not have current row.
#### Remarks
    Use `Value()` method to obtain actual data from RecordSet object.  
  

    
       rs = new RecordSet(db, "SELECT id,name,price FROM product") 
       ...
       id = rs.**value**("id")
       name = rs.**value**("name")
       price = rs.**value**("price")
      
---  
  
You can also use object property syntax, as though `RecordSet` object has properties with the same names as columns in the result set. The above example can be rewritten using the following syntax:   
  

    
       rs = new RecordSet(db, "SELECT id,name,price FROM product") 
       ...
       id = **rs.id**
       name = **rs.name**
       price = **rs.price**
      
---  
  
These two notations are equivalent. However, you cannot use property syntax to get data from `RecordSet` if column names conflict with ShortHand [keywords](apx.keywords.md) or names of RecordSet methods or standard properties \(like [RowNum](sql.rownum.md)\).  
For example, if your SQL statement contains column named `END` or `NEXT`, writing `rs.end` will produce syntax error and `rs.next` will trigger `next()` method. To avoid this, use `Value()` method explicitly \(`rs.value("end")`, `rs.value("end")`. `Value()` method, unlike property syntax, allows you to query columns with names that are not valid ShortHand identifiers:   
  

    
    rs = new RecordSet(db, "SELECT max(created) FROM guestbook WHERE created IS NOT NULL") 
    rs.execute()
    latestDate = rs.**value**("max(created)")
      
---  
  
Note that if you use aliases for columns in SELECT statement, you have to use these aliases to reference columns in ShortHand too. If your record set contains more than one column with the same name \(for example, as a result of join of two or more tables\), ShortHand will return first one. Use column aliases in your SQL to disambiguate such columns.   
  

    
    rs = new RecordSet(db, "SELECT max(created) as latest FROM guestbook WHERE created IS NOT NULL") 
    rs.execute()
    latestDate = rs.**value**("latest")
      
---  
  

#### Example
    
    
    <~ guestBook = new RecordSet(db, "SELECT * FROM guestbook WHERE active = 1 ORDER BY created DESC") 
       guestBook.execute() ~>
    <table>
       <tr><td>Date:</td><td>User:</td><td>Comments</td></tr>
    <~ grid(rs) ~>
    <tr>
       <td><~@ FormatDate(**guestBook.created** , "%m/%d/%y") ~></td>
       <td><~@ guestBook.**value**("name") ~></td>
       <td><~@ guestBook**.value**("comments") ~></td>
    </tr>
    <~ end grid ~>
    </table>
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [RecordSet.Execute](sql.execute.md)[](builtin.addseconds.md)
