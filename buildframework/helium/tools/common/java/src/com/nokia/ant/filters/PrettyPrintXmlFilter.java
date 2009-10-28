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
 
package com.nokia.ant.filters;

import java.io.StringWriter;

import org.apache.tools.ant.filters.TokenFilter;
import org.dom4j.Document;
import org.dom4j.DocumentHelper;
import org.dom4j.io.OutputFormat;
import org.dom4j.io.XMLWriter;
/**
 * Prints xml file in pretty format.
 *
 */
public class PrettyPrintXmlFilter implements TokenFilter.Filter
{
    public PrettyPrintXmlFilter()
    {
    
    }

    public String filter(String token)
    {
        if (token.length() == 0)
        {
            return token;
        }
        try
        {
//            DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
//            DocumentBuilder builder = docFactory.newDocumentBuilder();
//            Document doc = builder.parse(new InputSource(new StringReader(token)));
//            TransformerFactory tfactory = TransformerFactory.newInstance();
//            Transformer serializer;
//
//            StringWriter out = new StringWriter();
//            serializer = tfactory.newTransformer();
//            
//            // Configure to pretty-print the XML
//            serializer.setOutputProperty(OutputKeys.INDENT, "yes");
//            serializer.setOutputProperty(OutputKeys.METHOD, "xml");
//            serializer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "2");
//
//            serializer.transform(new DOMSource(doc), new StreamResult(out));
//            result = out.toString();
            
            Document doc = DocumentHelper.parseText(token);
            StringWriter out = new StringWriter();
            OutputFormat format = OutputFormat.createPrettyPrint();
            format.setIndentSize(4);
            XMLWriter writer = new XMLWriter( out, format );
            writer.write(doc);
            writer.close();
            return out.toString();
        }
        catch (Exception e)
        {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
    }

}
