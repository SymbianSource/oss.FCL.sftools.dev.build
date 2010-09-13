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

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpException;
import org.apache.commons.httpclient.methods.FileRequestEntity;
import org.apache.commons.httpclient.methods.PostMethod;
import org.apache.commons.httpclient.methods.RequestEntity;
import org.apache.commons.httpclient.methods.InputStreamRequestEntity;
import org.apache.commons.lang.StringUtils;
import org.apache.log4j.Logger;

import com.nokia.helium.core.EmailDataSender;
import com.nokia.helium.core.EmailSendException;

/**
 * Diamonds client used to connect to get build id and also to send the build results
 * 
 */
public class DiamondsClient {

    private static final int INT_SERV_ERROR = 500;

    private static final int SERV_NOT_FOUND = 404;

    private static final int SERV_OK = 200;

    private boolean isRecordOnly;

    private Logger log = Logger.getLogger(DiamondsClient.class);

    private String host;

    private String port;

    private String path;

    private String emailID;

    private HttpClient httpClient;

    public DiamondsClient(String hst, String prt, String pth, String mailID) {
        host = hst;
        port = prt;
        path = pth;
        emailID = mailID;
        httpClient = new HttpClient();
    }

    private int executeMethod(PostMethod postMethod) throws DiamondsException {
        int result = 0;
        try {
            result = httpClient.executeMethod(postMethod);
        }
        catch (IOException e) {
            isRecordOnly = true;
            throw new DiamondsException("IOException while sending http request." + e.getMessage());
            // e.printStackTrace();
        }
        return result;
    }

    private String checkForProtocol(String url) throws DiamondsException {
        String retURL = url;
        if (!StringUtils.containsIgnoreCase(url, "http://")) {
            retURL = "http://" + url;
        }
        return retURL;
    }

    private String getURL() throws DiamondsException {
        return getURL(null);
    }

    private String getURL(String subPath) throws DiamondsException {
        String urlPath = path;
        if (subPath != null) {
            urlPath = subPath;
        }
        return checkForProtocol("http://" + host + ":" + port + urlPath);
    }

    private PostMethod getPostMethod(String fileName, String urlPath) {

        // Get the Diamonds XML-file which is to be exported
        File input = new File(fileName);

        // Prepare HTTP post
        PostMethod post = new PostMethod(urlPath);

        // Request content will be retrieved directly
        // from the input stream

        RequestEntity entity = new FileRequestEntity(input, "text/xml; charset=ISO-8859-1");
        post.setRequestEntity(entity);
        return post;
    }

    private int processPostMethodResult(int result) {
        // Log status code
        switch (result) {
            case INT_SERV_ERROR:
                // log.error("Internal server error");
                break;
            case SERV_NOT_FOUND:
                // log.error("Server not found");
                break;
            case SERV_OK:
                // log.info("Connection to diamonds server - OK");
                break;
            default:
                // log.debug("Response code: " + result);
        }
        return result;
    }
    
    public String getBuildId(InputStream stream) throws DiamondsException {
        String diamondsBuildID = null;
        PostMethod postMethod = null;
        try {
            if (!isRecordOnly) {
                String strURL = getURL();
                log.debug("strURL:" + strURL);
                postMethod = getPostMethod(stream, strURL);
                log.debug("postmethod:" + postMethod);
                int postMethodResult = httpClient.executeMethod(postMethod);
                log.debug("postmethod-result:" + postMethodResult);

                int result = processPostMethodResult(postMethodResult);

                if (result == SERV_OK) {
                    // Display and save response code which functions as a id for
                    // the build.
                    diamondsBuildID = postMethod.getResponseBodyAsString();
                    log.debug("diamondsBuildID: " + diamondsBuildID);
                }
                else {
                    isRecordOnly = true;
                    log.error("Diamonds data not sent, because of connection failure.");
                    // throw new DiamondsException("Connection Failed");
                }
            }
        }
        catch (HttpException ex) {
            isRecordOnly = true;
            log.debug("Diamonds data not sent:s", ex);
            log.error("Diamonds data not sent: " + ex.getMessage());
        }
        catch (IOException ex) {
            isRecordOnly = true;
            log.debug("Diamonds data not sent:", ex);
            log.error("Diamonds data not sent: " + ex.getMessage());
        }
        finally {
            // Release current connection to the connection pool once you are
            // done
            if (postMethod != null) {
                postMethod.releaseConnection();
            }
        }
        return diamondsBuildID;
    }

