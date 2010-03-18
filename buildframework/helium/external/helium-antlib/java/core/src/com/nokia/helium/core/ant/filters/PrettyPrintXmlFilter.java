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

package com.nokia.helium.core.ant.filters;

import java.io.StringWriter;

import org.apache.tools.ant.filters.TokenFilter.Filter;
import org.dom4j.Document;
import org.dom4j.DocumentHelper;
import org.dom4j.io.OutputFormat;
import org.dom4j.io.XMLWriter;

/**
 * Prints xml file in pretty format.
 * 
 */
public class PrettyPrintXmlFilter implements Filter {

    public PrettyPrintXmlFilter() {
     
    }
    
    /**
     * Filter the input string.
     * 
     * @param string
     *            the string to filter
     * @return the modified string
     */
    public String filter(String token) {
        String output = token;
        XMLWriter writer = null;
        if (token.length() > 0) {
            try {
                Document doc = DocumentHelper.parseText(token);
                StringWriter out = new StringWriter();
                OutputFormat format = OutputFormat.createPrettyPrint();
                format.setIndentSize(4);
                writer = new XMLWriter(out, format);
                writer.write(doc);

                output = out.toString();
            } catch (Exception e) {
                throw new RuntimeException(e);
            } finally {
                try {
                    if (writer != null)
                        writer.close();
                } catch (Exception e2) {
                    e2.printStackTrace();
                }
            }
        }
        return output;
    }

}
