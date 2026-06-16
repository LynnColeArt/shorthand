# RecordSet.Count
Reports total number of records that RecordSet object contains.  

#### Syntax
rs.**Count**\(\)
#### Parameters
_none_
#### Return Value
    Total number of records that SQL query represented by `RecordSet` object produces.
#### Remarks
    `RecordSet.Count` method must be invoked only **after** `RecordSet` object has been executed \(explicitly using [execute\(\)](sql.execute.md) method or implicitly by [GRID](lang.grid.md) statement\).   
  
If you need to know number of records before starting GRID loop, execute statement explicitly. GRID statement in this case will not execute it again.  
  
`RecordSet.Count` works for non-SELECT statements, but always returns zero.
#### Example
    
    
    <~
       rs = new RecordSet(conn, "SELECT * FROM customer")
       rs.execute()
       totalCount = rs.**count**()
    ~>
       Total number of records: <~@ totalCount ~><br>
       Showing records <~@ first ~> to <~@ last ~><br>  
    <table>
       <tr><td>ID</td><td>Name</td><td>Company</td>
       <~ grid (rs) ~>
         <tr>
            <td><~@ rs.value("id") ~></td>
            <td><~@ rs.value("name") ~></td>
            <td><~@ rs.value("company") ~></td>
         </tr>
       <~ end grid ~>
    </table>
      
---  
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [RecordSet.Execute](sql.execute.md), [GRID](lang.grid.md)
