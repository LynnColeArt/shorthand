# Hash Arrays
_Hash Array_ is another type of array supported by ShortHand \(together with [Numbered Arrays](lang.arrays.md)\) - a collection of ShortHand values each having _index_ and _value_.  
  
Unlike in numbered arrays, elements in hash arrays are identified by strings, not by numeric indexes. Hash arrays do not contain redundant records - whic means that hash array contains exactly as many elements as you have explicitly put into it.  
  
Elements in hash arrays are accessed using curly brace syntax:  

**variable\{index\}**
where variable is variable name and `index` is any ShortHand expression that is evaluated as string.   
  
There is no specific syntax to create hash array variables. Any variable becomes hash array \(even if it had different type before\) when you use it with \{\} on the left side of assignment:  
  

    
    
      request**{** "X_Test_Request"**}** = "FALSE"  
    
      
---  
  
Hash keys are case-sensitive - i.e. `var{"One"}`, `var{"one"}` and `var{"ONE"}` refer to three different elements of hash array.  
  
You can traverse hash arrays using [FOREACH](lang.foreach.md) loop, however, the order in which elements are iterated is not alphabetical or numeric and is not the same order in which elements were added to the array:  
  

    
    
       foreach x as key=>value
          println "x{" & key & "} = " & value    
       end for
    
      
---  
  
  
The number of entries in hash array can be determined by querying pseudo-property `count` of hash variable \(the variable must non-null and have hash value for `count` to work\):   

    
      
     x{"Two"} = 2
     x{"Five"} = 5
     x{"Twenty Five"} = 25
    
     print x.count   ' prints 3   
    
      
---  
  
In most situations it is perfectly normal to use numbers \(or most other types\) as hash keys. But keep in mind that numbers are converted to strings in `{...}` context - `x{03}` and `x{"03"}` are different things.   
  

    
      
     x{"03"} = 2222
     x{03} = 333 
     print x{3}    ' prints 333   
     print x{"3"}  ' prints 333
     print x{"03"} ' prints 222
    
      
---  
  
The values that you put into hash array can be of any type - numbers, strings, objects or other hash arrays or numbered arrays. And you can use hash element references as keys or values of other arrays or object fields.   
  

    
     ' hash within hash 
     x{"Twenty"}{"Two"} = 22
    
     ' numbered array as hash element
     x{"Thirty"}[5] = "Thirty Five"
    
     ' object as hash element
     queries{"q1"}.execute()
    
     ' two-dimensional numbered array with hash array elements  
     colors[x][y]{"red"} = 255
    
     ' element of two-dimensional numbered array is used as key of hash array
     colorName = colorNames{colors[x][y]}
    
     ' access property of an object that is stored in hash array
     cookies{"Cookie1"}.value = "Blah Blah Blah"  
    
      
---  
  
As example above demonstrates, ShortHand allows to use primitive values, all types of arrays and objects in any combinations. This allows to create structures of unlimited complexity.   
  
When you assign entire array to other variable, ShortHand uses _assignment by reference_ \- which means that object is not "cloned" - only its reference is copied. If you later modify contents of array using original variable, it will be reflected when you access it through other variables \(and the other way round\):  
  

    
      
     a{"One"} = 1
     a{"Two"} = 2
     b = a
     print b{"Two"}  ' prints 2  
     a{"Two"} = 222
     print b{"Two"}  ' prints 222    
     b{"One"} = 111
     print a{"One"}  ' prints 111
    
      
---  
  

#### See Also
    [Numbered Arrays](lang.arrays.md)
