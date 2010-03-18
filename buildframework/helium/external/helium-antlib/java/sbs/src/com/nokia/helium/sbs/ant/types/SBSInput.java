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
 
package com.nokia.helium.sbs.ant.types;

import com.nokia.helium.core.ant.types.VariableSet;
import com.nokia.helium.core.ant.VariableIFImpl;
import java.util.Collection;
import com.nokia.helium.core.ant.types.Variable;
import org.apache.tools.ant.BuildException;
import java.util.Vector;
import org.apache.tools.ant.types.Reference;
import org.apache.log4j.Logger;

/**
 * Helper class to store the variable set (list of variables
 * with name / value pair)
 *
 *   &lt;hlm:sbsinput id=&quot;export-sbs-ec&quot;&gt;
 *       &lt;sbsoptions refid=&quot;exportSBS&quot; /&gt;
 *       &lt;sbsmakeoptions refid=&quot;exportSBSEC&quot; /&gt;
 *   &lt;/hlm:sbsinput&gt;
 * 
 * @ant.type name="sbsinput" category="SBS"
 */
public class SBSInput extends VariableIFImpl {
    
    private static Logger log = Logger.getLogger(SBSInput.class);
    
    private Vector<VariableSet> sbsOptions = new Vector<VariableSet>();
    private Vector<SBSMakeOptions> sbsMakeOptions = new Vector<SBSMakeOptions>();
    private Vector<SBSInput> sbsInputList = new Vector<SBSInput>();
    
    /**
     * Constructor
     */
    public SBSInput() {
    }    

    /**
     * Creates an empty variable element and adds 
     * it to the variables list
     * @return empty Variable pair
     */
    public VariableSet createSBSOptions() {
        SBSInput sbsInput = new SBSInput();
        VariableSet varSet =  new VariableSet();
        sbsInput.addSBSOptions(varSet);
        sbsInputList.add(sbsInput);
        return varSet;
    }

    /**
     * Adds sbs options to variableset. Called by ant
     * whenever the varSet is added to current sbs options. 
     * @param varSet, variable set to be added to current sbs options.
     */
    public void addSBSOptions(VariableSet varSet) {
        sbsOptions.add(varSet);
    }
    
    /**
     * Creates an empty sbs make options and add it
     * sbs make options list
     * @return empty Variable pair
     */
    public VariableSet createSBSMakeOptions() {
        SBSInput sbsInput = new SBSInput();
        SBSMakeOptions varSet =  new SBSMakeOptions();
        sbsInput.addSBSMakeOptions(varSet);
        sbsInputList.add(sbsInput);
        return varSet;
    }

    /**
     * Adds sbs make options to variableset. Called by ant
     * whenever the make option is added to current sbs options. 
     * @param varSet, variable set to be added to current sbs options.
     */
    public void addSBSMakeOptions(SBSMakeOptions varSet) {
        sbsMakeOptions.add(varSet);
    }

    /**
     * Creates a new sbsinput type for the current, and the created
     * sbs input is only containing refid of sbs options / sbs makeoptions.
     * @return empty sbsinput type.
     */
    public SBSInput createSBSInput() {
        SBSInput sbsInput = new SBSInput();
        sbsInputList.add(sbsInput);
        return sbsInput;
    }

    /**
     * Helper function to provide the sbs options associated with this
     * sbsinput.
     * @return sbs options associated with this sbs input.
     */
    public Vector<VariableSet> getSBSOptions() {
        return sbsOptions;
    }

    /**
     * Helper function to provide the sbs make options associated with this
     * sbsinput.
     * @return sbs make options associated with this sbs input.
     */
    public Vector<SBSMakeOptions> getSBSMakeOptions() {
        return sbsMakeOptions;
    }

    /**
     * Internal function to validate the sbsinput and throw exception
     * if the input is not valid.
     */
    private void validateInput() {
        if (getRefid() != null && (!sbsMakeOptions.isEmpty() || !sbsOptions.isEmpty())) {
            throw new BuildException("SBSInput with refid should not have sbsoptions / sbsmakeoptions");
        }
    }

    /**
     * Internal function to recursively gothrough the sbs options refered by
     * this sbsinput and provides the complete list of variables associated with
     * this input.
     * @return collection of variableset associatied with this sbsinput.
     */
    private Vector<VariableSet> getSBSOptions(SBSInput sbsInput) {
        Vector<VariableSet> fullList = null;
        sbsInput.validateInput();
        Reference refId = sbsInput.getRefid();
        Object sbsInputObject = null;
        if (refId != null) {
            try {
                sbsInputObject = refId.getReferencedObject();
            } catch ( Exception ex) {
                //log.info("Reference id of sbsinput list is not valid");
                throw new BuildException("Reference id (" + refId.getRefId() + ") of sbsinput list is not valid");
            }
            if (sbsInputObject != null && sbsInputObject instanceof SBSInput) {
                VariableSet options = ((SBSInput)sbsInputObject).getFullSBSOptions();
                if (options != null ) {
                    if (fullList == null) {
                        fullList = new Vector<VariableSet>();
                    }
                    fullList.add(options);
                }
            }
        }
        Vector<VariableSet> optionsList = sbsInput.getSBSOptions();
        if (optionsList != null ) {
            if (fullList == null) {
                fullList = new Vector<VariableSet>();
            }
            fullList.addAll(optionsList);
        }
        return fullList;
    }

