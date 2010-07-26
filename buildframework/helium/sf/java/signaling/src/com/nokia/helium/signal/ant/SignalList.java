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

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.taskdefs.condition.Condition;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import com.nokia.helium.signal.Notifier;
import com.nokia.helium.signal.SignalStatus;
import com.nokia.helium.signal.SignalStatusList;
import com.nokia.helium.signal.ant.types.SignalListenerConfig;
import com.nokia.helium.signal.ant.types.SignalInput;
import com.nokia.helium.signal.ant.types.SignalNotifierInput;
import com.nokia.helium.signal.ant.types.NotifierInput;
import com.nokia.helium.signal.ant.types.SignalNotifierList;
import com.nokia.helium.signal.ant.types.TargetCondition;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Vector;
import java.util.HashMap;
import java.util.Date;
import java.util.Enumeration;
import org.apache.log4j.Logger;

/**
 * Helper class to store the list of notifiers.
 */
public class SignalList {

    // default id list name
    public static final String DEFAULT_NOTIFIER_LIST_REFID = "defaultSignalInput";


    private Hashtable<String, SignalListenerConfig> signalListenerConfigs = new Hashtable<String, SignalListenerConfig>();

    private HashMap<String, List<SignalListenerConfig>> targetsMap = new HashMap<String, List<SignalListenerConfig>>();

    private Project project;

    private Logger log = Logger.getLogger(this.getClass());

