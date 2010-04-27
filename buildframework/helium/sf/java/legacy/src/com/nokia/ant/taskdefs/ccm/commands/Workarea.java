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
 
package com.nokia.ant.taskdefs.ccm.commands;
/**
 * Creates interface to get\set workarea informations for a given project.
 *
 */
public class Workarea extends CcmCommand
{
    private String project;
    private String path;
    private String pst;
    private boolean maintain;
    private boolean recursive;
    private boolean relative;
    private boolean wat;

    public String getProject()
    {
        return project;
    }

    public void setProject(String project)
    {
        this.project = project;
    }
    
    public boolean getMaintain()
    {
        return maintain;
    }

    public void setMaintain(boolean maintain)
    {
        this.maintain = maintain;
    }
    
    public boolean getRecursive()
    {
        return recursive;
    }

    public void setRecursive(boolean recursive)
    {
        this.recursive = recursive;
    }

    public boolean getRelative()
    {
        return relative;
    }

    public void setRelative(boolean relative)
    {
        this.relative = relative;
    }

    public String getPath()
    {
        return path;
    }

    public void setPath(String path)
    {
        this.path = path;
    }

    public String getPst()
    {
        return pst;
    }

    public void setPst(String pst)
    {
        this.pst = pst;
    }

    public boolean getWat()
    {
        return wat;
    }

    public void setWat(boolean wat)
    {
        this.wat = wat;
    }
}
