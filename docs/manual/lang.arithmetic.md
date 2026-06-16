# Arithmetic Operators
ShortHand supports four basic arithmetic operations that you know from school, and modulus operator \(%\).
    
    <~  
        a = b + c   ' addition 
        a = b - c   ' subtraction 
        a = b * c   ' multiplication 
        a = b / c   ' division
        a = b % c   ' modulus
    ~>
      
---  
  
There is nothing tricky about these operations, except that you should be aware of special behaviour of division operator.  
If you divide one expression by another expession, the result will always be integer number \(`126/10 = 12`, i.e. remainder is discarded\) unless at least one of operands is floating-point number. For most practical cases such integer division is sufficient, but if you specifically want to force floating-point division, use the following trick:  
  

    
    <~  
        a = (b + 0.0) / c   ' forces floating-point arithmetic 
    ~>
      
---  
  
By adding `0.0` to the quotient or denominator, you force the expression to have floating-point type internally.
