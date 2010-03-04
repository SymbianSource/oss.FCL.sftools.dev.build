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

import java.util.Hashtable;
import org.apache.tools.ant.BuildEvent;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.SubBuildListener;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.EnumeratedAttribute;
import org.apache.tools.ant.types.LogLevel;

import java.lang.reflect.Constructor;
import java.io.File;

/**
 * Adds a listener to the current build process that records the output to a
 * file.
 * <p>
 * Several recorders can exist at the same time. Each recorder is associated
 * with a file. The filename is used as a unique identifier for the recorders.
 * The first call to the recorder task with an unused filename will create a
 * recorder (using the parameters provided) and add it to the listeners of the
 * build. All subsequent calls to the recorder task using this filename will
 * modify that recorders state (recording or not) or other properties (like
 * logging level).
 * </p>
 * <p>
 * Some technical issues: the file's print stream is flushed for
 * &quot;finished&quot; events (buildFinished, targetFinished and taskFinished),
 * and is closed on a buildFinished event.
 * </p>
 *
 * @ant.task name="record" category="Utility"
 * @Deprecated Start using hlm:record task. 
 * @see LogRecorderEntry
 * @version 0.5
 * @since Ant 1.4
 */
@Deprecated
public class LogRecorderTask extends Task implements SubBuildListener
{

    // ////////////////////////////////////////////////////////////////////
    // ATTRIBUTES
    
    /** The list of recorder entries. */
    private static Hashtable recorderEntries = new Hashtable();

    /** The name of the file to record to. */
    private String filename;

    private String loggerclass = "nokia.ant.taskdefs.TextLogRecorderEntry";

    private String filterset;

    /**
     * Whether or not to append. Need Boolean to record an unset state (null).
     */
    private boolean append;
    
    /**
     * Whether or not to backup the old log (if exists). 
     */
    private boolean backup;

    /**
     * Whether to start or stop recording. Need Boolean to record an unset state
     * (null).
     */
    private boolean start;
    
    private int loglevel = -1;
    /** Strip task banners if true.  */
    private boolean emacsMode;

    private String regexp;

    // ////////////////////////////////////////////////////////////////////
    // CONSTRUCTORS / INITIALIZERS

    /**
     * Overridden so we can add the task as build listener.
     * 
     * @since Ant 1.7
     */
    public void init()
    {   
        log("Deprecated Start using hlm:record task", Project.MSG_WARN); 
        getProject().addBuildListener(this);
    }

    // ////////////////////////////////////////////////////////////////////
    // ACCESSOR METHODS

    /**
     * Sets the name of the file to log to, and the name of the recorder entry.
     * 
     * @param fname
     *            File name of logfile.
     */
    public void setName(String fname)
    {
        filename = fname;
    }

    public void setClass(String name)
    {
        loggerclass = name;
    }

    /**
     * Sets the action for the associated recorder entry.
     * 
     * @param action
     *            The action for the entry to take: start or stop.
     */
    public void setAction(ActionChoices action)
    {
        if (action.getValue().equalsIgnoreCase("start"))
        {
            start = true;
        }
        else
        {
            start = false;
        }
    }

    /**
     * Whether or not the logger should append to a previous file.
     * 
     * @param append
     *            if true, append to a previous file.
     */
    public void setAppend(boolean append)
    {
        this.append = append;
    }
    
    
    
    /**
     * Whether or not the logger should backup the previous file.
     * 
     * @param backup
     *            if true, backup the exising file.
     */
    public void setBackup(boolean backup)
    {
        this.backup = backup;
    }
    
    
    
    /**
     * Set emacs mode.
     * @param emacsMode if true use emacs mode
     */
    public void setEmacsMode(boolean emacsMode) {
        this.emacsMode = emacsMode;
    }


    /**
     * Sets the level to which this recorder entry should log to.
     * @param level the level to set.
     * @see VerbosityLevelChoices
     */
    public void setLoglevel(VerbosityLevelChoices level) {
        loglevel = level.getLevel();
    }

    /**
     * Sets filterset
     * 
     * @param filterset
     */
    public void setFilterSet(String filterset)
    {
        this.filterset = filterset;
    }

    public void setRegexp(String regexp)
    {
        this.regexp = regexp;
    }

    // ////////////////////////////////////////////////////////////////////
    // CORE / MAIN BODY

