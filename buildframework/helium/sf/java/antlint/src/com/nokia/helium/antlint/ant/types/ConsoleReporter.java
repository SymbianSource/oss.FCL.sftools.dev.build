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
package com.nokia.helium.antlint.ant.types;

import java.io.File;

import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.antlint.ant.Reporter;
import com.nokia.helium.antlint.ant.Severity;

/**
 * This reporter will produce Antlint reporting using ant logging system.
 * 
 * Usage:
 * 
 * <pre>
 *  &lt;antlint&gt;
 *       &lt;fileset id=&quot;antlint.files&quot; dir=&quot;${antlint.test.dir}/data&quot;&gt;
 *               &lt;include name=&quot;*.ant.xml&quot;/&gt;
 *               &lt;include name=&quot;*build.xml&quot;/&gt;
 *               &lt;include name=&quot;*.antlib.xml&quot;/&gt;
 *       &lt;/fileset&gt;
 *       
 *       ...
 *       
 *       &lt;antlintCheckstyleReporter /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.type name="antlintConsoleReporter" category="AntLint"
 */
public class ConsoleReporter extends DataType implements Reporter {

    private Task task;
    private File antFilename;

    /*
     * (non-Javadoc)
     * @see
     * com.nokia.helium.antlint.ant.Reporter#report(com.nokia.helium.antlint
     * .ant.Severity, java.lang.String, java.io.File, int)
     */
    @Override
    public void report(Severity severity, String message, File filename, int lineNo) {
        String errorMessage;
        if (this.antFilename == null) {
            this.antFilename = filename;
            task.log("\nError(s)/Warning(s) for: " + this.antFilename);
            task.log("----------------------------------------------------------");
        } else if (!this.antFilename.equals(filename)) {
            this.antFilename = filename;
            task.log("\nError(s)/Warning(s) for: " + this.antFilename);
            task.log("----------------------------------------------------------");
        }
        if (lineNo > 0) {
            errorMessage = severity.getValue().toUpperCase() + ": " + lineNo + ": " + message;

        } else {
            errorMessage = severity.getValue().toUpperCase() + ": " + message;
        }
        task.log(errorMessage);

    }

    /*
     * (non-Javadoc)
     * @see
     * com.nokia.helium.antlint.ant.Reporter#setTask(org.apache.tools.ant.Task)
     */
    @Override
    public void setTask(Task task) {
        this.task = task;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void close() {
        this.task = null;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void open() {
    }

}
