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


package com.nokia.helium.diamonds;

import java.io.File;
import java.io.FileOutputStream;
import java.util.Iterator;
import java.util.List;

import org.apache.log4j.Logger;
import org.dom4j.Attribute;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.OutputFormat;
import org.dom4j.io.SAXReader;
import org.dom4j.io.XMLWriter;

/**
 * This class implements an XML file merger. All node from an external XML with
 * same format (same root node name) will get added to the source root element.
 */
public class XMLMerger {
    private Logger log = Logger.getLogger(getClass());
    private File merge;
    private Document doc;
    private Element root;

    /**
     * Create an XMLMerger, the merge file will be used as input and output.
     * 
     * @param merge
     * @throws XMLMergerException
     */
    public XMLMerger(File merge) throws XMLMergerException {
        log.debug("Merging into: " + merge.getAbsolutePath());
        try {
            this.merge = merge;
            SAXReader reader = new SAXReader();
            doc = reader.read(merge);
            root = doc.getRootElement();
        } catch (DocumentException e) {
            throw new XMLMergerException(e.getMessage());
        }        
    }
    
    /**
     * Add all sub element of data file into the merged file. If the root
     * element name is different for the merged file an XMLMergerException is
     * thrown.
     * 
     * @param data
     *            the input file.
     * @throws XMLMergerException
     */
    public void merge(File data) throws XMLMergerException {
        log.debug("Merging " + data.getAbsolutePath());
        try {
            SAXReader reader = new SAXReader();
            Document dataDoc = reader.read(data);
            Element dataRoot = dataDoc.getRootElement();
            if (!root.getName().equals(dataRoot.getName())) {
                throw new XMLMergerException(
                        "Trying to merge incompatible xml format ('"
                                + root.getName() + "'!='" + dataRoot.getName()
                                + "')");
            }
            mergeNode(root, dataRoot);
            write();
        } catch (DocumentException e) {
            throw new XMLMergerException(e.getMessage());
        }
    }

    /**
     * Merging two XML elements. It only keeps difference.
     * 
     * @param dest
     * @param src
     */
    @SuppressWarnings("unchecked")
    protected void mergeNode(Element dest, Element src) {
        for (Iterator<Element> node = src.elements().iterator(); node.hasNext();) {
            Element e = node.next();
            
            List<Element> ses = dest.elements(e.getName());
            boolean add = true;
            for (Element se : ses) {
                if (areSame(se, e)) {
                    log.debug("Element " + e.getName() + " already found in dest.");
                    add = false;
                }
            }
            if (add) {
                log.debug("Adding node " + e.getName() + " to " + dest.getName());
                dest.add(e.detach());
            } else if (ses.size() > 0) {
                log.debug("Merging " + ses.get(0).getName() + " to " + e.getName());
                mergeNode(ses.get(0), e);
            }
        }
    }

    /**
     * Compare two elements name and attributes. Returns true if name and all
     * attributes are matching, false otherwise.
     * 
     * @param a
     * @param b
     * @return boolean
     */
    @SuppressWarnings("unchecked")
    protected boolean areSame(Element a, Element b) {
        log.debug("areSame:" + a + " <=> " + b);
        if (!a.getName().equals(b.getName()))
            return false;
        log.debug("same attribute list size?");
        if (a.attributes().size() != b.attributes().size())
            return false;
        log.debug("same attribute list?");
        for (Iterator<Attribute> at = a.attributes().iterator(); at.hasNext();) {
            Attribute attra = at.next();
            Attribute attrb = b.attribute(attra.getName());
            if (attrb == null || !attra.getValue().equals(attrb.getValue()))
                return false;
        }
        if (!a.getTextTrim().equals(b.getTextTrim()))
            return false;
        return true;
    }

    /**
     * Write the XML content back the file.
     * @throws XMLMergerException
     */
    protected void write() throws XMLMergerException {
        log.debug("Writing " + merge.getAbsolutePath());
        try {
            FileOutputStream fos = new FileOutputStream(merge);
            OutputFormat format = OutputFormat.createPrettyPrint();
            XMLWriter writer = new XMLWriter(fos, format);
            writer.write(doc);
            writer.flush();
        } catch (Exception e) {
            throw new XMLMergerException(e.getMessage());
        }
    }

    /**
     * Exception class related to the XMLMerger. 
     */
    public class XMLMergerException extends Exception {

        private static final long serialVersionUID = 7624650310086957316L;

        /**
         * Default constructor.
         * @param msg error message
         */
        public XMLMergerException(String msg) {
            super(msg);
        }
    }

}
