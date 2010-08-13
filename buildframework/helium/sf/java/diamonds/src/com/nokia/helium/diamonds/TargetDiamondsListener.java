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

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Map;
import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import com.nokia.helium.core.ant.types.TargetMessageTrigger;
import com.nokia.helium.core.ant.Message;

/**
 * Listener sending data based on target configuration to diamonds.
 */
public class TargetDiamondsListener extends DiamondsListenerImpl {


    private Logger log = Logger.getLogger(TargetDiamondsListener.class);

    private Map<String, TargetMessageTrigger> targetsMap;

    private String currentTarget;

    /**
     * Default constructor
     */
    public TargetDiamondsListener() {
        targetsMap = DiamondsConfig.getTargetsMap();
        for (String key : targetsMap.keySet()) {
            log.debug("target name: " + key);
        }
    }

    private boolean isTargetsToExecute(BuildEvent buildEvent) {
        Project projectInTarget = buildEvent.getProject();
        Target target = buildEvent.getTarget();
        boolean retValue = false;
        log.debug("isTargetsToExecute: target:" + target.getName() );
        TargetMessageTrigger targetInMap = targetsMap.get(target.getName());
        log.debug("isTargetsToExecute: targetInMap:" + targetInMap );
        if (targetInMap != null) {
            log.debug("target: " + target.getName());
            log.debug("targetInMap: " + targetInMap);
            String targetNameInMap = targetInMap.getTargetName();
            log.debug("targetNameInMap: " + targetInMap.getTargetName());
            if (targetNameInMap != null) {
                retValue = true;
                String ifCondition = target.getIf();
                if ((ifCondition != null) && (projectInTarget.getProperty(
                        projectInTarget.replaceProperties(ifCondition)) == null)) {
                    retValue = false;
                }
                String unlessCondition = target.getUnless();
                if (unlessCondition != null && (projectInTarget.getProperty(
                        projectInTarget.replaceProperties(unlessCondition)) != null)) {
                    retValue = false;
                }
            }
        }
        return retValue;
    }

    /**
     * Function to process logging info during beginning of target execution. This checks that the
     * current target execution is in config and requires some data to be send it to diamonds.
     * 
     * @param event of target execution.
     */
    public void targetBegin(BuildEvent buildEvent) throws DiamondsException {
        initDiamondsClient();
        String targetName = buildEvent.getTarget().getName();
        if (isTargetsToExecute(buildEvent)) {
            currentTarget = targetName;
        }
    }

    /**
     * Function to process logging info during end of build. If the target in config, sends the data
     * to diamonds (uses the template conversion if needed).
     * 
     * @param event of target execution.
     */
    public void targetEnd(BuildEvent buildEvent) throws DiamondsException {
        String targetName = buildEvent.getTarget().getName();
        if (isTargetsToExecute(buildEvent)) {
            if (currentTarget != null && currentTarget.equals(targetName)) {
                log.debug("targetEnd: " + targetName);
                if (getIsInitialized()) {
                    log.debug("diamonds:TargetDiamondsListener:finished recording, sending data to diamonds for target: "
                        + buildEvent.getTarget().getName());
                    sendTargetData(buildEvent, buildEvent.getTarget().getProject());
                }
                currentTarget = null;
            }
        }
    }

    private void sendData(InputStream stream) throws DiamondsException {
        String urlPath = DiamondsConfig.getBuildId();
        getDiamondsClient().sendData(stream, urlPath);
        log.debug("urlPath:" + urlPath);
    }
    /**
     * Sends the data to diamonds. First it looks if the template with target name exists, then it
     * looks for input source file from config, if ant properties required from config, it uses it
     * for template conversion. If no template file exists, sends the data directly.
     * 
     * @param event of target execution.
     */
    private void sendTargetData(BuildEvent buildEvent, Project project) throws DiamondsException {
        TargetMessageTrigger targetMap = targetsMap.get(currentTarget);
        if (targetMap != null) {
            
            List<Message> messageList = targetMap.getMessageList();
            for ( Message message : messageList ) {
                try {
                    File tempFile = streamToTempFile(message.getInputStream());
                    tempFile.deleteOnExit();
                    sendData(new FileInputStream(tempFile));
                    mergeToFullResults(new FileInputStream(tempFile));
                } catch (IOException iex) {
                    throw new DiamondsException("error closing the stream while sending data");
                }
                catch (com.nokia.helium.core.MessageCreationException mex) {
                    log.debug("IOException while retriving message:", mex);
                    throw new DiamondsException("error during message retrival");
                }
            }
        }
    }
}