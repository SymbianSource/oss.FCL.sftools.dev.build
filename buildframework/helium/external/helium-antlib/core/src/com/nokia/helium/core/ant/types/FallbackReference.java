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

import org.apache.tools.ant.Project;
import org.apache.tools.ant.taskdefs.Ant;

/**
 * This DataType implements a reference fallback.
 * If refid is not defined then the implementation,
 * can fallback on a defaultRefid.  
 *
 * @ant.type name="fallbackReference" category="Core"
 */
public class FallbackReference extends Ant.Reference {

    private String defaultRefid;

    /**
     * Set the refid if it is defined, else it uses the defaultRefid
     * @param id
     */
    public void setRefid(String id) {
        getProject().log("Setting reference:  " + id, Project.MSG_DEBUG);
        super.setRefId(id);
        if (getProject().getReference(super.getRefId()) == null
                && defaultRefid != null) {
            super.setRefId(defaultRefid);
        }
    }

    /**
     * Set the default refid if it refid doesn't exists then
     * it configures the reference to use the defaultRefid. 
     * @param id
     */
    public void setDefaultRefid(String defaultRefid) {
        getProject().log("Setting default reference: " + defaultRefid,
                Project.MSG_DEBUG);
        this.defaultRefid = defaultRefid;
        if (getProject().getReference(super.getRefId()) == null) {
            getProject().log(
                    "Reference not defined using default reference: "
                            + defaultRefid, Project.MSG_DEBUG);
            setRefId(defaultRefid);
        }
    }

}
