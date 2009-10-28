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
import org.apache.tools.ant.BuildListener;

/**
 * This class implements a listener registration action.
 * 
 * @ant.type name="listenerdef" category="Core"
 */
public class HlmListenerDef extends HlmPreDefImpl {

    private String classname;

    public void setClassname(String classname) {
        this.classname = classname;
    }

    /**
     * Register given listener to the project.
     */
    public void execute(Project prj, String module, String[] targetNames) {
        try {
            Class<?> listenerClass = Class.forName(classname);
            BuildListener listener = (BuildListener) listenerClass
                    .newInstance();
            prj.addBuildListener(listener);
        } catch (ClassNotFoundException ex) {
            ex.printStackTrace();
        } catch (InstantiationException ex1) {
            ex1.printStackTrace();
        } catch (IllegalAccessException ex1) {
            ex1.printStackTrace();
        }
    }
}