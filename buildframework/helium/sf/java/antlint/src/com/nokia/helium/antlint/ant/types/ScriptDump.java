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
import java.util.List;

import com.nokia.helium.ant.data.AntFile;
import com.nokia.helium.ant.data.AntlibMeta;
import com.nokia.helium.ant.data.MacroMeta;
import com.nokia.helium.ant.data.ProjectMeta;
import com.nokia.helium.ant.data.RootAntObjectMeta;
import com.nokia.helium.ant.data.TargetMeta;

/**
 * <code>ScriptDump</code> is an abstract implementation for extracting and
 * dumping of various scripts from within an Ant file.
 */
public abstract class ScriptDump {

    private File outputDir;
    private AntFile antFile;

    /**
     * Return the ant file.
     * 
     * @return the ant file.
     */
    protected AntFile getAntFile() {
        return antFile;
    }

    /**
     * Set the ant file.
     * 
     * @param the ant file to set.
     */
    public void setAntFile(AntFile antFile) {
        this.antFile = antFile;
    }

    /**
     * Method extracts and dumps the requested scripts.
     */
    public void dump() {
        RootAntObjectMeta root = getAntFile().getRootObjectMeta();
        if (root instanceof ProjectMeta) {
            ProjectMeta projectMeta = (ProjectMeta) root;
            List<TargetMeta> targets = projectMeta.getTargets();
            for (TargetMeta targetMeta : targets) {
                run(targetMeta);
            }
            List<MacroMeta> macros = projectMeta.getScriptDefinitions(getMacroXPathExpression());
            for (MacroMeta macroMeta : macros) {
                run(macroMeta);
            }
        } else {
            AntlibMeta antlibMeta = (AntlibMeta) root;
            List<MacroMeta> macros = antlibMeta.getScriptDefinitions(getMacroXPathExpression());
            for (MacroMeta macroMeta : macros) {
                run(macroMeta);
            }
        }
    }

    protected void run(TargetMeta targetMeta) {
        String xpath = getScriptXPathExpression(targetMeta.getName());
        if (xpath != null) {
            List<MacroMeta> macros = targetMeta.getScriptDefinitions(xpath);
            for (MacroMeta macroMeta : macros) {
                run(macroMeta);
            }
        }
    }

    public void setOutputDir(File outputDir) {
        this.outputDir = outputDir;
    }

    public File getOutputDir() {
        return outputDir;
    }

    /**
     * Get the xpath expression of the macro.
     * 
     * @return the xpath expression of the macro.
     */
    protected abstract String getMacroXPathExpression();

    /**
     * Get the xpath expression for the input target.
     * 
     * @param targetName is the name of the target.
     * @return the xpath expression for the input target.
     */
    protected abstract String getScriptXPathExpression(String targetName);

    /**
     * Method runs the check against the input {@link MacroMeta}.
     * 
     * @param macroMeta is the {@link MacroMeta} against whom the check is run.
     */
    protected abstract void run(MacroMeta macroMeta);

}
