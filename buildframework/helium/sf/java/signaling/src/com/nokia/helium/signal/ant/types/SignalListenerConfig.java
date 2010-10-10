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

/**
 * This Ant type defines a signal input for listener based signals.
 *
 * E.g:
 * <pre>
 * &lt;hlm:signalListenerConfig id="prepSignal" target="prep-signal-test" message="some-target-name triggered a signal" &gt;
 *    &lt;hlm:targetCondition  &gt;
 *         &lt;/available file="some-file.txt" /&gt;
 *    &lt;/hlm:targetCondition&gt;
 *      &lt;signalInput refid="prepSignalInput" &gt;
 *           &lt;notifierInput file = "${build.cache.log.dir}/signals/${build.id}_prep_status.html" /&gt;
 *      &lt;/signalInput&gt;
 *    
 * &lt;/hlm:signalListenerConfig&gt;
 * </pre>
 *
 * @ant.type name="signalListenerConfig" category="Signaling"
 */

public class SignalListenerConfig extends DataType
{
   
    private Vector<SignalNotifierInput> signalNotifierInputs = new Vector<SignalNotifierInput>();

    private String target;
    
    private String errMsg;

    private TargetCondition targetCondition;
        
    private String configID;

    public String getTargetName() {
        return target;
    }
    
    public String getErrorMessage() {
        return errMsg;
    }

    /**
     * Helper function to store the Name of the target for which
     * the signal to be processed. 
     * @param targetName to be stored.
     */    
    public void setTarget(String targetName) {
        target = targetName;
    }

    /**
     * Helper function to store the error message of
     * @param errorMessage to be displayed after failure.
     */        
    public void setMessage(String errorMessage) {
        errMsg = errorMessage;
    }


    /**
     * Helper function called by ant to create the new signalinput
     */
    public SignalNotifierInput createSignalNotifierInput() {
        SignalNotifierInput input =  new SignalNotifierInput();
        signalNotifierInputs.add(input);
        if (this.signalNotifierInputs.size() > 1) {
            throw new BuildException(this.getDataTypeName() + " only accept one nested signalNotifierInput at " + this.getLocation());
        }
        return input;
    }

    /**
     * Creates type target condition of type TargetCondition.
     * @return ReferenceType which is created and stored by the config.
     */
    public TargetCondition createTargetCondition() {
        if (this.targetCondition != null) {
            throw new BuildException(this.getDataTypeName() + " only accept one nested targetCondition at " + this.getLocation());
        }
        TargetCondition condition =  new TargetCondition();
        this.targetCondition = condition;
        return this.targetCondition;
    }

    /**
     * Helper function to store the config id
     * @param config id to store.
     */    
    public void setConfigId(String confID) {
        configID = confID;
    }

    /**
     * Helper function to return the config id
     * @return The configuration id
     */   
    public String getConfigId() {
        return configID;
    }

    /**
     * Helper function to return the Targetcondition matching the target name.
     * @param String name of the target for which the targetcondition is returned, can be null in case of
     * informative signal, in that case build should not be failing. 
     */    
    public TargetCondition getTargetCondition() {
        return this.targetCondition;
    }

    /**
     * Helper function to return the Targetcondition matching the target name.
     * @param String name of the target for which the targetcondition is returned,
     */    
    public SignalNotifierInput getSignalNotifierInput() {
        if (signalNotifierInputs.isEmpty()) {
            return null;
        }
        return signalNotifierInputs.get(0);
    }
}