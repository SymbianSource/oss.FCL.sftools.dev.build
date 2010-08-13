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

package com.nokia.helium.environment.ant.taskdefs;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

import com.nokia.helium.environment.Environment;
import com.nokia.helium.environment.EnvironmentXMLWriter;
import com.nokia.helium.environment.ant.listener.ExecListener;
import com.nokia.helium.environment.ant.types.EnvData;
import com.nokia.helium.environment.ant.types.ExecutableInfo;

/**
 * Checks the environment and logs executable information. Can validate tools versions if needed.
 * 
 * @ant.task name="environment" category="Environment"
 */
public class EnvironmentTask extends Task {
    private File outputFile;
    private List<EnvData> envDataList = new ArrayList<EnvData>();

    public EnvironmentTask() {
        setTaskName("environment");
    }

    /**
     * Set the output file path.
     * 
     * @param outputFile
     */
    public void setOutput(File outputFile) {
        this.outputFile = outputFile;
    }

    /**
     * Add envdata types.
     * 
     * @ant.required
     */
    public void add(EnvData envData) {
        envDataList.add(envData);
    }

    @Override
    public void execute() {
        Project project = getProject();
        project.log("Scanning environment...", Project.MSG_DEBUG);
        OutputStream out = System.out;
        try {
            if (outputFile != null) {
                out = new FileOutputStream(outputFile);
            }
            List<ExecutableInfo> executableDefs = new ArrayList<ExecutableInfo>();
            for (Iterator<EnvData> iterator = envDataList.iterator(); iterator.hasNext();) {
                EnvData envData = (EnvData) iterator.next();
                envData.getExecutableDefs(executableDefs);
            }

            Environment environment = new Environment(project);
            environment.setExecutableDefs(executableDefs);
            environment.scan(ExecListener.getExecCalls());
            EnvironmentXMLWriter writer = new EnvironmentXMLWriter(out);
            writer.write(environment);
        }

        catch (FileNotFoundException e) {
            e.printStackTrace();
            throw new BuildException("Could not find output file.");
        }
        catch (IOException e) {
            e.printStackTrace();
            throw new BuildException("Error reading version.");
        }
    }
}
