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

package com.nokia.helium.core;

import java.util.Arrays;
import java.util.Properties;
import java.util.Hashtable;
import java.util.zip.GZIPOutputStream;
import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import javax.mail.*;
import javax.mail.internet.*;
import javax.naming.*;
import javax.naming.directory.*;

import javax.activation.DataHandler;
import javax.mail.util.ByteArrayDataSource;
import org.apache.log4j.Logger;
import org.apache.commons.io.FileUtils;

/**
 * Send compressed or uncompressed xml data with email.
 */
public class EmailDataSender {

    // Logger
    private static Logger log = Logger.getLogger(EmailDataSender.class);

    // Address email is sent from
    private String from;
    
    // The target address
    private String[] toAddressList;

    // LDAP config
    private String ldapURL;
    // TODO all reference to nokia internals MUST be removed.
    private String rootdn = "o=Nokia";

    // Configured smtp server address
    private String smtpServerAddress;
    /**
    * Constructor
    * 
    * @param String
    *            comma separeted email recepients list
    * @param String
    *            smtp server 
    * @param String
    *            ldap server
    */
    public EmailDataSender(String toStrings, String smtpServer,
            String ldapAddress) {
        if (toStrings != null) {
            String[] splitList = toStrings.split(",");
            toAddressList = splitList;
        }
        smtpServerAddress = smtpServer;
        ldapURL = ldapAddress;
    }
    /**
    * Constructor
    * 
    * @param String
    *            email recepient list in array
    * @param String
    *            smtp server 
    * @param String
    *            ldap server
    */
    public EmailDataSender(String[] toList, String smtpServer,
            String ldapAddress) {
        toAddressList = toList;
        smtpServerAddress = smtpServer;
        ldapURL = ldapAddress;
    }
    /**
    * Constructor
    * 
    * @param String
    *            email recepients list in array
    * @param String
    *            smtp server 
    * @param String
    *            ldap server
    * @param String
    *            root domain in ldap server
    */
    public EmailDataSender(String[] toList, String smtpServer,
            String ldapAddress, String rootdn) {
        toAddressList = toList;
        smtpServerAddress = smtpServer;
        ldapURL = ldapAddress;
        this.rootdn = rootdn;
    }
    /**
    * Set sender address.
    *
    * @param String
    *            mail sender address
    */
    public void setFrom(String from) {
        this.from = from;
    }
    /**
    * Add current user to recipient list.
    *    
    */
    public void addCurrentUserToAddressList() {
        // Create an empty array if needed
        if (toAddressList == null)
            toAddressList = new String[0];
        try {
            String userEmail;
            userEmail = getUserEmail();
            toAddressList = Arrays.copyOf(toAddressList,
                    toAddressList.length + 1);
            toAddressList[toAddressList.length - 1] = userEmail;
        } catch (Exception e) {
            return;
        }
    }
    /**
    * Get recipient address list.
    * 
    * @return
    *       Recipient address list.
    */
    private InternetAddress[] getToAddressList() {
        int toListLength = 0;
        if (toAddressList != null)
            toListLength = toAddressList.length;
        InternetAddress[] addressList = new InternetAddress[toListLength];
        try {
            log.debug("getToAddressList:length: "
                    + toListLength);
            for (int i = 0; i < toListLength; i++) {
                log.debug("getToAddressList:address:"
                        + toAddressList[i]);
                addressList[i] = new InternetAddress(toAddressList[i]);
            }
        } catch (Exception aex) {
            // We are Ignoring the errors as no need to fail the build.
            log.error("AddressException: " + aex);
        }
        return addressList;
    }
    /**
    * Send xml data without compression
    * 
    * @param String
    *            purpose of this email
    * @param String
    *            file to send 
    * @param String
    *            mime type
    * @param String
    *            subject of email
    * @param String
    *            header of email
    */
    public void sendData(String purpose, String fileToSend, String mimeType,
            String subject, String header) {
        sendData(purpose, fileToSend, mimeType, subject, header, false);
    }

   
    /**
    * Sending the XML data(compressed) through email.
    * 
    * @param String
    *            purpose of this email
    * @param String
    *            file to send     
    * @param String
    *            subject of email
    * @param String
    *            header of email
    */
    public void compresseAndSendData(String purpose, String fileToSend,
            String subject, String header) {
        sendData(purpose, fileToSend, null, subject, header, true);
    }
    /**
    * Send xml data 
    * 
    * @param String
    *            purpose of this email
    * @param String
    *            file to send 
    * @param String
    *            mime type
    * @param String
    *            subject of email
    * @param String
    *            header of mail
    * @param boolean
    *            compress data if true
    */
    public void sendData(String purpose, String fileToSend, String mimeType,
            String subject, String header, boolean compressData) {
        try {
            log.debug("sendData:Send file: " + fileToSend + " and mimetype: " + mimeType);
            if (fileToSend != null) {
                log.debug("sendData:smtp address: "
                        + smtpServerAddress);
                InternetAddress[] toAddresses = getToAddressList();
                Properties props = new Properties();
                props.setProperty("mail.smtp.host", smtpServerAddress);
                Session mailSession = Session.getDefaultInstance(props, null);
                MimeMessage message = new MimeMessage(mailSession);
                String subjectToSend = subject;
                if (subject == null) {
                    subjectToSend = "";
                }
                message.setSubject(subjectToSend);
                MimeMultipart multipart = new MimeMultipart("related");
                BodyPart messageBodyPart = new MimeBodyPart();
                ByteArrayDataSource dataSrc = null;
                String fileName = new File(fileToSend).getName();
                if (compressData) {
                    log.debug("Sending compressed data");
                    dataSrc = compressFile(fileToSend);
                    dataSrc.setName(fileName + ".gz");
                    messageBodyPart.setFileName(fileName + ".gz");
                } else {
                    log.debug("Sending uncompressed data:");
                    dataSrc = new ByteArrayDataSource(new FileInputStream(
                            new File(fileToSend)), mimeType);

                    message.setContent(FileUtils.readFileToString(new File(
                            fileToSend)), "text/html");
                    multipart = null;
                }
                String headerToSend = null;
                if (header == null) {
                    headerToSend = "";
                }
                messageBodyPart.setHeader("helium-bld-data", headerToSend);
                messageBodyPart.setDataHandler(new DataHandler(dataSrc));

                if (multipart != null) {
                    multipart.addBodyPart(messageBodyPart); // add to the
                    // multipart
                    message.setContent(multipart);
                }
                try {
                    InternetAddress fromAddress = getFromAddress(); 
                    message.setFrom(fromAddress);
                } catch (Exception e) {
                    // We are Ignoring the errors as no need to fail the build.
                    log.debug("Error retrieving current user email address: " + e.getMessage(), e);
                }
                message.addRecipients(Message.RecipientType.TO, toAddresses);
                log.info("Sending email alert: " + subject);
                Transport.send(message);
            }
        } catch (Exception e) {
            String errorMessage = e.getMessage();
            String fullErrorMessage = "Failed sending e-mail: " + purpose;
            if (errorMessage != null) {
                fullErrorMessage += " " + errorMessage;
            }
            // We are Ignoring the errors as no need to fail the build.
            log.info(fullErrorMessage);
        }
    }

