# GRID Loop
GRID is just another type of loop that is optimized for iterating [SQL record sets](object.recordset.md). Most common use for such functionality is to produce HTML tables \(grids\) that are backed by results of SQL queries - hence the name GRID.  
You can achieve the same effect by using FOR or WHILE loop with additional operations, but GRID makes it more convenient and compact.  
  
GRID Loop has the following syntax:  

    
       **GRID**( RecordSet [, FirstRow [, LastRow ] )
            ...
       **END** **GRID**
    
Where RecordSet is variable that points to a [RecordSet](object.recordset.md) object, `FirstRow` is expression that specifies number of row in the recordset to begin with and `LastRow` is expression that specifies number of last row. Row numbers start with one. FirstRow and LastRow parameters are optional, but if you specifiy LastRow, you also have to specify FirstRow.  
  
If LastRow is omitted, record set is iterated until the end. If the end is reached before row number `LastRow` is fetched, the loop finishes. LastRow allows to limit number of rows processed in a loop. If LastRow has value -1, it is the same as if it was not specified.   
  
If FirstRow is omitted, record set iterations starts with row number one. If FirstRow is specified and is greater than one, ShortHand skips \(FirstRow-1\) rows from the beginning. If end of SQL record set is reached before FirstRow, or if the record set is empty, the contents of the loop are never executed.   
  
There is no need to call **Execute**\(\) method of RecordSet object before the loop. GRID operator does this automatically. However, you can call Execute before starting the loop \(for example, to learn how many records are there\). GRID will know if RecordSet has already been executed and will not call **Execute**\(\) again.   
  
Example:   

    
    <H1>List of products:</H1>  
    
    <~ 
       products = new RecordSet(conn, "SELECT * FROM product ORDER BY name") 
       products.execute()
       
       beginWith = max(1, Q("start")) ' CGI variable start specifies starting row
       stopAt = max(1, beginWith) + max(Q("count"), 20)
       lastRecord = min(stopAt, products.count()) 
    ~> 
       <table border=0 cellspacing=2 cellpadding=2>
       <tr>
          <td colspan=4 align=right>Showing records <~@ beginWith ~> - <~@ lastRecord ~></td>  
       </tr>
       <tr> <td>ID</td> <td>Name</td> <td>Price</td> </tr>
       <~ **grid**(products, beginWith, stopAt) ~>
       <tr>
          <td><~@ products.value("id")~></td>
          <td><b><~@ products.value("name")~></b></td>
          <td align=right><b>$<~@ format(products.value("price"),2) ~></b></td>
       </tr>
       <~ **end grid** ~>
       </table>  
---  
  
The output of the above code will look like this:   
Showing records 1 - 11  
---  
ID | Name | Price  
701 | **Canon 40-MC** | **$494.99**  
702 | **Canon ZR-45MC** | **$587.69**  
703 | **Hitachi VMD-965LA** | **$411.00**  
704 | **Hitachi VME-555LA** | **$518.79**  
706 | **JVC G-DVL920** | **$593.29**  
705 | **JVC GR-DVL320U** | **$624.99**  
707 | **Panasonic PV-DV401** | **$379.00**  
708 | **Samsung SCD55** | **$400.00**  
709 | **Sharp VL-WD255U** | **$649.95**  
710 | **Sony DCR-IP5** | **$415.00**  
711 | **Sony DCR-TRV18** | **$500.00**
