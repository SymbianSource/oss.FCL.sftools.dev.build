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
package com.nokia.helium.signal.ant.types;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.signal.ant.Notifier;

/**
 * The signalExceptionConfig type will allow you to configure post-build
 * operation based on its failure. The configured notifier will only be 
 * activated if any exception are terminating the build.
 * 
 *  * E.g:
 * <pre>
 * &lt;hlm:signalExceptionConfig id="some.ref.id"&gt;
        &lt;hlm:executeTaskNotifier&gt;
            &lt;echo&gt;Signal: ${signal.name}&lt;/echo&gt;
        &lt;/hlm:executeTaskNotifier&gt;    
 * &lt;/hlm:signalListenerConfig&gt;
 * </pre>
 *
 * @ant.type name="signalExceptionConfig" category="Signaling"
 */
public class SignalExceptionConfig extends DataType {
    public static final String BUILD_FAILED_SIGNAL_NAME = "buildFailedSignal";
    private List<SignalNotifierList> notifierLists = new ArrayList<SignalNotifierList>();
   
    /**
     * Add a nested notifier.
     * @param notifier
     */
    public void add(SignalNotifierList notifier) {
        notifierLists.add(notifier);
    }
    
    /**
     * Call all nested notifier.
     * @param project
     * @param exception
     */
    public void notify(Project project, Exception exception) {
        for (SignalNotifierList notifierList : notifierLists) {
            if (notifierList.isReference()) {
                notifierList = (SignalNotifierList)notifierList.getRefid().getReferencedObject();
            }
            for (Notifier notifier : notifierList.getNotifierList()) {
                try {
                    notifier.sendData(BUILD_FAILED_SIGNAL_NAME, true, null, exception.getMessage());
                } catch (BuildException exc) {
                    // Print exception with different logging level
                    this.log("[" + this.getDataTypeName() + "] ERROR: " + exc.getMessage(), Project.MSG_ERR);
                    StringWriter stackTrace = new StringWriter();
                    PrintWriter writer = new PrintWriter(stackTrace);
                    exc.printStackTrace(writer);
                    this.log("[" + this.getDataTypeName() + "] " +  stackTrace.getBuffer().toString(), Project.MSG_DEBUG);
                }
            }
        }
    }
    
}
