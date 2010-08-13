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

import java.io.File;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.DataType;
import org.apache.log4j.Logger;
import fmpp.tools.AntTask;
import fmpp.tools.AntTask.AntAttributeSubstitution;

import java.io.IOException;
import java.io.InputStream;
import java.io.FileInputStream;
import com.nokia.helium.core.MessageCreationException;
import com.nokia.helium.core.ant.Message;


/**
 * Helper class to store the list of targets to be recorded and to be sent for diamonds.
 *
 * Example 1:
 * <pre>
 *   &lt;hlm:fmppMessage target="diamonds" sourceFile="tool.xml.ftl"&gt;
 *        &lt;data expandProperties="yes"&gt;
 *           ant: antProperties()
 *       &lt;/data&gt;
 *   &lt;/hlm:fmppMessage&gt;
 * </pre>
 * @ant.type name="fmppMessage" category="Core" 
 */
public class FMPPMessage extends DataType implements Message {

    private File outputFile;

    private AntTask task = new AntTask();
    
    private Logger log = Logger.getLogger(FMPPMessage.class);

    public void setSourceFile(File sourceFile) {
        if (!sourceFile.exists()) {
            throw new BuildException("input file : " + sourceFile + " doesn't exists");
        }
        task.setSourceFile(sourceFile);
    }
    
    public void setFreemarkerLinks(String freemarkerLinks) {
        task.setFreemarkerLinks(freemarkerLinks);
    }

    public void addConfiguredData(AntAttributeSubstitution ats) {
        task.addConfiguredData(ats);
    }

    public void addConfiguredFreemarkerLinks(AntAttributeSubstitution ats) {
        task.addConfiguredFreemarkerLinks(ats);
    }
    public void setTemplateData(String templateData) {
        task.setTemplateData(templateData);
    }

    public InputStream getInputStream() throws MessageCreationException {
        InputStream stream = null;
        try {
            task.setProject(getProject());
            outputFile = File.createTempFile("fmppmessage", ".xml");
            outputFile.deleteOnExit();
            task.setTaskName("fmpp");
            task.setOutputFile(outputFile);
            task.execute();
            log.debug("outputfile in getinputstream: " + outputFile);
            stream = new FileInputStream(outputFile);
        } catch (BuildException bex) {
            throw new MessageCreationException(bex.getMessage());
        }
        catch (IOException iex) {
            throw new MessageCreationException(iex.getMessage());
        }
        return stream;
    }
}