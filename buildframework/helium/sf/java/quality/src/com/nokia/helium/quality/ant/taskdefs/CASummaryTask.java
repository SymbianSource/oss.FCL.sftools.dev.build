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
import org.apache.tools.ant.BuildException;


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
    private static final String HEADER_EXPRESSION = "//issuelist/headerfile/issue/typeid/text()";

    /** String used to look for the tag values in the library xml file **/
    private static final String LIBRARY_EXPRESSION = "//issuelist/library/issue/typeid/text()";

    /**maximum number of typeIDs available for the library compare file*/
    private static final int MAX_NUM_TYPE_IDS = 15;
    
    /** 0 to 14 typeID modes, supplied by Satarupa Pal. Add this i=to the output information to diamonds*/
    private static final String[] TYPE_MODE = {
        "unknown",
        "removed",
        "added",
        "moved",
        "deleted",
        "inserted",
        "modified",
        "added",
        "modified",
        "modified",
        "modified",
        "modified",
        "modified",
        "removed",
        "not available"};

    /** 
    the BC library output file: xml paths required to retrieve the additional textual information.
    */
    private static final String[] SEARCH_PATHS = {
        "//issuelist/library/issue[typeid = \"0\"]/bc_severity/text()",
        "//issuelist/library/issue[typeid = \"1\"]/bc_severity/text()",
        "//issuelist/library/issue[typeid = \"2\"]/bc_severity/text()",
        "//issuelist/library/issue[typeid = \"3\"]/bc_severity/text()",
        "//issuelist/library/issue[typeid = \"4\"]/bc_severity/text()",
        "//issuelist/library/issue[typeid = \"5\"]/bc_severity/text()",
        "//issuelist/library/issue[typeid = \"6\"]/bc_severity/text()",
        "//issuelist/library/issue[typeid = \"7\"]/bc_severity/text()",
        "//issuelist/library/issue[typeid = \"8\"]/typeinfo/text()",
        "//issuelist/library/issue[typeid = \"9\"]/typeinfo/text()",
        "//issuelist/library/issue[typeid = \"10\"]/typeinfo/text()",
        "//issuelist/library/issue[typeid = \"11\"]/typeinfo/text()",
        "//issuelist/library/issue[typeid = \"12\"]/typeinfo/text()",
        "//issuelist/library/issue[typeid = \"13\"]/typeinfo/text()",
        "//issuelist/library/issue[typeid = \"14\"]/typeinfo/text()"};

    private boolean failOnError;            //init to default value false

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

    /**
     * Defines if the task should fail in case of error. 
     * @param failOnError
     * @ant.not-required Default true
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }
    
    /**
     * Shall we fail in case of issue.
     * @return
     */
    public boolean shouldFailOnError() {
        System.out.println(" failOnError = " + failOnError);
        return failOnError;
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
            if (shouldFailOnError()) {
                throw new BuildException(exc.getMessage(), exc);
            }
        }
        
        if (inputFileFound) {
            try {
                // write the title stuff for the XML diamonds schema
                output = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(getoutputFile()), "UTF8"));
            } catch (FileNotFoundException exc) {
                log("FileNotFoundException while getting the output file.  : " + getoutputFile()
                    + "   " + exc.getMessage(), Project.MSG_ERR);
                if (shouldFailOnError()) {
                    throw new BuildException(exc.getMessage(), exc);
                }
            } catch (UnsupportedEncodingException exc) {
                // We are Ignoring the errors as no need to fail the build.
                log("UnsupportedEncodingException while creating the output file : "
                    + getoutputFile() + "   " + exc.getMessage(), Project.MSG_ERR);
                if (shouldFailOnError()) {
                    throw new BuildException(exc.getMessage(), exc);
                }
            } catch (SecurityException exc) {
                // We are Ignoring the errors as no need to fail the build.
                log("SecurityException while creating the output file : " + getoutputFile() + "   "
                    + exc.getMessage(), Project.MSG_ERR);
                if (shouldFailOnError()) {
                    throw new BuildException(exc.getMessage(), exc);
                }
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
                        findHeaderTextAndOutput(HEADER_EXPRESSION); // read input file and write the output
                    } else {
                        output.write("    <quality aspect=\"compatibility-libs\"> \r\n");
                        // process each line
                        findLibTextAndOutput(LIBRARY_EXPRESSION); // read input file and write the output
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
                    if (shouldFailOnError()) {
                        throw new BuildException(exc.getMessage(), exc);
                    }
                }
                catch (IOException exc) {
                    // We are Ignoring the errors as no need to fail the build.
                    log("IOException : " + getdiamondsHeaderFileName() + " output file =  "
                        + getoutputFile() + "  " + exc.getMessage(), Project.MSG_ERR);
                    if (shouldFailOnError()) {
                        throw new BuildException(exc.getMessage(), exc);
                    }
                }
                catch (IllegalArgumentException exc) {
                    // We are Ignoring the errors as no need to fail the build.
                    log("IllegalArgumentException : " + getdiamondsHeaderFileName()
                        + " output file =  " + getoutputFile() + "  " + exc.getMessage(), Project.MSG_ERR);
                    if (shouldFailOnError()) {
                        throw new BuildException(exc.getMessage(), exc);
                    }
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
    class for recording the number of occurances of a typeID for the library comparison output.
    */
    private class HeaderInfo {
        private int typeId;
        private long numOccurances;

        /**
         * @param typeId the type ID of the issue
         * @ant.required
         */
        private void settypeId(int typeId) {
            this.typeId = typeId;
        }
    
        /**
         * @return the typeID
         */
        private int gettypeId() {
            return typeId;
        }

        /**
         * @param numOccurances the number of times the type ID appears in the output file
         * @ant.required
         */
        public void setnumOccurances(long numOccurances) {
            this.numOccurances = numOccurances;
        }
    
        /**
         * @return the number of occurrance of the typeID
         */
        public long getnumOccurances() {
            return numOccurances;
        }
    }


    /**
     * This is the function that performs the actual file searches and writes the number of occurances
     * of each typeID to the output xml file
     */
    private void findHeaderTextAndOutput(String expression) {
        String value;
         
        /** place to store the number of typeids found */
        HeaderInfo[] headerinf = new HeaderInfo[MAX_NUM_TYPE_IDS];
        int tempKey;

        //initialise the array of typeIDs
        int sizevar = headerinf.length;
        for (int i = 0; i < MAX_NUM_TYPE_IDS; i++) {
            headerinf[i] = new HeaderInfo();
            headerinf[i].typeId = i;
            headerinf[i].numOccurances = 0;
        }
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
            //and scan through the list
            for (int i = 0; i < nodeList.getLength(); i++) {
                value = nodeList.item(i).getNodeValue();      //get the value as a string from the xml file
                tempKey = Integer.parseInt(value);            //convert it to an integer
                if (tempKey < MAX_NUM_TYPE_IDS) {
                    headerinf[tempKey].numOccurances++;       //increase the number of occurances
                } else {
                    log("tempKey out of range");
                }
            }
    
            boolean noErrors = true;                        //so we print something when no data present
            for (int i = 0; i < MAX_NUM_TYPE_IDS; i++)         //typeIDS 1 to 14
            {
                if (headerinf[i].numOccurances != 0) {
                    noErrors = false;
                    String headSearchPath = "//issuelist/headerfile/issue[typeid = \"" + i + "\"]/typestring/text()";
                    //XPath object created compiles the XPath expression: 
                    XPathExpression typeInfoExpr = xpath.compile(headSearchPath);
                    //expression is evaluated with respect to a certain context node which is doc.
                    Object typeInfoResult = typeInfoExpr.evaluate(doc, XPathConstants.NODESET);
                    NodeList typeInfoNodeList = (NodeList) typeInfoResult;
                    output.write("        <summary message=\"typeID:" + headerinf[i].typeId + 
                        ":" + typeInfoNodeList.item(0).getNodeValue() + ":occurs \" value=\"" + headerinf[i].numOccurances + "\"/> \r\n");
                }
            }
            if (noErrors) {
                output.write("        <summary message=\"number of errors present \" value=\"0\"/> \r\n");
            }
        } catch (ParserConfigurationException err) {
            log("Error: ParserConfigurationException: trying to parse xml file ", Project.MSG_ERR);
            if (shouldFailOnError()) {
                throw new BuildException(err.getMessage(), err);
            }
        } catch (SAXException err) {
            log("Error: SAXException: trying to parse xml file ", Project.MSG_ERR);
            if (shouldFailOnError()) {
                throw new BuildException(err.getMessage(), err);
            }
        } catch (XPathExpressionException err) {
            log("Error: XPathExpressionException: trying to parse xml file ", Project.MSG_ERR);
            if (shouldFailOnError()) {
                throw new BuildException(err.getMessage(), err);
            }
        } catch (IOException err) {
            log("Error: IOException: trying to parse xml file ", Project.MSG_ERR);
            if (shouldFailOnError()) {
                throw new BuildException(err.getMessage(), err);
            }
        }
    }
    
    /** 
    class for recording the number of occurances of a typeID for the library comparison output.
    */
    private class LibraryInfo {
        private int typeId;
        private long numOccurances;

        /**
         * @param typeId the type ID of the issue
         * @ant.required
         */
        private void settypeId(int typeId) {
            this.typeId = typeId;
        }
    
        /**
         * @return the typeID
         */
        private int gettypeId() {
            return typeId;
        }

        /**
         * @param numOccurances the number of times the type ID appears in the output file
         * @ant.required
         */
        public void setnumOccurances(long numOccurances) {
            this.numOccurances = numOccurances;
        }
    
        /**
         * @return the number of occurrance of the typeID
         */
        public long getnumOccurances() {
            return numOccurances;
        }
    }

    /**
     * This is the function that performs the actual file searches and writes the number of occurances
     * of each typeID to the output xml file
     */
    private void findLibTextAndOutput(String expression) {

        String value;
         
        /** place to store the number of typeids found */
        LibraryInfo[] libraryinf = new LibraryInfo[MAX_NUM_TYPE_IDS];
        int tempKey;

        //initialise the array of typeIDs
        int sizevar = libraryinf.length;
        for (int i = 0; i < MAX_NUM_TYPE_IDS; i++) {
            libraryinf[i] = new LibraryInfo();
            libraryinf[i].typeId = i;
            libraryinf[i].numOccurances = 0;
        }
        
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
            //create a node list
            NodeList nodeList = (NodeList) result;
            //and scan through the list
            for (int i = 0; i < nodeList.getLength(); i++) {
                value = nodeList.item(i).getNodeValue();      //get the value as a string from the xml file
                tempKey = Integer.parseInt(value);            //convert it to an integer
                if (tempKey < MAX_NUM_TYPE_IDS) {
                    libraryinf[tempKey].numOccurances++;         //increase the number of occurances
                } else {
                    log("tempKey out of range");
                }
            }
    
            boolean noErrors = true;                      //so we print something when no data present
            for (int i = 1; i < MAX_NUM_TYPE_IDS; i++) {        //typeIDS 1 to 14
                if (libraryinf[i].numOccurances != 0) {
                    noErrors = false;
                    //XPath object created compiles the XPath expression: 
                    XPathExpression typeInfoExpr = xpath.compile(SEARCH_PATHS[i]);
                    //expression is evaluated with respect to a certain context node which is doc.
                    Object typeInfoResult = typeInfoExpr.evaluate(doc, XPathConstants.NODESET);
                    NodeList typeInfoNodeList = (NodeList) typeInfoResult;
                    output.write("        <summary message=\"typeID:" + libraryinf[i].typeId + ":mode:" + TYPE_MODE[i] + 
                        ":" + typeInfoNodeList.item(0).getNodeValue() + ":occurs \" value=\"" + libraryinf[i].numOccurances + "\"/> \r\n");
                }
            }
            if (noErrors) {
                output.write("        <summary message=\"number of errors present \" value=\"0\"/> \r\n");
            }
        } catch (XPathExpressionException err) {
            log("Error: XPathExpressionException: trying to parse xml file ", Project.MSG_ERR);
            if (shouldFailOnError()) {
                throw new BuildException(err.getMessage(), err);
            }
        } catch (ParserConfigurationException err) {
            log("Error: ParserConfigurationException: trying to parse xml file ", Project.MSG_ERR);
            if (shouldFailOnError()) {
                throw new BuildException(err.getMessage(), err);
            }
        } catch (SAXException err) {
            log("Error: SAXException: trying to parse xml file ", Project.MSG_ERR);
            if (shouldFailOnError()) {
                throw new BuildException(err.getMessage(), err);
            }
        } catch (IOException err) {
            log("Error: IOException: trying to parse xml file ", Project.MSG_ERR);
            if (shouldFailOnError()) {
                throw new BuildException(err.getMessage(), err);
            }
        }
    }

}
