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

import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.HlmAntLibException;
import com.nokia.helium.core.ant.types.ReferenceType;
import com.nokia.helium.core.LogSource;
import com.nokia.helium.signal.ant.SignalListener;

import java.util.Set;
import java.util.Vector;
import java.util.HashMap;

/**
 * Deprecated: This Ant type defines a signal configuration. Please use signalListenerConfig element or signal task nested element.
 * E.g:
 * <pre>
 * &lt;hlm:signalConfig name="mySignal" &gt;
 *    &lt;hlm:targetCondition name="some-target-name" message="some-target-name triggered a signal" &gt;
 *         &lt;/available file="some-file.txt" /&gt;
 *    &lt;/hlm:targetCondition&gt;
 * &lt;/hlm:signalConfig&gt;
 * </pre>
 *
 * @ant.type name="signalConfig" category="Signaling"
 * @deprecated
 */

public class SignalConfig extends DataType
{
   
    private static boolean warningPrinted;
    
    private Vector<ReferenceType> signalInputListRef = new Vector<ReferenceType>();
    private HashMap<String, TargetCondition> targetConditionsMap = new HashMap<String, TargetCondition>();
    private Vector<TargetCondition> targetConditions = new Vector<TargetCondition>();
    
    private Vector<LogSourceList> sourceList = new Vector<LogSourceList>();
    
    private String configID;
    
   
    
    /**
     * {@inheritDoc}
     */
    public void setProject(Project project) {
        super.setProject(project);
        if (!warningPrinted) {
            getProject().log("signalConfig element is now deprecated. Please consider moving to signalListenerConfig element or" + 
                " signal task nested element.", Project.MSG_WARN);
            warningPrinted = true;
        }
    }
    
    /**
     * Creates data type ReferenceType and adds to the vector.
     * @return ReferenceType which is created and stored by the config.
     */
    public ReferenceType createInputRef() {
        ReferenceType inputRef =  new ReferenceType();
        add(inputRef);
        return (ReferenceType)inputRef;
    }

    /**
     * Adds the reference to the container.
     * @param ReferenceType to be added to the container
     */
    public void add(ReferenceType input) {
        if (input != null) {
            signalInputListRef.add(input);
        }
    }


    /**
     * Creates data type of list of sources and adds to the sourcelist.
     * @return sourcelist which is created and stored by the config.
     */
    public LogSourceList createSources() {
        LogSourceList source =  new LogSourceList();
        add(source);
        return (LogSourceList)source;
    }

    /**
     * Adds the source list to the container.
     * @param source list to be added to the container
     */
    public void add(LogSourceList source) {
        if (source != null) {
            if (sourceList.isEmpty()) {
                sourceList.add(source);
            }
        }
    }
    
    public Vector<LogSource> getLogSourceList() {
        Vector<LogSource> logSource = null;
        if (!sourceList.isEmpty()) {
            logSource = sourceList.elementAt(0).getLogSourceList();
        }
        return logSource;
    }
    
    public String getSourceType() {
        if (!sourceList.isEmpty()) {        
            return sourceList.elementAt(0).getSourceType();
        }
        return "default";
    }

    /**
     * Creates type target condition of type TargetCondition.
     * @return ReferenceType which is created and stored by the config.
     */
    public TargetCondition createTargetCondition() {
        TargetCondition condition =  new TargetCondition();
        add(condition);
        return (TargetCondition)condition;
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
     * Gets the signal input of this config.
     * @return signal input stored in the config, by dereferencing the input ref. 
     */    
    public SignalInput getSignalInput() {
        if (signalInputListRef == null) {
            throw new HlmAntLibException(SignalListener.MODULE_NAME,"signalInputList null exception");
        }
        ReferenceType inputRef = (ReferenceType)signalInputListRef.elementAt(0);
        Object obj = inputRef.getReferencedObject();
        if (obj instanceof SignalInput) {
            return (SignalInput)obj;
        }
        throw new HlmAntLibException(SignalListener.MODULE_NAME,"input type is not of type SignalInput");
    }

    /**
     * Helper function to return the TargetCondition matching the target name.
     * @param String name of the target for which the TargetCondition is returned,
     */    
    public TargetCondition getTargetCondition(String targetName) {
        if (targetConditionsMap.isEmpty()) {
            initializeTargetConditionsMap();
        }
        return targetConditionsMap.get(targetName);
    }

    /**
     * Helper function to return the complete target name set of the config.
     * @return Set, full set of target names referred by this config.
     * @throws HlmAntLibException
     */    
    public Set<String> getTargetNameSet() {
        if (targetConditionsMap.isEmpty()) {
            initializeTargetConditionsMap();
        }
        return targetConditionsMap.keySet();
    }

    /**
     * Initializes the TargetConditionsMap, mapping target name with corresponding TargetCondition
     * for fast lookup. 
     */    
    @SuppressWarnings("deprecation")
    private void initializeTargetConditionsMap() {
        java.util.ListIterator<TargetCondition> iter = targetConditions.listIterator();
        while (iter.hasNext()) {
            TargetCondition condition = iter.next();
            String name = condition.getName();
            if (name != null) {
                targetConditionsMap.put(name, condition);
            }
        }
    }
}