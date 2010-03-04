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
package com.nokia.helium.sbs.ant.taskdefs;

/**
 * This task is to execute the CTCWrap command with the list of sbs parameters
 * using sbsinput type. Based on the raptor input list of additional log file path
 * used needs to be set, so that the scanlog, additional log files are generated 
 * properly.
 * 
 * <pre>
 * &lt;ctctask sbsinput=&quot;sbs.input&quot; sysdefFile=&quot;system.def.file&quot;
 *      workingDir=&quot;build.drive&quot; failOnError=&quot;false&quot; 
 *      cleanLog=&quot;sbs.log.file.clean.log&quot; 
 *      failOnError=&quot;false&quot; 
 *      errorfile=&quot;path to error file&quot;/&gt;
 * </pre>
 * 
 * @ant.task name="ctctask" category="SBS"
 */
public class CTCTask extends SBSTask {
    
    private String instrumentType = "m";
    
    public CTCTask() {
        super();
        getSbsCmd().setExecutable("ctcwrap");
    }
    
    public void setInstrumentType(String i)
    {
        instrumentType = i;
    }
    
    protected String getSBSCmdLine() {
        return "-i " + instrumentType + " sbs" + super.getSBSCmdLine();
    }

}
