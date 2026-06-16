# Database Support
ShortHand provides support of databases through [Connection](object.connection.md), [RecordSet](object.recordset.md) and [DDL](object.ddl.md) objects. These objects provide properties and methods that allow you to perform all database tasks - establish connections, execute SQL statements, extract results from record sets, etc.  
  
ShortHand 1.0 supports only MySQL database engine \(and uses native MySQL libraries\). Future versions may add support for additional database systems.   
  
Typically you start working with database by creating one or more `Connection` objects. Connection object represents physical database connection to the server.  
  
Connection object is used to derive `RecordSet` and `DDL` objects that perform actual data manipulation.
