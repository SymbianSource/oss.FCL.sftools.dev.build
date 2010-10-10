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


import java.util.List;
import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.ant.types.ReferenceType;
import com.nokia.helium.signal.ant.Notifier;

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
    private List<ReferenceType<SignalNotifierList>> notifierListRef = new Vector<ReferenceType<SignalNotifierList>>();

    // By default it is configured to fail the build.
    private String failBuild = "now";

    
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
        if (this.isReference()) {
            return getReferencedObject().getFailBuild();
        } else {
            return failBuild;
        }
    }
    
    /**
     * Helper function called by ant to create a new notifier for
     * this input.
     * @return ReferenceType created ReferenceType.
     */    
    public ReferenceType<SignalNotifierList> createNotifierListRef() {
        ReferenceType<SignalNotifierList> notifierRef =  new ReferenceType<SignalNotifierList>();
        add(notifierRef);
        return notifierRef;
    }

    /**
     * Adds the created notifier to the list
     * @param ReferenceType notifier to be added to the list.
     */    
    public void add(ReferenceType<SignalNotifierList> notifier) {
        if (notifier != null) {
            notifierListRef.add(notifier);
        }
    }
        
    /**
     * Gets the NotifierList associated with this input. If the
     * notifier list reference is empty then it throws exception. 
     * @return List of notifier associated with this input.
     */    
    public Vector<Notifier> getSignalNotifierList() {
        if (this.isReference()) {
            return getReferencedObject().getSignalNotifierList();
        } else {
            Vector<Notifier> notifierList = null;
            if (notifierListRef != null) {
                for (ReferenceType<SignalNotifierList> notifierRef : notifierListRef) {
                    notifierList = notifierRef.getReferencedObject().getNotifierList();
                }
                return notifierList;
            }
            throw new BuildException("No signal notifierlist reference defined.");
        }
    }
    
    /**
     * Get the signal name. If the object is a reference then its id is used.
     * 'unknownSignalName' is returned otherwise. 
     * @return the signal name.
     */
    public String getName() {
        if (this.isReference()) {
            return this.getRefid().getRefId();
        }
        return "unknownSignalName";
    }
    
    protected SignalInput getReferencedObject() {
        Object obj = this.getRefid().getReferencedObject();
        if (obj instanceof SignalInput) {
            return (SignalInput)obj; 
        }
        throw new BuildException("SignalInput reference " + this.getRefid().getRefId() + " does not exist.");
    }
}