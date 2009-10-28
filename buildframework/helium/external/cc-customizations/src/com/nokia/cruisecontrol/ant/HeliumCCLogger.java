/* ============================================================================ 
Name        : HeliumBuilder.java
Part of     : Helium 

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.
This component and the accompanying materials are made available
under the terms of the License "Eclipse Public License v1.0"
which accompanies this distribution, and is available
at the URL "http://www.eclipse.org/legal/epl-v10.html".

Initial Contributors:
Nokia Corporation - initial contribution.

Contributors:

Description:

============================================================================ */

package com.nokia.cruisecontrol.ant;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintStream;
import java.io.Writer;
import java.util.Hashtable;
import java.util.Stack;
import java.util.Enumeration;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.apache.tools.ant.util.DOMElementWriter;
import org.apache.tools.ant.util.StringUtils;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Text;
import org.apache.tools.ant.*;

/**
 * Generates a file in the current directory with an XML description of what
 * happened during a build. The default filename is "log.xml", but this can be
 * overridden with the property <code>XmlLogger.file</code>.
 * 
 * This implementation assumes in its sanity checking that only one thread runs
 * a particular target/task at a time. This is enforced by the way that parallel
 * builds and antcalls are done - and indeed all but the simplest of tasks could
 * run into problems if executed in parallel.
 * 
 * @see Project#addBuildListener(BuildListener)
 */
public class HeliumCCLogger implements org.apache.tools.ant.BuildLogger
{
    /** Message priority of &quot;error&quot;. */
    public static final int MSG_ERR = 0;

    /** Message priority of &quot;warning&quot;. */
    public static final int MSG_WARN = 1;

    /** Message priority of &quot;information&quot;. */
    public static final int MSG_INFO = 2;

    /** Message priority of &quot;verbose&quot;. */
    public static final int MSG_VERBOSE = 3;

    /** Message priority of &quot;debug&quot;. */
    public static final int MSG_DEBUG = 4;

    /** DocumentBuilder to use when creating the document to start with. */
    private static DocumentBuilder builder = getDocumentBuilder();

    /** XML element name for a build. */
    private static final String BUILD_TAG = "build";

    /** XML element name for a target. */
    private static final String TARGET_TAG = "target";

    /** XML element name for a task. */
    private static final String TASK_TAG = "task";

    /** XML element name for a message. */
    private static final String MESSAGE_TAG = "message";

    /** XML attribute name for a name. */
    private static final String NAME_ATTR = "name";

    /** XML attribute name for a time. */
    private static final String TIME_ATTR = "time";

    /** XML attribute name for a message priority. */
    private static final String PRIORITY_ATTR = "priority";

    /** XML attribute name for a file location. */
    private static final String LOCATION_ATTR = "location";

    /** XML attribute name for an error description. */
    private static final String ERROR_ATTR = "error";

    /** XML element name for a stack trace. */
    private static final String STACKTRACE_TAG = "stacktrace";

    /** The complete log document for this build. */
    private Document doc = builder.newDocument();

    /** Mapping for when tasks started (Task to TimedElement). */
    private Hashtable tasks = new Hashtable();

    /** Mapping for when targets started (Task to TimedElement). */
    private Hashtable targets = new Hashtable();

    /**
     * Mapping of threads to stacks of elements (Thread to Stack of
     * TimedElement).
     */
    private Hashtable threadStacks = new Hashtable();

    /**
     * When the build started.
     */
    private TimedElement buildElement;

    private int msgOutputLevel = MSG_DEBUG;

    private PrintStream outStream;

 
    /**
     * Returns a default DocumentBuilder instance or throws an
     * ExceptionInInitializerError if it can't be created.
     * 
     * @return a default DocumentBuilder instance.
     */
    private static DocumentBuilder getDocumentBuilder()
    {
        try
        {
            return DocumentBuilderFactory.newInstance().newDocumentBuilder();
        }
        catch (Exception exc)
        {
            throw new ExceptionInInitializerError(exc);
        }
    }


