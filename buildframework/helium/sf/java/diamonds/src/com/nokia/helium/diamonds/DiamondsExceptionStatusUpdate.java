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
import java.util.Hashtable;
import java.util.Vector;
import org.apache.log4j.Logger;
import org.apache.tools.ant.Project;
import com.nokia.helium.core.ant.HlmExceptionHandler;
import com.nokia.helium.signal.SignalStatus;
import com.nokia.helium.signal.SignalStatusList;


/**
 * Class to store the builds status and check the signal is present in the deferred signal list.
 * if so get the signal informations like signal name, error message and target name.
 * With collected signal information and build status send the generated XML file to diamonds client class
 * to update the information into diamonds
 */
public class DiamondsExceptionStatusUpdate extends DataType implements HlmExceptionHandler {
    private Logger log = Logger.getLogger(DiamondsExceptionStatusUpdate.class);

    /* Initiate build status to failed as this method will be invoked in case of exceptions only */
    private String buildStatus = "failed";

    private SimpleDateFormat timeFormat;

    private Hashtable<String, String> signalInformation = new Hashtable<String, String>();

    private String outputFile,templateFile;


    /**
     * Implements the Exception method to update build status and signal information to diamonds.
     * @param project
     * @param module
     * @param e
     */
    @SuppressWarnings("unchecked")
    public void handleException(Project project, Exception e) {
        Project prj = DiamondsListenerImpl.getProject();

        try {
            if (DiamondsListenerImpl.isInitialized()) {
                if (SignalStatusList.getDeferredSignalList().hasSignalInList()) {
                    Vector<SignalStatus> signalList = SignalStatusList.getDeferredSignalList().getSignalStatusList();
                    timeFormat = new SimpleDateFormat(DiamondsConfig.getTimeFormat());
                    log.debug("Build Status = " + buildStatus);
                    int i = 0;
                    for (SignalStatus status : signalList) {
                        prj.setProperty("diamond.signal.name." + i, status.getName());
                        prj.setProperty("diamond.error.message." + i, status.getName());
                        prj.setProperty("diamond.time.stamp." + i, new String(timeFormat.format(status.getTimestamp())));
                        DiamondsListenerImpl.sendMessage("diamonds-signal");
                    }
                }
                if (SignalStatusList.getNowSignalList().hasSignalInList()) {
                    Vector<SignalStatus> signalList = SignalStatusList.getNowSignalList().getSignalStatusList();
                    buildStatus = "failed";
                    timeFormat = new SimpleDateFormat(DiamondsConfig.getTimeFormat());
                    log.debug("Build Status = " + buildStatus);
                    int i = 0;
                    for (SignalStatus status : signalList) {
                        prj.setProperty("diamond.signal.name." + i, status.getName());
                        prj.setProperty("diamond.error.message." + i, status.getMessage());
                        prj.setProperty("diamond.time.stamp." + i,new String(timeFormat.format(status.getTimestamp())));
                        i += 1;
                    }
                    DiamondsListenerImpl.sendMessage("diamonds.signal.message");
                }
                prj.setProperty("build.status", buildStatus);
                DiamondsListenerImpl.sendMessage("diamonds.status.message");
            }
        } catch (DiamondsException dex) {
            log.debug("exception: ", dex);
        }
    }
}