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


package com.nokia.helium.core.ant.taskdefs;

import org.apache.tools.ant.taskdefs.Ant;
import org.apache.tools.ant.taskdefs.CallTarget;

/**
 * This task extends current AntCall task by
 * supporting any kind of Reference object.
 * 
 * @ant.task name="antcall" category="Core"
 */
public class AntCall extends CallTarget {

    /**
     * Add a Reference object.
     * @param ref the reference object.
     */
    public void add(Ant.Reference ref) {
        this.addReference(ref);
    }

}
