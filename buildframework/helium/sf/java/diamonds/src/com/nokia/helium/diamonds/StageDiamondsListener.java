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

import java.util.ArrayList;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import com.nokia.helium.core.ant.types.Stage;

/**
 * Diamonds client used to connect to get build id and also to send the build results
 * 
 */
public class StageDiamondsListener extends DiamondsListenerImpl {

    private static final Date INVALID_DATE = new Date(-1);

    private static Object mutexObject = new Object();;

    private Logger log = Logger.getLogger(StageDiamondsListener.class);

    private List<Map<String, Date>> stageTargetBeginList = new ArrayList<Map<String, Date>>();

    private Map<String, List<Stage>> stageTargetEndMap = new HashMap<String, List<Stage>>();

    private Map<String, String> stageStartTargetMap = new HashMap<String, String>();

    private Map<String, Date> stageStartTargetTimeMap = new HashMap<String, Date>();

    private boolean isTargetMapInitialized;

    private Map<String, Stage> stages;


    public StageDiamondsListener() {
        stages = DiamondsConfig.getStages();
    }

    public void targetBegin(BuildEvent buildEvent) throws DiamondsException {
        initDiamondsClient();
        Project projectInStage = buildEvent.getProject();
        int hashCode = projectInStage.hashCode();
        String targetName = buildEvent.getTarget().getName();
        if (!isTargetMapInitialized && stages != null) {
            log.debug("diamonds:StageDiamondsListener: initializing for all stages.");
            initStageTargetsMap(projectInStage);
            isTargetMapInitialized = true;
        }
        String targetNameWithHashCode = targetName + "-" + hashCode;
        log.debug("targetBegin: targetNameWithHashCode: " + targetNameWithHashCode);
        log.debug("targetBegin targetName: " + targetName + " - currentStartTargetName:"
            + stageStartTargetMap.get(targetNameWithHashCode));
        if (stageStartTargetMap.get(targetNameWithHashCode) == null) {
            log.debug("looking for start target match and associating time to it");
            findAndSetStartTimeForTargetInStageList(targetName, targetNameWithHashCode);
        }
    }

    private Date getStartTime(Stage stage) {
        String startTargetName = stage.getStartTarget();
        for (Iterator<Map<String, Date>> listIter = stageTargetBeginList.iterator(); listIter.hasNext();) {
            Map<String, Date> stageMap = listIter.next();
            if (stageMap.get(startTargetName) != null) {
                Set<String> targetSet = stageMap.keySet();
                for (String key : targetSet) {
                    log.debug("key: " + key);
                    Date time = stageMap.get(key);
                    log.debug("time: " + time);
                    if (time != INVALID_DATE) {
                        return time;
                    }
                }
            }
        }
        throw new BuildException("No time recorded " + "for stage:" + stage.getStageName());
    }

    private void sendStageInfo(String targetName, int hashCode) throws DiamondsException {
        List<Stage> stageList = stageTargetEndMap.get(targetName);
        synchronized (mutexObject) {
            if (stageList != null) {
                for (Stage stage : stageList) {
                    if (stage != null) {
                        log.debug("stage.name: " + stage.getStageName());
                        log.debug("stage.start target name: " + stage.getStartTarget());
                        String currentStageTargetName = stageStartTargetMap.get(stage.getStartTarget()
                            + "-" + hashCode);
                        log.debug("getStageBasedOnEndTarget: currentStargetTargetName" + currentStageTargetName);
                        if (currentStageTargetName != null) {
                            log.debug("stage in targetend: " + stage);
                            if (stage != null && getIsInitialized()) {
                                //initDiamondsClient();
                                String stageName = stage.getStageName();
                                log.debug("stageName in targetend: " + stageName);
                                String stageMessage =  stageName + ".id";
                                sendMessage(stageMessage);
                                Date startTime = getStartTime(stage);
                                getProject().setProperty("logical.stage", stageName);
                                getProject().setProperty("stage.start.time", getTimeFormat().format(startTime));
                                getProject().setProperty("stage.end.time", getTimeFormat().format(new Date()));
                                sendMessage("stage.time.message");
                            }
                        }
                    }
                }
            }
        }
    }

    @SuppressWarnings("unchecked")
    public void targetEnd(BuildEvent buildEvent) throws DiamondsException {
        String targetName = buildEvent.getTarget().getName();
        Project prj = buildEvent.getProject();
        int hashCode = prj.hashCode();
        String targetNameWithHashCode = targetName + "-" + hashCode;
        log.debug("targetEnd: targetNamewith-hashcode: " + targetNameWithHashCode);
        sendStageInfo(targetName, hashCode);
    }

    private void findAndSetStartTimeForTargetInStageList(String targetName,
        String targetNameWithHashCode) throws DiamondsException {
        for (Iterator<Map<String, Date>> listIter = stageTargetBeginList.iterator(); listIter.hasNext();) {
            Map<String, Date> stageMap = listIter.next();
            Date targetTime = stageMap.get(targetName);
            if (targetTime != null && targetTime.equals(INVALID_DATE)) {
                log.debug("diamonds:StageDiamondsListener: started recording for stage-target-----: "
                    + targetName);
                log.debug("findtime: targetNamewith-hashcode: " + targetNameWithHashCode);
                log.debug("findtime: time: " + new Date());
                stageMap.put(targetName, new Date());
                stageStartTargetMap.put(targetNameWithHashCode, targetName);
                stageStartTargetTimeMap.put(targetNameWithHashCode, new Date());
            }
        }
    }

    @SuppressWarnings("unchecked")
    private void initStageTargetsMap(Project projectInStage) {
        for (String key : stages.keySet()) {
            Stage stage = stages.get(key);
            String startTargetName = stage.getStartTarget();
            Map<String, Date> stageMap = new LinkedHashMap<String, Date>();
            Vector<Target> arrayList = null;
            try {
                arrayList = projectInStage.topoSort(startTargetName, projectInStage.getTargets(), false);
            }
            catch (BuildException be) {
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
                String endTargetName = stage.getEndTarget();
                // fast lookup
                List<Stage> existingStageList = stageTargetEndMap.get(endTargetName);
                if (existingStageList == null) {
                    existingStageList = new ArrayList<Stage>();
                    stageTargetEndMap.put(endTargetName, existingStageList);
                }
                existingStageList.add(stage);
                log.debug("   - End target: " + endTargetName);
            }
        }
    }
}