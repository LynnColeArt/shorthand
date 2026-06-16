# Installation
ShortHand engine comes in three flavors - CGI executable, ISAPI Module, and Apache server module. All versions are functionally the same and your ShortHand programs will work exactly the same no matter what type of engine is running on your web server.  
  
**CGI version** is executable file \(called `shorthand` on Unix or `shorthand.exe` on Windows\) compiled for the specific operating system. When the engine is installed as CGI executable, your web server starts new OS process to handle every HTTP request to a ShortHand page.  

**ISAPI Module version** is a DLL file \(available for Windows only\). When the engine is installed as an ISAPI Module, Web server loads ShortHand dynamic library when it starts or when it receives first request to ShortHand page. The engine in this case doesn't run in its own OS process, but instead is runs as part of Web server process. ISAPI is probably the most conservative of server resources on a Windows IIS instalation, it also provides a signfigant advantage in terms of speed over the CGI version.
**Apache Module version** is dynamically linked library \(Windows DLL or Unix shared library\) compiled for specific OS and for specific Web server on that OS. When the engine is installed as server module, Web server loads ShortHand dynamic library when it starts or when it receives first request to ShortHand page. The engine in this case doesn't run in its own OS process, but instead is runs as part of Web server process.  
  
Module version provides a significant advantage in performance comparing to CGI version. Starting new process to handle every page request can be expensive operation. OS needs to load executable file and all required libraries into memory and allocate different resources to it. In case of dynamic library this is done only once.  
  
Therefore, CGI version should be avoided if possible. Use CGI version only if ShortHand doesn't have server module for your Web server and operating system.  
  
The following pages contain instructions on how to install and configure ShortHand for different Web servers:  

  * [Apache installation](install.apache.md)
  * [Installing CGI under Microsoft Internet Information Server \(IIS\)](install.iis.md)
  * [Installing ISAPI Module under Microsoft Internet Information Server \(IIS\)](install.iis.ISAPI.md)
