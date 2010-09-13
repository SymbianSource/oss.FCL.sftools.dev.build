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

package com.nokia.helium.quality.ant.taskdefs;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.SortedSet;
import java.util.TreeSet;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import java.io.FileReader;
import javax.xml.xpath.XPath;
import org.w3c.dom.NodeList;
import org.w3c.dom.Document;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPathFactory;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import org.xml.sax.SAXException;


/**
 * This Task searches the bc_header.xml and bc_library.xml files created by Binary Comparison and 
 * looks for the typeIds and counts them up. It then prints them in order to write the number of each 
 * typeID that was found to the diamonds output file for display by diamonds.
 * 
 * <pre>
 * &lt;hlm:casummarytask   
 *             header="true"
 *             diamondsHeaderFileName="C:\diamonds_header.xml" 
 *             diamondsFooterFileName="C:\diamonds_footer.xml"
 *             outptuFile="Z:\output\diamonds/ca_summary_header.xml" 
 *             inputFile="Z:\output\logs/headers_report_minibuild_ido_0.0.03_.xml/&gt;
 * </pre>
 * 
 * @ant.task name="casummarytask" category="Quality"
 */

public class CASummaryTask extends Task {

    /** String used to look for the tag values in the header xml file **/
    private static String headerExpression = "//issuelist/headerfile/issue/typeid/text()";

    /** String used to look for the tag values in the library xml file **/
    private static String libraryExpression = "//issuelist/library/issue/typeid/text()";

    /** The file containing the CA summary data */
    private String inputFile;
    /** Name of file to write the output to */
    private String outputFile;
    /** Whether we are dealng with a header or library */
    private boolean header;

    /** Each line of the input file is read into this */
    private String line;

    /** File descriptor for the input file */
    private BufferedReader inputFileReader;

    /** File handler used to write the summary numbers to the output file **/
    private BufferedWriter output; // default init = null

    /**
     * File name of the default diamonds XML file header part (1st few lines) used so not writing
     * the XML text here
     */
    private String diamondsHeaderFileName;
    /**
     * File name of the default diamonds XML file footer part (last line) used so not writing the
     * XML text here
     */
    private String diamondsFooterFileName;

    /**
     * @param outputFile set the output file name
     * @ant.required
     */
    public void setoutputFile(String outputFile) {
        this.outputFile = outputFile;
    }

    /**
     * @return the outputFile the output file name
     */
    public String getoutputFile() {
        return outputFile;
    }

    /**
     * @return the inputFile
     */
    public String getinputFile() {
        return inputFile;
    }

    /**
     * @param inputFile the name of file to scan and extract data from
     * @ant.required
     */
    public void setinputFile(String inputFile) {
        this.inputFile = inputFile;
    }

    /**
     * @param diamondsFooterFileName set the diamonds footer file name
     * @ant.required
     */
    public void setdiamondsFooterFileName(String diamondsFooterFileName) {
        this.diamondsFooterFileName = diamondsFooterFileName;
    }

    /**
     * @return the diamondsFooterFileName the diamonds footer file name
     */
    public String getdiamondsFooterFileName() {
        return diamondsFooterFileName;
    }

    /**
     * @param diamondsHeaderFileName set the diamonds header file name
     * @ant.required
     */
    public void setdiamondsHeaderFileName(String diamondsHeaderFileName) {
        this.diamondsHeaderFileName = diamondsHeaderFileName;
    }

    /**
     * @return the diamondsFooterFileName the diamonds footer file name
     */
    public String getdiamondsHeaderFileName() {
        return diamondsHeaderFileName;
    }
    
    /**
     * @param header set whether we are dealing with a headers or libraries
     * @ant.required
     */
    public void setheader(boolean header) {
        this.header = header;
    }

    /**
     * @return the fileType whether we are dealing with headers or libraries
     */
    public boolean getheader() {
        return header;
    }

    /** the main part of the code - the method that is called */
    public void execute() {
        log("CASummaryTask execute method with input file : " + inputFile, Project.MSG_ERR);
        boolean inputFileFound = true;
        BufferedReader diamondsHeaderFile;
        BufferedReader diamondsFooterFile;

        log("output File is " + getoutputFile(), Project.MSG_ERR);

        try {
            // open the file with the CA results init
            inputFileReader = new BufferedReader(new FileReader(inputFile));
        }
        catch (FileNotFoundException exc) {
            log("FileNotFoundException while getting the input file.  : " + inputFile + "  "
                + exc.getMessage(), Project.MSG_ERR);
            inputFileFound = false; // stops an empty output file being created.
        }
        if (inputFileFound) {
            try {
                // write the title stuff for the XML diamonds schema
                output = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(getoutputFile()), "UTF8"));
            }
            catch (FileNotFoundException exc) {
                log("FileNotFoundException while getting the output file.  : " + getoutputFile()
                    + "   " + exc.getMessage(), Project.MSG_ERR);
            }
            catch (UnsupportedEncodingException exc) {
                // We are Ignoring the errors as no need to fail the build.
                log("UnsupportedEncodingException while creating the output file : "
                    + getoutputFile() + "   " + exc.getMessage(), Project.MSG_ERR);
            }
            catch (SecurityException exc) {
                // We are Ignoring the errors as no need to fail the build.
                log("SecurityException while creating the output file : " + getoutputFile() + "   "
                    + exc.getMessage(), Project.MSG_ERR);
            }

