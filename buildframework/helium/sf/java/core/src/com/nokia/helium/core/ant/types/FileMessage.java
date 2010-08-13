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
import com.nokia.helium.core.MessageCreationException;
import com.nokia.helium.core.ant.Message;

import org.apache.tools.ant.types.DataType;

import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.FileInputStream;
    
/**
 * Helper class to store the list of targets to be recorded and to be sent for diamonds.
 *
 * Example 1:
 * <pre>
 *     &lt;hlm:filemessage id="initial-message" file="${build.output.dir}/temp.xml" /&gt;
 * 
 * </pre>
 * @ant.type name="fileMessage" category="Core" 
 */
public class FileMessage extends DataType implements Message {
    
    private File file;
    
    /**
     * Helper function set file to send as message
     * 
     * @param inputFile to be sent.
     */
    public void setFile(File inputFile) {
        file = inputFile;
    }

    /**
     * Helper function to the stream for the file
     * 
     * @return stream of the file content
     */
    public InputStream getInputStream() throws MessageCreationException {
        if (file == null) {
            throw new MessageCreationException("file attribute is not defined at " + this.getLocation().toString());
        }
        try {
            return  new FileInputStream(file);
        } catch (FileNotFoundException ex) { 
            throw new MessageCreationException("file Not found:" + file);
        }
    }

}