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

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.taskdefs.Execute;
import org.apache.tools.ant.taskdefs.LogStreamHandler;

/**
 * <code>AbstractScmBaseTask</code> is an abstract class for GSCM related tasks
 * such as rebaseline and deconfigure.
 * 
 * @ant.task category="SCM"
 * 
 */
public abstract class AbstractScmBaseTask extends Task {

  // common attributes
  private String database; // -d dbname = Database name (or database path)
  private String password; // -U password = UNIX password
  private String ccmProject; // -p projectname = Project name (incompatible
  // with -B)

  private Integer verbosity;

  private StringBuffer commandString = new StringBuffer();
  private List<SCMCommandArgument> commands = new ArrayList<SCMCommandArgument>();

  /**
   * Return the Synergy project name.
   * 
   * @return the Synergy project name.
   */
  public String getCcmProject() {
    return ccmProject;
  }

  /**
   * Set Synergy Project Name to be used.
   * 
   * @param ccmProject
   *            is the Synergy project name to set
   * @ant.required
   */
  public void setCcmProject(String ccmProject) {
    this.ccmProject = ccmProject;
    log("Set ccmProject to " + ccmProject);
  }

  /**
   * Return the database name.
   * 
   * @return the database name.
   */
  public String getDatabase() {
    return database;
  }

  /**
   * Set Synergy Database name to be used.
   * 
   * @param database
   *            is the name of the Synergy database to set.
   * @ant.required
   */
  public void setDatabase(String database) {
    this.database = database;
    log("Set database to " + database);
  }

  /**
   * Return the Synergy password.
   * 
   * @return the Synergy password.
   */
  public String getPassword() {
    return password;
  }

  /**
   * Set Synergy Password to be used.
   * 
   * @param password
   *            is the password to set.
   * @ant.required
   */
  public void setPassword(String password) {
    this.password = password;
    log("Set password to ****** ");
  }

  /**
   * Return the verbosity.
   * 
   * @return the verbosity.
   */
  public Integer getVerbosity() {
    return verbosity;
  }

  /**
   * Set verbosity level to be used. Verbosity level ( 0 - quiet, 1 - verbose,
   * 2 - very verbose). Exception will be raised for any other value.
   * 
   * @param verbosity
   *            is the verbosity level to set.
   * @ant.not-required
   */
  public void setVerbosity(Integer verbosity) {
    this.verbosity = verbosity;
    log("Set verbosity to " + verbosity);
  }

  /**
   * Method executes the current task.
   * 
   */
  @Override
  public void execute() {
    try {
      // Set execution script
      setExecutionScript();

      // Build command argument list
      buildCommandList();

      // handle the command arguments
      handleCommandArguments();

      // configure verbosity
      configureVerbosity();

      // Execute the command-line launching as a separate process
      runCommand();
      log("Completed successfully.");
    } catch (Throwable th) {
      th.printStackTrace();
      if (th instanceof BuildException) {
        throw (RuntimeException) th;
      } else {
        raiseError("Script execution failure.");
      }
    }
  }

  /**
   * Method appends the given prefix and the command to the command string if
   * the input cmd string is not null.
   * 
   * @param prefix
   *            is the prefix of the cmd string input.
   * @param cmd
   *            is the cmd string to be appended to main command string.
   */
  protected void append2CommandString(String prefix, Object cmd) {
    if (cmd != null) {
      commandString.append(prefix);
      commandString.append(" ");
      commandString.append(cmd);
      commandString.append(" ");
    }
  }

  /**
   * Method appends the given prefix to the command string if the boolean
   * value input is set true.
   * 
   * @param prefix
   *            is the prefix to be appended to the command string.
   * @param bool
   *            indicates whether to append the prefix or not.
   */
  protected void append2CommandString(String prefix, Boolean bool) {
    if (bool != null && bool) {
      append2CommandString(prefix);
    }
  }

  /**
   * Method appends the given cmd to the command string.
   * 
   * @param cmd
   *            is the command string to be appended.
   */
  protected void append2CommandString(String cmd) {
    commandString.append(cmd);
    commandString.append(" ");
  }

  /**
   * Method is used to throw a {@link BuildException} with the specified error
   * message.
   * 
   * @param errorMessage
   *            is the error message.
   */
  protected void raiseError(String errorMessage) {
    StringBuffer buffer = new StringBuffer("[").append(getTaskName())
        .append("] Error: ").append(errorMessage);
    throw new BuildException(buffer.toString());
  }

  /**
   * Add the given command argument to the command list.
   * 
   * @param fieldName
   *            is the name of the task field.
   * @param cmdArg
   *            is the command argument to be added to the command list.
   * @param required
   *            indicates whether the command argument is mandatory or not.
   * @param fieldValue is the value of the given field           
   */
  protected void addCommandArg(String fieldName, String cmdArg,
      Boolean required, Object fieldValue ) {
    SCMCommandArgument cmdObj = new SCMCommandArgument(fieldName, cmdArg,
        required, fieldValue );
    commands.add(cmdObj);
  }

  /**
   * Add the given command argument to the command list. By default, the input
   * command argument will be optional.
   * 
   * @param fieldName
   *            is the name of the task field.
   * @param cmdArg
   *            is the command argument to be added to the command list.
   * @param fieldValue is the value of the given field           
   */
  protected void addCommandArg(String fieldName, String cmdArg, Object fieldValue ) {
    addCommandArg(fieldName, cmdArg, false, fieldValue);
  }

  /**
   * Method validates the given arguments.
   */
  protected abstract void validateArguments();

