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

import java.io.File;
import com.nokia.ant.Database;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.ResourceCollection;
import org.apache.tools.ant.types.Reference;

/**
 * Reads the current ant project and a fileset and generates a xml file with a summary of targets,
 * macros and properties.
 *
 * @ant.task name="database"
 */
public class DatabaseTask extends Task
{
    private File outputFile;

    private ResourceCollection rc;
    private boolean homeFilesOnly = true;

    public DatabaseTask()
    {
        setTaskName("database");
    }

    public void setOutput(File outputFile)
    {
        this.outputFile = outputFile;
    }

    public void setRefid(Reference r)
    {
        Object o = r.getReferencedObject();
        if (!(o instanceof ResourceCollection))
        {
            throw new BuildException(r.getRefId() + " doesn\'t denote a ResourceCollection");
        }
        rc = (ResourceCollection) o;
    }
    
    /**
     * If true only read files that are not in the helium dir.
     */
    public void setHomeFilesOnly(boolean homeFilesOnly) {
        this.homeFilesOnly = homeFilesOnly;
    }

    public void execute()
    {
        log("Building Ant project database", Project.MSG_DEBUG);
        try
        {
            Database db = new Database(getProject(), rc, this);
            db.setHomeFilesOnly(homeFilesOnly);
            db.createXMLFile(outputFile);
        }
        catch (Exception e)
        {
            // TODO Auto-generated catch block
            e.printStackTrace();
            throw new BuildException(e.getMessage());
        }
    }

}
