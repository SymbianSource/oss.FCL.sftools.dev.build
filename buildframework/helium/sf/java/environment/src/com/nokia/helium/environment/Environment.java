/*
 * Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

package com.nokia.helium.environment;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileFilter;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.Project;

import com.nokia.helium.environment.ant.types.ExecutableInfo;

/**
 * Represents the environment of the computer in terms of executables, etc. Typically scans for
 * executables that have been run during the build.
 */
public class Environment {
    private static final String[] WINDOWS_EXE_EXTENSIONS = { ".exe", ".bat", ".cmd" };
    private static final String[] DEFAULT_EXECUTABLES = { "java", "ant" };

    private Project project;
    /** List of known executables. */
    private List<Executable> executables = new ArrayList<Executable>();
    /** List of meta information about executables. */
    private Map<String, ExecutableInfo> defs = new HashMap<String, ExecutableInfo>();

    public Environment(Project project) {
        this.project = project;
    }

    public void setExecutableDefs(List<ExecutableInfo> executableDefs) {
        for (Iterator<ExecutableInfo> iterator = executableDefs.iterator(); iterator.hasNext();) {
            ExecutableInfo execDef = (ExecutableInfo) iterator.next();
            defs.put(execDef.getName(), execDef);
        }
    }

    public List<Executable> getExecutables() {
        return executables;
    }

    public void scan(List<String> execCalls) throws IOException {
        addDefaultExecutables();
        parseExecLog(execCalls);
        addExecsWithInfo();
        populateExecutables(executables);
    }

    /**
     * Adds default executables to the list that must have been run because Ant is running.
     */
    private void addDefaultExecutables() {
        for (int i = 0; i < DEFAULT_EXECUTABLES.length; i++) {
            Executable exe = new Executable(DEFAULT_EXECUTABLES[i]);
            exe.setExecuted(true);
            executables.add(exe);
        }
    }

    /**
     * Parses a log of calls to executables in CSV format.
     * 
     * @param execLog
     * @throws IOException
     */
    private void parseExecLog(List<String> execCalls) throws IOException {
        for (Iterator<String> iterator = execCalls.iterator(); iterator.hasNext();) {
            String execCall = (String) iterator.next();

            File execFile = new File(execCall);
            String name = execFile.getName();
            String path = null;
            // See if the full path is available in the exec call
            if (execFile.getParentFile() != null) {
                path = execFile.getCanonicalPath();
            }
            Executable runExec = new Executable(name);
            runExec.setPath(path);
            runExec.setExecuted(true);
            if (!executables.contains(runExec)) {
                executables.add(runExec);
            }
        }
    }

    /**
     * Adds executables to the list based on the meta-information given in the configuration.
     */
    private void addExecsWithInfo() {
        for (Iterator<String> iterator = defs.keySet().iterator(); iterator.hasNext();) {
            String execName = (String) iterator.next();
            Executable exec = new Executable(execName);
            if (!executables.contains(exec)) {
                executables.add(exec);
            }
        }
    }

    private void populateExecutables(List<Executable> executables) throws IOException {
        for (Iterator<Executable> iterator = executables.iterator(); iterator.hasNext();) {
            Executable exec = (Executable) iterator.next();
            project.log("Checking executable: " + exec.toString(), Project.MSG_INFO);
            File executableFile = findExecutableFile(exec);

            if (executableFile != null) {
                if (!findVersion(exec)) {
                    calculateAdditionalVersioningInfo(exec);
                }
            }
            else {
                project.log("Cannot find path for executable: " + exec.toString(), Project.MSG_DEBUG);
            }
        }
    }

    /**
     * Finds an executable file based on the executable definition.
     * 
     * @param exec An executable definition.
     * @return The executable file.
     * @throws IOException
     */
    private File findExecutableFile(final Executable exec) throws IOException {
        File executableFile = null;

        // See if the executable has a full path
        String path = exec.getPath();
        if (path != null) {
            File file = new File(path);
            executableFile = file;
            exec.setPath(executableFile.getCanonicalPath());
        }
        // Or search the PATH
        else {
            String[] pathDirs = getPaths();
            // Filter object to match executable filenames
            FileFilter filter = new FileFilter() {
                public boolean accept(File file) {
                    if (isFileExecutable(file)) {
                        // Find the first file in the directory that has the same start of the name
                        String exeNameNoExt = exec.getNameNoExt();

                        String name = file.getName();
                        if (name.contains(".")) {
                            name = name.substring(0, name.indexOf("."));
                        }

                        if (name.equals(exeNameNoExt) || name.startsWith(exeNameNoExt + ".")) {
                            return true;
                        }
                    }
                    return false;
                }
            };
            for (int i = 0; i < pathDirs.length; i++) {
                File pathDir = new File(pathDirs[i]);
                File[] executableFiles = pathDir.listFiles(filter);
                if (executableFiles != null && executableFiles.length > 0) {
                    executableFile = executableFiles[0];
                    exec.setPath(executableFile.getCanonicalPath());
                    break;
                }
            }
        }
        return executableFile;
    }

