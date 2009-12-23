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
import org.apache.tools.ant.Target;
import org.apache.tools.ant.Project;

import java.util.ArrayList;
import java.util.List;
import java.util.Hashtable;
import java.util.Map;
import java.io.File;
import org.apache.log4j.Logger;
import com.nokia.helium.core.PropertiesSource;
import com.nokia.helium.core.TemplateInputSource;
import com.nokia.helium.core.XMLTemplateSource;

/**
 * Listener sending data based on target configuration to diamonds.
 */
public class TargetDiamondsListener extends DiamondsListenerImpl {

    private Project project;
    
    private Logger log = Logger.getLogger(TargetDiamondsListener.class);

    private Map<String, com.nokia.helium.diamonds.Target> targetsMap;

    private String currentTarget;

    /**
     * Default constructor
     */
    public TargetDiamondsListener() {
        targetsMap = DiamondsConfig.getTargets();
    }

    private boolean isTargetsToExecute(BuildEvent buildEvent) {
        project = buildEvent.getProject();
        Target target = buildEvent.getTarget();
        boolean retValue = false;
        com.nokia.helium.diamonds.Target currentTarget = targetsMap
                .get(target.getName());
        String currentTargetName = null;
        if (currentTarget != null) {
            currentTargetName = currentTarget.getTargetName();
        }
        if (currentTargetName != null) {
            String ifCondition = target.getIf();
            String unlessCondition = target.getUnless();
            if (ifCondition == null && unlessCondition == null) {
                retValue = true;
            } else {
                String ifProperty = project.getProperty(ifCondition);
                String unlessProperty = project.getProperty(unlessCondition);
                if (ifProperty != null || unlessProperty == null) {
                    retValue = true;
                }
            }
        }
        return retValue;
    }

    /**
     * Function to process logging info during beginning of target execution.
     * This checks that the current target execution is in config and requires
     * some data to be send it to diamonds.
     * 
     * @param event
     *            of target execution.
     */
    public void targetBegin(BuildEvent buildEvent) throws DiamondsException {
        String targetName = buildEvent.getTarget().getName();
        if (isTargetsToExecute(buildEvent)) {
            currentTarget = targetName;
            com.nokia.helium.diamonds.Target target = targetsMap
                    .get(currentTarget);
            if (!target.isDefer()) {
                initDiamondsClient();
            }
        }
    }

    /**
     * Function to process logging info during end of build. If the target in
     * config, sends the data to diamonds (uses the template conversion if
     * needed).
     * 
     * @param event
     *            of target execution.
     */
    public void targetEnd(BuildEvent buildEvent) throws DiamondsException {
        String targetName = buildEvent.getTarget().getName();
        if (currentTarget != null && currentTarget.equals(targetName)) {           
            if (getIsInitialized()) {
                log
                .debug("diamonds:TargetDiamondsListener:finished recording, sending data to diamonds for target: "
                        + buildEvent.getTarget().getName());
                sendTargetData(buildEvent, buildEvent.getTarget().getProject());
            }
            currentTarget = null;
        }
    }

    /**
     * Sends the data to diamonds. First it looks if the template with target
     * name exists, then it looks for input source file from config, if ant
     * properties required from config, it uses it for template conversion. If
     * no template file exists, sends the data directly.
     * 
     * @param event
     *            of target execution.
     */
    @SuppressWarnings("unchecked")
    private void sendTargetData(BuildEvent buildEvent, Project project)
            throws DiamondsException {
        com.nokia.helium.diamonds.Target target = targetsMap
                .get(currentTarget);
        String sourceFile = target.getSource();
        if (sourceFile == null) {
            sourceFile = getSourceFile(target.getTargetName());
        }
        Hashtable<String, String> antProperties = null;
        String targetTemplateFile = target.getTemplateFile();
        if (targetTemplateFile == null) {
            targetTemplateFile = target.getTargetName() + ".xml.ftl";
        }
        String output = DiamondsConfig.getOutputDir() + File.separator
                + target.getTargetName() + ".xml";
        File templateFile = new File(DiamondsConfig.getTemplateDir(),
                targetTemplateFile);
        List<TemplateInputSource> sourceList = new ArrayList<TemplateInputSource>();
        if (sourceFile == null) {
            log
                    .debug("diamonds:TargetDiamondsListener:sourceFile not defined.");
        } else {
            sourceList.add(new XMLTemplateSource("doc", new File(sourceFile)));
        }
        // Ant?
        if (target.isAntPropertiesRequired()) {
            sourceList
                    .add(new PropertiesSource("ant", project.getProperties()));
        }
        try {
            if (templateFile.exists()) {
                if (!(antProperties == null && sourceFile == null)) {
                    getTemplateProcessor().convertTemplate(DiamondsConfig
                            .getTemplateDir(), targetTemplateFile, output,
                            sourceList);
                }
            } else {
                log
                        .debug("sendTargetData: exists("
                                + templateFile.getAbsolutePath() + ") => false");

            }
        } catch (com.nokia.helium.core.TemplateProcessorException e1) {
            throw new DiamondsException("template conversion error while sending data for target:"
                    + target + ":" + e1.getMessage());
        }
        File outputFile = new File(output);
        if (outputFile.exists()) {
            mergeToFullResults(outputFile);
            if (!target.isDefer()) {
                getDiamondsClient().sendData(outputFile.getAbsolutePath(),
                        DiamondsConfig.getDiamondsProperties()
                                .getDiamondsBuildID());
            } else {
                log.debug("diamonds:TargetDiamondsListener:defer logging for: "
                        + outputFile);
                getDeferLogList().add(output);
            }
        } else {
            log.debug("diamonds:TargetDiamondsListener:outputfile "
                    + outputFile + " does not exist");
        }
    }

}