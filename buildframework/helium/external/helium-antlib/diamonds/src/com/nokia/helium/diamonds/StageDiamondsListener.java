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
import org.apache.tools.ant.BuildException;



import java.util.Date;

import java.util.HashMap;
import java.util.List;
import java.util.Enumeration;
import java.util.Map;
import java.io.File;
import java.util.Iterator;
import java.util.Vector;
import java.util.ArrayList;
import org.apache.log4j.Logger;

import com.nokia.helium.core.PropertiesSource;
import com.nokia.helium.core.TemplateInputSource;


import com.nokia.helium.core.XMLTemplateSource;

/**
 * Diamonds client used to connect to get build id and also to send the build
 * results
 * 
 */
public class StageDiamondsListener extends DiamondsListenerImpl {

    private static final Date INVALID_DATE = new Date(-1);

    private Logger log = Logger.getLogger(StageDiamondsListener.class);
    
    private List<Map<String, Date>> stageTargetBeginList = new ArrayList<Map<String, Date>>();

    private Map<String, Stage> stageTargetEndMap = new HashMap<String, Stage>();

    private boolean isTargetMapInitialized;

    private Project project;

    private String currentStartTargetName;

    private List<Stage> stages;

    private Date currentStartTargetTime;

    public StageDiamondsListener() {
        stages = DiamondsConfig.getStages();
    }

    public void targetBegin(BuildEvent buildEvent) throws DiamondsException {
        project = buildEvent.getProject();
        String targetName = buildEvent.getTarget().getName();
        if (!isTargetMapInitialized && stages != null) {
            log
                    .debug("diamonds:StageDiamondsListener: initializing for all stages.");
            initStageTargetsMap();
            isTargetMapInitialized = true;
        }
        log.debug("targetBegin targetName: " + targetName + " - currentStartTargetName:" + currentStartTargetName);
        if (currentStartTargetName == null) {
            findAndSetStartTimeForTargetInStageList(targetName);
        }
    }

    @SuppressWarnings("unchecked")
    public void targetEnd(BuildEvent buildEvent) throws DiamondsException {
        if (currentStartTargetName != null) {
            String targetName = buildEvent.getTarget().getName();
            Stage stage = stageTargetEndMap.get(targetName);
            if (stage != null && getIsInitialized() ) {
                //initDiamondsClient();
                String stageName = stage.getStageName();
                String sourceFile = stage.getSourceFile();
                log
                        .debug("diamonds:StageDiamondsListener: finished recording for stage: "
                                + stageName);
                if (sourceFile == null) {
                    sourceFile = getSourceFile(stageName);
                }
                project.setProperty("logical.stage", stageName);
                project.setProperty("stage.start.time", getTimeFormat()
                        .format(currentStartTargetTime));
                project.setProperty("stage.end.time", getTimeFormat()
                        .format(new Date()));
                currentStartTargetName = null;
                // Look for template file with stage name
                String stageTemplateFileName = stageName + ".xml.ftl";
                File stageTemplateFile = new File(stageTemplateFileName);
                if (stageTemplateFile.exists()) {
                    String output = DiamondsConfig.getOutputDir()
                            + File.separator + stageName + ".xml";
                    try {
                        List<TemplateInputSource> sourceList = new ArrayList<TemplateInputSource>();
                        sourceList.add(new PropertiesSource("ant", project
                                .getProperties()));
                        sourceList
                                .add(new XMLTemplateSource("doc", new File(sourceFile)));
                        getTemplateProcessor().convertTemplate(DiamondsConfig
                                .getTemplateDir(), stageTemplateFileName,
                                output, sourceList);
                        mergeToFullResults(new File(output));

                        // String mergedFile = mergeFiles(new File(output));

                        log.info("Sending data to diamonds for stage: "
                                + stageName);
                        getDiamondsClient().sendData(output, DiamondsConfig
                                .getDiamondsProperties().getDiamondsBuildID());
                    } catch (com.nokia.helium.core.TemplateProcessorException e1) {
                        throw new DiamondsException(
                                "template conversion error for stage: "
                                        + stageName + " : " + e1.getMessage());
                    }
                } else {
                    log.debug("diamonds:StageDiamondsListener:tempalte file: "
                            + stageTemplateFile + " does not exist");
                }

                String output = DiamondsConfig.getOutputDir() + File.separator
                        + stageName + "-time.xml";
                // Store the time for the current stage and send it
                stageTemplateFileName = "diamonds_stage.xml.ftl";
                try {
                    List<TemplateInputSource> sourceList = new ArrayList<TemplateInputSource>();
                    sourceList.add(new PropertiesSource("ant", project
                            .getProperties()));
                    sourceList.add(new XMLTemplateSource("doc", new File(sourceFile)));
                    getTemplateProcessor().convertTemplate(DiamondsConfig
                            .getTemplateDir(), stageTemplateFileName, output,
                            sourceList);
                    mergeToFullResults(new File(output));
                    // List filesToMerge = new ArrayList();

                    // mergedFile = mergeFiles(output);
                    getDiamondsClient().sendData(output, DiamondsConfig
                            .getDiamondsProperties().getDiamondsBuildID());
                } catch (com.nokia.helium.core.TemplateProcessorException e1) {
                    throw new DiamondsException("template conversion error while sending data for stage: "
                            + stageName + " : " + e1.getMessage());
                }
            }
        }
    }

    private void findAndSetStartTimeForTargetInStageList(String targetName)
            throws DiamondsException {
        for (Iterator<Map<String, Date>> listIter = stageTargetBeginList.iterator(); listIter
                .hasNext();) {
            Map<String, Date> stageMap = listIter.next();
            Date targetTime = stageMap.get(targetName);
            if (targetTime != null && targetTime.equals(INVALID_DATE)) {
                log.debug("diamonds:StageDiamondsListener: started recording for stage-target: "
                                + targetName);
                stageMap.put(targetName, new Date());
                currentStartTargetName = targetName;
                currentStartTargetTime = new Date();
            }
        }
    }

    @SuppressWarnings("unchecked")
    private void initStageTargetsMap() {
        Iterator<Stage> iter = stages.iterator();
        while (iter.hasNext()) {
            // stage begin process
            Stage stage = iter.next();
            String startTargetName = stage.getStartTargetName();
            Map<String, Date> stageMap = new HashMap<String, Date>();
            Vector<Target> arrayList = null;
            try {
                arrayList = project.topoSort(startTargetName, project
                        .getTargets(), false);
            } catch (BuildException be) {
                log.debug("Diamonds target missing: ", be);
            }
            if (arrayList != null) {
                log.debug(" + Stage definition: " + stage.getStageName());
                Enumeration<Target> targetEnum = arrayList.elements();
                while (targetEnum.hasMoreElements()) {
                    // fast lookup
                    Target target = targetEnum.nextElement();
                    stageMap.put(target.getName(), INVALID_DATE);
                    log.debug("   - Start target: " + target.getName());
                }
                stageTargetBeginList.add(stageMap);

                // stage end process
                String endTargetName = stage.getEndTargetName();
                // fast lookup
                stageTargetEndMap.put(endTargetName, stage);
                log.debug("   - End target: " + endTargetName);
            }
        }
    }
}