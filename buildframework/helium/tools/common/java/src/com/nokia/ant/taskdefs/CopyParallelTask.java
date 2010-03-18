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


import org.apache.tools.ant.taskdefs.Copy;
import java.io.File;
import java.io.IOException;
import java.util.Enumeration;

import java.util.Vector;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.FilterSet;
import org.apache.tools.ant.types.FilterSetCollection;

/**
 * Copies a file(s) or directory(s) to a new file(s)
 * or directory(s) using parallel threads. Number of parallel
 * threads can be defined by threadCount. Files are only 
 * copied if the source file is newer
 * than the destination file, or when the destination file does not
 * exist.  It is possible to explicitly overwrite existing files.</p>
 *
 *
 * @ant.task category="Filesystem"
 * @since Helium 0.21
 *
 */ 
public class CopyParallelTask extends Copy
{
   
    static final String LINE_SEPARATOR = System.getProperty("line.separator");
    private int copyThreadCount;
    private int maxThreadCount;
    /**
     * CopyParallelTask task constructor.
     */
    public CopyParallelTask()
    {
        setTaskName("copy-parallel");        
    }
    /**
     * Perform the copy operation in parallel.
     * @exception BuildException if an error occurs.
     */
    public final void execute()
    {
       super.execute(); 
       //wait until all copy threads are dead
       while (copyThreadCount > 0)
       {
            try
            {
                Thread.sleep(500);
            }
            catch (InterruptedException e)
            {
                if (failonerror) {
                    throw new BuildException("Copy parallel task has been interrupted " + e.getMessage());
                }
                log("Copy parallel task has been interrupted " + e.getMessage(), Project.MSG_ERR);
            }
       }
       
    }
    /**
     * Set maximum number of thread.
     * @param threadCount maximum number of threads
     */
    public final void setThreadCount(final int threadCount) 
    {
        // Limit max. threads to 8 otherwise we experience freezing when using the fastcopy task on 8 processor build machines
        if (threadCount > 8) 
        {
            this.maxThreadCount = 8;   
        } else {
            this.maxThreadCount = threadCount;
        }    
     }
     /**
     * Actually does the file (and possibly empty directory) copies.
     * This is a good method for subclasses to override.
     */
    protected final void doFileOperations() 
    {
        Vector filterChains = getFilterChains();
        Vector filterSets = getFilterSets();
        String inputEncoding = getEncoding();
        String outputEncoding = getOutputEncoding();
        long granularity = 0;   
        
        // set default thread count to 1 if it is not set
        if ( maxThreadCount < 1 )
            maxThreadCount = 1;   
        
      
        if (fileCopyMap.size() > 0) 
        {
            log("Copying " + fileCopyMap.size()
                + " file" + (fileCopyMap.size() == 1 ? "" : "s")
                + " to " + destDir.getAbsolutePath() + " using " +  maxThreadCount 
                + " threads in parallel.");

            Enumeration e = fileCopyMap.keys();
            while (e.hasMoreElements())
            {
                String fromFile = (String) e.nextElement();
                String[] toFiles = (String[]) fileCopyMap.get(fromFile);

                for (int i = 0; i < toFiles.length; i++) {
                    String toFile = toFiles[i];

                    if (fromFile.equals(toFile)) {
                        log("Skipping self-copy of " + fromFile, verbosity);
                        continue;
                    }
                    try {
                        log("Copying " + fromFile + " to " + toFile, verbosity);

                        FilterSetCollection executionFilters = new FilterSetCollection();
                        if ( filtering ) 
                        {
                            executionFilters.addFilterSet(getProject().getGlobalFilterSet());
                        }
                        for (Enumeration filterEnum = filterSets.elements();
                            filterEnum.hasMoreElements();) {
                            executionFilters
                                .addFilterSet((FilterSet) filterEnum.nextElement());
                        }                       
                        
                        while (true)
                        {
                          if ( copyThreadCount < maxThreadCount)
                          {
                              CopyThread copyThread = new CopyThread(fromFile, toFile, executionFilters);
                              copyThread.start();
                              copyThreadCount++;
                              break;
                          }                           
                        }
                    }
                     catch (Exception ioe) {
                        String msg = "Failed to copy " + fromFile + " to " + toFile
                            + " due to " + getDueTo(ioe);
                        File targetFile = new File(toFile);
                        if (targetFile.exists() && !targetFile.delete()) {
                            msg += " and I couldn't delete the corrupt " + toFile;
                        }
                        if (failonerror) {
                            throw new BuildException(msg, ioe, getLocation());
                        }
                        log(msg, Project.MSG_ERR);
                    }
                }
            }
        }
        if (includeEmpty) {
            Enumeration e = dirCopyMap.elements();
            int createCount = 0;
            while (e.hasMoreElements()) {
                String[] dirs = (String[]) e.nextElement();
                for (int i = 0; i < dirs.length; i++) {
                    File d = new File(dirs[i]);
                    if (!d.exists()) {
                        if (!d.mkdirs()) {
                            log("Unable to create directory "
                                + d.getAbsolutePath(), Project.MSG_ERR);
                        } else {
                            createCount++;
                        }
                    }
                }
            }
            if (createCount > 0) {
                log("Copied " + dirCopyMap.size()
                    + " empty director"
                    + (dirCopyMap.size() == 1 ? "y" : "ies")
                    + " to " + createCount
                    + " empty director"
                    + (createCount == 1 ? "y" : "ies") + " under "
                    + destDir.getAbsolutePath());
            }
        }
    }
    
    /**
     * Returns a reason for failure based on
     * the exception thrown.
     * If the exception is not IOException output the class name,
     * output the message
     * if the exception is MalformedInput add a little note.
     */
    private String getDueTo(Exception ex) {
        boolean baseIOException = ex.getClass() == IOException.class;
        StringBuffer message = new StringBuffer();
        if (!baseIOException || ex.getMessage() == null) {
            message.append(ex.getClass().getName());
        }
        if (ex.getMessage() != null) {
            if (!baseIOException) {
                message.append(" ");
            }
            message.append(ex.getMessage());
        }
        if (ex.getClass().getName().indexOf("MalformedInput") != -1) {
            message.append(LINE_SEPARATOR);
            message.append(
                "This is normally due to the input file containing invalid");
             message.append(LINE_SEPARATOR);
            message.append("bytes for the character encoding used : ");
            message.append(
                getEncoding() == null
                 ? fileUtils.getDefaultEncoding() : getEncoding());
            message.append(LINE_SEPARATOR);
        }
        return message.toString();
    }
    /**
     * private class to start a new thread to copy a single file or 
     * or directory. 
     */ 
    private class CopyThread extends Thread 
    {   
        private String fromFile;
        private String toFile;
        private FilterSetCollection executionFilters;
        private Vector filterChains;
        private String inputEncoding;
        private String outputEncoding;
        
        public CopyThread(String fromFile, String toFile, FilterSetCollection executionFilters)
        {
            this.fromFile = fromFile;
            this.toFile = toFile;
            this.executionFilters = executionFilters;            
            this.filterChains = getFilterChains();
            this.inputEncoding = getEncoding();
            this.outputEncoding = getOutputEncoding();        
        }        
    
        public void run() 
        {  
          try 
          { 
             fileUtils.copyFile(fromFile, toFile, executionFilters,
                                         filterChains, forceOverwrite,
                                         preserveLastModified, inputEncoding,
                                         outputEncoding, getProject());                                  
                 
           }
           catch (Exception e) 
           {
                log("Problem found in parallel copy " + e.toString(), Project.MSG_ERR);
           } 
             
          copyThreadCount--;            
          stop();
       }    
    }
   
}
