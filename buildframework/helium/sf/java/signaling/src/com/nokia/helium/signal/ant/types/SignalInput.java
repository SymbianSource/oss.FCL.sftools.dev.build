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

 
package com.nokia.helium.signal.ant.types;


import java.util.Vector;

import org.apache.log4j.Logger;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.types.ReferenceType;
import com.nokia.helium.signal.Notifier;

/**
 * SignalInput class which is a type to store input for signals
 * Signals..
 *   
 * <pre>
 *   &lt;hlm:signalInput id=&quot;testDeferredSignalInput&quot;&gt;
 *      &lt;/hlm:notifierList refid=&quot;defaultNotiferList&quot; &gt;
 *   &lt;/hlm:signalInput&gt;
 *   
 *   &lt;hlm:signal name=&quot;compileSignal&quot; result=&quot;${result}&quot;&gt;
 *       &lt;-- Let's refer to some existing signal input configuration --&gt;
 *       &lt;hlm:signalInput refid=&quot;testDeferredSignalInput&quot; /&gt;
 *   &lt;/hlm:signal&gt;
 * </pre>
 * 
 * @ant.type name="signalInput" category="Signaling"
 */
public class SignalInput extends DataType
{
    private Vector<ReferenceType> notifierListRef = new Vector<ReferenceType>();

    private Vector<NotifierInput> notifierInputList = new Vector<NotifierInput>();

    // By default it is configured to fail the build.
    private String failBuild = "now";

    private Logger log = Logger.getLogger(SignalInput.class);

    
    /**
     * Defines how the signal framework should handle the error, either
     * fail "now", at the end of the build "defer", or ignore the failure
     * with "never".
     * @param failBuild type of failure for this input.
     * @ant.not-required Default is now.
     */
    public void setFailBuild(FailBuildEnum failInput) {
        failBuild = failInput.getValue();
    }

    /**
     * Helper function called by ant to set the failbuild type
     * @param failBuild type of failure for this input.
     */
    public String getFailBuild() {
        return failBuild;
    }

    /**
     * Helper function called by ant to create a new notifier for
     * this input.
     * @return ReferenceType created ReferenceType.
     */    
    public NotifierInput createNotifierInput() {
        NotifierInput notifierInput =  new NotifierInput();
        add(notifierInput);
        return notifierInput;
    }

    /**
     * Adds the created notifier to the list
     * @param ReferenceType notifier to be added to the list.
     */    
    public void add(NotifierInput notifierInput) {
        if (notifierInput != null) {
            notifierInputList.add(notifierInput);
        }
    }
    
    /**
     * Helper function called by ant to create a new notifier for
     * this input.
     * @return ReferenceType created ReferenceType.
     */    
    public ReferenceType createNotifierListRef() {
        ReferenceType notifierRef =  new ReferenceType();
        add(notifierRef);
        return notifierRef;
    }

    /**
     * Adds the created notifier to the list
     * @param ReferenceType notifier to be added to the list.
     */    
    public void add(ReferenceType notifier) {
        if (notifier != null) {
            notifierListRef.add(notifier);
        }
    }
    
    public Vector<NotifierInput> getNotifierInput() {
        return notifierInputList;
    }
    
    /**
     * Gets the NotifierList associated with this input. If the
     * notifier list reference is empty then it throws exception. 
     * @return List of notifier associated with this input.
     */    
    public Vector<Notifier> getSignalNotifierList() {
        Vector<Notifier> notifierList = null;
        if (notifierListRef != null) {
            log.debug("getSignalNotifierList:list.size:" + notifierListRef.size());
            for (ReferenceType notifierRef : notifierListRef) {
                Object obj = notifierRef.getReferencedObject();
                if (obj instanceof SignalNotifierList) {
                    notifierList = ((SignalNotifierList)obj).getNotifierList();
                    break;
                }
            }
            return notifierList;
        }
        throw new BuildException("No signal notifierlist reference defined.");
    }    
}