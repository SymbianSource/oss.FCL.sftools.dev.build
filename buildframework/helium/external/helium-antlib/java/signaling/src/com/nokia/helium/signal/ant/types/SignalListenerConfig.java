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

import org.apache.tools.ant.types.DataType;
import java.util.Vector;

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

    private Vector<TargetCondition> targetConditions = new Vector<TargetCondition>();
        
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
        add(input);
        return input;
    }

    /**
     * Helper function to add the created signalinput
     * @param filter to be added to the filterset
     */
    public void add(SignalNotifierInput input) {
        signalNotifierInputs.add(input);
    }


    /**
     * Creates type target condition of type TargetCondition.
     * @return ReferenceType which is created and stored by the config.
     */
    public TargetCondition createTargetCondition() {
        TargetCondition condition =  new TargetCondition();
        add(condition);
        return condition;
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
     * Adds the TargetCondition reference to the container.
     * @param TargetCondition to be added to the container, to be processed during signaling.
     */    
    public void add(TargetCondition condition) {
        if (condition != null) {
            targetConditions.add(condition);
        }
    }    

    /**
     * Helper function to return the Targetcondition matching the target name.
     * @param String name of the target for which the targetcondition is returned,
     */    
    public TargetCondition getTargetCondition() {
        if (targetConditions.isEmpty()) {
            return null;
        }
        return targetConditions.get(0);
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

    /**
     * Helper function to return the complete target name set of the config.
     * @return Set, full set of target names referred by this config.
     * @throws HlmAntLibException
     */    
    //public Set<String> getTargetNameSet() {
    //    if (targetConditionsMap.isEmpty()) {
    //        initializeTargetConditionsMap();
    //    }
    //    return targetConditionsMap.keySet();
    //}

    /**
     * Initializes the TargetConditionsMap, mapping target name with corresponding targetcondition
     * for fast lookup. 
     */    
    //private void initializeTargetConditionsMap() {
    //    for (TargetCondition condition : targetConditions) {
    //        String name = condition.getName();
    //        if (name != null) {
    //            targetConditionsMap.put(name, condition);
    //        }
    //    }
    //}
}