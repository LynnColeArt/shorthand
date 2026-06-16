# Apache Installation
## Instaling as Apache Module
Current version of ShortHand \(1.0\) supports only Apache 1.3.X on Windows, Linux and SPARC Solaris 2.7.  
  
Before you proceed, make sure that `mysql/bin` directory is included in the PATH environment variable globally or for the user account under which Apache server is running.  
  
To install ShortHand module under Apache, follow these steps: 
  1. Copy file **mod\_shorthand.so** to some existing or separate directory that is not under your HTML documents hierarchy. For example, `/usr/local/shorthand/` or `C:\Apache\ShortHand`.  
  

  2. Open file `httpd.conf` that is normally found in `conf` subdirectory of your Apache installation. Add the following piece in the global scope of `httpd.conf`:  
Unix: 
        LoadModule shorthand_module /usr/local/shorthand/mod_shorthand.so
    AddType application/x-httpd-shorthand .shh
      
---  
replace `/usr/local/shorthand` by actual directory where you put the file.  
Windows: 
        LoadModule shorthand_module "C:/Apache/ShortHand/mod_shorthand.so"
    AddType application/x-httpd-shorthand .shh
      
---  
  
This will enable ShortHand for your entire web server and all virtual servers. Request to any file with .shh extension will handles by ShortHand module. Alternatively, you can move `AddType` directive to `<VirtualHost>`, `<Directory>` section or `.htaccess` file. In this case, `.shh` extension will only be recognized within corresponding scope.  
Make sure that `LoadModule` line appear **after** `ClearModuleList` directive if you have one in your `httpd.conf`.  
  

  3. Restart Apache

If everything went all right, you have ShortHand-enabled Apache. You can test installation by placing some file with .shh extension into your documents hierarchy and pointing browser to it. 
## Installing CGI executable under Apache
This is not the best way to run ShortHand, but if you don't have a choice, here's what to do:  

  1. Copy executable file **shorthand** \(Unix\) or **shorthand.exe** \(Windows\) into a separate directory that has nothing else in it and is **not** under your HTML documents hierarchy. For example, `/usr/local/shorthand` or `C:\ShortHand`.  
  

  2. Add the following lines to your httpd.conf:  

        ScriptAlias /shorthand_cgi/ "c:/shorthand/" 
    AddType application/x-httpd-shorthand .shh
    Action application/x-httpd-shorthand "/shorthand_cgi/shorthand.exe"
      
---  
Replace `C:/ShortHand/` by actual directory where you put executable file. Note that slash at the end is important and must not be omitted.  

  

  3. Restart Apache
