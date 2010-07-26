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
 
package com.nokia.helium.ccmtask.ant.taskdefs;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.Vector;
import java.util.jar.JarFile;
import java.util.zip.ZipEntry;

import org.python.util.PythonInterpreter;

import com.nokia.helium.ccmtask.ant.commands.AddTask;
import com.nokia.helium.ccmtask.ant.commands.CcmCommand;
import com.nokia.helium.ccmtask.ant.commands.ChangeReleaseTag;
import com.nokia.helium.ccmtask.ant.commands.Checkout;
import com.nokia.helium.ccmtask.ant.commands.Close;
import com.nokia.helium.ccmtask.ant.commands.Reconcile;
import com.nokia.helium.ccmtask.ant.commands.Role;
import com.nokia.helium.ccmtask.ant.commands.Snapshot;
import com.nokia.helium.ccmtask.ant.commands.Synchronize;
import com.nokia.helium.ccmtask.ant.commands.Update;
import com.nokia.helium.ccmtask.ant.commands.Workarea;
import com.nokia.helium.ccmtask.ant.types.SessionSet;
import com.nokia.helium.ccmtask.ant.commands.CreateReleaseTag;
import com.nokia.helium.ccmtask.ant.commands.DeleteReleaseTag;
import org.apache.tools.ant.BuildException;
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

    private List<CcmCommand> commands = new ArrayList<CcmCommand>();
    private Vector<SessionSet> sessionSets = new Vector<SessionSet>();
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
        return commands.toArray(new CcmCommand[commands.size()]);
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

    public void addCreateReleaseTag(CreateReleaseTag a)
    {
        addCommand(a);
    }

    public void addDeleteReleaseTag(DeleteReleaseTag a)
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

    public void addRole(Role a)
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

    public Role createRole()
    {
        Role cmd = new Role();
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
        File jar = getJarFile();
        if (jar == null) {
            throw new BuildException("Could not find the jar file for class " + this.getClass().getCanonicalName());
        }
        try {
            JarFile jarFile = new JarFile(jar);
            String entryName = this.getClass().getPackage().getName().replace('.', '/') + "/ccmtask.py";
            ZipEntry entry = jarFile.getEntry(entryName);
            if (entry == null) {
                throw new BuildException("CcmTask internal error: Could not find the following entry: " + entryName);
            }
            PythonInterpreter pi = new PythonInterpreter();
            pi.set("java_ccmtask", this);
            pi.set("project", getProject());
            pi.execfile(jarFile.getInputStream(entry), "ccmtask.py");
        } catch (IOException e) {
            throw new BuildException(e.getMessage(), e);
        }
    }
    
    /**
     * Returns the jar file name containing this class
     * @return a File object or null if not found.
     * @throws IMakerException
     */
    protected File getJarFile() {
        URL url = this.getClass().getClassLoader().getResource(this.getClass().getName().replace('.', '/') + ".class");
        if (url.getProtocol().equals("jar") && url.getPath().contains("!/")) {
            String fileUrl = url.getPath().split("!/")[0];
            try {
                return new File(new URL(fileUrl).getPath());
            } catch (MalformedURLException e) {
                throw new BuildException("Error determining the jar file where "
                        + this.getClass().getName() + " is located.", e);
            }
        }
        return null;
    }
}
