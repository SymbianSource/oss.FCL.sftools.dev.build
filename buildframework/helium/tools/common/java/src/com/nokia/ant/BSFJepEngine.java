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
 
package com.nokia.ant;

import java.io.*;
import org.apache.bsf.BSFException;
import org.apache.bsf.BSFManager;

/**
 * Override default implementation to support source with are not files.
 * 
 * @author Helium Team
 * @see jep.BSFJepEngine
 */
public class BSFJepEngine extends jep.BSFJepEngine
{

    static
    {
        BSFManager.registerScriptingEngine("jep", "com.nokia.ant.BSFJepEngine", new String[]
        { "py" });
    }

    /**
     * Execute a script.
     * 
     * @param source
     *            a <code>String</code> value
     * @param lineNo
     *            an <code>int</code> value
     * @param columnNo
     *            an <code>int</code> value
     * @param script
     *            an <code>Object</code> value
     * @exception BSFException
     *                if an error occurs
     */
    public final void exec(final String source, final int lineNo, final int columnNo, final Object script) throws BSFException
    {
        boolean deleteTemp = false;
        File file = null;
        try
        {
            file = new File(script.toString());
            if (file.exists() && file.isFile())
            {
                super.exec(source, lineNo, columnNo, script);
            }
            else
            {
                deleteTemp = true;
                file = File.createTempFile("helium", null);
                PrintWriter output = new PrintWriter(new FileOutputStream(file));
                output.write(script.toString());
                output.close();
                super.exec(source, lineNo, columnNo, file.getAbsolutePath());
            }
        }
        catch (Exception e)
        {
            throw new BSFException(BSFException.REASON_EXECUTION_ERROR, e.toString(), e);
        }
        finally
        {
            terminate();
            if (deleteTemp && file != null && file.exists()) {
                file.delete();
            }
        }
    }
}
