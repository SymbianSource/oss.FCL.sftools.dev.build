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
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

/**
 * This Task searches the index.html files created by CMT and looks for the summary values at the
 * end of the file e.g. Files: 12 LOCphy: 137. and takes the info and places it in an XMl file ready
 * to be sent to diamonds. The Xml file is placed in the diamonds folder in the output folder and
 * these files are then sent to diamonds when the build is finished soall we have to do is create
 * the file in the correct folder.
 * 
 * <pre>
 * &lt;hlm:cmtmetadatainput   
 *             diamondsHeaderFileName="C:\brtaylor\1\diamonds_header.xml" 
 *             diamondsFooterFileName="C:\brtaylor\1\diamonds_footer.xml"
 *             outptuFile="Z:\output\diamonds/cmt_summary_componentName_1.xml/" 
 *             inputFile="Z:\output\logs/minibuild_ido_0.0.03_test_cmt_componentName1_cmt/CMTHTML/index.html/&gt;
 * </pre>
 * 
 * @ant.task name="cmtsummarytask" category="Quality"
 */

public class CMTSummaryTask extends Task {

    // The following 2 variables are indexes to the SEARCH_TERMS_ARRAY
    /** Index to the searched for text */
    private static final int INPUT_TEXT_INDEX = 0;
    /** Index to the text to write to the xml file */
    private static final int OUTPUT_ELEMENT_INDEX = 1;

    /**
     * this array contains the text to be searched for in the inputFile (1st element) and the text
     * to be written to the .xml output file (2nd element)
     */
    private static final String[][] SEARCH_TERMS_ARRAY = {
        // 1st elem 2nd elem
        { "Files:", "files" }, { "LOCphy:", "locphy" }, { "LOCbl:", "locbl" },
        { "LOCpro:", "locpro" }, { "LOCcom:", "loccom" }, { "v(G) :", "vg" },
        { "MI without comments  :", "mi_wo_comments" },
        { "MI comment weight    :", "mi_comment_weight" }, { "MI:", "mi" } };

    /** always accesses the 1st group of the matcher */
    private static int matcherGroupNum; // default init is 0

    /** indexes to the SEARCH_TERMS_ARRAY */
    private int arrayIndex;

    private int sizeArray = SEARCH_TERMS_ARRAY.length;

    /** the file containing the CMT summary data */
    private String inputFile;
    /** name of file to write the output to */
    private String outputFile;

    /** each line of the input file is read into this */
    private String line;
    /** the regex for a string of digits */
    private Pattern digitPattern = Pattern.compile("\\d+");

    /** file descriptor for the input file */
    private BufferedReader inputFileReader;

    /** file handler used to write the summary numbers to the output file **/
    private BufferedWriter output; // default init = null

    /** tells the main method whether it should be looking for digist or text */
    private boolean lineStartsWithDigits; // default init = false

    /**
     * file name of the default diamonds XML file header part (1st few lines) used so not writing
     * the XML text here
     */
    private String diamondsHeaderFileName;
    /**
     * file name of the default diamonds XML file footer part (last line) used so not writing the
     * XML text here
     */
    private String diamondsFooterFileName;

    /**
     * @param outputFile set the output file name
     * @ant.required
     */
    public void setOutputFile(String outputFile) {
        this.outputFile = outputFile;
    }