    /** Utility class representing the time an element started. */
    private static class TimedElement
    {
        /**
         * Start time in milliseconds (as returned by
         * <code>System.currentTimeMillis()</code>).
         */
        private long startTime;

        /** Element created at the start time. */
        private Element element;

        public String toString()
        {
            return element.getTagName() + ":" + element.getAttribute("name");
        }
    }


    /**
     * Fired when the build starts, this builds the top-level element for the
     * document and remembers the time of the start of the build.
     * 
     * @param event
     *            Ignored.
     */
    public void buildStarted(BuildEvent event)
    {
    }

    /**
     * Fired when the build finishes, this adds the time taken and any error
     * stacktrace to the build element and writes the document to disk.
     * 
     * @param event
     *            An event with any relevant extra information. Will not be
     *            <code>null</code>.
     */
    public void buildFinished(BuildEvent event)
    {
        long totalTime = System.currentTimeMillis() - buildElement.startTime;
        // buildElement.element.setAttribute(TIME_ATTR,
        // DefaultLogger.formatTime(totalTime));

        System.out.println("Build finished in cruise control HeliumCCLogger");

        if (event.getException() != null)
        {
            System.out.println("Build finished exception occured in cruise control HeliumCCLogger");
            System.out.println("Build finished exception is:-----"
                    + event.getException().toString());
            buildElement.element.setAttribute(ERROR_ATTR, event.getException().toString());
            // print the stacktrace in the build file it is always useful...
            // better have too much info than not enough.
            Throwable t = event.getException();
            Text errText = doc.createCDATASection(StringUtils.getStackTrace(t));
            Element stacktrace = doc.createElement(STACKTRACE_TAG);
            stacktrace.appendChild(errText);
            buildElement.element.appendChild(stacktrace);
        }
        String outFilename = event.getProject().getProperty("HeliumCCLogger.file");
        System.out.println("Build finished writing to log file1" + outFilename);
        if (outFilename == null)
        {
            outFilename = "log.xml";
        }
        System.out.println("Build finished writing to log file2");
        String xslUri = event.getProject().getProperty("ant.HeliumCCLogger.stylesheet.uri");
        if (xslUri == null)
        {
            xslUri = "log.xsl";
        }
        System.out.println("Build finished writing to log file3");
        Writer out = null;
        try
        {
            // specify output in UTF8 otherwise accented characters will blow
            // up everything
            System.out.println("Build finished writing to log file3");

            OutputStream stream = outStream;
            if (stream == null)
            {
                stream = new FileOutputStream(outFilename);
            }
            out = new OutputStreamWriter(stream, "UTF8");
            System.out.println("Build finished writing to log file4");

            out.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
            if (xslUri.length() > 0)
            {
                out.write("<?xml-stylesheet type=\"text/xsl\" href=\"" + xslUri + "\"?>\n\n");
            }
            System.out.println("Build finished writing to log file5");
            (new DOMElementWriter()).write(buildElement.element, out, 0, "\t");
            out.flush();
        }
        catch (IOException exc)
        {
            System.out.println("Build finished writing to log file6");
            throw new BuildException("Unable to write log file", exc);
        }
        finally
        {
            System.out.println("Build finished writing to log file7");

            if (out != null)
            {
                try
                {
                    out.close();
                }
                catch (IOException e)
                {
                    // ignore
                    e = null;
                }
            }
        }
        buildElement = null;
    }

    /**
     * Returns the stack of timed elements for the current thread.
     * 
     * @return the stack of timed elements for the current thread
     */
    private Stack getStack()
    {
        Stack threadStack = (Stack) threadStacks.get(Thread.currentThread());
        if (threadStack == null)
        {
            threadStack = new Stack();
            threadStacks.put(Thread.currentThread(), threadStack);
        }
        /*
         * For debugging purposes uncomment: org.w3c.dom.Comment s =
         * doc.createComment("stack=" + threadStack);
         * buildElement.element.appendChild(s);
         */
        return threadStack;
    }