  /**
   * Set the execution script.
   * 
   */
  protected abstract void setExecutionScript();

  /**
   * Build a command list consisting of all the required and optional command
   * arguments of the current task.
   */
  protected abstract void buildCommandList();

  /**
   * Method returns the correct verbosity level for the input choice.
   * 
   * @param choice
   *            is the verbosity choice set by user.
   * @return the verbosity level to set.
   */
  protected abstract String getVerbosity(int choice);

  // ----------------------------------- PRIVATE METHODS  --------------------------------------

  /**
   * Method returns the requested {@link Field} object from the input
   * {@link Class}. If the requested field is not found in the given
   * {@link Class} then all its super classes are searched recursively.
   * 
   * @param clazz
   *            is the {@link Class} of which the field is requested.
   * @param fieldName
   *            is the name of the requested field.
   * @return the requested field.
   */
  private Field getField(Class<?> clazz, String fieldName) {
    Field field = null;
    if (clazz != null) {
      try {
        field = clazz.getDeclaredField(fieldName);
      } catch (NoSuchFieldException nsfe) {
        field = getField(clazz.getSuperclass(), fieldName);
      }
    }
    return field;
  }

  /**
   * Method process the command arguments set in the command list.
   * 
   * @throws Exception
   *             if any error occurs while processing the command arguments.
   */
  private void handleCommandArguments() throws Exception {
    StringBuffer missingArgs = new StringBuffer();
    Field field = null;
    for (SCMCommandArgument cmdObj : commands) {
      field = getField(getClass(), cmdObj.fieldName);
      if (field != null) {
        Object fieldValue = field.getType().cast( cmdObj.fieldValue );
        check4MandatoryCmdArguments(cmdObj, fieldValue, missingArgs);
        buildCommand(cmdObj, fieldValue);
      }
    }
    // handle missing args if any
    handleMissingArguments(missingArgs);
    validateArguments();
  }

  /**
   * Method checks for the mandatory command arguments.
   * 
   * @param cmdObj
   *            is the {@link SCMCommandArgument} used in verification
   * @param fieldValue
   *            is the field value to verify
   * @param missingArgs
   *            contains the mandatory command arguments which are missing.
   */
  private void check4MandatoryCmdArguments(SCMCommandArgument cmdObj,
      Object fieldValue, StringBuffer missingArgs) {
    if (cmdObj.required && fieldValue == null) {
      missingArgs.append(cmdObj.fieldName);
      missingArgs.append(" ");
    }
  }

  /**
   * Method is used to construct an executable command string.
   * 
   * @param cmdObj
   *            is the {@link SCMCommandArgument}
   * @param fieldValue
   *            is the fieldValue containing the actual command argument.
   */
  private void buildCommand(SCMCommandArgument cmdObj, Object fieldValue) {
    if (fieldValue instanceof Boolean) {
      append2CommandString(cmdObj.commandArgument, (Boolean) fieldValue);
    } else {
      append2CommandString(cmdObj.commandArgument, fieldValue);
    }
  }

  /**
   * Method throws a {@link BuildException} if any mandatory command arguments
   * are missing.
   * 
   * @param missingArgs
   *            is the {@link StringBuffer} consisting of mandatory command
   *            arguments which are missing.
   */
  private void handleMissingArguments(StringBuffer missingArgs) {
    if (missingArgs.length() > 0) {
      raiseError("mandatory attributes are not defined - "
          + missingArgs.toString());
    }
  }

  /**
   * Configure the verbosity set by the user.
   */
  private void configureVerbosity() {
    if (verbosity != null) {
      append2CommandString(getVerbosity(verbosity));
    }
  }

  /**
   * Execute the specified command.
   * 
   * @throws Exception
   *             if execution fails or any error occurs while execution of the
   *             command.
   */
  private void runCommand() throws Exception {
    String[] cmdline = commandString.toString().split(" ");
    /*
     * Note: static method call to Execute.runCommand doesnot run the given
     * perl script here due to the setting of vmLauncher which acutally
     * tries executing the script using Runtime.getRuntime().exec() method
     * and this method cannot run the script without reference to the cmd or
     * shell. (Similar with ExecTask)
     * 
     * So creating an instance of Execute class helps to disable the
     * vmLauncher and an OS dependent shellLauncher will be available for
     * the execution of the script.
     */
    Execute exe = new Execute(new LogStreamHandler(this, Project.MSG_INFO,
        Project.MSG_ERR));
    exe.setAntRun(getProject());
    exe.setCommandline(cmdline);
    exe.setVMLauncher(false);
    int retval = exe.execute();
    if (Execute.isFailure(retval)) {
      throw new RuntimeException(cmdline[0] + " failed with return code "
          + retval);
    }
  }

  // ************************************* PRIVATE CLASSES ***************************************

  /**
   * <code>SCMCommandArgument</code> is a private class and represents a
   * normal java bean which is used to hold the information related to SCM
   * command arguments.
   */
  private class SCMCommandArgument {

    private String fieldName;
    private Object fieldValue;
    private String commandArgument;
    private Boolean required;

    /**
     * Create an instance of {@link SCMCommandArgument}.
     * 
     * @param fieldName
     *            is the name of the task field
     * @param commandArg
     *            is the SCM command argument
     * @param reqd
     *            indicates the input command argument is mandatory or not.
     */
    protected SCMCommandArgument(String fieldName, String commandArg,
        Boolean reqd, Object fieldValue ) {
      this.fieldName = fieldName;
      this.commandArgument = commandArg;
      this.required = reqd;
      this.fieldValue = fieldValue;
    }
  }
}
