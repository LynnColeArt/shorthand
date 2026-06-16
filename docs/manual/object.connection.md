# Connection Object
Connection object encapsulates a database connection. Current version of ShortHand \(1.0\) supports only MySQL databases, but future versions may add support for different databases. To create `Connection` object, use the following syntax: 
    
       connectionVariable = **new** **Connection**(DriverName, ConnectionString)
    
where `connectionVariable` is any variable that receives a reference to the new `Connection` object. 
#### Constructor parameters:
`DriverName`
    String expression that specifies type of database driver. ShortHand 1.0 supports only native MySQL driver - this value shold always be `MySQL`
`ConnectionString`
    Driver-specific _connection string_ which tells ShortHand which server and database connect to under which user name
#### MySQL connection string
     MySQL connection string must be string expression that has the following format:  

    
    name1=value1;name2=value2;...;
Where `nameX` can be one of the following:  **name** | **value**  
---|---  
**server** | Name of IP address of the server to connect to. This value can be `.` \(single dot\) or `localhost` which means to connect to the server on the same machine where ShortHand engine is running. When you omit `server` parameter, it is assumed to be `.`  
In case of local connection, MySQL will try to use Unix domain sockets \(on Unix\) or named pipes \(on Windows\) rather than TCP/IP as protocol for communication with server \(if such mechanism is enabled in MySQL configuration\).  
**database** | Name of the database. For example, `demo` or `ecommerce`.  
**uid** | MySQL user name used for connection. Check MySQL for information about what assumptions MySQL does if you don't specify user name. In most cases it would derive MySQL user name from OS user name \(MySQL user names have nothing to do with OS user names - MySQL has its own authentication\)  
**pwd** | User password for this database connection. If you don't specify this password here, in some cases MySQL can derive password from other sources \(if actual password is not blank\). Check MySQL manual.  
**port** | Port number for remote database connection. Specify this parameter explicitly only if you are connecting to remote or local server using TCP/IP with non-default port number. Default port number for MySQL is 3306.  
**option** | Optional integer number that is combination of bit flags specifying different options affecting database connection behavior. Consult MySQL documentation for possible values.  
You can omit any of these parameters except for `database`. Semicolon \(;\) at the end of connection string is required.   
  
Connection example:   

    
      conn = new Connection("MySQL", "server=localhost;database=shop;uid=demo;pwd=demo;")
      
---  
  
Actual connection is established at the moment when you construct `Connection` object. If connection cannot be established for any reason \(server is down, incorrect password, etc\), `Connection` object is not created and exception is thrown. 
#### Properties
     `Connection` object properties reflect `name=value` pairs of connection string that were specified during object construction. They exist for reference only and changes to these properties do not have any effect on the connection.  
  
MySQL Connection objects have the following properties:  **server** | server name  
---|---  
**database** | database name  
**uid** | user name  
**pwd** | password  
**port** | TCP/IP port \(zero for IPC connections\)  
**option** | connection flags \(zero if omitted\)  
  
In addition, all `Connection` objects have another two properties that reflect parameters passed to the constructor:   
**driver** | driver name \("MySQL" for native MySQL connections\)  
---|---  
**spec** | original connection string passed to the constructor  
  
You can use these two properties to "clone" connections:  

    
     connectionClone = new Connection(conn.driver, conn.spec)
      
---  
  

#### Methods
     `Connection` object doesn't have any methods. 
#### Upgrade Note:
    As of Shorthand 1.2 `Connection` object has been expanded to include [ODBC](builtin.ODBC.md).
