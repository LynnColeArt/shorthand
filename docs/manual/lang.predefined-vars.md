# Predefined Variables
ShortHand has few variables that are initially defined and available to all programs. Below is the list of all such variables. Note that the names below are not keywords. You can create your own functions with the same name, or change values of these variables. 
## ip
    String representing dotted IP address of the remote computer making HTTP request \(e.g. `11.22.33.44`\). Corresponds to the `REMOTE_ADDR` environment variable \(see [env](builtin.env.md)\).
## script
    String representing virtual script name passed to the web server \(if provided by Web server - which is not always the case\).  
For example: `/myapp/scripts/doit.shh`.
