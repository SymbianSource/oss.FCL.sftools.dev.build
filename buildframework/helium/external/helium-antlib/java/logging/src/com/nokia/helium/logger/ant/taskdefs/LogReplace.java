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
package com.nokia.helium.logger.ant.taskdefs;

import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

import com.nokia.helium.logger.ant.listener.AntLoggingHandler;
import com.nokia.helium.logger.ant.listener.StatusAndLogListener;

/**
 * To replace the property values with real values if the properties are not set at the begining of the build.
 * 
 * pre>
 *      &lt;hlm:logreplace regexp="${property.not.set}"/&gt;
 * </pre>
 * 
 * @ant.task name="logreplace" category="Logging".
 */
public class LogReplace extends Task {
    
    private String regExp;
    
    /**
     * Run by the task.
     */
    
    public void execute () {
        if (StatusAndLogListener.getStatusAndLogListener() == null) {
            this.log("The StatusAndLogListener is not available.", Project.MSG_WARN);
            return;
        }

        AntLoggingHandler antLoggingHandler  = (AntLoggingHandler)StatusAndLogListener.getStatusAndLogListener().getHandler(AntLoggingHandler.class);
        
        if (regExp == null ) {
            throw new BuildException ("'regexp' attribute should not be null.");
        }
        
        if (antLoggingHandler != null) {
            String pattern = Pattern.quote(regExp);
            antLoggingHandler.addRegExp(pattern);
        }
    }

    /**
     * @param regExp the regExp to set
     * @ant.required
     */
    public void setRegExp(String regExp) {
        this.regExp = regExp;
    }

    /**
     * @return the regExp
     */
    public String getRegExp() {
        return regExp;
    }
    

}
