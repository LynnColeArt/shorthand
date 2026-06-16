# Objects
An _Object_ in ShortHand is an entity that reflects behavior of some real-life object, operating system object, web browser object, etc. Objects have methods and properties. Methods represent actions that can be performed on objects and properties reflect current state or payload of an object.  
  
Current version of ShortHand \(1.0\) has a set of pre-defined object types that can you can work with. Future versions of the engine may implement additional object types and provide ability to programmers to define their own object types.  
  
Current version of ShortHand has the following types of objects:  

  * [Connection](object.connection.md) \- reflects database connections
  * [RecordSet](object.recordset.md) \- reflects SQL record set
  * [DDL](object.ddl.md) \- reflects DDL or DML SQL statement
  * [Cookie](object.cookie.md) \- reflects HTTP cookie
  * [File](object.file.md) \- reflects operating system file
  * [SMTP](object.smtp.md) \- provides E-Mail sending functions

Objects are instantiated using object constructors \(operator [NEW](lang.objects.constructor.md)\):  

    
       conn = new Connection("MySQL", "database=demo;uid=demo")
      
---  
  
Object constructor may require parameters to be passed to it. For example, Connection object expects two parameters - driver type and connection string to be passed to it. Object constructor may fail, in which case exception will be generated and further execution will be aborted.  
  
When you construct an instance of an object, you assign it to some variable \(example above assings new `Connection` object to the variable `conn`\). Later you work with that instance of an object through that variable. You can assign object value to other variables or pass it to functions or return from functions like value of any other type:  

    
      query = new RecordSet("SELECT * FROM product")
      q = query
      q.execute()
      processQuery(q) ' call user-defined function and pass an object to it
      
---  
  
Object names \(`RecordSet`, `File`, etc\) are not keywords and do not interfere with variable names. It is perfectly normal to give variables the same names as object types: 
    
      file = new File(fileName, "r")
      recordSet = new RecordSet(db, "SELECT * FROM foo")
      
---  
  
Object methods work like normal functions - they may have parameters and may return values. The only difference is that methods can be called only with connection to object instances - you have to write variable name followed by dot followed by method name to invoke object method - like `q.execute()` in the example above. If a variable before dot is not an object, or if an object doesn't have such method, error will be generated during execution of the statement. Method names, like function names, are not case-sensitive: `execute()` and `Execute()` refer to the same method.   
  
Consult documentation for particular object type for a list of supported methods and properties and their meanings.   
  
Objects can also have _properties_. Properties behave exactly like variables that exist only per instance of an object. You can use object properties wherever you would use regular variables - assign values to them or use them as expressions:   

    
    cookie1.expires = AddMinutes(now(), 30)
      
---  
This example sets `expires` property of `Cookie` object `cookie1` to the time value that is 30 minutes from now.  
  
You cannot invent property names. The object that you are working with must have a list of supported properties \- consult documentation for particular object types for a list of available properties.  
  
Object instances, like any other ShortHand variables are automatically destroyed when ShortHand finishes executing you program.
