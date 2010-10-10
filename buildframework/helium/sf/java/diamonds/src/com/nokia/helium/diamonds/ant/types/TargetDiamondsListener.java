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

package com.nokia.helium.diamonds.ant.types;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;

import com.nokia.helium.core.ant.Message;
import com.nokia.helium.core.MessageCreationException;
import com.nokia.helium.core.ant.types.TargetMessageTrigger;
import com.nokia.helium.diamonds.DiamondsException;
import com.nokia.helium.diamonds.DiamondsListener;
import com.nokia.helium.diamonds.DiamondsSession;
import com.nokia.helium.diamonds.ant.Listener;

/**
 * Listener sending data based on target configuration to diamonds.
 */
public class TargetDiamondsListener implements DiamondsListener {
    private static final int READ_ARRAY_SIZE = 1000;
    
    private Listener  diamondsListener;
    private Map<String, TargetMessageTrigger> targetTriggers = new HashMap<String, TargetMessageTrigger>();
 
    
    public void configure(Listener diamondsListener) throws DiamondsException {
        this.diamondsListener = diamondsListener;
        for (Object entry : diamondsListener.getProject().getReferences().values()) {
            if (entry instanceof TargetMessageTrigger) {
                TargetMessageTrigger targetMessageTrigger = (TargetMessageTrigger)entry;
                targetTriggers.put(targetMessageTrigger.getTargetName(), targetMessageTrigger);
            }
        }
    }

    public void buildFinished(BuildEvent buildEvent) throws DiamondsException {
    }

    public void buildStarted(BuildEvent buildEvent) throws DiamondsException {
    }

    public void targetFinished(BuildEvent buildEvent) throws DiamondsException {
        String targetName = buildEvent.getTarget().getName();
        if (testIfCondition(buildEvent.getTarget()) && testUnlessCondition(buildEvent.getTarget()) &&
                targetTriggers.containsKey(buildEvent.getTarget().getName())) {
            DiamondsSession session = diamondsListener.getSession();
            if (session != null && session.isOpen()) {
                for (Message message : targetTriggers.get(targetName).getMessageList()) {
                    buildEvent.getProject().log("Sending message to Diamonds:\n" + dumpMessage(message), Project.MSG_DEBUG);
                    session.send(message);
                }
            }
        }
    }

    /**
     * Check if the target should be skipped because of the if attribute.
     * @param target the target instance to be tested.
     * @return Returns true if the target should be executed, false otherwise.
     */
    private boolean testIfCondition(Target target) {
        if (target.getIf() == null) {
            return true;
        }
        String test = target.getProject().replaceProperties(target.getIf());
        return target.getProject().getProperty(test) != null;
    }

    /**
     * Check if the target should be skipped because of the unless attribute.
     * @param target the target instance to be tested.
     * @return Returns true if the target should be executed, false otherwise.
     */
    private boolean testUnlessCondition(Target target) {
        if (target.getUnless() == null) {
            return true;
        }
        String test = target.getProject().replaceProperties(target.getUnless());
        return target.getProject().getProperty(test) == null;
    }
    
    /**
     * Dump the content of a Message and return a String.
     * @param message The message.
     * @return String of contents.
     * @throws DiamondsException If any IO errors.
     */
    private String dumpMessage(Message message) throws DiamondsException {
        StringBuilder builder;
        try {
            InputStream in = message.getInputStream();
            builder = new StringBuilder();
            byte[] data = new byte[READ_ARRAY_SIZE];
            int length = in.read(data);
            while (length > 0) {
                builder.append(new String(data, 0, length));
                length = in.read(data);
            }
        }
        catch (IOException e) {
            throw new DiamondsException(e.toString());
        } catch (MessageCreationException e) {
            throw new DiamondsException(e.toString());
        }
        return builder.toString();
    }

    public void targetStarted(BuildEvent buildEvent) throws DiamondsException {
    }
}


