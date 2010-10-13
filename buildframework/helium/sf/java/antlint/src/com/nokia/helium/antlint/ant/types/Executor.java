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
import java.util.Collection;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.ant.data.AntFile;
import com.nokia.helium.ant.data.Database;

/**
 * <code>Executor</code> is used to run any external tool or command from within
 * the antlint task.
 */
public abstract class Executor extends DataType {

    private File outputDir;
    private Database database;

    /**
     * Set the Database.
     * @param database is the Database to set.
     */
    public void setDatabase(Database database) {
        this.database = database;
    }

    /**
     * Set the output directory.
     * @param outputDir is the output directory.
     */
    public void setOutputDir(File outputDir) {
        this.outputDir = outputDir;
    }

    public File getOutputDir() {
        return outputDir;
    }

    /**
     * Method to run the configured external tool or command.
     */
    public void run() {
        extractScripts();
        execute();
    }
    
    /**
     * Method to validate configured attributes.
     * 
     */
    public void validateAttributes() {
        if (outputDir == null) {
            throw new BuildException("'outputDir' attribute should be specified for '" + toString()
                    + "'");
        }
    }

    /*
     * (non-Javadoc)
     * @see java.lang.Object#toString()
     */
    public String toString() {
        return getClass().getSimpleName();
    }

    private void extractScripts() {
        Collection<AntFile> antFiles = database.getAntFiles();
        for (AntFile antFile : antFiles) {
            getScriptDump().setAntFile(antFile);
            getScriptDump().setOutputDir(outputDir);
            getScriptDump().dump();
        }
    }

    /**
     * Get the script dump.
     * 
     * @return the script dump task.
     */
    protected abstract ScriptDump getScriptDump();
    
    /**
     * Method executes the configured tool or task.
     */
    protected abstract void execute();
}
