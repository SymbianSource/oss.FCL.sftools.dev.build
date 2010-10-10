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

package com.nokia.helium.core.ant.taskdefs;

import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;

import com.nokia.helium.core.ant.MappedVariable;
import com.nokia.helium.core.ant.VariableMap;
import com.nokia.helium.core.ant.types.VariableSet;

/**
 * To retrive a variable value from a collection of variable set based on name, which contains
 * property-value in pair.
 * 
 * <pre>
 * Example:
 * 
 * &lt;hlm:argSet id="test.variableSet"&gt;
 * &lt;variable name="v1" value="the_value_1"/&gt;
 *     &lt;variable name="v2" value="the_value_2"/&gt;
 *      &lt;variable name="v3" value="the_value_3"/&gt;
 * &lt;/hlm:argSet&gt;
 *       
 *  &lt;hlm:getVariableValue name="v3" property="v1.value"&gt;
 * &lt;hlm:argSet refid="test.variableSet"/&gt;
 * &lt;/hlm:getVariableValue&gt;
 * </pre>
 * 
 * @ant.task category="Core"
 * @ant.task name="getVariableValue"
 */
public class GetValueFromVariableSetTask extends Task {
    private String name;
    private String property;
    private boolean failOnError = true;

    private Vector<VariableMap> variableMaps = new Vector<VariableMap>();

    public void setName(String name) {
        this.name = name;
    }

    /**
     * Helper function to set failonerror attribute for the task.
     * 
     * @param failStatus, if true will fail the build if no variable is found for matching name.
     */
    public void setFailOnError(boolean failStatus) {
        failOnError = failStatus;
    }

    /**
     * Helper function to store the name of the property where the value to be stored
     * 
     * @param property name of the property where the result to be stored
     */
    public void setProperty(String property) {
        this.property = property;
    }

    /**
     * Helper function to create the VariableIFImpl object.
     * 
     * @return created VariableIFImpl instance
     */
    public VariableSet createVariableIFImpl() {
        VariableSet var = new VariableSet();
        add(var);
        return var;
    }

    /**
     * Helper function to add the newly created variable set. Called by ant.
     * 
     * @param vs variable set to be added.
     */
    public void add(VariableMap vs) {
        variableMaps.add(vs);
    }

    public VariableMap getVariableInterface() {
        if (variableMaps.isEmpty()) {
            throw new BuildException("variable interface cannot be null");
        }
        if (variableMaps.size() > 1) {
            throw new BuildException("maximum one variable interface can be set");
        }
        return variableMaps.elementAt(0);
    }

    /**
     * Task to get the name / value pair
     * 
     * @return return the name / value pair for the variable set.
     */
    public void execute() {
        if (name == null) {
            throw new BuildException("'name' attribute has not been defined.");
        }
        if (property == null) {
            throw new BuildException("'property' attribute has not been defined.");
        }
        VariableMap variableMap = getVariableInterface();
        for (MappedVariable var : variableMap.getVariables()) {
            if (var.getName().equals(name)) {
                getProject().setProperty(property, var.getValue());
                return;
            }
        }
        if (failOnError) {
            throw new BuildException("Could not find '" + name + "' variable.");
        }
    }
}