    /**
     * The main execution.
     * 
     * @throws BuildException
     *             on error
     */
    public void execute()
    {
        if (filename == null)
        {
            throw new BuildException("No filename specified");
        }
        
        //Backup the old log file        
        if (backup)
        {            
            long timestamp = System.currentTimeMillis();                         
            File oldFile = new File(filename); 
            if (oldFile.exists()) {
                oldFile.renameTo(new File(filename + "." + timestamp));
                getProject().setProperty("backup.file.name", filename + "." + timestamp);
            }    
            
        }
        
        
        getProject().log("setting a recorder for name " + filename, Project.MSG_DEBUG);

        // get the recorder entry
        LogRecorderEntry recorder = getRecorder(filename, getProject());
        recorder.setMessageOutputLevel(loglevel);
        recorder.setEmacsMode(emacsMode);
        if (regexp != null && regexp.trim().length() > 0)
        {
            recorder.setRegexp(regexp);
        }
        // if (filterset != null)
        // {
        // Object o = getProject().getReference(filterset);
        // if (o != null && o instanceof LogFilterSet)
        // {
        // recorder.setFilterSet((LogFilterSet) o);
        // }
        // }

        // set the values on the recorder
        if (start)
        {
            recorder.reopenFile();
            recorder.setRecordState(true);
        }
        else
        {
            recorder.setRecordState(false);
            recorder.closeFile();
        }
    }

    /**
    * INNER CLASSES
    */
    public static class VerbosityLevelChoices extends LogLevel {
    }

    /**
     * A list of possible values for the <code>setAction()</code> method.
     * Possible values include: start and stop.
     */
    public static class ActionChoices extends EnumeratedAttribute
    {
        private static final String[] VALUES =
        { "start", "stop" };

        /**
         * @see EnumeratedAttribute#getValues()
         */
        public String[] getValues()
        {
            return VALUES;
        }
    }

    /**
     * Gets the recorder that's associated with the passed in name. If the
     * recorder doesn't exist, then a new one is created.
     * 
     * @param name
     *            the name of the recoder
     * @param proj
     *            the current project
     * @return a recorder
     * @throws BuildException
     *             on error
     */
    protected LogRecorderEntry getRecorder(String name, Project proj)
    {
        Object o = recorderEntries.get(name);
        LogRecorderEntry entry;

        if (o == null)
        {
            try
            {
                Class[] parameters = new Class[1];
                parameters[0] = String.class;
                Class centry = Class.forName(loggerclass);
                Constructor c = centry.getConstructor(parameters);
                Object[] params = new Object[1];
                params[0] = filename;
                entry = (LogRecorderEntry) c.newInstance(params);
            }
            catch (Exception e)
            {
                // We are Ignoring the errors as no need to fail the build.
                entry = new TextLogRecorderEntry(name);
            }

            entry.openFile(append);
            entry.setProject(proj);
            recorderEntries.put(name, entry);
        }
        else
        {
            entry = (LogRecorderEntry) o;
        }
        return entry;
    }

    /**
     * Empty implementation required by SubBuildListener interface.
     * 
     * @since Ant 1.7
     */
    public void buildStarted(BuildEvent event)
    {
    }

    /**
     * Empty implementation required by SubBuildListener interface.
     * 
     * @since Ant 1.7
     */
    public void subBuildStarted(BuildEvent event)
    {
    }

    /**
     * Empty implementation required by SubBuildListener interface.
     * 
     * @since Ant 1.7
     */
    public void targetStarted(BuildEvent event)
    {
    }

    /**
     * Empty implementation required by SubBuildListener interface.
     * 
     * @since Ant 1.7
     */
    public void targetFinished(BuildEvent event)
    {
    }

    /**
     * Empty implementation required by SubBuildListener interface.
     * 
     * @since Ant 1.7
     */
    public void taskStarted(BuildEvent event)
    {
    }

    /**
     * Empty implementation required by SubBuildListener interface.
     * 
     * @since Ant 1.7
     */
    public void taskFinished(BuildEvent event)
    {
    }

    /**
     * Empty implementation required by SubBuildListener interface.
     * 
     * @since Ant 1.7
     */
    public void messageLogged(BuildEvent event)
    {
    }

    /**
     * Cleans recorder registry.
     * 
     * @since Ant 1.7
     */
    public void buildFinished(BuildEvent event)
    {
        cleanup();
    }

    /**
     * Cleans recorder registry, if this is the subbuild the task has been
     * created in.
     * 
     * @since Ant 1.7
     */
    public void subBuildFinished(BuildEvent event)
    {
        if (event.getProject() == getProject())
        {
            cleanup();
        }
    }

    /**
     * cleans recorder registry and removes itself from BuildListener list.
     * 
     * @since Ant 1.7
     */
    private void cleanup()
    {
        recorderEntries.clear();
        getProject().removeBuildListener(this);
    }
}
