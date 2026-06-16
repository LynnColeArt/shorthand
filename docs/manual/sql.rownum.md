# RecordSet.RowNum
Reports current row number of the RecordSet object  

#### Syntax
rs**.RowNum**\(\)
#### Parameters
_none_
#### Return Value
    Current row number of `RecordSet` object \(starting with 1\)  
**0** if RecordSet hasn't been executed yet  
**-1** if RecordSet has gone past last row or if there are no rows
#### Remarks
    `Rownum()` reports sequential number of the current row in `RecordSet`. First row has number one and last row number equals to the number of records in the result set. Calling `RowNum()` makes sense only if `RecordSet` has any data, otherwise it returns zero or minus one.  
  
If `RecordSet.next()` method has been called when `RecordSet` was already at the last row, `RowNum()` will return **-1**.
#### Example
    
    
         prod = new RecordSet(db, "SELECT * FROM product WHERE brand = :brand")
         prod.execute()
         ...
         GRID (prod, firstRecord, lastRecord)
         ....
             if lastRecord > 0 and prod.**rownum**() >= lastRecord then
     		     break
     	     end if
         ...
         END GRID
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [RecordSet.Count](sql.count.md), [RecordSet.Next](sql.next.md)
