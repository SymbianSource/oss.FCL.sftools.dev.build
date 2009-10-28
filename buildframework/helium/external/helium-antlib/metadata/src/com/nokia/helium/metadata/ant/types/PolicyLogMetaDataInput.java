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

package com.nokia.helium.metadata.ant.types;

import java.util.*;
import org.apache.log4j.Logger;
import javax.xml.stream.XMLStreamReader;
import java.util.regex.Pattern;


/**
 * This Type is to specify and use the policy logparsertype to 
 * parse and store the data based on xmlstreamreader.
 * <pre>
 * &lt;hlm:metadatafilterset id="policy.metadata.filter"&gt;
 *    &lt;metadatafilterset filterfile="common.csv" /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:policymetadatainput&gt;
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*validate*policy*.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid="policy.metadata.filter" /&gt;
 * &lt;/hlm:policymetadatainput&gt;
 * </pre>
 * @ant.task name="policymetadatainput" category="Metadata"
 */
public class PolicyLogMetaDataInput extends XMLLogMetaDataInput {

    private Logger log = Logger.getLogger(XMLLogMetaDataInput.class);
    
    private Map<String, String> currentAttributeMap;
    
    
    public PolicyLogMetaDataInput() {
    }
    

    private Map<String, String> getAttributes(XMLStreamReader streamReader) {
        int count = streamReader.getAttributeCount() ;
        if (count > 0 ) {
            Map<String, String> attributesMap = new HashMap<String, String>();
            for (int i = 0 ; i < count ; i++) {
                attributesMap.put(streamReader.getAttributeLocalName(i), 
                        streamReader.getAttributeValue(i));
            }
            return attributesMap;
        }
        return null;
    }

   
    
    boolean startElement (XMLStreamReader streamReader) {
        String tagName = streamReader.getLocalName();
        //log.debug("startElement: " + tagName);
        if (tagName.equalsIgnoreCase("error")) {
            currentAttributeMap = getAttributes(streamReader);
        }
        return false;
    }

    boolean endElement(XMLStreamReader streamReader) throws Exception {
        boolean retValue = false;
        try {
            String tagName = streamReader.getLocalName();
            String priority = "ERROR";
            log.debug("endElement: " + tagName);
            if (tagName.equalsIgnoreCase("error")) {
                log.debug("tagName matches error");
                String errorType = currentAttributeMap.get("type");
                log.debug("errorType:" + errorType);
                if (errorType.equals("unknownstatus")) {
                    addEntry(priority, "CSV validation", getCurrentFile().toString(), -1, currentAttributeMap.get("message") + 
                            currentAttributeMap.get("value"));
                    retValue = true;
                } else if (errorType.equals("A") || errorType.equals("B") 
                        || errorType.equals("C") || errorType.equals("D")) {
                    int flags = Pattern.CASE_INSENSITIVE | Pattern.DOTALL ;
                    Pattern pattern = Pattern.compile("([\\\\/][^\\\\/]+?)$", flags);
                    addEntry(priority, "Issues", getCurrentFile().toString(), -1, 
                            errorType + "Found incorrect value for" + 
                            pattern.matcher(currentAttributeMap.get("message")).replaceAll(""));
                    retValue = true;
                } else if (errorType.equals("missing")) {
                    addEntry(priority, "Missing", getCurrentFile().toString(), -1, currentAttributeMap.get("message"));
                    retValue = true;
                } else if (errorType.equals("invalidencoding")) {
                    addEntry(priority, "Incorrect policy files", getCurrentFile().toString(), -1,  currentAttributeMap.get("message"));
                    retValue = true;
                }
            }
        } catch (Exception ex) {
            log.debug("exception in endelement",ex);
            throw ex;
        }
        return retValue;
    }

    boolean characters (XMLStreamReader streamReader) {
        return false;
    }
}