    /**
     * Fired when a target starts building, this pushes a timed element for the
     * target onto the stack of elements for the current thread, remembering the
     * current time and the name of the target.
     * 
     * @param event
     *            An event with any relevant extra information. Will not be
     *            <code>null</code>.
     */
    public void targetStarted(BuildEvent event)
    {
        System.out.println("target started in cruise control HeliumCCLogger");
        Target target = event.getTarget();
        TimedElement targetElement = new TimedElement();
        targetElement.startTime = System.currentTimeMillis();
        targetElement.element = doc.createElement(TARGET_TAG);
        targetElement.element.setAttribute(NAME_ATTR, target.getName());
        targets.put(target, targetElement);
        getStack().push(targetElement);
    }

    /**
     * Fired when a target finishes building, this adds the time taken and any
     * error stacktrace to the appropriate target element in the log.
     * 
     * @param event
     *            An event with any relevant extra information. Will not be
     *            <code>null</code>.
     */
    public void targetFinished(BuildEvent event)
    {
        System.out.println("target finished in cruise control HeliumCCLogger");
        Target target = event.getTarget();
        TimedElement targetElement = (TimedElement) targets.get(target);
        if (targetElement != null)
        {
            long totalTime = System.currentTimeMillis() - targetElement.startTime;
            // targetElement.element.setAttribute(TIME_ATTR,
            // DefaultLogger.formatTime(totalTime));

            TimedElement parentElement = null;
            Stack threadStack = getStack();
            if (!threadStack.empty())
            {
                TimedElement poppedStack = (TimedElement) threadStack.pop();
                if (poppedStack != targetElement)
                {
                    throw new RuntimeException("Mismatch - popped element = " + poppedStack
                            + " finished target element = " + targetElement);
                }
                if (!threadStack.empty())
                {
                    parentElement = (TimedElement) threadStack.peek();
                }
            }
            if (parentElement == null)
            {
                buildElement.element.appendChild(targetElement.element);
            }
            else
            {
                parentElement.element.appendChild(targetElement.element);
            }
        }
        targets.remove(target);
    }

    /**
     * Fired when a task starts building, this pushes a timed element for the
     * task onto the stack of elements for the current thread, remembering the
     * current time and the name of the task.
     * 
     * @param event
     *            An event with any relevant extra information. Will not be
     *            <code>null</code>.
     */
    public void taskStarted(BuildEvent event)
    {
        TimedElement taskElement = new TimedElement();
        taskElement.startTime = System.currentTimeMillis();
        taskElement.element = doc.createElement(TASK_TAG);

        Task task = event.getTask();
        String name = event.getTask().getTaskName();
        if (name == null)
        {
            name = "";
        }
        taskElement.element.setAttribute(NAME_ATTR, name);
        taskElement.element.setAttribute(LOCATION_ATTR, event.getTask().getLocation().toString());
        tasks.put(task, taskElement);
        getStack().push(taskElement);
    }

    /**
     * Fired when a task finishes building, this adds the time taken and any
     * error stacktrace to the appropriate task element in the log.
     * 
     * @param event
     *            An event with any relevant extra information. Will not be
     *            <code>null</code>.
     */
    public void taskFinished(BuildEvent event)
    {
        Task task = event.getTask();
        TimedElement taskElement = (TimedElement) tasks.get(task);
        if (taskElement != null)
        {
            long totalTime = System.currentTimeMillis() - taskElement.startTime;
            // taskElement.element.setAttribute(TIME_ATTR,
            // DefaultLogger.formatTime(totalTime));
            Target target = task.getOwningTarget();
            TimedElement targetElement = null;
            if (target != null)
            {
                targetElement = (TimedElement) targets.get(target);
            }
            if (targetElement == null)
            {
                buildElement.element.appendChild(taskElement.element);
            }
            else
            {
                targetElement.element.appendChild(taskElement.element);
            }
            Stack threadStack = getStack();
            if (!threadStack.empty())
            {
                TimedElement poppedStack = (TimedElement) threadStack.pop();
                if (poppedStack != taskElement)
                {
                    throw new RuntimeException("Mismatch - popped element = " + poppedStack
                            + " finished task element = " + taskElement);
                }
            }
            tasks.remove(task);
        }
        else
        {
            throw new RuntimeException("Unknown task " + task + " not in " + tasks);
        }
    }

