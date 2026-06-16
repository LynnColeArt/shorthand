# FOREACH Loop
FOREACH loop repeatedly executes a block of statements for every value \(or key+value pair\) in the specified [hash array](lang.hashes.md).  
FOREACH loop has the following syntax: 
    
       **FOREACH** hashArray **AS** value 
            ...
            statements
            ...
       **END FOR**
    
where `hashArray` is any expression that has [Hash Array](lang.hashes.md) value. Value is the name of the variable that receives value of the next hash array element during each iteration.   
  
Second version of FOREACH loop: 
    
       **FOREACH** hashArray **AS** key => value 
            ...
            statements
            ...
       **END FOR**
    
where `key `is the name of the variable that receives **key** of the next hash array element during each iteration. Use this second version when you need to access both keys and values of hash array elements.  
  
For example:   

    
    <~ 
       colors["red"] = "#ff0000"
       colors["green"] = "#00ff00"
       ...
    ~>  
    
    Standard Color Names:<br>
    <table> 
      <tr><td>Name</td><td>Value</td></tr>
      <~ **foreach colors as** colorName**= > **colorValue ~>
         <tr>
            <td><~@ colorName ~></td>
            <td color="<~@colorValue~>"><~@ colorValue ~></td>   
         </tr>
      <~ **end for** ~>
    </table>  
---  
  
A block of stements inside FOREACH \(loop body\) is executed for every value in the array. The order in which values are traversed is not specified - i.e. it is not alphanumeric and is not the same order in which the values were put into the array.  
However, if you don't put new elements to the same instance hash array or delete existing elements between two traversals, the order will be the same.  
  
You can change contents of the hash array during execution of FOREACH loop, but if keys are added or deleted, there's no guarantee that new entries will be "visited" by current loop - \(however deleted entries that haven't been visited yet will not be\). Also, if add new entries in the middle of the loop, some entries that have been passed by the loop may be passed again.   
  

#### See Also
     [Hash Arrays](lang.hashes.md), [FOR](lang.for.md), [WHILE](lang.while.md), [GRID](lang.grid.md)
