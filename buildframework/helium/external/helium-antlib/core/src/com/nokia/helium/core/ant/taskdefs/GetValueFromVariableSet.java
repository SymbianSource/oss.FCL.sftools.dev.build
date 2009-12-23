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

import org.apache.tools.ant.BuildException;
import java.util.Vector;
import java.util.Collection;
import com.nokia.helium.core.ant.VariableIFImpl;
import org.apache.tools.ant.Task;
import com.nokia.helium.core.ant.types.Variable;


/**
 * To retrive a variable value from a collection of variable set based on name, which contains property-value in pair.
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
 * @ant.task name="getVariableValue"
 */
public class GetValueFromVariableSet extends Task {
    private String name;
    private String property;
    private boolean failOnError = true;
    
   private Vector<VariableIFImpl> variableIntefaces = new Vector<VariableIFImpl>();
    
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Helper function to set failonerror attribute for the task. 
     * @param failStatus, if true will fail the build if no variable is found for 
     * matching name.
     */
    public void setFailOnError(boolean failStatus) {
        failOnError = failStatus;
    }

    /**
     * Helper function to store the name of the property where the value to be stored
     * @param property name of the property where the result to be stored
     */
    public void setProperty(String property) {
        this.property = property;
    }

    /**
     * Helper function to create the VariableIFImpl object. 
     * @return created VariableIFImpl instance
     */
    public VariableIFImpl createVariableIFImpl() {
        VariableIFImpl var = new VariableIFImpl();
        add(var);
        return var;
    }

    
    /**
     * Helper function to add the newly created variable set. Called by ant.
     * @param vs variable set to be added.
     */
    public void add(VariableIFImpl vs) {
        variableIntefaces.add(vs);
    }

    public VariableIFImpl getVariableInterface() {
        if (variableIntefaces.isEmpty()) {
            throw new BuildException("variable interface cannot be null");
        }
        if (variableIntefaces.size() > 1 ) {
            throw new BuildException("maximum one variable interface can be set");
        }
        return variableIntefaces.elementAt(0);
    }
    

    /**
     * Task to get the name / value pair
     * @return return the name / value pair for the variable set.
     */
    public void execute() {
        if (name == null)
            throw new BuildException("'name' attribute has not been defined.");
        if (property == null)
            throw new BuildException(
                    "'property' attribute has not been defined.");
        VariableIFImpl varInterface = getVariableInterface();
        Collection<Variable> variables = varInterface.getVariables();
        for (Variable var : variables) {
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
