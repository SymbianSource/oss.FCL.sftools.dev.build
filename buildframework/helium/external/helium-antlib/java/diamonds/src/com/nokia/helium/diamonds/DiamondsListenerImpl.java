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
import org.apache.tools.ant.util.FileUtils;
import java.util.Date;
import java.util.List;
import java.util.HashSet;
import java.io.File;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.ListIterator;
import org.apache.log4j.Logger;
import java.util.Properties;
import com.nokia.helium.core.PropertiesSource;
import com.nokia.helium.core.TemplateInputSource;
import com.nokia.helium.core.TemplateProcessor;

/**
 * Base diamonds logger implementation. The common implementation like
 * initialization done here and used by sub classes.
 */
public class DiamondsListenerImpl implements DiamondsListener {

    private static ArrayList<File> finalLogList = new ArrayList<File>();

    private static DiamondsClient diamondsClient;

    private static boolean isInitialized;

    private static ArrayList<String> deferLogList = new ArrayList<String>();

    private TemplateProcessor templateProcessor;

    private Project project;
    
    private SimpleDateFormat timeFormat;

    private Date buildStartTime;
    
    private Logger log = Logger.getLogger(DiamondsListenerImpl.class);

    /**
     * Default constructor
     */
    public DiamondsListenerImpl() {
        templateProcessor = new TemplateProcessor();
        timeFormat = new SimpleDateFormat(DiamondsConfig
                .getDiamondsProperties().getProperty("tstampformat"));
    }

    /**
     * Function to process logging info during end of build
     * 
     * @param event
     *            of target execution.
     */
    public final void buildBegin(BuildEvent buildEvent)
            throws DiamondsException {
        project = buildEvent.getProject();
        buildStartTime = new Date();
    }
    
    /**
     * Function to process logging info during end of build
     * 
     * @param event
     *            of target execution.
     */
    @SuppressWarnings("unchecked")
    public final void buildEnd(BuildEvent buildEvent) throws DiamondsException {
        if (isInitialized()) {
            log.debug("diamonds:DiamondsListenerImpl:sending final data to diamonds.");
            String output = DiamondsConfig.getOutputDir() + File.separator
                    + "diamonds-finish.xml";
            File outputFile = new File(output);
            String finishTemplateFile = "diamonds_finish.xml.ftl";
            try {
                Properties tempProperties = new Properties();
                tempProperties.put("build.end.time", timeFormat
                        .format(new Date()));
                List<TemplateInputSource> sourceList = new ArrayList<TemplateInputSource>();
                sourceList.add(new PropertiesSource("ant", project
                        .getProperties()));
                sourceList
                        .add(new PropertiesSource("diamonds", tempProperties));
                templateProcessor.convertTemplate(DiamondsConfig
                        .getTemplateDir(), finishTemplateFile, output,
                        sourceList);
            } catch (Exception e) {
                throw new DiamondsException(
                        "failed to convert the build finish template: "
                                + e.getMessage());
            }

            try {
                log.info("Sending final data to diamonds.");
                // String mergedFile = mergeFiles(output);
                diamondsClient.sendData(output, DiamondsConfig
                        .getDiamondsProperties().getDiamondsBuildID());
            } catch (Exception e) {
                throw new DiamondsException("Failed to send data to diamonds: "
                        + e.getMessage());
            }
            mergeToFullResults(outputFile);
            isInitialized = false;
            DiamondsProperties props = DiamondsConfig.getDiamondsProperties();
            String smtpServer = project.getProperty(props
                    .getProperty("smtpserver"));
            String ldapServer = project.getProperty(props
                    .getProperty("ldapserver"));

            try {
                File first = finalLogList.remove(0);
                String outputDir = DiamondsConfig.getOutputDir();
                File fullResultsFile = new File(outputDir + File.separator
                        + "diamonds-full-results.xml");
                FileUtils.getFileUtils().copyFile(first, fullResultsFile);
                XMLMerger merger = new XMLMerger(fullResultsFile);
                HashSet<File> h = new HashSet<File>(finalLogList);
                for (File f : h) {
                    try {
                        merger.merge(f);
                    } catch (XMLMerger.XMLMergerException xe) {
                        log.debug("Error during the merge: ", xe);
                    }
                }
//                diamondsClient.sendData(fullResultsFile.getAbsolutePath(), DiamondsConfig.getDiamondsProperties().getDiamondsBuildID());
                diamondsClient.sendDataByMail(
                        fullResultsFile.getAbsolutePath(), smtpServer,
                        ldapServer);
            } catch (Exception e) {
                log.error("Error sending diamonds final log: ", e);
            }
        }
    }

