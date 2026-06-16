# Numbered Arrays
Array in ShortHand is a special type of object that contains collection of other values. Array values can be of any type - integers, strings, objects or other arrays. Array indexes are non-negative integer numbers - therefore we would also refer to this kind of arrays as _numbered arrays_. Different type of arrays - [Hash Arrays](lang.hashes.md) \- offers string indexes and different behavior.   
  
Arrays were introduced in ShortHand in version 1.1.0  
  
Array elements are accessed using square brackets syntax:   

    
    
      months[3] = 31
      names[i+1] = "One Two Three"
      daysInMonth = months[month]  
      
      
---  
  
There is no special syntax to create array. Once you used `variable[index]` expression on the left side of assignment \(like in the first two lines of the above example\), variable automatically becomes array, even if it had value of different type before.   
  
If you use `variable[index]` as expression \(not in the left part of assignment\) where `variable` is not array variable, the expression will produce NULL value and variable's type will be left intact.   
  
Elements in numbered arrays are internally arranged according to their indexes \(counting begins at zero\). Array size is automatically adjusted when new elements are added. If you have empty \(uninitialized\) array and assign value to the element with index 9, array will have 10 elements after this operation. Elements 0 through 8 will be initialized to NULL values.  
  

    
    
      x[9] = 999
      x[4] = 444
    
      println "array x has "& x.count & " elements "   ' prints "10"   
      
---  
  
This is very similar to how arrays are implemented in JavaScript language.  
  
Current version of ShortHand supportes one pseudo-property for numbered arrays - `count` \- which returns number of elements in the array. It can be used only against variables that are already arrays:   

    
    
        arrayVariable[i] = x
        ...
        elementCount = arrayVariable**.count**  
    
      
---  
  
There is no restriction on the type and number of array elements. For example, you can use [objects](lang.objects.md) of any type as arrary elements:   
  

    
    cookies[0] = new Cookie("cookie1")  
    cookies[1] = new Cookie("cookie2")  
    cookies[2] = new Cookie("cookie3")  
      
---  
  
You can also create two-dimensional arrays and arrays with arbitraty nesting by using array elements as arrays themselves.   
For example, the code below creates two-dimensional array representing multiplication table of numbers 1 through 10:   
  

    
    for i=1 to 10
      for j=1 to 10
        matrix[i][j] = i * j   
      end for
    end for
      
---  
  
  

#### See Also
    [Hash Arrays](lang.hashes.md)
