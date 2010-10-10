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


package com.nokia.helium.core.ant.taskdefs;

import java.io.RandomAccessFile;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.io.File;
import java.util.HashMap;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.taskdefs.Sequential;

/**
 * This class implements the functionality to provide sequential access of
 * resources. Resources access could be controled by providing a unique lock name
 * and when try to access the resource call this task with locking to true so that
 * no other threads / process can access the same resource at the same time. 
 *
 * Examples:
 * <pre>
 * &lt;target name=&quot;locksubst&quot;&gt;
 *   &lt;hlm:resourceaccess lockname=&quot;subst&quot; noOfRetry=&quot;-1&quot;&gt;
 *   &lt;subst/&gt;
 *   &lt;/hlm:resourceaccess&gt;
 * &lt;/target&gt;
 * </pre>
 * @ant.task name="resourceaccess" category="Core"
 */
public class ResourceAccessTask extends Sequential {

    private static HashMap<String, FileLock> lockMap = 
        new HashMap<String, FileLock>();
    private static Object mutexObject = new Object();
    private int noOfRetry = -1;
    private String lockName;
    private File baseDirectory;
    private long interval = 1000;
    private FileLock fileLock;

    /*
     * Default Constructor
     */
    public ResourceAccessTask() {
        String tempDirectory = System.getProperty("java.io.tmpdir");
        baseDirectory = new File(tempDirectory);
    }
    
    /*
     * Helper function to set the interval
     * @param intervalValue - waiting period till to try next time.
     */
    public void setInterval(Long intervalValue) {
        interval = intervalValue;
    }

    /*
     * Helper function to retry as many times 
     * @param retry - no. of times to retry before throwing
     * LockAccessException
     */
    public void setNoOfRetry(int retry) {
        noOfRetry = retry;
    }

    /*
     * A unique lock name for a specific task to be run
     * sequential. 
     * @param name of the lock to do sequential task.
     */
    public void setLockName(String name) {
        lockName = name;
    }

    /*
     * Base directory for lock file creation. 
     * @param dir, directory in which the lock file to be created
     * defaults to temporary directory.
     */
    public void setBaseDirectory(File dir) {
        baseDirectory = dir;
    }

    /*
     * Function acquires the lock on the specified lock name. 
     */
    public void acquireLock() {
        File file = new File(baseDirectory, lockName);
        if (! file.exists()) {
            FileOutputStream stream = null;
            try {
                stream = new FileOutputStream(file);
                stream.write("do not edit \n lock processing".getBytes());
                stream.close();
            } catch (FileNotFoundException e) {
                throw new BuildException("interrupted during waiting period");
            } catch (IOException e) {
                throw new BuildException("I/O exception during creating lock for file: " + file);
            }
        }
        try {
            FileChannel channel = new RandomAccessFile(new File(baseDirectory, 
                        lockName), "rw").getChannel();
            boolean lockAcquired = false;
            int i = 0;
            while (!lockAcquired) {
                try {
                    synchronized (mutexObject) {
                        if (lockMap.get(lockName) == null) {
                            if ( noOfRetry != -1 && i >= noOfRetry) {
                                throw new BuildException("lock not acquired");
                            }
                            i += 1;
                            fileLock = channel.lock();
                            lockAcquired = true;
                            lockMap.put(lockName, fileLock);
                        } else {
                            if ( noOfRetry != -1 && i >= noOfRetry) {
                                throw new BuildException("lock not acquired");
                            }
                            try {
                                Thread.sleep(interval);
                            } catch (InterruptedException e) {
                                throw new BuildException("interrupted during waiting period");
                            }
                            i += 1;
                        }
                    }
                } catch (IOException e) {
                    throw new BuildException(e.getMessage());
                } catch (java.nio.channels.OverlappingFileLockException jex) {
                    try {
                        Thread.sleep(interval);
                    } catch (InterruptedException e) {
                        throw new BuildException("interrupted during waiting period");
                    }
                }
            }
        } catch (FileNotFoundException e) {
            throw new BuildException("interrupted during waiting period");
        }
    }

    /*
     * Function to release the lock. 
     */
    public void releaseLock() {
        try {
            synchronized (mutexObject) {
                FileLock fileLock = lockMap.get(lockName);
                if (fileLock == null) {
                    throw new BuildException("releasing without trying to lock resource: " + lockName);
                }
                lockMap.remove(lockName);
                fileLock.release();
            }
        } catch (IOException e) {
            throw new BuildException("IOException during releasing lock");
        }
    }
    
    public void execute() {
        if (!baseDirectory.exists()) {
            throw new BuildException("base directory of resource access task not exists");
        }
        if (lockName == null) {
            throw new BuildException("lock name should not "
                    + "be null during releasing the lock");
        }
        acquireLock();
        try {
            super.execute();
        } finally {
            releaseLock();
        }
    }
}