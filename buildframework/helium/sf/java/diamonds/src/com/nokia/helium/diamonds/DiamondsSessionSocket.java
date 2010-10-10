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
 * Description: To update the build status to Diamonds with signals in case of build exceptions.
 *
 */
package com.nokia.helium.diamonds;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpStatus;
import org.apache.commons.httpclient.HttpException;
import org.apache.commons.httpclient.methods.FileRequestEntity;
import org.apache.commons.httpclient.methods.PostMethod;

import com.nokia.helium.core.EmailDataSender;
import com.nokia.helium.core.EmailSendException;
import com.nokia.helium.core.MessageCreationException;
import com.nokia.helium.core.ant.Message;
import com.nokia.helium.diamonds.XMLMerger.XMLMergerException;

/**
 * This class implements the DiamondsSession interface. The implementation
 * is based on TCP/IP socket communication.
 *
 */
public class DiamondsSessionSocket implements DiamondsSession {

    private List<File> messages = new ArrayList<File>();
    private String buildId;
    private HttpClient httpClient = new HttpClient();
    private URL url;
    private String email;
    private String smtpServer;
    private String ldapServer;
    
    /**
     * Create a new session instance. The session needs to be opened.
     * @param url the diamonds base url
     * @param email the diamonds email address where to send merged results
     * @param smtpServer the address of the SMTP server.
     * @param ldapServer the url of the LDAP server.
     */
    public DiamondsSessionSocket(URL url, String email, String smtpServer, String ldapServer) {
        this.url = url;
        this.email = email;
        this.smtpServer = smtpServer;
        this.ldapServer = ldapServer;
    }
    
    /**
     * Create a new session instance based on an already existing build id  
     * @param url the diamonds base url
     * @param email the diamonds email address where to send merged results
     * @param smtpServer the address of the SMTP server.
     * @param ldapServer the url of the LDAP server.
     * @param buildId diamonds build id
     */
    public DiamondsSessionSocket(URL url, String email, String smtpServer, String ldapServer, String buildId) {
        this.url = url;
        this.email = email;
        this.smtpServer = smtpServer;
        this.ldapServer = ldapServer;
        this.buildId = buildId;
    }
    
    
    /**
     * {@inheritDoc}
     */
    public synchronized void open(Message message) throws DiamondsException {
        if (!isOpen()) {
            buildId = sendInternal(message, false);
        } else {
            throw new DiamondsException("Diamonds session is already open.");
        }
    }

    /**
     * Internal method to send data to diamonds.
     * If ignore result is true, then the method will return null, else the message return by the query
     * will be returned.
     * @param message
     * @param ignoreResult
     * @return
     * @throws DiamondsException is thrown in case of message retrieval error, connection error. 
     */
    protected synchronized String sendInternal(Message message, boolean ignoreResult) throws DiamondsException {
        URL destURL = url;
        if (buildId != null) {
            try {
                destURL = new URL(url.getProtocol(), url.getHost(), url.getPort(), buildId);
            } catch (MalformedURLException e) {
                throw new DiamondsException("Error generating the url to send the message: " + e.getMessage(), e);
            }
        }
        PostMethod post = new PostMethod(destURL.toExternalForm());
        try {
            File tempFile = streamToTempFile(message.getInputStream());
            tempFile.deleteOnExit();
            messages.add(tempFile);
            post.setRequestEntity(new FileRequestEntity(tempFile, "text/xml"));
        } catch (MessageCreationException e) {
            throw new DiamondsException("Error retrieving the message: " + e.getMessage(), e);
        } catch (IOException e) {
            throw new DiamondsException("Error serializing the message into a temporary file: " + e.getMessage(), e);
        }
        try {
            int result = httpClient.executeMethod(post);
            if (result != HttpStatus.SC_OK && result != HttpStatus.SC_ACCEPTED) {
                throw new DiamondsException("Error sending the message: " +  post.getStatusLine() +
                        "(" + post.getResponseBodyAsString() + ")");
            }
            if (!ignoreResult) {
                return post.getResponseBodyAsString();
            }
        } catch (HttpException e) {
            throw new DiamondsException("Error sending the message: " + e.getMessage(), e);
        } catch (IOException e) {
            throw new DiamondsException("Error sending the message: " + e.getMessage(), e);
        } finally {
            post.releaseConnection();            
        }
        return null;
    }

    /**
     * {@inheritDoc}
     */
    public synchronized void send(Message message) throws DiamondsException {
        if (isOpen()) {
            sendInternal(message, true);
        } else {
            throw new DiamondsException("Diamonds session is not opened.");
        }
    }
        
    /**
     * {@inheritDoc}
     */
    public synchronized void close(Message message) throws DiamondsException {
        if (isOpen()) {
            sendInternal(message, true);
            buildId = null;
            
            if (!messages.isEmpty()) {
                // Sending the data via email.
                String mergingErrors = null;
                File firstFile = messages.remove(0);
                try {
                    File fullResultsFile = File.createTempFile("diamonds-full-results", ".xml");
                    XMLMerger merger = new XMLMerger(new FileInputStream(firstFile), fullResultsFile);
                    for (File file : messages) {
                        try {
                            merger.merge(new FileInputStream(file));
                        } catch (XMLMerger.XMLMergerException xe) {
                            mergingErrors = mergingErrors == null ? xe.getMessage() :
                                mergingErrors + "\n" + xe.getMessage();
                        }
                    }
                    EmailDataSender emailSender = new EmailDataSender(email, smtpServer, ldapServer);
                    emailSender.sendData("diamonds", fullResultsFile, "application/xml", "[DIAMONDS_DATA]", null);
                } catch (IOException e) {
                    throw new DiamondsException("Error while merging the xml files: " + e.getMessage(), e);
                } catch (XMLMergerException e) {
                    throw new DiamondsException("Error while merging the xml files: " + e.getMessage(), e);
                } catch (EmailSendException e) {
                    throw new DiamondsException("Error occured while sending mail: " + e.getMessage(), e);
                }
                if (mergingErrors != null) {
                    throw new DiamondsException("Error occured while sending mail: " + mergingErrors);                    
                }
            }            
            
        } else {
            throw new DiamondsException("Diamonds session is not opened.");
        }
    }

    /**
     * {@inheritDoc}
     */
    public boolean isOpen() {
        return getBuildId() != null;
    }

    /**
     * {@inheritDoc}
     */
    public String getBuildId() {
        return buildId;
    }

    /**
     * Write the content of an inputstream into a temp file. Deletion of the file
     * has to be made by the caller.
     * @param stream the input stream
     * @return the temp file created.
     */
    protected static File streamToTempFile(InputStream stream) throws IOException {
        File temp = File.createTempFile("diamonds", "xml");
        FileOutputStream out = new FileOutputStream(temp);
        int read = 0;
        byte[] bytes = new byte[1024];
 
        while ((read = stream.read(bytes)) != -1) {
            out.write(bytes, 0, read);
        }
        out.flush();
        out.close();
        stream.close();
        return temp;
    }
    
}
