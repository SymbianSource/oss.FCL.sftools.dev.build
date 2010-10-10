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
 * Description: To print the message on the shell in case of build has errors
 * is user sets failbuild status to never in signal configuration file.
 *
 */
package com.nokia.helium.signal.ant;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Vector;

import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.ResourceCollection;

import com.nokia.helium.signal.ant.types.SignalInput;
import com.nokia.helium.signal.ant.types.SignalNotifierInput;

/**
 * Signals give access to signals raised during the build.
 *
 */
public class Signals {
    // Global instance handling signals a the running Ant build
    private static Signals self;
    
    private SignalStatusList deferSignalList = new SignalStatusList();
    private SignalStatusList nowSignalList = new SignalStatusList();
    private SignalStatusList neverSignalList = new SignalStatusList();
    private Logger log = Logger.getLogger(this.getClass());
    
    /**
     * Get the access to the unique instance of Signals.
     * @return
     */
    public static Signals getSignals() {
        if (self == null) {
            self = new Signals();
        }
        return self;
    }

    /**
     * Returns the deferred signal list.
     */
    public List<SignalStatus> getDeferredSignalList() {
        return deferSignalList;
    }
    
    /**
     * Returns the now signal list.
     */
    public List<SignalStatus> getNowSignalList() {
        return nowSignalList;
    }
    
    /**
     * Returns the never signal list.
     */
    public List<SignalStatus> getNeverSignalList() {
        return neverSignalList;
    }

    /**
     * 
     * @param project current Ant project
     * @param signalNotifierInput can be null, the DEFAULT_NOTIFIER_LIST_REFID will be used for notification,
     *                            and failing configuration will be considered as now.  
     * @param signalName the signal name
     * @param targetName target where the signal has been raised.
     * @param errorMessage the message
     * @param failBuild true for a failure, false in case of success.
     */
    public void processSignal(Project project, SignalNotifierInput signalNotifierInput, String signalName, String targetName, 
            String errorMessage, boolean failBuild) {
        Vector<Notifier> notifierList = null;
        ResourceCollection notifierInput = null;
        if (signalNotifierInput != null) {
            SignalInput signalInput = signalNotifierInput.getSignalInput();
            notifierList = signalInput.getSignalNotifierList();
            notifierInput = signalNotifierInput.getNotifierInput();
        }
        // Print some verbose log information about signal raised.
        project.log("------------ Signal raised ------------", notifierList != null ? Project.MSG_VERBOSE : Project.MSG_INFO);
        project.log("Signal: " + signalName, notifierList != null ? Project.MSG_VERBOSE : Project.MSG_INFO);
        project.log("Target: " + targetName, notifierList != null ? Project.MSG_VERBOSE : Project.MSG_INFO);
        project.log("Message: " + errorMessage, notifierList != null ? Project.MSG_VERBOSE : Project.MSG_INFO);
        project.log("Failure: " + (failBuild ? "Yes" : "No"), notifierList != null ? Project.MSG_VERBOSE : Project.MSG_INFO);
        project.log("---------------------------------------", notifierList != null ? Project.MSG_VERBOSE : Project.MSG_INFO);

        // Only run notification 
        if (notifierList != null) {
            sendNotifications(notifierList, signalName, failBuild,
                    notifierInput, errorMessage );
        }
        if (failBuild) {
            String failStatus = "now";
            if (signalNotifierInput != null && signalNotifierInput.getSignalInput() != null) {
                failStatus = signalNotifierInput.getSignalInput().getFailBuild();
            } else {
                log.debug("Could not find config for signal: " + signalName);
            }
            if (failStatus == null || failStatus.equals("now")) {
                log.debug("Adding now signal. Signal name is " + signalName);
                Signals.getSignals().getNowSignalList().add(new SignalStatus(signalName,
                        errorMessage, targetName, new Date()));
                throw new BuildException(new SignalStatus(signalName,
                        errorMessage, targetName, new Date()).toString());
            } else if (failStatus.equals("defer")) {
                log.debug("Adding deffer signal. Signal " + signalName + " will be deferred.");
                Signals.getSignals().getDeferredSignalList().add(new SignalStatus(
                        signalName, errorMessage, targetName, new Date()));
            } else if (failStatus.equals("never")) {
                log.debug("Adding never signal. Signal name is " + signalName);
                Signals.getSignals().getNeverSignalList().add(new SignalStatus(signalName,
                        errorMessage, targetName, new Date()));
            } else if (!failStatus.equals("never")) {
                Signals.getSignals().getNowSignalList().add(new SignalStatus(signalName,
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
    protected void sendNotifications(List<Notifier> notifierList, String signalName,
            boolean failStatus, ResourceCollection notifierInput, String errorMessage ) {
        if (notifierList == null) {
            return;
        }
        for (Notifier notifier : notifierList) {
            if (notifier != null) {
                notifier.sendData(signalName, failStatus, notifierInput, errorMessage);
            }
        }
    }
    
    protected class SignalStatusList extends ArrayList<SignalStatus> {

        private static final long serialVersionUID = 2159492246599277712L;

        /**
         * Converts the error list into a user readable message.
         * 
         * @return the error message.
         */
        public String toString() {
            StringBuffer statusBuffer = new StringBuffer();
            for (SignalStatus signalStatus : this) {
                statusBuffer.append(signalStatus);
                statusBuffer.append("\n");
            }
            return statusBuffer.toString();
        }

    }
}
