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
 
package com.nokia.ant.taskdefs;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

//import jep.Jep;
//import jep.JepException;
import org.python.util.PythonInterpreter;

import com.nokia.ant.taskdefs.ccm.commands.*;
import com.nokia.ant.types.ccm.SessionSet;

//import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;

/**
 * Synergy task.
 * <pre>
 * &lt;hlm:createSessionMacro database="to1tobet" reference="test.session" /&gt;
 * &lt;hlm:ccm verbose="false"&gt;
 *     &lt;hlm:sessionset refid="test.session" /&gt;
 *     &lt;hlm:addtask folder="tr1test1#2079"&gt;
 *         &lt;task name="tr1test1#5310" /&gt;
 *     &lt;/hlm:addtask&gt;
 *     &lt;hlm:snapshot project="helium-to1tobet#helium_3.0:project:vc1s60p1#1" dir="c:\test" fast="true" recursive="true" /&gt;
 *     &lt;hlm:synchronize project="helium-to1tobet#helium_3.0:project:vc1s60p1#1" recursive="true" /&gt;
 *     &lt;hlm:close /&gt;
 * &lt;/hlm:ccm&gt;
 * </pre>
 * @ant.task category="SCM"
 */
public class CcmTask extends Task
{
    private String username;

    private String password;

    private List commands = new ArrayList();
    private Vector sessionSets = new Vector();
    private boolean verbose;

    public void setVerbose(boolean value) {
        verbose = value;
    }
    
    public boolean getVerbose() {
        return verbose;
    }

    public String getUsername()
    {
        return username;
    }

    public final void setUsername(final String username)
    {
        this.username = username;
    }

    public String getPassword()
    {
        return password;
    }

    public final void setPassword(final String password)
    {
        this.password = password;
    }

    public CcmCommand[] getCommands()
    {
        return (CcmCommand[]) commands.toArray(new CcmCommand[0]);
    }

    public void addUpdate(Update a)
    {
        addCommand(a);
    }
    
    public void addSynchronize(Synchronize a)
    {
        addCommand(a);
    }
    
    public void addReconcile(Reconcile a)
    {
        addCommand(a);
    }
    
    public void addSnapshot(Snapshot a)
    {
        addCommand(a);
    }
    
    public void addChangeReleaseTag(ChangeReleaseTag a)
    {
        addCommand(a);
    }

    public void addCheckout(Checkout a)
    {
        addCommand(a);
    }

    public void addWorkarea(Workarea a)
    {
        addCommand(a);
    }

    private void addCommand(CcmCommand cmd)
    {
        cmd.setTask(this);
        commands.add(cmd);
    }

    public AddTask createAddTask()
    {
        AddTask cmd = new AddTask();
        addCommand(cmd);
        return cmd;
    }

    public Close createClose()
    {
        Close cmd = new Close();
        addCommand(cmd);
        return cmd;
    }

    public SessionSet createSessionSet()
    {
        SessionSet sessionSet = new SessionSet();
        sessionSets.add(sessionSet);
        return sessionSet;
    }
    
    public SessionSet[] getSessionSets() {
        SessionSet[] result = new SessionSet[sessionSets.size()];
        sessionSets.copyInto(result);
        return result; 
    }

    public final void execute()
    {
        String ccmtaskScript = getProject().getProperty("ccmtask.python.script.file");
        PythonInterpreter pi = new PythonInterpreter();
        pi.set("java_ccmtask", this);
        pi.set("project", getProject());
        pi.execfile(ccmtaskScript);
        
//        try
//        {
//            String ccmtaskScript = getProject().getProperty("ccmtask.python.script.file");
//            Jep jep = new Jep(false, ccmtaskScript);
//            jep.set("java_ccmtask", this);
//            jep.set("project", getProject());
//            jep.runScript(ccmtaskScript);
//            jep.close();
//        }
//        catch (JepException e)
//        {
//            // TODO Auto-generated catch block
//            e.printStackTrace();
//            throw new BuildException(e.getMessage());
//        }
    }
}
