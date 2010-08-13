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

import java.io.File;
import java.io.IOException;
import java.util.Enumeration;
import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.taskdefs.Copy;
import org.apache.tools.ant.types.FilterSet;
import org.apache.tools.ant.types.FilterSetCollection;

/**
 * Copies a file(s) or directory(s) to a new file(s) or directory(s) using parallel threads. Number
 * of parallel threads can be defined by threadCount. Files are only copied if the source file is
 * newer than the destination file, or when the destination file does not exist. It is possible to
 * explicitly overwrite existing files.</p>
 * 
 * 
 * @ant.task category="Filesystem"
 * @since Helium 0.21
 * 
 */
public class CopyParallelTask extends Copy {

    static final String LINE_SEPARATOR = System.getProperty("line.separator");
    private int copyThreadCount;
    private int maxThreadCount;

    /**
     * CopyParallelTask task constructor.
     */
    public CopyParallelTask() {
        setTaskName("copy-parallel");
    }

    /**
     * Perform the copy operation in parallel.
     * 
     * @exception BuildException if an error occurs.
     */
    public final void execute() {
        super.execute();
        // wait until all copy threads are dead
        while (copyThreadCount > 0) {
            try {
                Thread.sleep(500);
            }
            catch (InterruptedException e) {
                if (failonerror) {
                    throw new BuildException("Copy parallel task has been interrupted "
                        + e.getMessage());
                }
                log("Copy parallel task has been interrupted " + e.getMessage(), Project.MSG_ERR);
            }
        }

    }

    /**
     * Set maximum number of thread.
     * 
     * @param threadCount maximum number of threads
     */
    public final void setThreadCount(final int threadCount) {
        // Limit max. threads to 8 otherwise we experience freezing when using the fastcopy task on
        // 8 processor build machines
        if (threadCount > 8) {
            this.maxThreadCount = 8;
        }
        else {
            this.maxThreadCount = threadCount;
        }
    }

    /**
     * Actually does the file (and possibly empty directory) copies. This is a good method for
     * subclasses to override.
     */
    protected final void doFileOperations() {
        Vector filterSets = getFilterSets();

        // set default thread count to 1 if it is not set
        if (maxThreadCount < 1) {
            maxThreadCount = 1;
        }

        if (fileCopyMap.size() > 0) {
            log("Copying " + fileCopyMap.size() + " file" + (fileCopyMap.size() == 1 ? "" : "s")
                + " to " + destDir.getAbsolutePath() + " using " + maxThreadCount
                + " threads in parallel.");

            Enumeration fileEnum = fileCopyMap.keys();
            while (fileEnum.hasMoreElements()) {
                String fromFile = (String) fileEnum.nextElement();
                String[] toFiles = (String[]) fileCopyMap.get(fromFile);

                for (int i = 0; i < toFiles.length; i++) {
                    String toFile = toFiles[i];

                    if (fromFile.equals(toFile)) {
                        log("Skipping self-copy of " + fromFile, verbosity);
                        continue;
                    }
                    log("Copying " + fromFile + " to " + toFile, verbosity);

                    FilterSetCollection executionFilters = new FilterSetCollection();
                    if (filtering) {
                        executionFilters.addFilterSet(getProject().getGlobalFilterSet());
                    }
                    for (Enumeration filterEnum = filterSets.elements(); filterEnum.hasMoreElements();) {
                        executionFilters.addFilterSet((FilterSet) filterEnum.nextElement());
                    }

                    while (true) {
                        if (copyThreadCount < maxThreadCount) {
                            CopyThread copyThread = new CopyThread(fromFile, toFile, executionFilters);
                            copyThread.start();
                            copyThreadCount++;
                            break;
                        }
                    }
                }
            }
        }
        if (includeEmpty) {
            Enumeration dirEnum = dirCopyMap.elements();
            int createCount = 0;
            while (dirEnum.hasMoreElements()) {
                String[] dirs = (String[]) dirEnum.nextElement();
                for (int i = 0; i < dirs.length; i++) {
                    File file = new File(dirs[i]);
                    if (!file.exists()) {
                        if (!file.mkdirs()) {
                            log("Unable to create directory " + file.getAbsolutePath(), Project.MSG_ERR);
                        }
                        else {
                            createCount++;
                        }
                    }
                }
            }
            if (createCount > 0) {
                log("Copied " + dirCopyMap.size() + " empty director"
                    + (dirCopyMap.size() == 1 ? "y" : "ies") + " to " + createCount
                    + " empty director" + (createCount == 1 ? "y" : "ies") + " under "
                    + destDir.getAbsolutePath());
            }
        }
    }

    /**
     * private class to start a new thread to copy a single file or or directory.
     */
    private class CopyThread extends Thread {
        private String fromFile;
        private String toFile;
        private FilterSetCollection executionFilters;
        private Vector filterChains;
        private String inputEncoding;
        private String outputEncoding;

        public CopyThread(String fromFile, String toFile, FilterSetCollection executionFilters) {
            this.fromFile = fromFile;
            this.toFile = toFile;
            this.executionFilters = executionFilters;
            this.filterChains = getFilterChains();
            this.inputEncoding = getEncoding();
            this.outputEncoding = getOutputEncoding();
        }

        public void run() {
            try {
                fileUtils.copyFile(fromFile, toFile, executionFilters, filterChains, forceOverwrite, preserveLastModified, inputEncoding, outputEncoding, getProject());
            }
            catch (IOException e) {
                log("Problem found in parallel copy " + e.toString(), Project.MSG_ERR);
            }
            copyThreadCount--;
        }
    }

}
