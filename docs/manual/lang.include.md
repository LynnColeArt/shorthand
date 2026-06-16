# INCLUDE
INCLUDE operator does what it says - it _includes_ and _executes_ another ShortHand file into the current ShortHand file. INCLUDE operator has the following syntax:  

    
      **INCLUDE** filename 
Where filename is a quoted string or any other string expression that specifies name of the file to include. File name must follow file naming conventions of the operating system on which ShortHand engine runs.  
  
All commands in the included file are executed as though there they are in the current file and then execution is resumed in the current file from the point after `INCLUDE` operator. Unless included file does something that breaks normal control flow \(like [jump](lang.jump.md), [exit](builtin.exit.md) or [redirect](builtin.redirect.md)\).  
  
File name can be absolute \(`"/home/site4974/shhlib/auth.shh"`\) or relative \(`"auth.shh"` or `"lib/auth.shh"`\). On Windows platforms you can use forward slash character \(`/`\) instead of backslash \(`\`\) to separate file components, like in `"C:/Program Files/ShortHand/auth.shh"`. In fact, it is highly recommended to use forward slashes, so that you can more easily move programs between Windows and Unix \(unless file name contains drive letter\).  
  
But if you use backslashes, don't forget to escape them:   
  
For example - correct way:   

    
      include "c:\\Program Files\\ShortHand\\auth.shh"  
      
---  
  
**Wrong** \- will not work:  

    
       include "c:\Program Files\ShortHand\auth.shh"    
      
---  
  
If name of the included file is absolute - i.e. starts with drive letter \(`C:\`\) or `\\` on Windows or with slash \(`/`\) on Unix, ShortHand will try to include the file with this exact name.  
  
But if file name is relative - not absolute \(doesn't start with drive letter or slash\), ShortHand will look for the file in the following locations:  

  1. The directory in which original file is located. For example, if you say `include "auth.shh"` in file `/sites/mysite.com/html_root/index.shh`, ShortHand will first look for `auth.shh` in directory `/sites/mysite.com/html_root`.  
If you say `include "lib/auth.shh"`, ShortHand will look for `/sites/mysite.com/html_root/lib/auth.shh`.  
You can also use `".."` to denote parent directory:  

          include "../lib/auth.shh"  
      
---  
ShortHand will look for file `/sites/mysite.com/lib/auth.shh` in this case.  
  

  2. If file cannot be found in the directory which relative to the original file, ShortHand will check operating system environment variable `**SHH_INCLUDE_PATH**`, which must contain a list of directories separated by '`;`' on Windows or '`:`' on Unix \(similar to `**PATH**` variable on Unix or Windows or `**CLASSPATH**` variable used by Java\).  
For example:  
`C:\Program Files\ShortHand\lib;C:\Dev\Mysite.com\lib;C:\Scripts` \(Windows\)  
`/usr/local/shorthand/lib:/sites/mysite.com/lib:/sites/scripts` \(Unix\)  
  
No spaces should surround ';' or ':' in `SHH_INCLUDE_PATH`. Normally you should include only absolute directory names into this list. You may include relative directory names \(this would mean relative to the current directory in OS sense\), but when ShortHand engine runs as part of Web server, it is imposible to predict what current directory would be.  
  
For every directory mentioned in `SHH_INCLUDE_PATH`, ShortHand will try apply rules described in Step 1 - as though that directory is the one where original file is located. For example, if file `/sites/mysite.com/html_root/index.shh` includes `"lib/auth.shh"`, ShortHand will look for the following files:  
\(assuming `SHH_INCLUDE_PATH = /usr/local/shorthand:/sites/mysite.com:/sites/scripts`\).   
  
`/usr/local/shorthand/lib/auth.shh`  
`/sites/mysite.com/lib/auth.shh`  
`/sites/scripts/lib/auth.shh`  
  
Once the file is found at some of these location, further search is not performed. Directories are checked in the same order in which they were mentioned in `SHH_INCLUDE_PATH`. 

Once the file is included using `INCLUDE` operator, it will never be included again in the same context. This means that if you use `INCLUDE` that refers to the same physical file more than once within your original file or other included files, subsequent `INCLUDE` operators will be ignored. ShortHand checks if file has already been included by its absolute name, not by relative name \(if relative name was used\).  
  
You can use variables or any other expressions with `INCLUDE` operator, not necessarily hard-coded literal strings:  

    
    fileName = "common.shh"  
    include fileName
      
---  
#### See Also:
    [JUMP](lang.jump.md)
