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

import org.apache.tools.ant.types.DataType;

import org.apache.tools.ant.BuildException;


/**
 * SignalInput class which is a type to store input for signals
 * Signals..
 * &lt;targetCondition&gt;
 *    &lt;hasSeverity severity="error" file="${build.cache.log.dir}/signals/prep_work_status.xml" /&gt;
 * &lt;/targetCondition&gt;
 * 
 */
public class SignalNotifierInput extends DataType
{
    private Vector<SignalInput> signalInputs = new Vector<SignalInput>();

    private Vector<NotifierInput> notifierInputList = new Vector<NotifierInput>();

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
     * Helper function to add the created signalinput
     * @param filter to be added to the filterset
     */
    public void add(SignalInput input) {
        signalInputs.add(input);
    }

    /**
     * Helper function called by ant to create the new signalinput
     */
    public SignalInput createSignalInput() {
        SignalInput input =  new SignalInput();
        add(input);
        return input;
    }

    public NotifierInput getNotifierInput() {
        NotifierInput input = null;
        if (notifierInputList.size() > 1) {
            throw new BuildException("One and only signal input can be defined");
        }
        if (!notifierInputList.isEmpty()) {
            input = notifierInputList.elementAt(0);
        }
        return input;
    }

    /**
     * Gets the signal input of this config.
     * @return signal input stored in the config, by dereferencing the input ref. 
     */    
    public SignalInput getSignalInput() {
        if (signalInputs.isEmpty()) {
            throw new BuildException("No signal input in signal config, failed: ");
        }
        if (signalInputs.size() > 1) {
            throw new BuildException("One and only signal input can be defined");
        }

        Object refObject =  signalInputs.elementAt(0).getRefid().getReferencedObject();
        if (refObject == null) {
            throw new BuildException("Signal Input Reference not exists");
        }
        
        SignalInput signalInput = (SignalInput)refObject;
        return signalInput;
    }
}