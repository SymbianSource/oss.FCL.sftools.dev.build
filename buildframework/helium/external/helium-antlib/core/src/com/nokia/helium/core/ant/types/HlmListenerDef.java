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
import org.apache.log4j.Logger;

/**
 * This class implements a listener registration action.
 * 
 * @ant.type name="listenerdef" category="Core"
 */
public class HlmListenerDef extends HlmPreDefImpl {

    private String classname;
    private Logger log = Logger.getLogger(HlmListenerDef.class);

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
            log.debug("Class not found exception:" + ex.getMessage(), ex);
        } catch (InstantiationException ex1) {
            log.debug("Class Instantiation exception:" + ex1.getMessage(), ex1);
        } catch (IllegalAccessException ex1) {
            log.debug("Illegal Class Access exception:" + ex1.getMessage(), ex1);
        }
    }
}