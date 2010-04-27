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
 
package com.nokia.helium.internaldata.ant.taskdefs;

import org.apache.tools.ant.Task;
import org.apache.tools.ant.BuildException;
import com.nokia.helium.internaldata.*;
import com.nokia.helium.internaldata.ant.listener.Listener;

import javax.naming.*;
import javax.naming.directory.*;

/**
 * Task to identify failing assert.
 *
 * Usage: &lt;hlm:hlmassertmessage assertName="hlm:assertPropertySet" message="Warning: @{message}"/&gt;
 */

public class HlmAssertMessage extends Task {
    
    private String message;
    private String assertName;
        
    public void execute() {
        
        if (assertName == null)
            throw new BuildException("'assertName' attribute is not defined");
        if (message == null)
            throw new BuildException("'message' attribute is not defined");
        
        for (int i = 0 ; i < getProject().getBuildListeners().size() ; i++) {
            if (getProject().getBuildListeners().get(i) instanceof Listener) {
                Listener listen = (Listener)getProject().getBuildListeners().get(i);
                listen.addAssertTask(this);
                break;
            }
        }
    }
    /**
     * Returns assert name.
     * @return
     */
    public String getAssertName() 
    {
        return assertName;
    }
    /**
     * Set the assertname.
     * @param assertName
     */
    public void setAssertName(String assertName) 
    {
        this.assertName = assertName;
    }
    /**
     * Return the assert message.
     * @return
     */
    public String getMessage() 
    {
        return message;
    }
    /**
     * Set the assert message.
     * @param message
     */
    public void setMessage(String message) 
    {
        this.message = message;
    }
    
}
