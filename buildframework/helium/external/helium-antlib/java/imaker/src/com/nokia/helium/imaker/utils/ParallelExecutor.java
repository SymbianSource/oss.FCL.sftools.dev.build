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
package com.nokia.helium.imaker.utils;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
import java.util.StringTokenizer;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.Date;
import java.text.SimpleDateFormat;

/**
 * Simple application which will execute each line from a text file
 * as a command. All the command will be executed in parallel.
 * Default number of threads is 4.
 * 
 * The implementation must not rely on any external dependencies except JVM and owning jar.
 *
 */
public final class ParallelExecutor {
    
    /**
     * Private constructor - not meant to be instantiated.
     */
    private ParallelExecutor() {
    }
    
    /**
     * Internal class holding a command to 
     * execute.
     *
     */
    private static class RunCommand implements Runnable {
        private String cmdline;
        
        /**
         * Default constructor
         * @param cmdline the command to run
         */
        public RunCommand(String cmdline) {
            this.cmdline = cmdline;
        }
        
        /**
         * Running command line and capturing the output.
         */
        @Override
        public void run() {
            StringTokenizer st = new StringTokenizer(cmdline);
            String[] cmdArray = new String[st.countTokens()];
            for (int i = 0; st.hasMoreTokens(); i++) {
                cmdArray[i] = st.nextToken();
            }
            Process p;
            try {
                p = new ProcessBuilder(cmdArray).redirectErrorStream(true).start();
                BufferedReader in = new BufferedReader(new InputStreamReader(p.getInputStream()));
                String line;
                StringBuffer buffer = new StringBuffer();
                SimpleDateFormat df = new SimpleDateFormat("EEE MMM d HH:mm:ss yyyy");
                
                Date start = new Date();
                buffer.append("++ Started at " + df.format(start) + "\n");
                buffer.append("+++ HiRes Start " + start.getTime() / 1000 + "\n");
                buffer.append("-- " + cmdline + "\n");
                while ((line = in.readLine()) != null) {
                    buffer.append(line + "\n");
                }
                Date end = new Date();
                buffer.append("+++ HiRes End " + end.getTime() / 1000 + "\n");
                buffer.append("++ Finished at " + df.format(end) + "\n");
                synchronized (System.out) {
                    System.out.print(buffer);
                }
            } catch (IOException e) {
                System.err.println("ERROR: " + e.getMessage());
            }
        }
    }
    
    /**
     * This is the entry point of the application.
     * It will only accept one file name as parameter.
     * @param args a list of arguments.
     */
    public static void main(String[] args) {
        if (args.length == 1) {
            try {
                List<String> cmds = new ArrayList<String>();
                BufferedReader in = new BufferedReader(new FileReader(args[0]));
                String line;
                while ((line = in.readLine()) != null) {
                    if (line.trim().length() > 0) {
                        cmds.add(line);
                    }
                }
                
                final ArrayBlockingQueue<Runnable> queue = new ArrayBlockingQueue<Runnable>(cmds.size());
                int numOfProcessor = Runtime.getRuntime().availableProcessors();
                System.out.println("Number of threads: " + numOfProcessor);
                ThreadPoolExecutor executor = new ThreadPoolExecutor(numOfProcessor, numOfProcessor, 100, TimeUnit.MILLISECONDS, queue);
                for (String cmd : cmds) {
                    executor.execute(new RunCommand(cmd));
                }
                executor.shutdown();
            } catch (IOException e) {
                System.err.println("ERROR: " + e.getMessage());
            }
        } else {
            System.out.println("ParallelExecutor: nothing to execute.");
        }
    }

}