            if (output != null) {
                // managed to open the output file
                try {
                    // write the initial XML text to the file
                    String tempLine;
                    diamondsHeaderFile = null;
                    diamondsHeaderFile = new BufferedReader(new FileReader(getdiamondsHeaderFileName()));
                    while ((tempLine = diamondsHeaderFile.readLine()) != null) {
                        output.write(tempLine);
                        output.newLine();
                    }
                    diamondsHeaderFile.close();
                    boolean tempheader = getheader();
                    if (tempheader) {
                        output.write("    <quality aspect=\"compatibility-headers\"> \r\n");
                        // process each line
                        findTextAndOutput(headerExpression); // read input file and write the output
                    } else {
                        output.write("    <quality aspect=\"compatibility-libs\"> \r\n");
                        // process each line
                        findTextAndOutput(libraryExpression); // read input file and write the output
                    }

                    // write the end of file text
                    output.write("    </quality>");
                    output.newLine();

                    diamondsFooterFile = null;
                    diamondsFooterFile = new BufferedReader(new FileReader(getdiamondsFooterFileName()));
                    while ((tempLine = diamondsFooterFile.readLine()) != null) {
                        output.write(tempLine);
                        output.newLine();
                    }
                    output.close(); // close the output file
                    diamondsFooterFile.close();
                }
                catch (FileNotFoundException exc) {
                    log("FileNotFoundException while getting the diamonds header file : "
                        + getdiamondsHeaderFileName() + "   " + exc.getMessage(), Project.MSG_ERR);
                }
                catch (IOException exc) {
                    // We are Ignoring the errors as no need to fail the build.
                    log("IOException : " + getdiamondsHeaderFileName() + " output file =  "
                        + getoutputFile() + "  " + exc.getMessage(), Project.MSG_ERR);
                }
                catch (IllegalArgumentException exc) {
                    // We are Ignoring the errors as no need to fail the build.
                    log("IllegalArgumentException : " + getdiamondsHeaderFileName()
                        + " output file =  " + getoutputFile() + "  " + exc.getMessage(), Project.MSG_ERR);
                }
            }
            else {
                log("Error: no output File available ", Project.MSG_ERR);
            }
        }
        else {
            log("Error: no input File available ", Project.MSG_ERR);
        }
    }

    /**
     * This is the function that performs the actual file searches and writes the number of occurances
     * of each typeID to the output xml file
     */
    private void findTextAndOutput(String expression) {
        String value;
        Integer count;
        /** place to store the number of typeids found */
        Hashtable<Integer, Integer> typeIds = new Hashtable<Integer, Integer>();
        int tempKey;
        int tempVal;
        
        try {
            DocumentBuilderFactory docFactory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = docFactory.newDocumentBuilder();
            Document doc = builder.parse(getinputFile());
    
            //creating an XPathFactory:
            XPathFactory factory = XPathFactory.newInstance();
            //using this factory to create an XPath object: 
            XPath xpath = factory.newXPath();
            //XPath object created compiles the XPath expression: 
            XPathExpression expr = xpath.compile(expression);
    
            //expression is evaluated with respect to a certain context node which is doc.
            Object result = expr.evaluate(doc, XPathConstants.NODESET);
            NodeList nodeList = (NodeList) result;
            for (int i = 0; i < nodeList.getLength(); i++) {
                value = nodeList.item(i).getNodeValue();    //get the value as a string from the xml file
                tempKey = Integer.parseInt(value);          //convert it to an integer so they can be sorted
                if (!typeIds.containsKey(tempKey)) {        //see if the typeID is already present in the hashtable
                    typeIds.put(tempKey, 0);                //it's not so create it (stops null pointer exceptions)
                }
                count = typeIds.get(tempKey);               //get the current count of this typeID
                count++;                                    //inc the count
                typeIds.put(tempKey, count);                //write it back to the hashtable
            }
            
            //now sort and write to xml file
            SortedSet<Integer> sortedset = new TreeSet<Integer>(typeIds.keySet());
            Iterator<Integer> sorted = sortedset.iterator();
            while (sorted.hasNext()) {      //go through each one on the file and write to xml output file
                tempVal = sorted.next();
                output.write("        <summary message=\"type ID " + tempVal + " occurs \" value=\"" + typeIds.get(tempVal) + "\"/> \r\n");
            }
        } catch (ParserConfigurationException err) {
            log("Error: ParserConfigurationException: trying to parse xml file ", Project.MSG_ERR);
        } catch (SAXException err) {
            log("Error: SAXException: trying to parse xml file ", Project.MSG_ERR);
        } catch (XPathExpressionException err) {
            log("Error: XPathExpressionException: trying to parse xml file ", Project.MSG_ERR);
        } catch (IOException err) {
            log("Error: IOException: trying to parse xml file ", Project.MSG_ERR);
        }
    }

}
