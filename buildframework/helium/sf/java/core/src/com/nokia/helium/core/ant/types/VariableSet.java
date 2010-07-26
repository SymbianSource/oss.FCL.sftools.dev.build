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
 
package com.nokia.helium.core.ant.types;

import java.util.Collection;
import java.util.HashMap;
import java.util.List;

import com.nokia.helium.core.ant.MappedVariable;
import com.nokia.helium.core.ant.Variable;
import com.nokia.helium.core.ant.VariableMap;


import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;
import java.util.ArrayList;

/**
 * Helper class to store the variable set (list of variables
 * with name / value pair)
 * @ant.type name="argSet" category="Core"
 */
public class VariableSet extends DataType implements Variable, VariableMap {
    
    private List<Variable> variables = new ArrayList<Variable>();

    /**
     * Creates an empty variable element and adds 
     * it to the variables list
     * @return empty Variable pair
     */
    public VariableSet createArgSet() {
        VariableSet variableSet =  new VariableSet();
        variables.add(variableSet);
        return variableSet;
    }

    /**
     * Creates an empty variable element and adds 
     * it to the variables list
     * @return empty Variable pair
     */
    public Variable createArg() {
        Variable variable =  new VariableImpl();
        variables.add(variable);
        return variable;
    }
        
    /**
     * Add a given variable to the list 
     * @param var variable to add
     */
    public void add(Variable variable) {
        variables.add(variable);
    }

    /**
     * Helper function to get the list of variables defined for this set.
     * @return variable list for this set.
     */
    public List<Variable> getVariablesList() {
        return variables;
    }
    
    /**
     * Get the list of nested VariableSet.
     * @return the list of VariableSet.
     */
    public List<VariableSet> getVariableSets() {
        List<VariableSet> variableSets = new ArrayList<VariableSet>();
        for (Variable variable : variables) {
            if (variable instanceof VariableSet) {
                variableSets.add((VariableSet)variable);
            }
        }
        return variableSets;
    }
        
    /**
     * Returns the list of variables available in the VariableSet 
     * @return variable list
     */
    public HashMap<String, MappedVariable> getVariablesMap() {
        if (this.isReference()) {
            Object varSetObject = this.getRefid().getReferencedObject();
            if (varSetObject != null && varSetObject instanceof VariableSet) {
                return ((VariableSet)varSetObject).getVariablesMap();
            } else {
                throw new BuildException("The '" + this.getRefid().getRefId() + "' reference is not referencing a VariableSet");
            }
        } else {
            HashMap<String, MappedVariable> allVariables = new HashMap<String, MappedVariable>();
            for (Variable variable : variables) {
                if (variable instanceof MappedVariable) {
                    allVariables.put(((MappedVariable)variable).getName(), (MappedVariable)variable);
                } else if (variable instanceof VariableSet)
                    allVariables.putAll(((VariableSet)variable).getVariablesMap());
            }
            return allVariables;
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String getParameter() {
        return getParameter("=");
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public String getParameter(String separator) {
        if (this.isReference()) {
            Object varSetObject = this.getRefid().getReferencedObject();
            if (varSetObject != null && varSetObject instanceof VariableSet) {
                return ((VariableSet)varSetObject).getParameter(separator);
            } else {
                throw new BuildException("The '" + this.getRefid().getRefId() + "' reference is not referencing a VariableSet");
            }
        } else {
            String parameter = "";
            for (Variable variable : variables) {
                
                parameter += " " + variable.getParameter(separator);
            }
            return parameter; 
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public Collection<MappedVariable> getVariables() {
        return this.getVariablesMap().values();
    }
    
    
}