# SMTP.Send
Sends out E-mail message using SMTP server defined by SMTP object. 
#### Syntax
smtp.**Send**\(from, to, subject, body\) 
#### Parameters
_From_
    `From:` e-mail address - the address on behalf of which the message is to be sent. It is very likely \(especially when you use remote server\) that SMTP server has policies regarging sender e-mail addresses and it accepts only addresses matching its domain \(for example, your ISP domain or the domain where your hosted server belongs to\). So in most cases you canot just invent `From` addresses and this field must be a valid e-mail address.
_To_
     E-mail address of the recipent. This must be bare E-mail address in the form `john@smith.com` and must not contain any names \(like in `"John Smith" <john@smith.com>` \- wrong\). This address is being fed directly to SMTP server and SMTP server expectes addresses only, without any 
names or `< >`. _Subject_
    Subject of e-mail message - arbitrary string expression
_Body_
    Body of E-mail message - arbitrary string expression that may contain multiple lines of text.
#### Return Value
    zero if the message has been successfully sent \(accepted for delivery\).  
non-zero error code that is one of SMTP error codes if SMTP server refused to deliver this message - for example, 550 \(relaying to recipient is not allowed\) - when server SMTP server doesn't trust your IP address\).
#### Remarks
    Method `Send` of `SMTP` object connects to SMTP server specified when `SMTP` object has been created and tries to submit E-mail message for delivery. If message cannot be delivered for any reason \(invalid addresses or domains, for example, or SMTP server is not responding\), `Send` returns non-zero value and `error` property of `SMTP` object can be used to obtain detailed error message returned by the server.  
  
Present version of ShortHand \(1.0\) does not support SMTP authentication - your SMTP server must be local or recognize your IP address. 
#### Example
    
    
        smtp = new SMTP("smtp-server.my-isp.net")
        body = "Good News!\nWe have sold " & itemCount & " FOOs for total amount of $" & Format(totalAmount,2) & "\n"
        body = body & "The buyer is " & buyerName & "\n"
        body = body & "Best Regards,\nFOO sales support"
    
        smtp.**Send**("support@foo.com", "sales@foo.com", "New FOO order", body)
        if smtp.Error != NULL then
           logError(smtp.error)
        end if
    
    
#### Compatibility
    ShortHand **1.0** or higher
#### See Also
    [SMTP Object](object.smtp.md)
