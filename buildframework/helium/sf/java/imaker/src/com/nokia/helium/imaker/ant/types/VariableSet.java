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
 
package com.nokia.helium.imaker.ant.types;
import org.apache.tools.ant.types.DataType;

import java.util.Hashtable;
import java.util.Map;
import java.util.Vector;

/**
 * This type is a container for variable configuration.
 * 
 * <pre>
 * &lt;variableset&gt;
 *     &lt;variable name="TYPE" value="rnd" /&gt;
 * &lt;/variableset&gt;
 * </pre>
 * 
 * @ant.type name="variableset" category="imaker"
 */
public class VariableSet extends DataType {
    
    private Vector<Variable> variables = new Vector<Variable>();
    
    /**
     * Creates a Variable object.
     * @return a Variable object.
     */
    public Variable createVariable() {
        Variable var =  new Variable();
        add(var);
        return var;
    }
    
    /**
     * Support the addition of a Variable object.
     * @param a Variable object.
     */
    public void add(Variable var) {
        variables.add(var);
    }
    
    /**
     * Get the list of Variable object.
     * @return a vector of Variable objects
     */
    public Vector<Variable> getVariables() {
        return variables;
    }
    
    /**
     * Convert the set of variable to a Map object.
     * @return the content of that set into a Map object.
     */
    public Map<String, String> toMap() {
        Map<String, String> data = new Hashtable<String, String>();
        for (Variable var : variables) {
            var.validate();
            data.put(var.getName(), var.getValue());
        }
        return data;
    }
}
