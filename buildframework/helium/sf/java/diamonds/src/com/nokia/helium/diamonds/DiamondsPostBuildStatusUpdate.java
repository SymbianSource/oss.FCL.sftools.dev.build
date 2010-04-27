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
import com.nokia.helium.core.ant.types.*;
import com.nokia.helium.core.PropertiesSource;
import com.nokia.helium.core.TemplateInputSource;
import com.nokia.helium.core.TemplateProcessor;

import org.apache.log4j.Logger;

import java.util.List;
import java.io.File;
import java.util.ArrayList;
import java.util.Properties;


/**
 * Class to store the builds status and send the generated XML file to diamonds client class
 * to update the build status into diamonds
 */
public class DiamondsPostBuildStatusUpdate extends HlmPostDefImpl {
    private Logger log;

    /* Initiate build status to failed as this method will be invoked in case of exceptions only */
    private String buildStatus = "succeeded";

    private TemplateProcessor templateProcessor;

    private String outputFile,templateFile;

    private List<TemplateInputSource> sourceList = new ArrayList<TemplateInputSource>();

    public DiamondsPostBuildStatusUpdate() {
        log = Logger.getLogger(DiamondsPostBuildStatusUpdate.class);    
    }

    /**
     * Override execute method to update build status to diamonds.
     * @param prj
     * @param module
     * @param targetNames
     */
    @SuppressWarnings("unchecked")
    public void execute(Project prj, String module, String[] targetNames) {
        templateProcessor = new TemplateProcessor();
        Properties tempProperties = new Properties();

        /* Intialiaze the diamond properties class to access the diamonds properties */
        DiamondsProperties diamondsProperties = DiamondsConfig.getDiamondsProperties();

        //Check, Is the diamonds listener is initialized?
        if (DiamondsListenerImpl.isInitialized()) {
            /* Initialize the diamond client class required to update the information into diamonds. */
            DiamondsClient diamondsClient = new DiamondsClient(getProject()
                    .getProperty(diamondsProperties.getProperty("host")),
                    getProject().getProperty(diamondsProperties
                            .getProperty("port")), getProject()
                            .getProperty(diamondsProperties
                                    .getProperty("path")), getProject()
                                    .getProperty(diamondsProperties
                                            .getProperty("mail")));
            /* Generate the build status XML file required for diamonds to update the build status information,
             * using templateprocessor class. 
             */
            tempProperties.put("build.status", buildStatus);
            sourceList.add(new PropertiesSource("ant", getProject().getProperties()));
            sourceList.add(new PropertiesSource("diamonds", tempProperties));
            outputFile = DiamondsConfig.getOutputDir() + File.separator + "diamonds-status.xml";
            templateFile = "diamonds_status.xml.ftl";
            templateProcessor.convertTemplate(DiamondsConfig.getTemplateDir(), templateFile, outputFile, sourceList);

            /* send the generated XML file for diamonds client to update the build status into Diamonds */
            log.debug("[DiamondsPostBuildStatusUpdate] => sending data to diamonds ..." + outputFile);
            diamondsClient.sendData(outputFile, DiamondsConfig.getDiamondsProperties().getDiamondsBuildID());
            try {
                DiamondsListenerImpl.mergeToFullResults(new File(outputFile));
            } catch (DiamondsException de) {
                log.error("Not able to merge into full results XML file " + de.getMessage(), de);
            }
        }
    }

}