     /**
     * Constructor
     */
    @SuppressWarnings("unchecked")
    public SignalList(Project project) {
        this.project = project;
        Hashtable<String, Object> references = project.getReferences();
        Enumeration<String> keyEnum = references.keys();
        while (keyEnum.hasMoreElements()) {
            String key = keyEnum.nextElement();
            if (references.get(key) instanceof SignalListenerConfig) {
                log.debug("SignalList: Found reference: " + key);
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
    }

    public Project getProject() {
        return project;
    }

    /**
     * Returns the list of SignalListenerConfig discovered.
     * @return a Vector of SignalList objects.
     */
    public Vector<SignalListenerConfig> getSignalListenerConfigList() {
        return new Vector<SignalListenerConfig>(signalListenerConfigs.values());
    }

    /**
     * Check if targetName is defined is defined by a targetCondition.
     * @param targetName the target name
     * @return a boolean, true if found, false otherwise.
     */
    public boolean isTargetInSignalList(String targetName) {
        return targetsMap.get(targetName) != null;
    }

    /**
     * Return the list of SignalListenerConfig defining a target.
     * @param targetName
     * @return
     */
    public List<SignalListenerConfig> getSignalListenerConfig(String targetName) {
        return targetsMap.get(targetName);
    }

    protected void sendNotifications(Vector<Notifier> notifierList, String signalName, String errorMessage ) {
        sendNotifications( notifierList, signalName, false, null, errorMessage );
    }

    public void processForSignal(Project prj, SignalNotifierInput signalNotifierInput, String signalName, String targetName, 
            String errorMessage, boolean failBuild) {
        SignalInput signalInput = signalNotifierInput.getSignalInput();
        Vector<Notifier> notifierList = signalInput.getSignalNotifierList();
        if (notifierList == null) {
            Object obj = (Object) prj
                    .getReference(DEFAULT_NOTIFIER_LIST_REFID);
            if (obj instanceof SignalNotifierList) {
                notifierList = ((SignalNotifierList) obj)
                        .getNotifierList();
            }
        }
        NotifierInput notifierInput = signalNotifierInput.getNotifierInput();
        sendNotifications(notifierList, signalName, failBuild,
                notifierInput, errorMessage );
        if (failBuild) {
            String failStatus = "now";
            if (signalInput != null) {
                failStatus = signalInput.getFailBuild();
            } else {
                log.debug("Could not find config for signal: " + signalName);
            }
            if (failStatus == null || failStatus.equals("now")) {
                log.debug("Adding now signal. Signal name is " + signalName);
                SignalStatusList.getNowSignalList().addSignalStatus(new SignalStatus(signalName,
                        errorMessage, targetName, new Date()));
                throw new BuildException(new SignalStatus(signalName,
                        errorMessage, targetName, new Date()).toString());
            } else if (failStatus.equals("defer")) {
                log.debug("Adding deffer signal. Signal " + signalName + " will be deferred.");
                SignalStatusList.getDeferredSignalList().addSignalStatus(new SignalStatus(
                        signalName, errorMessage, targetName, new Date()));
            } else if (failStatus.equals("never")) {
                log.debug("Adding never signal. Signal name is " + signalName);
                SignalStatusList.getNeverSignalList().addSignalStatus(new SignalStatus(signalName,
                        errorMessage, targetName, new Date()));
            } else if (!failStatus.equals("never")) {
                SignalStatusList.getNowSignalList().addSignalStatus(new SignalStatus(signalName,
                        errorMessage, targetName, new Date()));
                throw new BuildException(new SignalStatus(signalName,
                        errorMessage, targetName, new Date()).toString());
            } else {
                log.info("Signal " + signalName
                        + " set to be ignored by the configuration.");
            }
        }
    }
    /**
     * Send notification using the notification list.
     * 
     * @param notifierList
     */
    protected void sendNotifications(Vector<Notifier> notifierList, String signalName,
            boolean failStatus, NotifierInput notifierInput, String errorMessage ) {
        if (notifierList == null) {
            return;
        }
        for (Notifier notifier : notifierList) {
            if (notifier != null) {
                notifier.sendData(signalName, failStatus, notifierInput, errorMessage );
            }
        }
    }

    public boolean checkAndNotifyFailure(Target target, Project prj) {
        String targetName = target.getName();
        String signalName = "unknown";
        boolean retValue = false;
        
        if (isTargetInSignalList(targetName)) {
            retValue = true;
            for (SignalListenerConfig config : getSignalListenerConfig(targetName))
            {
                TargetCondition targetCondition = config
                        .getTargetCondition();
                String errorMessage = null;
                log.debug("targetcondition:" + targetCondition);
                Condition condition = null;
                if (targetCondition != null) {
                    condition = getFailureCondition(targetCondition);
                }
                errorMessage = config.getErrorMessage();
                String refid = config.getConfigId();
                log.debug("refid:" + refid);
                Object  configCurrent = prj.getReference(refid);
                if (configCurrent != null && configCurrent instanceof SignalListenerConfig) {
                    signalName = refid;
                }
                processForSignal(prj, config.getSignalNotifierInput(), signalName, 
                        targetName, errorMessage, condition != null);
                log.debug("checkAndNotifyFailure: SignalName: " + signalName);
            }
        }
        return retValue;
    }
    
    private Condition getFailureCondition(TargetCondition targetCondition) {
        Condition retCondition = null;
        Vector<Condition> conditionList = targetCondition.getConditions();
        for (Condition condition : conditionList) {
            log.debug("getFailureCondition:" + condition.eval());
            if (condition.eval()) {
                retCondition = condition;
                break;
            }
        }
        return retCondition;
    }

    /**
     * Send signal notification by running configured notifiers.
     * 
     * @param targetName
     */
    public void sendSignal(String signalName, boolean failStatus)
    {
        log.debug("Sending signal for:" + signalName);
        if (project.getReference(DEFAULT_NOTIFIER_LIST_REFID) != null) {
            // sending using default settings
            sendNotify(((SignalInput) project
                    .getReference(DEFAULT_NOTIFIER_LIST_REFID))
                    .getSignalNotifierList(), signalName, failStatus,null);
        }
    }

    protected void sendNotify(Vector<Notifier> notifierList, String signalName) {
        sendNotify(notifierList, signalName, false, null);
    }

    /**
     * Send notification using the notification list.
     * 
     * @param notifierList
     */
    @SuppressWarnings("deprecation")
    protected void sendNotify(Vector<Notifier> notifierList, String signalName,
            boolean failStatus, List<String> fileList) {
        if (notifierList == null) {
            return;
        }
        for (Notifier notifier : notifierList) {
            if (notifier != null) {
                notifier.sendData(signalName, failStatus, fileList);
            }
        }
    }

    /**
     * Handle the signal, either fail now, or defer the failure.
     * 
     * @param targetName
     *            , target where the failure happened.
     * @param errMsg
     *            , the error message
     */
    public void fail(String signalName, String targetName, String errorMessage)
    {
        String failStatus = "now";
        log.debug("Could not find config for signal: " + signalName);
        log.debug("failStatus: " + failStatus);
        log.debug("Adding now signal. Signal name is " + signalName);
        SignalStatusList.getNowSignalList().addSignalStatus(new SignalStatus(signalName,
            errorMessage, targetName, new Date()));
        throw new BuildException(new SignalStatus(signalName,
            errorMessage, targetName, new Date()).toString());
    }
}