    /**
     * GZipping a string.
     * 
     * @param data
     *            the content to be gzipped.
     * @param filename
     *            the name for the file.
     * @return a ByteArrayDataSource.
     */
    protected ByteArrayDataSource compressFile(String fileName)
            throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        GZIPOutputStream gz = new GZIPOutputStream(out);
        BufferedInputStream bufferedInputStream = new BufferedInputStream(
                new FileInputStream(new File(fileName)));
        byte[] dataBuffer = new byte[512];
        while ((bufferedInputStream.read(dataBuffer)) != -1) {
            gz.write(dataBuffer);
        }
        gz.close();
        bufferedInputStream.close();
        ByteArrayDataSource dataSrc = new ByteArrayDataSource(
                out.toByteArray(), "application/x-gzip");
        return dataSrc;
    }
    /**
    * Get sender address.
    * 
    * @return
    *       sender address.
    */
    private InternetAddress getFromAddress() throws Exception {
        if (from != null) {
            return new InternetAddress(from);
        }
        return new InternetAddress(getUserEmail());
    }
    
    /**
     * Getting user email.
     * 
     * @return
     *    the user email address.
     */
    protected String getUserEmail() throws Exception {
        String username = System.getProperty("user.name");
        log.debug("EmailDataSender:getUserEmail:username: " + username);

        // Set up environment for creating initial context
        Hashtable<String, String> env = new Hashtable<String, String>(11);
        env.put(Context.INITIAL_CONTEXT_FACTORY,
                "com.sun.jndi.ldap.LdapCtxFactory");
        env.put(Context.PROVIDER_URL, ldapURL + "/" + rootdn);

        // Create initial context
        DirContext ctx = new InitialDirContext(env);
        SearchControls controls = new SearchControls();
        controls.setSearchScope(SearchControls.SUBTREE_SCOPE);
        try {
            NamingEnumeration<SearchResult> en = ctx.search("", "uid=" + username, controls);
            if (en.hasMore()) {
                SearchResult sr = en.next();
                String email = (String) sr.getAttributes().get("mail").get();
                log.debug("getUserEmail:" + email);
                return email;
            }
        } catch (javax.naming.NameNotFoundException ex) {
            throw new HlmAntLibException("Error finding user email for " + username );
        }
        throw new HlmAntLibException("Could not find user email in LDAP.");
    }
}