    /**
     * Internal function to recursively gothrough the sbs make options refered by
     * this sbsinput and provides the complete list of sbs make options associated 
     * with this input.
     * @return collection of sbs make options associatied with this sbsinput.
     */
    private Vector<SBSMakeOptions> getSBSMakeOptions(SBSInput sbsInput) {
        Vector<SBSMakeOptions> sbsMakeOptionsList = null;
        Reference refId = sbsInput.getRefid();
        Object sbsInputObject = null;
        if (refId != null) {
            try {
                sbsInputObject = refId.getReferencedObject();
            } catch ( Exception ex) {
               throw new BuildException("Reference id (" + refId.getRefId() + ") of sbsinput list is not valid");
            }
            if (sbsInputObject != null && sbsInputObject instanceof SBSInput) {
                SBSMakeOptions options = ((SBSInput)sbsInputObject).getFullSBSMakeOptions(); 
                if (options != null ) {
                    if (sbsMakeOptionsList == null) {
                        sbsMakeOptionsList = new Vector<SBSMakeOptions>();
                    }
                    sbsMakeOptionsList.add(options);
                }
            }
        }
        Vector<SBSMakeOptions> options = sbsInput.getSBSMakeOptions();
        if (options != null) {
            if (sbsMakeOptionsList == null) {
                sbsMakeOptionsList = new Vector<SBSMakeOptions>();
            }
            sbsMakeOptionsList.addAll(options);
        }
        return sbsMakeOptionsList;
    }

    /**
     * Internal function to recursively gothrough the sbs make options refered by
     * this sbsinput and provides the complete list of sbs make options associated 
     * with this input.
     * @return collection of sbs make options associatied with this sbsinput.
     */
    public VariableSet getFullSBSOptions() {
        Vector<VariableSet> fullList = null;
        VariableSet resultSet = null;
        Vector<VariableSet> currentOptions = getSBSOptions(this);
        if (currentOptions != null && !currentOptions.isEmpty()) {
            if (fullList == null ) {
                fullList = new Vector<VariableSet>();
            }
            fullList.addAll(currentOptions);
        }
        for (SBSInput sbsInput : sbsInputList) {
            Vector<VariableSet> options = getSBSOptions(sbsInput);
            if (options != null && !options.isEmpty()) {
                if (fullList == null ) {
                    fullList = new Vector<VariableSet>();
                }
                fullList.addAll(options);
            }
        }
        if (fullList != null) {
            for (VariableSet varSet : fullList) {
                for (Variable var : varSet.getVariables()) {
                    if (resultSet == null) {
                        resultSet = new VariableSet();
                    }
                    resultSet.add(var);
                }
            }
        }
        return resultSet;
    }

    /**
     * Internal function to recursively gothrough the sbs make options refered by
     * this sbsinput and provides the complete list of sbs make options associated 
     * with this input.
     * @return collection of sbs make options associatied with this sbsinput.
     */
    public SBSMakeOptions getFullSBSMakeOptions() {
        Vector<SBSMakeOptions> sbsMakeOptionsList = null;
        SBSMakeOptions resultSet = null;
        Vector<SBSMakeOptions> currentOptions = getSBSMakeOptions(this);
        if (currentOptions != null && !currentOptions.isEmpty()) {
            if (sbsMakeOptionsList == null ) {
                sbsMakeOptionsList = new Vector<SBSMakeOptions>();
            }
            sbsMakeOptionsList.addAll(currentOptions);
        }
        for (SBSInput sbsInput : sbsInputList) {
            Vector<SBSMakeOptions> options = getSBSMakeOptions(sbsInput);
            if (options != null && !options.isEmpty()) {
                if (sbsMakeOptionsList == null ) {
                    sbsMakeOptionsList = new Vector<SBSMakeOptions>();
                }
                sbsMakeOptionsList.addAll(options);
            }
        }
        if (sbsMakeOptionsList != null ) {
            String engine = null;
            String ppThreads = null;
            for (SBSMakeOptions varSet : sbsMakeOptionsList) {
                String currentEngine = varSet.getEngine();
                String currentThread = varSet.getPPThreads();
                if (currentEngine != null) {
                    if (engine == null) {
                        engine = currentEngine;
                        if (resultSet == null ) {
                            resultSet = new SBSMakeOptions();
                        }
                        resultSet.setEngine(currentEngine);
                    } else {
                        if (!engine.equals(currentEngine) ) {
                            throw new BuildException("inheriting engine types mismatch: " + engine + " != " + currentEngine);
                        }
                    }
                }
                if (resultSet == null ) {
                    resultSet = new SBSMakeOptions();
                }
                if (ppThreads == null && currentThread != null) {
                    ppThreads = currentThread;
                    resultSet.setPPThreads(ppThreads);
                }
                for (Variable var : varSet.getVariables()) {
                    resultSet.add(var);
                }
            }
        }
        return resultSet;
    }
    
    /**
     * Helper function to return the collection of variabes associated with this
     * @return collection of sbs options associatied with this sbsinput.
     */
    public Collection<Variable> getVariables() {
        Collection<Variable> varList = null;
        VariableSet  options = getFullSBSOptions();
        if (options != null) {
            varList = options.getVariables();
        }
        return varList;
    }
}