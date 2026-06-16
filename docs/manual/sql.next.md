# RecordSet.Next
Fetches next record of the RecordSet and advances current row number  

#### Syntax
rs**.next**\(\)
#### Parameters
_none_
#### Return Value
    `TRUE` \(non-zero\) if next\(\) successfully fetched next row  
`FALSE` \(zero\) if next\(\) failed because there are no more rows
#### Remarks
    `**Next**` method tries to fetch next row of the record set. If there is no next row, `next()` does not generate an error, but returns boolean value FALSE. In this case, current record data and current row number remain intact.  
  
Note that you have to call next\(\) not only to fetch subsequent records, but first record too, immediately after the statement has been executed \(unless you're using GRID\). Execute\(\) method does not automatically fetches first row.   
  
If you you are using GRID loop to iterate RecordSet, there is no need to call next\(\), unless you want to artificially advance record set within GRID, for example, to present recordset data using multi-column view.  
  
For example, here we present a list of products using GRID statement, and use next\(\) to produce multiple columns:   

    
    <~ GRID( prod, first, last ) ~>
      <TR>
      <~ col = 0
       WHILE col < columnCount
           IF prod.eof THEN
              BREAK
           END IF
      ~>
        <TD valign="top">
            ID: <~@prod.id~>:<br> 
            Name: <~@prod.name~><br>  
            Price: <B>$<~@prod.price~>
            <IMG SRC="<~@prod.picture~>" VSPACE=4 HSPACE=8>  
        </TD>
        <~
          IF last > 0 AND prod.rownum >= last THEN
              BREAK
           END IF
          col = col + 1
          IF col < columnCount THEN
              prod.**next()**
          END IF
      END WHILE ~>
      </TR>
      <~ i = i + 1 ~>
    <~ END GRID ~>
      
---  
#### Example
    
    
        rs = new RecordSet(db, "SELECT * FROM users")
        rs.execute()
        while rs.**next**()
            ...
        end while
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [RecordSet.More](sql.more.md), [RecordSet.EOF](sql.eof.md), [GRID](lang.grid.md)
