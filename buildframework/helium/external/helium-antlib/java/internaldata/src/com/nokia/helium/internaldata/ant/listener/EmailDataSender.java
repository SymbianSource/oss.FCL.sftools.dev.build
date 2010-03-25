/*
* Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of the License "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description: 
*
*/

package com.nokia.helium.internaldata.ant.listener;

import java.util.Properties;
import java.util.Hashtable;
import java.util.zip.GZIPOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import javax.mail.*;
import javax.mail.internet.*;
import javax.naming.*;
import javax.naming.directory.*;

import javax.activation.DataHandler;
import javax.mail.util.ByteArrayDataSource;

import org.apache.log4j.Logger;

/**
 * Sends email of the internal data log in a zipped format.
 *
 */
public class EmailDataSender {

    
    // The target address
    public static final String TO_EMAIL = "helium.internaldata@nokia.com";
    
    // LDAP config
    public static final String LDAP_URL = "ldap://nedi.europe.nokia.com:389/o=Nokia";

    // Default SMTP server
    public static final String SMTP_SERVER = "smtp.nokia.com";
    
    // Configured smtp server address
    private String smtpServer;
    // Logger
    private Logger log = Logger.getLogger(EmailDataSender.class);
    
    
    
    
    /**
     * Set the smtp server address.
     */
    public void setSMTPServer(String address) {
        smtpServer = address;
    }

    /**
     * Get the smtp server address.
     */
    public String getSMTPServer() {
        if (smtpServer != null)
            return smtpServer;
        return SMTP_SERVER;
    }
    
    /**
     * Sending the XML data through email.
     */
    public void sendData(String data) {     
        try {
            String email = getUserEmail();
            Properties props = new Properties();
            props.setProperty("mail.smtp.host", getSMTPServer());

            Session mailSession = Session.getDefaultInstance(props, null);

            MimeMessage message = new MimeMessage(mailSession);
            message.setSubject("[HELIUM]: internal data");
            
            MimeMultipart multipart = new MimeMultipart("related");
            
            // first part  (the text html content)
            BodyPart messageBodyPart = new MimeBodyPart();
            String htmlText = "<H1>Internal data</H1>";
            messageBodyPart.setContent(htmlText, "text/html");
            multipart.addBodyPart(messageBodyPart); // add to the multipart

            // second part (the data)
            messageBodyPart = new MimeBodyPart();
            ByteArrayDataSource dataSrc = gzip(data, "data.xml");
            messageBodyPart.setFileName(dataSrc.getName());
            messageBodyPart.setDataHandler(new DataHandler(dataSrc));
            messageBodyPart.setHeader("Content-ID","<data>");
            
            multipart.addBodyPart(messageBodyPart); // add to the multipart
            
            message.setContent(multipart);
            message.setFrom(new InternetAddress(email));
            message.addRecipient(Message.RecipientType.TO, new InternetAddress(TO_EMAIL));
            
            log.debug("Sending data.");
            Transport.send(message);
        } catch (Exception e) {
            // We are Ignoring the errors as no need to fail the build.
            log.debug("Internal data failure: " + e.getMessage(), e);
        }        
    }

    /**
     * GZipping a string.
     * @param data the content to be gzipped.
     * @param filename the name for the file.
     * @return a ByteArrayDataSource.
     */
    protected ByteArrayDataSource gzip(String data, String filename) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        GZIPOutputStream gz = new GZIPOutputStream(out);
        gz.write(data.getBytes());
        gz.close();
        out.close();
        ByteArrayDataSource dataSrc = new ByteArrayDataSource(out.toByteArray(), "application/x-gzip");
        dataSrc.setName(filename + ".gz");
        return dataSrc;
    }

    /**
     * Getting user email.
     * @returns the user email.
     */
    protected String getUserEmail() throws Exception {
        String username = System.getProperty("user.name");

        // Set up environment for creating initial context
        Hashtable<String, String> env = new Hashtable<String, String>(11);
        env.put(Context.INITIAL_CONTEXT_FACTORY,
                "com.sun.jndi.ldap.LdapCtxFactory");
        env.put(Context.PROVIDER_URL, LDAP_URL);

        // Create initial context
        DirContext ctx = new InitialDirContext(env);
        SearchControls controls = new SearchControls();
        controls.setSearchScope(SearchControls.SUBTREE_SCOPE);
        NamingEnumeration<SearchResult> en = ctx.search("", "uid=" + username, controls);
        if (en.hasMore()) {
            SearchResult sr = (SearchResult) en.next();
            String email = (String) sr.getAttributes().get("mail").get();
            return email;
        }
        throw new Exception("Could not find user email in LDAP.");
    }

}
