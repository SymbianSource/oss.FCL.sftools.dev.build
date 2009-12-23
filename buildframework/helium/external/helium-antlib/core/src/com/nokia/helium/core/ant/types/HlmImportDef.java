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


package com.nokia.helium.core.ant.types;

import org.apache.log4j.Logger;
import org.apache.tools.ant.taskdefs.ImportTask;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.Location;
import org.apache.tools.ant.Project;

import java.io.File;

/**
 * This class implements an Executor importer pre-action.
 * 
 * @ant.type name="importdef" category="Core"
 */
public class HlmImportDef extends HlmPreDefImpl {

    private static Logger log = Logger.getLogger(HlmImportDef.class);
    
    private File file ;

    public void setFile(File file) {
        this.file = file;
    }

    /**
     * Will import the given file.
     */
    public void execute(Project prj, String module, String[] targetNames) {
        log.debug("importdef:prj name" + prj.getName() + ". fileName" + file.toString());
        ImportTask task = new ImportTask();
        Target target = new Target();
        target.setName("");
        target.setProject(prj);
        task.setOwningTarget(target);
        task.setLocation(new Location(file.getAbsolutePath()));
        task.setFile(file.toString());
        task.setProject(prj);
        task.execute();
    }
}