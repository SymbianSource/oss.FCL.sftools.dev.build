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
 
package com.nokia.ant.conditions;

import org.apache.log4j.Logger;
import org.apache.tools.ant.ProjectComponent;
import org.apache.tools.ant.taskdefs.condition.Condition;

import java.util.Iterator;
import java.net.MalformedURLException;
import java.net.URL;

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.SAXReader;

/**
 * Condition to read check from diamonds and tell if ats has failed
 * @ant.type name="hasAtsPassed"
 */
public class AtsCondition extends ProjectComponent implements Condition
{
    private Logger log = Logger.getLogger(AtsCondition.class);
    private int sleeptimesecs = 60;
    
    public void setSleeptime(int seconds)
    {
        sleeptimesecs = seconds;
    }
    
    /** Read from diamonds and signal if ats failed */
    public boolean eval()
    {
        String bid = getProject().getProperty("diamonds.build.id");
        if (bid == null)
            log.info("Diamonds not enabled");
        else
        {
            boolean testsfound = false;
            log.info("Looking for tests in diamonds");
            SAXReader xmlReader = new SAXReader();
            
            while (!testsfound)
            {
                Document antDoc = null;
                
                try {
                    URL url = new URL("http://" + getProject().getProperty("diamonds.host") + bid + "?fmt=xml");
                    antDoc = xmlReader.read(url);
                } catch (MalformedURLException  e) {
                    // We are Ignoring the errors as no need to fail the build.
                    log.error("Not able to read the Diamonds URL http://" + getProject().getProperty("diamonds.host") + bid + "?fmt=xml: " + e.getMessage());
                } catch (DocumentException e) {
                    log.error("Not able to read the Diamonds URL http://" + getProject().getProperty("diamonds.host") + bid + "?fmt=xml: " + e.getMessage());
                }
                  
                for (Iterator iterator = antDoc.selectNodes("//test/failed").iterator(); iterator.hasNext();)
                {
                    testsfound = true;
                    Element element = (Element) iterator.next();
                    String failed = element.getText();
                    if (!failed.equals("0"))
                    {
                        log.error("ATS tests failed");
                        
                        for (Iterator iterator2 = antDoc.selectNodes("//actual_result").iterator(); iterator2.hasNext();)
                        {
                            Element resultElement = (Element) iterator2.next();
                            log.error(resultElement.getText());
                        }
                        return false;
                    }
                }
                
                int noofdrops = Integer.parseInt(getProject().getProperty("drop.file.counter"));
                if (noofdrops > 0)
                {
                    int testsrun = antDoc.selectNodes("//test").size();
                    if (testsrun < noofdrops)
                    {
                        log.info(testsrun + " test completed, " + noofdrops + " total");
                        testsfound = false;
                    }
                }
                if (!testsfound)
                {
                    log.info("Tests not found sleeping for " + sleeptimesecs + " seconds");
                    try {
                    Thread.sleep(sleeptimesecs * 1000);
                    } catch (InterruptedException e) {
                        // This will not affect the build process so ignoring.
                        log.debug("Interrupted while reading ATS build status " + e.getMessage());
                    }
                }
            }
        }
        return true;
    }
}