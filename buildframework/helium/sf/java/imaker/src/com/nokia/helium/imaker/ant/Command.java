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
package com.nokia.helium.imaker.ant;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

/**
 * Abstract a command call. The default command will be imaker.
 * 
 */
public class Command {
    // default command is iMaker
    private String command = "imaker";
    private List<String> args = new ArrayList<String>();
    private Map<String, String> variables = new Hashtable<String, String>();
    private String target = "";
    
    /**
     * Get the target name.
     * @return the target name.
     */
    public String getTarget() {
        return target;
    }

    /**
     * Set the command name
     * @param target the command name.
     */
    public void setTarget(String target) {
        this.target = target;
    }

    /**
     * Get the command name.
     * @return the command name.
     */
    public String getCommand() {
        return command;
    }

    /**
     * Set the command name 
     * @param command the command name.
     */
    public void setCommand(String command) {
        this.command = command;
    }
    
    /**
     * Set the list of arguments based on a list of String.
     * @param args the arg list.
     */
    public void setArguments(List<String> args) {
        this.args.clear();
        this.args.addAll(args);
    }
    
    /**
     * Append an argument to the argument list.
     * @param arg the argument to add.
     */
    public void addArgument(String arg) {
        this.args.add(arg);
    }
    
    /**
     * Get the list of arguments.
     * @return the list of arguments
     */
    public List<String> getArguments() {
        return args;
    }

    /**
     * Get the map of variables.
     * @return a map representing variables for current object.
     */
    public Map<String, String> getVariables() {
        return variables;
    }

    /**
     * Set variables using vars set of variables.
     * @param vars
     */
    public void setVariables(Map<String, String> vars) {
        variables.clear();
        variables.putAll(vars);
    }

    /**
     * Add all the variables from vars.
     * @param vars a set of variables
     */
    public void addVariables(Map<String, String> vars) {
        variables.putAll(vars);
    }

    /**
     * Add a variable to the command.
     * @param name the variable name
     * @param value the variable value
     */
    public void addVariable(String name, String value) {
        variables.put(name, value);
    }

    /**
     * Convert the current object as a command line string.
     * The final string will be contains the data in the following
     * order:
     *   <li> command
     *   <li> arguments
     *   <li> variables
     *   <li> target 
     * @return
     */
    public String getCmdLine() {
        String cmdLine = getCommand();
        for (String arg : getArguments()) {
            cmdLine += " " + arg;            
        }
        for (Entry<String, String> e : getVariables().entrySet()) {
            cmdLine += " " + e.getKey() + "=" + e.getValue();            
        }
        cmdLine += " " + getTarget();
        return cmdLine;
    }
}
