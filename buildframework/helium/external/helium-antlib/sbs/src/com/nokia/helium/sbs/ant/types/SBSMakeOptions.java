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
import org.apache.log4j.Logger;
import org.apache.tools.ant.types.Reference;
import org.apache.tools.ant.BuildException;
import java.util.List;

/**
 * Helper class to store the variable set (list of variables
 * with name / value pair)
 * @ant.type name="argSet"
 */
public class  SBSMakeOptions extends VariableSet {

    private static Logger log = Logger.getLogger(SBSMakeOptions.class);

    private String engine;

    private String ppThreads;

    
    private boolean initialized;
    /**
     * Constructor
     */
    public SBSMakeOptions() {
    }    

    /**
     * Helper function called by ant to create the new varset
     */
    public SBSMakeOptions createSBSMakeOptions() {
        SBSMakeOptions options =  new SBSMakeOptions();
        add(options);
        return options;
    }

    /**
     * Helper function to add the created varset
     * @param filter to be added to the varset
     */
    public void add(SBSMakeOptions option) {
        super.add(option);
    }

    /**
     * Sets the engine type for this options 
     * @param engine for which the make options are used
     */
    public void setEngine(String engineName) {
        engine = engineName;
    }

    /**
     * Sets the ppthreads (no. bldinfs to process) 
     * @param ppBlock no. bldinfs to process per block
     */
    public void setPPThreads(String ppBlock) {
        ppThreads = ppBlock;
    }
    
    public String getPPThreads() {
        if (ppThreads == null) {
            if (!initialized) {
                initializeAll();
                initialized = true;
            }
        }
        return ppThreads;
    }

    /**
     * Returns the engine name 
     * @return type of make engine
     */
    public String getEngine() {
        if (engine == null) {
            if (!initialized) {
                initializeAll();
                initialized = true;
            }
            if (engine == null) {
                throw new BuildException("engine should not be null");
            }
        }
        return engine;
    }
    private void initializeAll() {
        Object sbsInputObject = null;
        List<VariableSet> varSets = getVariableSets();
        initialize(this);
        for (VariableSet varSet : varSets) {
            initialize(varSet);
        }
    }
    
    private void initialize(VariableSet varSet) {
        SBSMakeOptions makeOptions = null;
        Reference refId = varSet.getRefid();
        if (refId != null) {
            try {
                makeOptions = (SBSMakeOptions)refId.getReferencedObject();
                if (makeOptions != null) {
                    String refEngine = makeOptions.getEngine();
                    String threads = makeOptions.getPPThreads();
                    if (engine != null && !(engine.equals(refEngine))) {
                        throw new BuildException(" Config's engine type " + engine + " not matching with reference : " 
                                + refId.getRefId() + ": engine: " + refEngine);
                    }
                    if (ppThreads == null && threads != null) {
                        ppThreads = threads;
                    }
                    if (engine == null) {
                        engine = refEngine;
                    }
                }
            } catch ( Exception ex) {
                throw new BuildException(ex.getMessage());
            }
        }
    }
}