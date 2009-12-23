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
import java.util.ArrayList;
import java.util.Iterator;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.FileSet;
import org.apache.tools.ant.types.ResourceCollection;
import org.apache.tools.ant.types.resources.FileResource;

import org.apache.commons.configuration.*;

/**
 * Can load ant configuration file both in .xml and .txt format.
 * In .txt file configuration could be defined like -
 * text.a = text.value.A
 * text.b : text.value.B
 * text.c : ${text.a}
 * In .xml file configuration could be defined like -
 * <config>
 *   <foo>bar</foo>
 *   <interpolated>foo value = ${foo}</interpolated>
 *    <xml>
 *        <c>C</c>
 *        <d>D</d>
 *    </xml>
 *    <array>
 *        <value>one</value>
 *        <value>two</value>
 *    </array>
 *</config> 
 * @ant.task name="configuration"
*/
public class AntConfigurationTask extends Task
{
    private String filepath;

    private ArrayList rcs;

    public AntConfigurationTask()
    {
        rcs = new ArrayList();
    }

    public final void setFile(final String file)
    {
        this.filepath = file;
    }

    public final void addFileset(final FileSet set)
    {
        add(set);
    }

    public final void add( final ResourceCollection res)
    {
        rcs.add(res);
    }

    public final void execute() 
    {
        if (filepath != null)
        {
            importFile(new File(filepath));
        }
        else
        {
            Iterator resourceCollectionIter = rcs.iterator();

            while (resourceCollectionIter.hasNext())
            {
                ResourceCollection resourceCollection = (ResourceCollection) resourceCollectionIter
                        .next();
                Iterator resourceIter = resourceCollection.iterator();
                while (resourceIter.hasNext())
                {
                    FileResource filepath = (FileResource) resourceIter.next();
                    importFile(filepath.getFile());
                }
            }
        }
    }

    private void importFile(final File file)
    {
        try
        {
            String filename = file.getName();
            Configuration config = null;
            if (filename.endsWith(".txt"))
            {
                config = new PropertiesConfiguration(file);
            }
            else if (filename.endsWith(".xml"))
            {
                config = new XMLConfiguration(file);
            }
            Iterator keysIter = config.getKeys();
            while (keysIter.hasNext())
            {
                String key = (String) keysIter.next();
                getProject().setProperty(key, config.getString(key));
            }
        }
        catch (ConfigurationException e)
        {
            throw new BuildException("Not able to import the ANT file " + e.getMessage());
        }
    }
}
