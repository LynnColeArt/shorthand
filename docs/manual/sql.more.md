# RecordSet.More
Reports whether or not `RecordSet `object has more rows available after the current one.  

#### Syntax
rs.**More**\(\)
#### Parameters
_none_
#### Return Value
    `TRUE` \(non-zero\) if `RecodSet` has more data \(and `next()` will succeed\)  
`FALSE` \(zero\) if `RecordSet` doesn't have more data \(it stands at the last row or there are no rows at all\)
#### Remarks
    `More()` method helps you to determine the end of result set condition when you iterate `RecordSet` manually using next\(\) or automatically using `GRID`.  
  
Note that `More()` returns FALSE when record set stands on the last record, even if this record is the only one. It also returns FALSE if RecodSet object doens't have any rows at all. Be careful not to miss last record when you check for end-of-data condition using `More`. Normally you should call more\(\) **after** the record has been fetched.  
  
`More()` is the opposite of [EOF\(\)](sql.eof.md). 
#### Example
    
    
        rs = new RecordSet(cdb, "SELECT id, name FROM product")
        rs.execute()
        for i=1 to 10
            rs.next()
            .....
            if not rs.**more**() then
               break
            end if
        end for
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [Next](sql.next.md), [EOF](sql.eof.md), [GRID](lang.grid.md)
