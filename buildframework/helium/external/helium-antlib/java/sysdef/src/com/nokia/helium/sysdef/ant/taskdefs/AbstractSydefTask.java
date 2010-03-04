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
package com.nokia.helium.sysdef.ant.taskdefs;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Map;

import javax.xml.transform.ErrorListener;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

/**
 * This is the base class for manipulating Sysdef v3 files using XML Stylesheet. 
 * The implementation/interface is not frozen yet. It is morelikely going to
 * change in the future, depending of the underlaying implementation.
 * 
 */
public abstract class AbstractSydefTask extends Task implements ErrorListener {

    private File srcFile;
    private File destFile;
    private File epocroot;
    private boolean failOnError = true;
    
    /**
     * Get the source file.
     * @return
     */
    public File getSrcFile() {
        return srcFile;
    }

    /**
     * Defines the location of the source system definition file. 
     * @param srcfile
     * @ant.required
     */
    public void setSrcFile(File srcfile) {
        this.srcFile = srcfile;
    }

    /**
     * Get the location of the output file. 
     * @return
     */
    public File getDestFile() {
        return destFile;
    }

    /**
     * The the name of the destination file.
     * @param destfile
     * @ant.required
     */
    public void setDestFile(File destfile) {
        this.destFile = destfile;
    }

    /**
     * Get the epocroot.
     * If epocroot is not set by the user it return the value from the EPOCROOT environment variable.
     * If the EPOCROOT environment variable is not defined then a BuildException is thrown.
     * @return the epocroot location as a File object.
     */
    public File getEpocroot() {
        if (epocroot == null) {
            if (System.getenv("EPOCROOT") != null) {
                return new File(System.getenv("EPOCROOT"));
            }
            else {
                throw new BuildException("'epocroot' attribute has not been defined.");
            }
        }
        return epocroot;
    }

    /**
     * Location of the EPOCROOT.
     * @ant.not-required By default the EPOCROOT environment variable is used.
     * @param epocroot path to the epocroot.
     */
    public void setEpocroot(File epocroot) {
        this.epocroot = epocroot;
    }

    /**
     * Shall we fail the build on error.
     * @return is the task should failonerror.
     */
    public boolean isFailOnError() {
        return failOnError;
    }

    /**
     * Defines if the file should fail on error.
     * @param failonerror
     * @ant.not-required Default is true.
     */
    public void setFailOnError(boolean failonerror) {
        this.failOnError = failonerror;
    }

    /**
     * This method should be defined by the implementing class
     * to define the location of the XSLT file.
     * @return the XSLT file location.
     */
    abstract File getXsl();
    
    /**
     * Check if required attribute have been configured correctly.
     * If not the method will raise a BuildException.
     */
    protected void check() {
        if (srcFile == null) {
            throw new BuildException("'srcfile' attribute is not defined");
        }
        if (destFile == null) {
            throw new BuildException("'destfile' attribute is not defined");
        }
        File xslt = getXsl();
        if (!xslt.exists()) {
            throw new BuildException("Could not find " + xslt);
        }        
        if (!srcFile.exists()) {
            throw new BuildException("Could not find source file " + srcFile);
        }        
    }
    
    /**
     * Transform the srcfile using the stylesheet provided by getXsl. The data parameters are
     * passed to the template engine. The result is save to the destfile.
     * 
     * @param data a set of key/value to pass to the XSLT engine.
     */
    public void transform(Map<String, String> data) {
        check();
        if (destFile.exists()) {
            log("Deleting previous output file: " + destFile, Project.MSG_DEBUG);
            destFile.delete();
        }
        
        FileOutputStream output = null;        
        try {
            output = new FileOutputStream(destFile);
            TransformerFactory factory = TransformerFactory.newInstance();
            Transformer transformer = factory.newTransformer(new StreamSource(getXsl()));

            transformer.setParameter("path", srcFile);
            for (Map.Entry<String, String> entry : data.entrySet()) {
                transformer.setParameter(entry.getKey(), entry.getValue());
            }
            transformer.setErrorListener(this);        
            transformer.transform(new StreamSource(srcFile), new StreamResult(
                    output));
        
        } catch (Exception exc) {
            // deleting the intermediate file in case of error.
            if (destFile.exists()) {
                // closing current output stream, so we can delete the file
                try {
                    if (output != null) {
                        output.close();
                    }
                } catch (IOException ioe) {
                    // we should just ignore that error.
                    log(ioe, Project.MSG_DEBUG);
                }
                log("Deleting " + destFile + " because an error occured.", Project.MSG_INFO);
                destFile.delete();
            }
            // Raising the error to Ant.
            throw new BuildException(exc.toString());
        }
    }

    /**
     * {@inheritDoc}
     * Reports errors to the Ant logging system of throw the exception if the task
     * is set to failonerror.
     */
    @Override
    public void error(TransformerException message) throws TransformerException {
        if (this.isFailOnError()) {
            throw message;
        } else {
            log("ERROR: " + message.getMessageAndLocation(), Project.MSG_ERR);            
        }
    }

    /**
     * {@inheritDoc}
     * Fails the task in case of fatal error. The is nothing we can do about that.
     */
    @Override
    public void fatalError(TransformerException message) throws TransformerException {
        log("ERROR: " + message.getMessageAndLocation(), Project.MSG_ERR);
        throw message;
    }

    /**
     * {@inheritDoc}
     * Reports errors to the Ant logging system of throw the exception if the task
     * is set to failonerror.
     */
    @Override
    public void warning(TransformerException message) throws TransformerException {
        if (this.isFailOnError()) {
            throw message;
        } else {
            log("WARNING: " + message.getMessageAndLocation(), Project.MSG_WARN);
        }
    }
}
