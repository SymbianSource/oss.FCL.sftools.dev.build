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

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;

import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.MessageCreationException;
import com.nokia.helium.core.ant.Message;

   
/**
 * Helper class to store the text message.
 *
 * Example 1:
 * <pre>
 *     &lt;hlm:textMessage id="initial-message" text="helloworld" /&gt;
 * </pre>
 * @ant.type name="textMessage" category="Core" 
 */
public class TextMessage extends DataType implements Message {
    private String text;
    
    /**
     * Helper function to set the text to be sent.
     * 
     * @param text to be sent.
     */
    /**
     * Helper function to return the contents as stream.
     * 
     * @return content as input stream.
     */
    public InputStream getInputStream() throws MessageCreationException {
        if (text == null) {
            throw new MessageCreationException("text attribute is not defined at " + this.getLocation());
        }
        try {
            return new ByteArrayInputStream(text.getBytes("UTF-8"));
        } catch (UnsupportedEncodingException uex) {
            throw new MessageCreationException(uex.getMessage());                
        }
    }
    
    /**
     * Text message to send.
     * 
     * @param text to be sent.
     * @ant.required
     */
    public void setText(String text) {
        this.text = text;
    }
 
}