# ** ODBC \(open database connectivity\)**  
---  
New Database connectivity option for Shorthand starting in version 1.2.1.  
**Inputs:**  
Connection type, DSN Name  
**Remarks:**  
ODBC is an extension of the connection object which has been part of Shorthand since version 0.1.6. Using ODBC for database connections dramatically simplifies the way Shorthand applications connect to databases. ODBC is now available on Windows and Linux versions of Shorthand. Linux versions of Shorthand are dynamically linked to [Unixodbc](<http://unixodbc.org>) a Dsn manager for nix systems.  
**Example**  
    
` conn = new Connection("ODBC", "MyDsnName")`
