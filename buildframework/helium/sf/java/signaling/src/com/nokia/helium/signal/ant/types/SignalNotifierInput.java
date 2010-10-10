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

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.ResourceCollection;


/**
 * SignalInput class which is a type to store input for signals
 * Signals..
 * &lt;targetCondition&gt;
 *    &lt;hasSeverity severity="error" file="${build.cache.log.dir}/signals/prep_work_status.xml" /&gt;
 * &lt;/targetCondition&gt;
 * 
 */
public class SignalNotifierInput extends DataType {
    
    private Vector<SignalInput> signalInputs = new Vector<SignalInput>();

    private Vector<ResourceCollection> notifierInputList = new Vector<ResourceCollection>();

    /**
     * Create a nested notifierInput element.
     * @return a new NotifierInput instance.
     */    
    public NotifierInput createNotifierInput() {
        NotifierInput notifierInput =  new NotifierInput(getProject());
        add(notifierInput);
        return notifierInput;
    }

    /**
     * Adds any kind of ResourceCollection Ant type like 
     * paths or filesets.
     * @param notifierInput notifier to be added to the list.
     */    
    public void add(ResourceCollection notifierInput) {
        notifierInputList.add(notifierInput);
    }

    /**
     * Add a nested signalInput.
     * @param signalInput the signalInput to be added
     */
    public void add(SignalInput signalInput) {
        signalInputs.add(signalInput);
    }

    /**
     * Create a nested signalInput.
     */
    public SignalInput createSignalInput() {
        SignalInput input =  new SignalInput();
        add(input);
        return input;
    }

    /**
     * Returns the notifierInput associated to the current object.
     * @return a ResourceCollection representing the notifier inputs.
     */
    public ResourceCollection getNotifierInput() {
        ResourceCollection input = null;
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
            throw new BuildException("One nested signalInput is required at " + this.getLocation());
        }
        if (signalInputs.size() > 1) {
            throw new BuildException("One and only signalInput can be defined at " + this.getLocation());
        }
        return signalInputs.elementAt(0);
    }
}