    /**
     * Get the TimedElement associated with a task.
     * 
     * Where the task is not found directly, search for unknown elements which
     * may be hiding the real task
     */
    private TimedElement getTaskElement(Task task)
    {
        TimedElement element = (TimedElement) tasks.get(task);
        if (element != null)
        {
            return element;
        }

        for (Enumeration e = tasks.keys(); e.hasMoreElements();)
        {
            Task key = (Task) e.nextElement();
            if (key instanceof UnknownElement)
            {
                if (((UnknownElement) key).getTask() == task)
                {
                    return (TimedElement) tasks.get(key);
                }
            }
        }

        return null;
    }

    /**
     * Fired when a message is logged, this adds a message element to the most
     * appropriate parent element (task, target or build) and records the
     * priority and text of the message.
     * 
     * @param event
     *            An event with any relevant extra information. Will not be
     *            <code>null</code>.
     */
    public void messageLogged(BuildEvent event)
    {

        if (buildElement == null)
        {
            buildElement = new TimedElement();
            buildElement.startTime = System.currentTimeMillis();
            buildElement.element = doc.createElement(BUILD_TAG);
        }
        int priority = event.getPriority();
        if (priority > msgOutputLevel)
        {
            return;
        }
        Element messageElement = doc.createElement(MESSAGE_TAG);

        String name = "debug";
        switch (event.getPriority())
        {
        case MSG_ERR:
            name = "error";
            break;
        case MSG_WARN:
            name = "warn";
            break;
        case MSG_INFO:
            name = "info";
            break;
        default:
            name = "debug";
            break;
        }
        messageElement.setAttribute(PRIORITY_ATTR, name);

        Throwable ex = event.getException();
        if (MSG_DEBUG <= msgOutputLevel && ex != null)
        {
            Text errText = doc.createCDATASection(StringUtils.getStackTrace(ex));
            Element stacktrace = doc.createElement(STACKTRACE_TAG);
            stacktrace.appendChild(errText);
            buildElement.element.appendChild(stacktrace);
        }
        Text messageText = doc.createCDATASection(event.getMessage());
        messageElement.appendChild(messageText);

        TimedElement parentElement = null;

        Task task = event.getTask();

        Target target = event.getTarget();
        if (task != null)
        {
            parentElement = getTaskElement(task);
        }
        if (parentElement == null && target != null)
        {
            parentElement = (TimedElement) targets.get(target);
        }

        /*
         * if (parentElement == null) { Stack threadStack = (Stack)
         * threadStacks.get(Thread.currentThread()); if (threadStack != null) {
         * if (!threadStack.empty()) { parentElement = (TimedElement)
         * threadStack.peek(); } } }
         */

        if (parentElement != null)
        {
            parentElement.element.appendChild(messageElement);
        }
        else
        {
            buildElement.element.appendChild(messageElement);
        }
    }

    // -------------------------------------------------- BuildLogger interface

    /**
     * Set the logging level when using this as a Logger
     * 
     * @param level
     *            the logging level - see
     *            {@link org.apache.tools.ant.Project#MSG_ERR Project} class for
     *            level definitions
     */
    public void setMessageOutputLevel(int level)
    {
        msgOutputLevel = level;
    }

    /**
     * Set the output stream to which logging output is sent when operating as a
     * logger.
     * 
     * @param output
     *            the output PrintStream.
     */
    public void setOutputPrintStream(PrintStream output)
    {
        this.outStream = new PrintStream(output, true);
    }

    /**
     * Ignore emacs mode, as it has no meaning in XML format
     * 
     * @param emacsMode
     *            true if logger should produce emacs compatible output
     */
    public void setEmacsMode(boolean emacsMode)
    {
    }

    /**
     * Ignore error print stream. All output will be written to either the XML
     * log file or the PrintStream provided to setOutputPrintStream
     * 
     * @param err
     *            the stream we are going to ignore.
     */
    public void setErrorPrintStream(PrintStream err)
    {
    }

}
