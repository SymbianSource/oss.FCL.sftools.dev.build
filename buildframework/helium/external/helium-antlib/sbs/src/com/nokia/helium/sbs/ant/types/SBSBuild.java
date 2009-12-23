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

import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.BuildException;
import java.util.Vector;
import java.util.List;
import java.util.ArrayList;
import org.apache.tools.ant.types.Reference;
import org.apache.log4j.Logger;


/**
 * Helper class to store the command line variables
 * with name / value pair.
 * @ant.type name="arg"
 * @ant.type name="makeOption"
 */
public class SBSBuild extends DataType
{
    private static Logger log = Logger.getLogger(SBSBuild.class);

    private String name;

    private Vector<SBSInput> sbsInputList = new Vector<SBSInput>();


    public SBSBuild() {
    }
    
    /**
     * Set the name of the variable.
     * @param name
     */
    public void setName(String nm) {
        name = nm;
    }

    /**
     * Gets the name of the build input.
     * @param name
     */
    public String getName() {
        return name;
    }
    
    /**
     * Creates an empty variable element and adds 
     * it to the variables list
     * @return empty Variable pair
     */
    public SBSInput createSBSInput() {
        SBSInput input =  new SBSInput();
        sbsInputList.add(input);
        return input;
    }
    
    public List<SBSInput> getSBSInputList() {
        List<SBSInput> inputList = new ArrayList<SBSInput>();
        Reference refId = getRefid();
        Object sbsInputObject = null;
        if (refId != null) {
            try {
                sbsInputObject = refId.getReferencedObject();
            } catch ( Exception ex) {
                //log.info("Reference id of sbsinput list is not valid");
                throw new BuildException("Reference id (" + refId.getRefId() + ") of sbsinput list is not valid");
            }
            if (sbsInputObject != null && sbsInputObject instanceof SBSInput) {
                inputList.add((SBSInput)sbsInputObject);
            }
        }
        inputList.addAll(sbsInputList);
        return inputList;
    }
}