    /**
     * 
     * @param fileName Filename to export to Diamonds
     * @return diamonds build id
     */
    public String getBuildId(String fileName) throws DiamondsException {
        String diamondsBuildID = null;
        PostMethod postMethod = null;

        // Get HTTP client
        // MyHttpClient httpclient = createHttpClient();

        // Execute post request
        try {
            if (!isRecordOnly) {
                String strURL = getURL();
                log.debug("strURL:" + strURL);
                postMethod = getPostMethod(fileName, strURL);
                log.debug("postmethod:" + postMethod);
                int postMethodResult = httpClient.executeMethod(postMethod);
                log.debug("postmethod-result:" + postMethodResult);

                int result = processPostMethodResult(postMethodResult);

                if (result == SERV_OK) {
                    // Display and save response code which functions as a id for
                    // the build.
                    diamondsBuildID = postMethod.getResponseBodyAsString();
                    log.debug("diamondsBuildID: " + diamondsBuildID);
                }
                else {
                    isRecordOnly = true;
                    log.error("Diamonds data not sent, because of connection failure.");
                    // throw new DiamondsException("Connection Failed");
                }
            }
        }
        catch (HttpException ex) {
            isRecordOnly = true;
            log.debug("Diamonds data not sent:s", ex);
            log.error("Diamonds data not sent: " + ex.getMessage());
        }
        catch (IOException ex) {
            isRecordOnly = true;
            log.debug("Diamonds data not sent:", ex);
            log.error("Diamonds data not sent: " + ex.getMessage());
        }
        finally {
            // Release current connection to the connection pool once you are
            // done
            if (postMethod != null) {
                postMethod.releaseConnection();
            }
        }
        return diamondsBuildID;
    }

    private PostMethod getPostMethod(InputStream stream, String urlPath) {

        // Get the Diamonds XML-file which is to be exported
        //File input = new File(fileName);

        // Prepare HTTP post
        PostMethod post = new PostMethod(urlPath);

        RequestEntity entity = new InputStreamRequestEntity(stream, "text/xml");
        post.setRequestEntity(entity);
        return post;
    }

    public int sendData(InputStream stream, String urlPath) {
        PostMethod postMethod = null;
        int result = -1;
        if (urlPath != null && !isRecordOnly) {
            try {
                String strURL = getURL(urlPath);
                postMethod = getPostMethod(stream, strURL);
                result = processPostMethodResult(httpClient.executeMethod(postMethod));
            }
            catch (IllegalArgumentException e) {
                // Catching this exception is needed because it is raised by httpclient
                // library if the server is under update.
                log.error("sendData:The final data via http not sent because errors:IllegalArgumentException ", e);
            }
            catch (DiamondsException e) {
                log.error("sendData:The final data via http not sent because errors:DiamondsException ", e);
            }
            catch (IOException e) {
                log.error("sendData:The final data via http not sent because errors:IOException ", e);
            }
        }
        return result;
    }
    
    public int sendData(String fileName, String urlPath) {
        PostMethod postMethod = null;
        int result = -1;
        if (urlPath != null && !isRecordOnly) {
            try {
                String strURL = getURL(urlPath);
                postMethod = getPostMethod(fileName, strURL);
                result = processPostMethodResult(httpClient.executeMethod(postMethod));
            }
            catch (IllegalArgumentException e) {
                // Catching this exception is needed because it is raised by httpclient
                // library if the server is under update.
                log.error("sendData:The final data via http not sent because errors:IllegalArgumentException ", e);
            }
            catch (DiamondsException e) {
                log.error("sendData:The final data via http not sent because errors:DiamondsException ", e);
            }
            catch (IOException e) {
                log.error("sendData:The final data via http not sent because errors:IOException ", e);
            }
        }
        return result;
    }

    public int sendDataByMail(String fileName, String smtpServer, String ldapServer) throws EmailSendException {
        log.debug("DiamondsClient:sendDataByEmail:emailID" + emailID);
        EmailDataSender emailSender = new EmailDataSender(emailID, smtpServer, ldapServer);
        log.debug("DiamondsClient:sendDataByEmail: " + fileName);
        emailSender.sendData("diamonds", new File(fileName), "application/xml", "[DIAMONDS_DATA]", null);
        log.debug("DiamondsClient:sendDataByEmail:succeeds");
        return 0;
    }
}