    private boolean isFileExecutable(File file) {
        if (file.canExecute()) {
            String os = System.getProperty("os.name").toLowerCase();
            if (os.contains("windows") || os.contains("win32")) {
                for (int i = 0; i < WINDOWS_EXE_EXTENSIONS.length; i++) {
                    if (file.getName().endsWith(WINDOWS_EXE_EXTENSIONS[i])) {
                        return true;
                    }
                }
            }
            else {
                return true;
            }
        }
        return false;
    }

    private String[] getPaths() {
        String pathEnvVar = System.getenv("Path");
        String[] pathDirs = null;
        if (pathEnvVar == null) {
            pathEnvVar = System.getenv("PATH");
        }
        if (pathEnvVar != null) {
            pathDirs = pathEnvVar.split(File.pathSeparator);
        }
        else {
            pathDirs = new String[0];
        }
        return pathDirs;
    }

    private class ExecutableVersionReader implements Runnable {
        private static final int VERSION_TEXT_READ_TIMEOUT = 5000;
        private static final int CHAR_ARRAY_SIZE = 1000;
        
        private String[] commands;
        private InputStream in;
        private StringBuilder text = new StringBuilder();
        private char[] chars = new char[CHAR_ARRAY_SIZE];
        private IOException exception;

        ExecutableVersionReader(String[] commands) {
            this.commands = commands;
        }

        public void run() {
            try {
                int dataRead = 0;
                InputStreamReader textIn = new InputStreamReader(in);
                while (dataRead != -1) {

                    dataRead = textIn.read(chars, 0, chars.length);

                    if (dataRead != -1) {
                        text.append(chars, 0, dataRead);
                    }
                }
            }
            catch (IOException e) {
                exception = e;
            }
            synchronized (this) {
                notify();
            }
        }

        /**
         * Read output data from both stdout and stderr streams.
         * 
         * @return Text data.
         * @throws IOException
         * @throws InterruptedException
         */
        public String readData() throws IOException {
            try {
                Process commandProcess = Runtime.getRuntime().exec(commands);
                // Try to read from stdout
                in = commandProcess.getInputStream();
                new Thread(this).start();
                synchronized (this) {
                    wait(VERSION_TEXT_READ_TIMEOUT);
                }

                // If no data available after timeout, try reading from stderr
                if (text.length() == 0) {
                    in = commandProcess.getErrorStream();
                    new Thread(this).start();
                    synchronized (this) {
                        wait(VERSION_TEXT_READ_TIMEOUT);
                    }
                }
            }
            catch (InterruptedException e) {
                e.printStackTrace();
            }
            if (exception != null) {
                throw exception;
            }
            return text.toString();
        }
    }

    private boolean findVersion(Executable exec) throws IOException {
        // Get the executable additional data for this execution
        ExecutableInfo def = defs.get(exec.getNameNoExt());
        if (def != null && def.getVersionArgs() != null) {
            String exePath = exec.getPath();
            if (exePath == null) {
                exePath = "";
            }
            String[] versionArgs = def.getVersionArgs().split(" ");
            String[] commands = new String[versionArgs.length + 1];
            commands[0] = exePath;
            for (int i = 0; i < versionArgs.length; i++) {
                commands[i + 1] = versionArgs[i].trim();
            }

            ExecutableVersionReader reader = new ExecutableVersionReader(commands);
            String versionText = reader.readData();
            if (def.getVersionRegex() != null) {
                Pattern versionPattern = Pattern.compile(def.getVersionRegex());
                Matcher versionMatch = versionPattern.matcher(versionText);
                if (versionMatch.find()) {
                    String version = versionMatch.group(1);
                    exec.setVersion(version);
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Calculate extra versioning info for the executable file. Used if cannot find a version value.
     * 
     * @param exec The executable.
     * @throws IOException If file cannot be read.
     */
    private void calculateAdditionalVersioningInfo(Executable exec) throws IOException {
        calculateHash(exec);
        File file = new File(exec.getPath());
        exec.setLastModified(file.lastModified());
        exec.setLength(file.length());
    }

    /**
     * Calculate a hash value for the executable file.
     * 
     * @param exec The executable.
     * @throws IOException If file cannot be read.
     */
    private void calculateHash(Executable exec) throws IOException {
        FileInputStream in = new FileInputStream(exec.getPath());
        byte[] bytes = new byte[1000];
        ByteArrayOutputStream fileBytes = new ByteArrayOutputStream();
        int bytesRead = 0;
        bytesRead = in.read(bytes);
        while (bytesRead != -1) {
            fileBytes.write(bytes, 0, bytesRead);
            bytesRead = in.read(bytes);
        }
        MessageDigest digest;
        String hash = "";
        try {
            digest = MessageDigest.getInstance("MD5");
            digest.update(fileBytes.toByteArray());
            byte[] hashBytes = digest.digest();
            StringBuilder builder = new StringBuilder();
            for (int i = 0; i < hashBytes.length; i++) {
                builder.append(Byte.toString(hashBytes[i]));
            }
            hash = new String(builder.toString());
            exec.setHash(hash);

        }
        catch (NoSuchAlgorithmException e) {
            // Not expected to occur
            e.printStackTrace();
        }
    }
}
