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

import info.bliki.wiki.model.WikiModel;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Iterator;
import java.util.List;

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.OutputFormat;
import org.dom4j.io.SAXReader;
import org.dom4j.io.XMLWriter;
import org.apache.log4j.Logger;


/**
 * Renders model property and group description to Wiki Model Syntax
 * @author Helium Team
 */
public class ModelPropertiesParser
{
    private String inputPath;
    private String outputPath;
    private Document doc;
    private Logger log = Logger.getLogger(ModelPropertiesParser.class);
    
    public ModelPropertiesParser(String inputPath, String outputPath)
    {
        this.inputPath = inputPath;
        this.outputPath = outputPath;
    }

    /**
     * Reads model xml file, changes description format.
     * @throws DocumentException
     * @throws IOException
     */
    public void parsePropertiesDescription() throws IOException, DocumentException
    {
        SAXReader xmlReader = new SAXReader();
        doc = xmlReader.read(new File(inputPath));
        List importNodes = doc.selectNodes("//description");
        for (Iterator iterator = importNodes.iterator(); iterator.hasNext();)
        {
            Element importCurrentNode = (Element) iterator.next();
            importCurrentNode.setText(renderWikiModel(importCurrentNode.getText()));
            writeXMLFile();
        }
    }
    
     /**
     * Writes Document object as xml file
     */
    private void writeXMLFile()
    {
        try {
            if (outputPath != null) {
            XMLWriter out = new XMLWriter(new FileOutputStream(new File(outputPath)), OutputFormat.createPrettyPrint());
            out.write(doc);
          }
        } catch (Exception e) {
            //We are Ignoring the errors as no need to fail the build.
            log.debug("Not able to write into XML Document " + e.getMessage());
        }
    }
    
     /**
     * Render the description as Wiki model
     * @param String descriptionText
     * @return String
     */
    private String renderWikiModel(String descriptionText) throws IOException, DocumentException
    {
        if (descriptionText != null)
        {
            WikiModel wikiModel = new WikiModel("", "");
            //If description contains unwanted symbols like "**", "==" and "- -", remove those from description.
            if (descriptionText.contains("**") || descriptionText.contains("==") || descriptionText.contains("- -"))
            {
                descriptionText = descriptionText.replace("**", "").replace("==", "").replace("- -", "").trim();
            }
            //If description starts with "-", remove it. As wiki have special meaning for this symbol
            if (descriptionText.startsWith("-"))
                descriptionText = descriptionText.replace("-", "");
            descriptionText = descriptionText.trim();
            //Render description with wiki model syntax
            descriptionText = wikiModel.render(descriptionText);
        }
        else
        {
            descriptionText = "";
        }
      return descriptionText;
     }
}

