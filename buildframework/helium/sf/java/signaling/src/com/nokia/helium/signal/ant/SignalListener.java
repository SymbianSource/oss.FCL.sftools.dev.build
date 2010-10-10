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


package com.nokia.helium.signal.ant;

import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.List;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildListener;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;

import com.nokia.helium.signal.ant.types.SignalListenerConfig;

/**
 * Listener class that can connect to Ant and log information regarding to build
 * times, number of errors and such. Data is sent to Diamonds server, where it
 * is processed further.
 * 
 * This class is listening all build related events. It catches the build
 * start-finish, target start-finish events of Ant and gather build start-end
 * time, errors/warnings and store in BuildData class. Stored data will be
 * exported to XML and uploaded to Diamonds server after each specific target.
 * For example after target "create-bom" this class will upload all BOM data to
 * Diamonds.
 * 
 * 
 */
public class SignalListener implements BuildListener {
    private boolean initialized;

    private Project project;

    private Hashtable<String, SignalListenerConfig> signalListenerConfigs = new Hashtable<String, SignalListenerConfig>();

    private HashMap<String, List<SignalListenerConfig>> targetsMap = new HashMap<String, List<SignalListenerConfig>>();

    /**
     * Ant call this function when build start.
     */
    public void buildStarted(BuildEvent event) {
        project = event.getProject();
    }

    /**
     * Triggered when a target starts.
     */
    @SuppressWarnings("unchecked")
    public void targetStarted(BuildEvent event) {
        if (project == null) {
            project = event.getProject();
        }
        if (!initialized) {
            Hashtable<String, Object> references = (Hashtable<String, Object>)project.getReferences();
            Enumeration<String> keyEnum = references.keys();
            while (keyEnum.hasMoreElements()) {
                String key = keyEnum.nextElement();
                if (references.get(key) instanceof SignalListenerConfig) {
                    SignalListenerConfig config = (SignalListenerConfig) references
                        .get(key);
                    config.setConfigId(key);
                    signalListenerConfigs.put(key, config);
                    String targetName = config.getTargetName();
                    List<SignalListenerConfig> list;
                    if (targetsMap.get(targetName) == null) {
                        list = new ArrayList<SignalListenerConfig>();
                    } else {
                        list = targetsMap.get(targetName);
                    }
                    list.add(config);
                    targetsMap.put(targetName, list);
                }
            }
            initialized = true;
        }
    }

    /**
     * Triggered when a target finishes.
     */
    public void targetFinished(BuildEvent event) {
        checkAndNotifyFailure(event.getTarget(), event.getProject());
    }

    /**
     * Triggered when the build finishes.
     */
    public void buildFinished(BuildEvent event) {
    }

    /**
     * Triggered when a task starts.
     */
    public void taskStarted(BuildEvent event) {
    }

    /**
     * Triggered when a task finishes.
     */
    public void taskFinished(BuildEvent event) {
    }

    /**
     * Triggered when a build message is logged.
     */
    public void messageLogged(BuildEvent event) {
    }

    protected boolean checkAndNotifyFailure(Target target, Project prj) {
        String targetName = target.getName();
        String signalName = "unknown";
        boolean retValue = false;
        
        if (targetsMap.containsKey(targetName)) {
            retValue = true;
            for (SignalListenerConfig config : targetsMap.get(targetName))
            {
                String refid = config.getConfigId();
                Object  configCurrent = prj.getReference(refid);
                if (configCurrent != null && configCurrent instanceof SignalListenerConfig) {
                    signalName = refid;
                }
                boolean failBuild = false;
                if (config.getTargetCondition() != null) {
                    failBuild = config.getTargetCondition().getCondition().eval();
                }
                Signals.getSignals().processSignal(prj, config.getSignalNotifierInput(), signalName, 
                        targetName, config.getErrorMessage(), failBuild);
            }
        }
        return retValue;
    }

}