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

import java.text.SimpleDateFormat;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.HlmExceptionHandler;
import com.nokia.helium.core.ant.Message;
import com.nokia.helium.core.ant.PostBuildAction;
import com.nokia.helium.diamonds.ant.Listener;
import com.nokia.helium.signal.ant.SignalStatus;
import com.nokia.helium.signal.ant.Signals;


/**
 * Class to store the builds status and check the signal is present in the deferred signal list.
 * if so get the signal informations like signal name, error message and target name.
 * With collected signal information and build status send the generated XML file to diamonds client class
 * to update the information into diamonds
 *
 * @ant.type name="diamondsStatusUpdate" category="diamonds" 
 */
public class DiamondsStatusUpdate extends DataType implements HlmExceptionHandler, PostBuildAction {
    private static final String BUILD_SIGNAL_MESSAGE_REFERENCE_ID = "diamonds.signal.message";
    private static final String BUILD_STATUS_MESSAGE_REFERENCE_ID = "diamonds.status.message";
    private static final String BUILD_STATUS_PROPERTY = "build.status";
    private String buildStatus = "succedded";

    /**
     * Implements the Exception method to update build status and signal information to diamonds.
     * @param project
     * @param module
     * @param e
     */
    public void handleException(Project project, Exception e) {
        buildStatus = "failed";
        Listener listener = Listener.getDiamondsListener(project);
        if (listener != null && listener.getConfiguration() != null && 
                listener.getSession() != null && listener.getSession().isOpen()) {
            try {
                log("Build Status = " + buildStatus, Project.MSG_DEBUG);
                project.setProperty(BUILD_STATUS_PROPERTY, buildStatus);
                sendMessage(listener, BUILD_STATUS_MESSAGE_REFERENCE_ID);
            } catch (DiamondsException dex) {
                log(dex.getMessage(), Project.MSG_WARN);
            }
        }
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void executeOnPostBuild(Project project, String[] targetNames) {
        Listener listener = Listener.getDiamondsListener(project);
        if (listener != null && listener.getSession() != null && listener.getSession().isOpen()) {
            try {
                // Sending the signal data on post build, as they have already been raised.
                sendSignals(listener);
                log("Build Status = " + buildStatus, Project.MSG_DEBUG);
                project.setProperty(BUILD_STATUS_PROPERTY, buildStatus);
                sendMessage(listener, BUILD_STATUS_MESSAGE_REFERENCE_ID);
            } catch (DiamondsException de) {
                log("Not able to merge into full results XML file " + de.getMessage(), Project.MSG_WARN);
            }
        }
    }

    /**
     * Send a message.
     * @param listener the diamonds listener
     * @param the messageId a reference string to a Message instance.
     */
    protected void sendMessage(Listener listener, String messageId) throws DiamondsException {
        Object object = listener.getProject().getReference(messageId);
        if (object != null
                && object instanceof Message) {
            listener.getSession().send((Message)object);
        }        
    }
    
    /**
     * Sending signal information to diamonds
     * @param project the root project instance
     * @param listener the diamonds listener.
     * @return
     */
    protected void sendSignals(Listener listener) {
        Project project = listener.getProject();
        try {
            SimpleDateFormat timeFormat = new SimpleDateFormat(listener.getConfiguration().getTimeFormat());
            int i = 0;
            if (!Signals.getSignals().getDeferredSignalList().isEmpty()) {
                buildStatus = "failed";
                for (SignalStatus status : Signals.getSignals().getDeferredSignalList()) {
                    project.setProperty("diamond.signal.name." + i, status.getName());
                    project.setProperty("diamond.error.message." + i, status.getMessage());
                    project.setProperty("diamond.time.stamp." + i, new String(timeFormat.format(status.getTimestamp())));
                    i += 1;
                }
            }
            if (!Signals.getSignals().getNowSignalList().isEmpty()) {
                buildStatus = "failed";
                for (SignalStatus status : Signals.getSignals().getNowSignalList()) {
                    project.setProperty("diamond.signal.name." + i, status.getName());
                    project.setProperty("diamond.error.message." + i, status.getMessage());
                    project.setProperty("diamond.time.stamp." + i,new String(timeFormat.format(status.getTimestamp())));
                    i += 1;
                }
            }
            // At list one signal has been found, let's send the message.
            if (i > 0) {
                sendMessage(listener, BUILD_SIGNAL_MESSAGE_REFERENCE_ID);
            }
        } catch (DiamondsException dex) {
            log(dex.getMessage(), Project.MSG_WARN);
        }
    }
}