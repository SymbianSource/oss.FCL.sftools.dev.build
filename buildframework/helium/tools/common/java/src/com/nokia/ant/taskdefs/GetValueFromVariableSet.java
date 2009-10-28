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

package com.nokia.ant.taskdefs;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.Reference;
import java.util.Iterator;
import java.util.Vector;
import com.nokia.ant.types.VariableSet;
import com.nokia.ant.types.Variable;


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
    private Vector<VariableSet> variablesets = new Vector<VariableSet>();

    public void setName(String name) {
        this.name = name;
    }

    public void setProperty(String property) {
        this.property = property;
    }

    public void add(VariableSet vs) {
        variablesets.add(vs);
    }

    public VariableSet createVariableSet() {
        VariableSet vs = new VariableSet();
        variablesets.add(vs);
        return vs;
    }

    public void execute() {
        if (name == null)
            throw new BuildException("'name' attribute has not been defined.");
        if (property == null)
            throw new BuildException(
                    "'property' attribute has not been defined.");

        for (Iterator<VariableSet> vsit = variablesets.iterator(); vsit
                .hasNext();) {
            VariableSet vs = vsit.next();
            if (vs.isReference()) {
                Reference reference = vs.getRefid();
                vs = (VariableSet)reference.getReferencedObject(getProject());
            }
            for (Iterator vit = vs.getVariables().iterator(); vit.hasNext();) {
                Variable v = (Variable) vit.next();
                if (v.getName().equals(name)) {
                    log("Setting '" + property + "' property to '" + v.getValue() + "'");
                    getProject().setProperty(property, v.getValue());
                    return;
                }
            }
        }

        throw new BuildException("Could not find '" + name + "' variable.");
    }

}
