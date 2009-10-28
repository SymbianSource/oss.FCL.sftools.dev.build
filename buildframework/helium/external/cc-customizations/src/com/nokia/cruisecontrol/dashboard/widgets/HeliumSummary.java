/* 
============================================================================ 
Name        : HeliumSummary.java
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
package com.nokia.cruisecontrol.dashboard.widgets;

import java.io.*;
import java.util.Map;
import net.sourceforge.cruisecontrol.dashboard.widgets.Widget;

public class HeliumSummary implements Widget
{
    public String getDisplayName()
    {
        return "Helium summary";
    }

    public Object getOutput(Map parameters)
    {
        String output = "Error retreiving logs.";
        try
        {
            File projectLogDir = findHeliumLogDir(parameters);
            if (projectLogDir.exists())
            {
                File log = findCCLog(projectLogDir);
                if (log != null)
                {
                    FileReader fr = new FileReader(log);
                    BufferedReader br = new BufferedReader(fr);
                    String s;
                    output = "";
                    while ((s = br.readLine()) != null)
                    {
                        output += s;
                    }
                    fr.close();
                }
                else
                {
                    output = "Could not find CC summary.";
                }
            }
            else
            {
                output = "Could not find " + projectLogDir.getAbsolutePath();
            }
        }
        catch (Exception e)
        {
            return e.toString();
        }
        return output;
    }

    protected File findCCLog(File location)
    {
        if (location.exists() && location.isDirectory())
        {
            File[] list = location.listFiles();
            for (int i = 0; i < list.length; i++)
            {
                if (list[i].isDirectory())
                {
                    File result = findCCLog(list[i]);
                    if (result != null)
                        return result;
                }
                else if (list[i].getName().toLowerCase().endsWith("_cc_summary.html"))
                {
                    return list[i];
                }
            }
        }
        return null;
    }

    protected File findHeliumLogDir(Map parameters) throws Exception
    {
        File projectLogDir = (File) parameters.get(Widget.PARAM_BUILD_ARTIFACTS_ROOT);
        if (projectLogDir != null)
            return projectLogDir;

        throw new Exception("Could not retieve the log directory.");
    }
}
