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
 
package com.nokia.ant.types.imaker;
import org.apache.tools.ant.types.DataType;
import java.util.Vector;

/**
 * This object stores a set of Variable object.
 * @ant.type name="variableset" category="Imaker"
 */
public class VariableSet extends DataType {
    
    private Vector variables = new Vector();
    
    public VariableSet() {
    }    

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
    public Vector getVariables() {
        return variables;
    }
    
}
