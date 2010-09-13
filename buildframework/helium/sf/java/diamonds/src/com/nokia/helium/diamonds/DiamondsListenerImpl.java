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

package com.nokia.helium.diamonds;

import org.apache.tools.ant.BuildEvent;

import org.apache.tools.ant.Project;
import java.util.Date;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import org.apache.log4j.Logger;
import com.nokia.helium.core.EmailSendException;
import com.nokia.helium.core.ant.Message;
import com.nokia.helium.core.MessageCreationException;
import com.nokia.helium.diamonds.XMLMerger.XMLMergerException;
import java.io.InputStream;

/**
 * Base diamonds logger implementation. The common implementation like initialization done here and
 * used by sub classes.
 */
public class DiamondsListenerImpl implements DiamondsListener {

    private static ArrayList<InputStream> finalStreamList = new ArrayList<InputStream>();

    private static DiamondsClient diamondsClient;

    private static boolean isInitialized;

    private static ArrayList<String> deferLogList = new ArrayList<String>();

    private static Logger log = Logger.getLogger(DiamondsListenerImpl.class);

    private static Project project;

    private static Object mutexObject = new Object();;
    
    private static SimpleDateFormat timeFormat;

    /**
     * Default constructor
     */
    public DiamondsListenerImpl() {
    }
    
    public static void initialize(Project prj) {
        project = prj;
        log.debug("buildbegin:" + project);
        Date date = new Date();
        timeFormat = new SimpleDateFormat(DiamondsConfig.getTimeFormat());
        log.debug("build.start.time:" + date);
        project.setProperty("build.start.time", timeFormat.format(date));
    }

    /**
     * Function to process logging info during end of build
     * 
     * @param event of target execution.
     */
    public final void buildBegin(BuildEvent buildEvent) throws DiamondsException {
    }
    
    /**
     * Function to process logging info during end of build
     * 
     * @param event of target execution.
     */
    @SuppressWarnings("unchecked")
    public void buildEnd(BuildEvent buildEvent) throws DiamondsException {
        log.debug("build end: " + isInitialized());
        if (isInitialized()) {
            project.setProperty("build.end.time", timeFormat.format(new Date()));
            sendMessage("final.message");
            isInitialized = false;
            InputStream first = finalStreamList.remove(0);
            try {
                //printStreamContent(first);
                File fullResultsFile = File.createTempFile("diamonds-full-results", ".xml");
                XMLMerger merger = new XMLMerger(first, fullResultsFile);
                String smtpServer = DiamondsConfig.getSMTPServer();
                String ldapServer = DiamondsConfig.getLDAPServer();
                for (InputStream stream : finalStreamList) {
                    try {
                        merger.merge(stream);
                    }
                    catch (XMLMerger.XMLMergerException xe) {
                        log.debug("Error during the merge: ", xe);
                    }
                }
                diamondsClient.sendDataByMail(fullResultsFile.getAbsolutePath(), smtpServer, ldapServer);
            } catch (EmailSendException ese) {
                log.warn("Error occured while sending mail: " + ese.getMessage());
                
            } catch (IOException e) {
                log.error("Error sending diamonds final log: IOException", e);
            }
            catch (XMLMergerException e) {
                log.error("Error sending diamonds final log: XMLMergerException ", e);
            }
        }
    }

    /**
     * Function to process logging info during begining of target execution
     * 
     * @param event of target execution.
     */
    public void targetBegin(BuildEvent buildEvent) throws DiamondsException {
        initDiamondsClient();
    }

    /**
     * Function to process logging info during end of target execution
     * 
     * @param event of target execution.
     */
    public void targetEnd(BuildEvent buildEvent) throws DiamondsException {
    }

    /**
     * returns true if diamonds is already initialized for the build.
     * 
     * @param true diamonds initialized otherwise false.
     */
    public static boolean isInitialized() {
        return isInitialized;
    }

    public static void mergeToFullResults(InputStream stream) throws DiamondsException {
        finalStreamList.add(stream);
    }


    /**
     * Helper function to return the default project passed to messages.
     */
    static Project getProject() {
        return project;
    }



    protected DiamondsClient getDiamondsClient() {
        return diamondsClient;
    }


    protected boolean getIsInitialized() {
        return isInitialized;
    }

    protected static SimpleDateFormat getTimeFormat() {
        return timeFormat;
    }

    protected ArrayList<String> getDeferLogList() {
        return deferLogList;
    }
    
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

    private static void sendMessage(Message message, String buildID) throws DiamondsException {
        try {
            File tempFile = streamToTempFile(message.getInputStream());
            tempFile.deleteOnExit();
            if (buildID == null) {
                buildID = diamondsClient.getBuildId(new FileInputStream(tempFile));
                if (buildID != null) {
                    project.setProperty(DiamondsConfig.getBuildIdProperty(), buildID);
                    log.info("got Build ID from diamonds:" + buildID);
                }
            } else {
                diamondsClient.sendData(new FileInputStream(tempFile), buildID);
            }
            mergeToFullResults(new FileInputStream(tempFile));
        } catch (IOException iex) {
            log.debug("IOException while retriving message:", iex);
            throw new DiamondsException("IOException while retriving message");
        } 
        catch (MessageCreationException mex) {
            log.debug("IOException while retriving message:", mex);
            throw new DiamondsException("error during message retrival");
        }
    }

    /**
     * Send message to diamonds.
     * @param messageId - id to look from in the ant config and to send it to diamonds.
     *                    id is pointing to an fmpp message.
     */
    public static void sendMessage(String messageId) throws DiamondsException {
        log.debug("send-message:" + messageId);
        synchronized (mutexObject) {
            String buildID = project.getProperty(DiamondsConfig.getBuildIdProperty());
            Object obj = project.getReference(messageId);
            if (obj != null) {
                if (obj instanceof Message) {
                    sendMessage((Message)obj, buildID);
                }
            } else {
                log.debug("Message not sent for message id: " + messageId);
            }
        }
    }
    
    /**
     * Initializes the diamonds client and sends the initial data
     */
    @SuppressWarnings("unchecked")
    protected void initDiamondsClient() throws DiamondsException {
        if (!isInitialized) {
            diamondsClient = new DiamondsClient(DiamondsConfig.getHost(), 
                    DiamondsConfig.getPort(), 
                    DiamondsConfig.getPath(), 
                    DiamondsConfig.getMailInfo());
            String buildID = project.getProperty(DiamondsConfig.getBuildIdProperty());
            if (buildID == null ) {
                sendMessage("initial.message");
            }
            isInitialized = true;
        }
    }
}