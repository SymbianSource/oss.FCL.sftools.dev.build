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
import org.apache.tools.ant.types.PatternSet;
import java.util.Vector;

/**
 * This object represent a iMaker configuration.
 * @ant.type name="imakerconfiguration" category="Imaker"
 */
public class Configuration extends DataType {
    
    private Vector makefiles = new Vector();
    private Vector targets = new Vector();
    private Vector variables = new Vector();
    private boolean regionalVariation;
    
    public Configuration() {
    }    

    /**
     * Create a makefileset element.
     * Makefileset elements are based on regular Ant PatternSet.
     * @return a PatternSet object.
     */
    public PatternSet createMakefileSet() {
        PatternSet makefile =  new PatternSet();
        makefiles.add(makefile);
        return makefile;
    }
    
    /**
     * Get the list of makefileset element.
     * @return a vector of PatternSet objects.
     */
    public Vector getMakefileSet() {
        return makefiles;
    }
    
    /**
     * Create a targetset element.
     * Targetset elements are based on regular Ant PatternSet.
     * @return a PatternSet object.
     */
    public PatternSet createTargetSet() {
        PatternSet target =  new PatternSet();
        targets.add(target);
        return target;
    }
    
    /**
     * Get the list of targetset.
     * @return a vector of PatternSet objects.
     */
    public Vector getTargetSet() {
        return targets;
    }

    /**
     * Create a VariableSet element.
     * @return a VariableSet object.
     */
    public VariableSet createVariableSet() {
        VariableSet var =  new VariableSet();
        variables.add(var);
        return var;
    }
        
    /**
     * Get the list of variableset.
     * @return a vector of VariableSet objects.
     */
    public Vector getVariableSet() {
        return variables;
    }

    public void setRegionalVariation(boolean value) {
        regionalVariation = value;
    }

    public boolean getRegionalVariation() {
        return regionalVariation;
    }
    
}
