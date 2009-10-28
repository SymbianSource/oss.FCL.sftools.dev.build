/* 
============================================================================ 
Name        : SynergyBaselineProjects.java 
Part of     : Helium 

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.
This component and the accompanying materials are made available
under the terms of the License "Eclipse Public License v1.0"
which accompanies this distribution, and is available
at the URL "http://www.eclipse.org/legal/epl-v10.html".

Initial Contributors:
Nokia Corporation - initial contribution.

Contributors:

Description:

============================================================================
 */
package com.nokia.cruisecontrol.sourcecontrol;

import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Level;
import org.apache.log4j.Logger;

import net.sourceforge.cruisecontrol.util.ManagedCommandline;

public class SynergyBaselineProjects
{
    private static final Logger LOG = Logger.getLogger(SynergyBaselineProjects.class);

    private ManagedCommandline cmd;

    private String project;

    public SynergyBaselineProjects(ManagedCommandline cmd, String project)
    {
        this.cmd = cmd;
        this.project = project;
        // Configure the logger to be always in debug mode.
        LOG.setLevel(Level.DEBUG);
    }

    /**
     * Running the following command: ccm query
     * "hierarchy_project_members(is_project_in_baseline_of(is_baseline_in_pg_of
     * ( is_project_grouping_of('<project_four_part_name>'))),none)"
     * 
     * @return a list of baseline projects
     * @throws IOException
     */
    public List<String> getBaselineProjects()
    {
        List<String> baselines = new ArrayList<String>();
        LOG.info("Querying baselines projects for " + project);
        cmd.clearArgs();
        cmd.createArgument("query");
        cmd.createArgument("hierarchy_project_members(is_project_in_baseline_of("
                + "is_baseline_in_pg_of(is_project_grouping_of('" + project + "'))),none)");
        cmd.createArgument("-u");
        cmd.createArgument("-f");
        cmd.createArgument("%objectname");
        try
        {
            cmd.execute();
            cmd.assertExitCode(0);
        }
        catch (Exception e)
        {
            String message = "Could not query baseline projects for \"" + project + "\".";
            LOG.error(message, e);
            throw new OperationFailedException(message, e);
        }
        LOG.info("stderr: " + cmd.getStderrAsString());
        LOG.info("stdout: " + cmd.getStdoutAsString());

        for (Object o : cmd.getStdoutAsList())
        {
            String l = (String) o;
            if (l.length() > 0)
            {
                LOG.info("Baseline: " + l);
                baselines.add(l);
            }
        }
        return baselines;
    }
}
