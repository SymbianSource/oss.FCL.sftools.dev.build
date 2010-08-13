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
package com.nokia.helium.sysdef.ant.taskdefs;

import java.io.File;
import java.util.Hashtable;

/**
 * <p>This task allows to do the join operation on system definition file v3.0.
 * Join operation consist in combining a distributed system definition file into
 * a stand-alone version.</p>
 * 
 * <p>The following example shows how you can join the X:\layer.sysdef.xml under
 * X:\joined_layer.sysdef.xml.</p>
 * 
 * E.g:
 * <pre>
 *   &lt;hlm:joinSysdef epocroot=&quot;X:\&quot; srcfile=&quot;X:\layer.sysdef.xml&quot; 
 *                      destfile=&quot;X:\joined_layer.sysdef.xml&quot; /&gt;
 * </pre>
 *
 * For more information about system definition file v3.0 please check 
 * <a href="http://developer.symbian.org/wiki/index.php/System_Definition">http://developer.symbian.org/wiki/index.php/System_Definition</a>.
 *
 * <br>
 * This task relies on externals tools. Their location can be configured the following ways:
 *  <li>by configuring the sysdef.tools.home property, fails if the location is incorrect.
 *  <li>The parent folder of the joinsysdef tool from the PATH, fallback on SDK location.
 *  <li>Default SDK location.
 *
 * @ant.task name="joinSysdef" category="Sysdef"
 */

public class JoinTask extends AbstractSydefTask {
    private static final String XSLT = "joinsysdef.xsl"; 

    /**
     * {@inheritDoc}
     */
    public void execute() {
        // This task is configure to always fail on warnings,
        // because it doesn't fails in case of missing link. 
        this.setFailOnWarning(true);
        check();
        log("Joining " + this.getSrcFile()); 
        log("Creating " + this.getDestFile());
        transform(new Hashtable<String, String>());
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected File getXsl() {
        return new File(SysdefUtils.getSysdefHome(getProject(), this.getEpocroot()), XSLT);
    }
}
