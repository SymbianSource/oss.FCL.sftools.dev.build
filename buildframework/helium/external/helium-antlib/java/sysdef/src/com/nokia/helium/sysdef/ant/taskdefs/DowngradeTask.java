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
 * <p>This task allows to downgrade of a system definition file v3.0 into v2.0.</p>
 * 
 * <p>The following example shows how you can downgrade the X:\model.sysdef.xml as
 * X:\model_2_0_1.sysdef.xml.</p>
 * 
 * E.g:
 *   <pre>
 *   &lt;hlm:downgradeSysdef epocroot=&quot;X:\&quot; srcfile=&quot;X:\model.sysdef.xml&quot; 
 *                      destfile=&quot;X:\model_2_0_1.sysdef.xml&quot; /&gt;
 *   </pre>
 *
 *   For more information about system definition file v3.0 please check 
 *   <a href="http://developer.symbian.org/wiki/index.php/System_Definition">http://developer.symbian.org/wiki/index.php/System_Definition</a>.
 *
 *   @ant.task name="downgradeSysdef" category="Sysdef"
 */
public class DowngradeTask extends AbstractSydefTask {
    private static final String XSLT = "sf/os/buildtools/bldsystemtools/buildsystemtools/sysdefdowngrade.xsl"; 

    /**
     * {@inheritDoc}
     */
    public void execute() {
        check();
        log("Downgrading " + this.getSrcFile() + " to 2.0.1 schema.");
        log("Creating " + this.getDestFile());
        transform(new Hashtable<String, String>());
    }

    /**
     * {@inheritDoc}
     */
    @Override
    protected File getXsl() {
        return new File(this.getEpocroot(), XSLT);
    }
}
