# SMTP Object
SMTP Object encapsulates connection to the outgoing \(SMTP\) mail server for the purpose of sending e-mail messages. You constuct SMTP object and define name or IP address of the server, and later use method [Send](smtp.send.md) to send one on more messages over this connection.  
  
`SMTP` Object constuctor has the following syntax:  

    
       new **SMTP**(Host [, Port])
    
#### Constructor Parameters:
`_Host_`
    Name of IP addess of SMTP server. In most Unix-hosted environments this value should probably set to 'localhost'.
`_Post_`
    Optional parameter that overrides default TCP port number \(25 for SMTP\) on which the application talks to SMTP server.
SMTP object has only one method - send\(\) that actually sends outgoing e-mail message.  
  
Typical usage of SMTP object looks like this: 
    
       ...
       smtp = new **SMTP**("localhost") 
       smtp.send("sales@mysite.com", customerEmail, "Thank you for your order", orderEmailBody) 
      
---  
  

#### Methods
     **·** | [send](smtp.send.md) | Sends E-mail message  
---|---|---  
#### Properties
     **·** | **host** | Host name or IP address of SMTP server passed to the constructor. This property is for information purposes only and changing it will not affect the server to which SMTP object connects to send messages.  
---|---|---  
**·** | **port** | TCP port number that is used for connection to SMTP server. If not specified, this property has value **25** \(which is standard SMTP port\). This property is for information purposes only and changing it will not affect the server port to which SMTP object connects to send messages.  
**·** | **error** | Reflects explanation of an error happened during last SMTP send\(\) operation. If there was no error, this property has NULL value.
