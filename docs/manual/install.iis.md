# Windows CGI Installation
Current version of ShortHand \(1.0\) and higher supports Microsoft Internet Information Server \(IIS\) in CGI mode. To install ShortHand CGI under IIS, follow these steps: 
  1. Make sure that `MySQL\BIN` directory is included into `PATH` environment variable \(available to all users or to IIS user\). If you just added it to the PATH, restart IIS Admin service and "World Wide Web Publishing" service.  
  

  2. Place file **shorthand.exe** into separate directory that is **not** anywhere under your documents hierarchy. For example, `C:\ShortHand`.  
  

  3. Open IIS Management Console \(**Internet Services Manager**\). 
  4. Choose **Default Web Site** \(or sub-directory if you don't want to enable ShortHand for entire site\). 
  5. Invoke **Properties** from pop-up menu. 
  6. Choose **Home Directory** tab \(or **Virtual Directory** or just **Directory** \- actual tab shown depends on the node level\). 
  7. If **Application Name** field under **Application Settings** is disabled, press **Create** button. 
  8. Press **Configuration** button. **Application Configuration** window will be displayed. 
  9. Choose **App Mappings** tab. 
  10. If there is alreay an entry for **.shh** extension in the list, select it and press **Edit** button. Otherwise press **Add** button. New window will appear - **Add/Edit Extension Mapping**. 
  11. In the Extension field, type **.shh**. 
  12. Check **Script Engine** box. 
  13. Press OK, OK, OK to close three windows that are displayed. 

You don't need to restart IIS after that. New extension mapping should take effect immediately.   
  
This prodcure describes IIS 5.0, but with slight variations it can be applied to earlier versions too.
