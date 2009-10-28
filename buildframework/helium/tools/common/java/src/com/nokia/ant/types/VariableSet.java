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
 
package com.nokia.ant.types;

import org.apache.tools.ant.types.DataType;
import java.util.Vector;

/**
 * Helper class to store the variable set (list of variables
 * with name / value pair)
 * @ant.type name="argSet"
 */
public class VariableSet extends DataType {
    
    private Vector variables = new Vector();
    
    /**
     * Constructor
     */
    public VariableSet() {
    }    

    /**
     * Creates an empty variable element and adds 
     * it to the variables list
     * @return empty Variable pair
     */
    public Variable createVariable() {
        Variable var =  new Variable();
        add(var);
        return var;
    }
    
    /**
     * Add a given variable to the list 
     * @param var variable to add
     */
    public void add(Variable var) {
        variables.add(var);
    }
    
    /**
     * Returns the list of variables available in the VariableSet 
     * @return variable list
     */
    public Vector getVariables() {
        return variables;
    }
}
