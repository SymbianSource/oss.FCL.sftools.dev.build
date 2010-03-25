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

import java.util.Vector;
import java.util.HashMap;
import java.util.List;
import com.nokia.helium.core.ant.VariableIFImpl;
import java.util.Collection;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.Reference;
import java.util.ArrayList;
import org.apache.log4j.Logger;

/**
 * Helper class to store the variable set (list of variables
 * with name / value pair)
 * @ant.type name="argSet" category="Core"
 */
public class VariableSet extends VariableIFImpl {

    private static Logger log = Logger.getLogger(VariableSet.class);
    
    private HashMap<String, Variable> variablesMap = new HashMap<String, Variable>();

    private List<Variable> variables = new ArrayList<Variable> ();

    private Vector<VariableSet> varSets = new Vector<VariableSet>();
    
    private VariableSet currentSet;

    /**
     * Constructor
     */
    public VariableSet() {
    }    

    /**
     * Helper function to add the created varset
     * @param filter to be added to the varset
     */
    public void add(VariableSet varSet) {
        currentSet = null;
        if (varSet != null) {
            varSets.add(varSet);
        }
    }

    /**
     * Creates an empty variable element and adds 
     * it to the variables list
     * @return empty Variable pair
     */
    public VariableSet createArgSet() {
        VariableSet varSet =  new VariableSet();
        add(varSet);
        return varSet;
    }

    /**
     * Creates an empty variable element and adds 
     * it to the variables list
     * @return empty Variable pair
     */
    public Variable createArg() {
        Variable var =  new Variable();
        add(var);
        return var;
    }
    
    private void addVariable(Variable var) {
        variables.add(var);
    }
    
    /**
     * Add a given variable to the list 
     * @param var variable to add
     */
    public void add(Variable var) {
        if ( currentSet == null) {
            currentSet = new VariableSet();
            varSets.add(currentSet);
        }
        currentSet.addVariable(var);
    }

    /**
     * Helper function to get the list of variables defined for this set.
     * @return variable list for this set.
     */
    public List<Variable> getVariablesList() {
        return variables;
    }
    
    public List<VariableSet> getVariableSets() {
        return varSets;
    }


    /**
     * Helper function to return the list of variables and its references
     * @return variable list for this set and its references.
     */
    public Collection<Variable> getVariables() {
        HashMap<String, Variable> varMap =   getVariablesMap();
        //if (varMap.isEmpty()) {
        //    throw new BuildException("Variable should not be empty and should contain one arg");
        //}
        return getVariablesMap().values();
    }
    /**
     * Returns the list of variables available in the VariableSet 
     * @return variable list
     */
    public HashMap<String, Variable> getVariablesMap() {
        HashMap<String, Variable> allVariables = new HashMap<String, Variable>();
        // Then filters as reference in filterset
        Reference refId = getRefid();
        Object varSetObject = null;
        if (refId != null) {
            try {
                varSetObject = refId.getReferencedObject();
            } catch ( Exception ex) {
                log.debug("exception in getting variable", ex);
                throw new BuildException("Not found: " + ex.getMessage());
            }
            if (varSetObject != null && varSetObject instanceof VariableSet) {
                HashMap<String, Variable> varSetMap = ((VariableSet)varSetObject).getVariablesMap();
                allVariables.putAll(varSetMap);
            }
        }
        if (varSets != null && (!varSets.isEmpty())) {
            for (VariableSet varSet : varSets) {
                HashMap<String, Variable> variablesMap = varSet.getVariablesMap();
                allVariables.putAll(variablesMap);
            }
        }
        if (variables != null && !variables.isEmpty()) {
            for (Variable var : variables) {
                allVariables.put(var.getName(), var);
            }
        }
        return allVariables;
    }
}