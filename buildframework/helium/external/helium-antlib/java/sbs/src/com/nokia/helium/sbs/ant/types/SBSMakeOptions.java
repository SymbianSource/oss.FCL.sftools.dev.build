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
 * with name / value pair) for sbsmakeoptions inheriting from argSet.

 *  * &lt;sbsbuild id=&quot;sbs.dfs_build_ncp&quot;&gt;
 *      &lt;sbsinput refid=&quot;dfs_build_ncp_input&quot;/&gt;
 * &lt;/sbsbuild&gt;

 *   &lt;hlm:sbsmakeoptions id=&quot;commonEMakeOptions&quot; engine=&quot;emake&quot;&gt;
 *       &lt;arg name=&quot;--emake-emulation&quot; value="gmake" /&gt;
 *       &lt;arg name=&quot;--emake-annodetail&quot; value=&quot;basic,history,waiting&quot; /&gt;
 *       &lt;arg name=&quot;--emake-class&quot; value=&quot;${ec.build.class}&quot; /&gt;
 *       &lt;arg name=&quot;--emake-historyfile&quot; value=&quot;${build.log.dir}/ec_history/raptor_clean.emake.data&quot; /&gt;
 *       &lt;arg name=&quot;--case-sensitive&quot; value=&quot;0&quot; /&gt;
 *       &lt;arg name=&quot;--emake-root&quot; value=&quot;${build.drive}/;${env.EMAKE_ROOT};${helium.dir};${env.SBS_HOME}&quot; /&gt;
 *   &lt;/hlm:sbsmakeoptions&gt;
 * 
 * @ant.type name="sbsMakeOptions" category="SBS"
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
     * Helper function called by ant to create the new sbs make options
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

    /**
     * Returns the ppthreads required for parallel parsing support from raptor
     * available from 2.11.2 of raptor for parallel builds. 
     * @return the no. of threads to be used for parallel parsing the makefile.
     */
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

    /**
     * Initializes all the variableset associated with this options. First
     * initializes the current object and then the objects embedded within this
     * input. 
     */
    private void initializeAll() {
        Object sbsInputObject = null;
        List<VariableSet> varSets = getVariableSets();
        initialize(this);
        for (VariableSet varSet : varSets) {
            initialize(varSet);
        }
    }

    /**
     * Initializes individual variable set 
     */
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