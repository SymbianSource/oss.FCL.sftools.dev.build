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

import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.HlmExceptionHandler;
import com.nokia.helium.core.PropertiesSource;
import com.nokia.helium.core.TemplateInputSource;
import com.nokia.helium.core.TemplateProcessor;
import com.nokia.helium.signal.SignalStatus;
import com.nokia.helium.signal.SignalStatusList;

import org.apache.log4j.Logger;

import java.util.Hashtable;
import java.util.Vector;
import java.util.List;
import java.io.File;
import java.util.ArrayList;
import java.text.SimpleDateFormat;
import java.util.Properties;


/**
 * Class to store the builds status and check the signal is present in the deferred signal list.
 * if so get the signal informations like signal name, error message and target name.
 * With collected signal information and build status send the generated XML file to diamonds client class
 * to update the information into diamonds
 */
public class DiamondsExceptionStatusUpdate implements HlmExceptionHandler {
    private Logger log = Logger.getLogger(DiamondsExceptionStatusUpdate.class);

    /* Initiate build status to failed as this method will be invoked in case of exceptions only */
    private String buildStatus = "failed";

    private SimpleDateFormat timeFormat;

    private TemplateProcessor templateProcessor;

    private Hashtable<String, String> signalInformation = new Hashtable<String, String>();

    private String outputFile,templateFile;

    private List<TemplateInputSource> sourceList = new ArrayList<TemplateInputSource>();

    /**
     * Implements the Exception method to update build status and signal information to diamonds.
     * @param project
     * @param module
     * @param e
     */
    @SuppressWarnings("unchecked")
    public void handleException(Project project, String module, Exception e) {
        templateProcessor = new TemplateProcessor();
        Properties tempProperties = new Properties();
        String templateDir = DiamondsConfig.getTemplateDir();
        /* Initialize the diamond properties class to access the diamonds properties */
        DiamondsProperties diamondsProperties = DiamondsConfig.getDiamondsProperties();
        //Check, Is the diamonds listener is initialized?
        if (DiamondsListenerImpl.isInitialized()) {
            timeFormat = new SimpleDateFormat(DiamondsConfig.getDiamondsProperties().getProperty("tstampformat"));
            /* Initialize the diamond client class required to update the information into diamonds. */
            DiamondsClient diamondsClient = new DiamondsClient(project
                    .getProperty(diamondsProperties.getProperty("host")),
                    project.getProperty(diamondsProperties
                            .getProperty("port")), project
                            .getProperty(diamondsProperties
                                    .getProperty("path")), project
                                    .getProperty(diamondsProperties
                                            .getProperty("mail")));

            /* Check is the signal is in deferred signal list?
             * If so get the signal information like signal name, error message and target name
             * 
             */
            if (SignalStatusList.getDeferredSignalList().hasSignalInList()) {
                Vector<SignalStatus> signalList = SignalStatusList.getDeferredSignalList().getSignalStatusList();
                timeFormat = new SimpleDateFormat(DiamondsConfig.getDiamondsProperties().getProperty("tstampformat"));
                log.debug("Build Status = " + buildStatus);
                int i = 0;
                for (SignalStatus status : signalList) {
                    signalInformation.put("diamond.signal.name." + i, status.getName());
                    signalInformation.put("diamond.error.message." + i, status.getMessage());
                    signalInformation.put("diamond.time.stamp." + i,new String(timeFormat.format(status.getTimestamp())));
                    i += 1;
                }
                /* Generate the signal XML file required for diamonds to update the signal information,
                 * using templateprocessor class
                 */
                templateFile = "diamonds_signal.xml.ftl";
                outputFile = DiamondsConfig.getOutputDir() + File.separator + "diamonds-signal.xml";
                sourceList.add(new PropertiesSource("diamondSignal", signalInformation));
                templateProcessor.convertTemplate(templateDir, templateFile, outputFile,sourceList);

                /* send the generated XML file for diamonds client to update the signals information into Diamonds */
                log.debug("sending data to diamonds ..." + outputFile);
                diamondsClient.sendData(outputFile, DiamondsConfig.getDiamondsProperties().getDiamondsBuildID());
                try {
                    DiamondsListenerImpl.mergeToFullResults(new File(outputFile));
                } catch (DiamondsException de) {
                    log.error("Not able to merge into full results XML file " + de.getMessage(), de);
                }
            }
            /* Check, is the signal is in now signal list?
             * If so get the signal information like signal name, error message and target name
             * 
             */
            if (SignalStatusList.getNowSignalList().hasSignalInList()) {
                Vector<SignalStatus> signalList = SignalStatusList.getNowSignalList().getSignalStatusList();
                buildStatus = "failed";
                timeFormat = new SimpleDateFormat(DiamondsConfig.getDiamondsProperties().getProperty("tstampformat"));
                log.debug("Build Status = " + buildStatus);
                int i = 0;
                for (SignalStatus status : signalList) {
                    signalInformation.put("diamond.signal.name." + i, status.getName());
                    signalInformation.put("diamond.error.message." + i, status.getMessage());
                    signalInformation.put("diamond.time.stamp." + i,new String(timeFormat.format(status.getTimestamp())));
                    i += 1;
                }
                /* Generate the signal XML file required for diamonds to update the signal information,
                 * using templateprocessor class
                 */
                templateFile = "diamonds_signal.xml.ftl";
                outputFile = DiamondsConfig.getOutputDir() + File.separator + "diamonds-signal.xml";
                sourceList.add(new PropertiesSource("diamondSignal", signalInformation));
                templateProcessor.convertTemplate(templateDir, templateFile, outputFile,sourceList);

                /* send the generated XML file for diamonds client to update the signals information into Diamonds */
                log.debug("sending data to diamonds ..." + outputFile);
                diamondsClient.sendData(outputFile, DiamondsConfig.getDiamondsProperties().getDiamondsBuildID());
                try {
                    DiamondsListenerImpl.mergeToFullResults(new File(outputFile));
                } catch (DiamondsException de) {
                    log.error("Not able to merge into full results XML file " + de.getMessage(), de);
                }
            }
            /* Generate the build status XML file required for diamonds to update the build status information,
             * using templateprocessor class. 
             */
            tempProperties.put("build.status", buildStatus);
            sourceList.add(new PropertiesSource("ant", project.getProperties()));
            sourceList.add(new PropertiesSource("diamonds", tempProperties));
            outputFile = DiamondsConfig.getOutputDir() + File.separator + "diamonds-status.xml";
            templateFile = "diamonds_status.xml.ftl";
            templateProcessor.convertTemplate(templateDir, templateFile, outputFile, sourceList);

            /* send the generated XML file for diamonds client to update the build status into Diamonds */
            log.debug("[DiamondsExceptionStatusUpdate] => sending data to diamonds ..." + outputFile);
            diamondsClient.sendData(outputFile, DiamondsConfig.getDiamondsProperties().getDiamondsBuildID());
            try {
                DiamondsListenerImpl.mergeToFullResults(new File(outputFile));
            } catch (DiamondsException de) {
                log.error("Not able to merge into full results XML file " + de.getMessage(), de);
            }
        }

    }
}