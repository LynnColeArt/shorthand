# RecordSet.EOF
Rerorts whether or not SQL record set stands at last row of data.  

#### Syntax
rs**.EOF**\(\)
#### Parameters
_none_
#### Return Value
    `TRUE` \(non-zero\) if RecordSet is at the last row \(or there are no rows at all\)  
`FALSE` \(zero\) if there are more rows available after current row 
#### Remarks
    `RecordSet.EOF` method allows you to determine the moment when the end of result set has been reached during RecordSet iteration.  
RecordSet object maintains "current row" pointer which is a sequential number of the current row in the entire result set. When you iterate RecordSet manually using [Next](sql.next.md) method and/or automatically using GRID loop, this pointer advances.  
  
When record set contains no data \(SQL query returned zero rows\), EOF will always return TRUE.  
When record set contains one record, EOF will also return TRUE after this record was fetched.  
  
`EOF` is an opposite of [MORE](sql.more.md).
#### Example
    
    
       rs = new RecordSet(conn, "SELECT * FROM product ORDER BY id")
       rs.execute()
       ' process up to first 10 records
       for i = 1 to 10
           rs.next() 
           .....
           if rs.**eof**() then
              break
           end if
       end for
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [More\(\)](sql.more.md), [Next\(\)](sql.next.md)