    /**
     * Function to process logging info during begining of target execution
     * 
     * @param event
     *            of target execution.
     */
    public void targetBegin(BuildEvent buildEvent) throws DiamondsException {
        initDiamondsClient();
    }

    /**
     * Function to process logging info during end of target execution
     * 
     * @param event
     *            of target execution.
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

    public static void mergeToFullResults(File xmlFile) throws DiamondsException {
        finalLogList.add(xmlFile);
    }

    protected String getSourceFile(String inputName) {
        return DiamondsConfig.getOutputDir() + File.separator + inputName
                + ".xml";
    }
    
    protected DiamondsClient getDiamondsClient() {
        return diamondsClient;
    }
    
    protected TemplateProcessor getTemplateProcessor() {
        return templateProcessor;
    }
    
    protected boolean getIsInitialized() {
        return isInitialized;
    }
    
    protected SimpleDateFormat getTimeFormat() {
        return timeFormat;
    }
    
    protected ArrayList<String> getDeferLogList() {
        return deferLogList;
    }

    /**
     * Initializes the diamonds client and sends the initial data
     */
    @SuppressWarnings("unchecked")
    protected void initDiamondsClient() throws DiamondsException {
        String outputDir = DiamondsConfig.getOutputDir();
        if (!isInitialized) {
            String startTemplateFile = "diamonds_start.xml.ftl";
            String output = outputDir + File.separator
                    + "diamonds-start.log.xml";
            File outputFile = new File(output);
            try {
                Properties tempProperties = new Properties();
                tempProperties.put("build.start.time", timeFormat
                        .format(buildStartTime));
                List<TemplateInputSource> sourceList = new ArrayList<TemplateInputSource>();
                sourceList.add(new PropertiesSource("ant", project
                        .getProperties()));
                sourceList
                        .add(new PropertiesSource("diamonds", tempProperties));
                DiamondsProperties diamondsProperties = DiamondsConfig
                        .getDiamondsProperties();
                templateProcessor.convertTemplate(DiamondsConfig
                        .getTemplateDir(), startTemplateFile, output,
                        sourceList);
                mergeToFullResults(outputFile);

                // String mergedFile = mergeFiles(output);
                log.info("Initializing diamonds client");
                diamondsClient = new DiamondsClient(project
                        .getProperty(diamondsProperties.getProperty("host")),
                        project.getProperty(diamondsProperties
                                .getProperty("port")), project
                                .getProperty(diamondsProperties
                                        .getProperty("path")), project
                                .getProperty(diamondsProperties
                                        .getProperty("mail")));
                String buildID = diamondsClient
                        .getBuildId(outputFile.getAbsolutePath());
                if (buildID != null) {
                    diamondsProperties.setDiamondsBuildID(buildID);
                    project.setProperty(diamondsProperties.getProperty("buildid-property"),
                            diamondsProperties.getDiamondsBuildID());
                    log.info("Got build id from diamonds: " + buildID);
                } else {
                    diamondsProperties.setDiamondsBuildID(buildID);
                    project.setProperty(diamondsProperties.getProperty("buildid-property"),
                            "default");
                    log.info("diamonds build id set to default and in record only mode");
                }
                if (deferLogList.size() > 0) {
                    log
                            .debug("diamonds:DiamondsListenerImpl: sending DefferList");
                    ListIterator<String> defferList = deferLogList
                            .listIterator();
                    while (defferList.hasNext()) {
                        String mergedDeferFile = defferList.next();
                        mergeToFullResults(new File(mergedDeferFile));
                        diamondsClient.sendData(mergedDeferFile, DiamondsConfig
                                .getDiamondsProperties().getDiamondsBuildID());
                    }
                    deferLogList.clear();
                }
                isInitialized = true;
            } catch (Exception e) {
                throw new DiamondsException("failed to connect to diamonds: "
                        + e.getMessage());
            }
        }
    }
}