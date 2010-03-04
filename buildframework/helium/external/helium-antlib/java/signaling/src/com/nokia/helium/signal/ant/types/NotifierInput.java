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

 
package com.nokia.helium.signal.ant.types;


import java.io.File;
import java.util.List;
import java.util.ArrayList;
import java.util.Vector;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.FileSet;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.log4j.Logger;

/**
 * Helper class to store the signal notifier info.
 */
public class NotifierInput extends DataType
{

    private File file;

    //Different notifier could choose specific file
    private String pattern = ".html";

    private Vector<FileSet> fileSetList = new Vector<FileSet>();

    private Logger log = Logger.getLogger(this.getClass());

    /**
     * Adds the fileset (list of input log files to be processed).
     *  @param fileSet fileset to be added
     * 
     */
    public void add(FileSet fileSet) {
        fileSetList.add(fileSet);
    }   

    public File getFile() {
        return getFile(pattern);
    }
    
    /**
     * Return a file from the input fileset.
     *  @param pattern pattern to match from the input fileset
     *  @return the matched files including the base dir. 
     */
    public File getFile(String pattern) {
        File fileToReturn = null;
        if (file != null) {
            if (file.toString().matches(pattern)) {
                fileToReturn = file;
            }
            return fileToReturn;
        }
        for (FileSet fs : fileSetList) {
            DirectoryScanner ds = fs.getDirectoryScanner(getProject());
            String[] includedFiles = ds.getIncludedFiles();
            for ( String filePath : includedFiles ) {
                if (filePath.matches(pattern)) {
                    fileToReturn = new File(ds.getBasedir(), filePath);
                    log.debug("matched file for pattern: " + pattern + ":" + fileToReturn);
                    break;
                }
            }
        }
        return fileToReturn;
    }

    /**
     * Returns the list of filelist from the input fileset.
     *  @param pattern pattern to match from the input fileset
     *  @return the matched files including the base dir. 
     */
    public List<File> getFileList(String pattern) {
        List<File> fileList = new ArrayList<File>();
        for (FileSet fs : fileSetList) {
            DirectoryScanner ds = fs.getDirectoryScanner(getProject());
            String[] includedFiles = ds.getIncludedFiles();
            for ( String filePath : includedFiles ) {
                if (filePath.matches(pattern)) {
                    fileList.add(new File(ds.getBasedir(), filePath));
                }
            }
        }
        return fileList;
    }

    /**
     * Helper function called by ant to set the input file.
     * @param inputFile input file for notifier
     */
    public void setFile(File inputFile) {
        file = inputFile;
    }

    /**
     * Helper function called by ant to get the file
     * @return the input file for notifier.
     */
    public String getPattern() {
        return pattern ;
    }

    /**
     * Helper function called by ant to get the file
     * @return the input file for notifier.
     */
    public void setPattern(String ptn) {
        pattern = ptn;
    }
}