# Error Logging
ShortHand reports any syntax or execution errors to the standard output stream that goes directly to the client browser. In addition, you can configure it to write all error messages into a file on the server.  
  
To enable this feature, define `SHH_ERROR_LOG` environment variable globally or for the user account under which your web server is working. This variable must contain full name of the file which will accumulate error messages. For example, `C:\ShortHand\error.log`.  
  
Make sure the file and directory pointed to by `SHH_ERROR_LOG` is writable by the user account under which web server starts. IIS, for example, by default runs Web server under `IUSR_XXX` account \(where `XXX` is computer name\), which doesn't have any local filesystem permissions.  
  
`SHH_ERROR_LOG` feature has effect only on CGI version of the engine. Apache module version duplicates error messages to `stderr`, which is redirected by Apache into server error log \(or virtual server error log\).