    /**
     * @return the outputFile the output file name
     */
    public String getOutputFile() {
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

    /** the main part of the code - the method that is called */
    public void execute() {
        log("CMTSummaryTask execute method with input file : " + inputFile, Project.MSG_ERR);
        boolean inputFileFound = true;
        BufferedReader diamondsHeaderFile;
        BufferedReader diamondsFooterFile;

        log("output File is " + getOutputFile(), Project.MSG_ERR);

        try {
            // open the file with the CMT results init
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
                output = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(getOutputFile()), "UTF8"));
            }
            catch (FileNotFoundException exc) {
                log("FileNotFoundException while getting the output file.  : " + getOutputFile()
                    + "   " + exc.getMessage(), Project.MSG_ERR);
            }
            catch (UnsupportedEncodingException exc) {
                // We are Ignoring the errors as no need to fail the build.
                log("UnsupportedEncodingException while creating the output file : "
                    + getOutputFile() + "   " + exc.getMessage(), Project.MSG_ERR);
            }
            catch (SecurityException exc) {
                // We are Ignoring the errors as no need to fail the build.
                log("SecurityException while creating the output file : " + getOutputFile() + "   "
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
                    output.write("    <cmt>\r\n");

                    // CheckStyle:InnerAssignment OFF
                    // process each of the searchterms
                    while ((arrayIndex < sizeArray)
                        && ((line = inputFileReader.readLine()) != null)) {
                        findTextAndOutput(); // read finput file and write the output
                    }
                    // CheckStyle:InnerAssignment ON

                    // write the end of file text
                    output.write("    </cmt>");
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
                        + getOutputFile() + "  " + exc.getMessage(), Project.MSG_ERR);
                }
                catch (IllegalArgumentException exc) {
                    // We are Ignoring the errors as no need to fail the build.
                    log("IllegalArgumentException : " + getdiamondsHeaderFileName()
                        + " output file =  " + getOutputFile() + "  " + exc.getMessage(), Project.MSG_ERR);
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
     * This is the function that performs the actual file searches and writes the number following
     * the searched for text to the output XML file
     */
    private void findTextAndOutput() {
        final int colonSkip = 2;
        byte[] lineBytes = null;
        int buffLen;
        int lineLen;
        int serchTermTextLen;
        int spacesLen;

        try {
            lineLen = line.length();
            while ((lineLen > 0) && (arrayIndex < sizeArray)) {
                // Process each of the groups of chars in a line
                if (line.startsWith(SEARCH_TERMS_ARRAY[arrayIndex][INPUT_TEXT_INDEX])) {
                    // Found the CMT data type we are looking for so look fo r the digits now
                    serchTermTextLen = SEARCH_TERMS_ARRAY[arrayIndex][INPUT_TEXT_INDEX].length();
                    buffLen = writeToOutput();
                    if ((buffLen > 0) && (arrayIndex < sizeArray)) {
                        // Skip over the digits so can get the next searchterm near start of line
                        line = line.substring(line.indexOf(':') + colonSkip + buffLen);
                        spacesLen = removeAnySpaces();
                        // Decrease line length for the while loop
                        lineLen = lineLen - (buffLen + serchTermTextLen + spacesLen);
                    }
                    else {
                        // Didn't find the digits so probably at the end of the line and the digits
                        // are on the next line
                        // Convert the line to bytes so we can check for a specific Character
                        lineBytes = line.getBytes("UTF-8");
                        int sbLen = lineBytes.length;
                        // The last real char (i.e. not the EOL) should be '=' if the digits are on
                        // the next line
                        if (lineBytes[sbLen - 1] == '=') {
                            // found the '=' so read the next line in
                            lineStartsWithDigits = true;
                            lineLen = 0;
                        }
                        else {
                            lineLen = 0;
                        }
                    }
                }
                else if (lineStartsWithDigits) { // probably got a line with digits on
                    buffLen = writeToOutput(); // definitely got a line with digits on
                    lineStartsWithDigits = false;
                    if ((buffLen > 0) && (arrayIndex < sizeArray)) {
                        // Now need to get rid of the digits and get to the next
                        // none digits char
                        line = line.substring(buffLen);
                        spacesLen = removeAnySpaces();
                        // decrease line length for the while loop
                        lineLen = lineLen - (buffLen + spacesLen);
                    }
                    else {
                        lineLen = 0;
                    }
                }
                else {
                    lineLen = 0;
                }
            }
        }
        catch (IOException exc) {
            log("IOException Error searching : " + exc.getMessage(), Project.MSG_ERR);
        }
    }

    private int writeToOutput() throws IOException {
        String buffer;
        int buffLen;

        Matcher componentMatch = digitPattern.matcher(line);
        if (componentMatch.find()) {
            // Found the digits after the search term
            buffer = componentMatch.group(matcherGroupNum);
            // Write the XML formated <files>nn</files> to the output file (plus the other)
            output.write("        <" + SEARCH_TERMS_ARRAY[arrayIndex][OUTPUT_ELEMENT_INDEX] + ">");
            output.write(buffer);
            output.write("</" + SEARCH_TERMS_ARRAY[arrayIndex++][OUTPUT_ELEMENT_INDEX] + ">");
            output.newLine();
            buffLen = buffer.length();
        }
        else {
            buffLen = 0;
            log("can't find digits may be '=' at end of line ", Project.MSG_ERR);
        }
        return buffLen;
    }

    private int removeAnySpaces() throws UnsupportedEncodingException {
        byte[] lineBytes;
        int num = 0;
        int len = line.length();
        // Convert the line to bytes so we can check for a specific Character
        lineBytes = line.getBytes("UTF-8");
        // While there are still spaces at the front of the line shuffle the line along to get rid
        // of them
        while ((lineBytes[num++] == ' ') && (len > 0)) {
            // Remove 1 space at front of line
            line = line.substring(1);
            len--;
        }
        return num;
    }
}
