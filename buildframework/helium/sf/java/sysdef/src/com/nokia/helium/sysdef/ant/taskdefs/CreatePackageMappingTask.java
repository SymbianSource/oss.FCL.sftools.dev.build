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
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import org.apache.tools.ant.types.DirSet;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.types.ResourceCollection;
import java.util.Hashtable;
import org.apache.tools.ant.DirectoryScanner;
import com.nokia.helium.sysdef.PackageMap;
import com.nokia.helium.sysdef.PackageMapParsingException;

/**
 * Create a ini file which stores the mapping between packages under a checked out
 * location and where they should be located under the environment.
 * 
 * Format of the generated file:
 * <pre>
 * #DO NOT EDIT - File generated automatically
 * #Thu Mar 25 15:52:03 EET 2010
 * source\\location\\of\\package=EPOCROOT\\root\\layer\\package
 * E\:\\scm\\package=E:\sdk\root\layer\package
 * </pre>
 * 
 * Example:
 * <pre>
 * &lt;hlm:createPackageMapping epocroot="E:\sdk" destFile="E:\sdk\mapping.ini" &gt;
 *     &lt;fileset dir="E:\scm" includes="&#42;&#42;/package_definition.xml"&gt;
 * &lt;/hlm:createPackageMapping&gt;
 * </pre>
 * <pre>
 * &lt;hlm:createPackageMapping epocroot="E:\sdk" destFile="E:\sdk\mapping.ini" 
 * filterDirSet="ado.filter.dir" &gt;
 *     &lt;fileset dir="E:\scm" includes="&#42;&#42;/package_definition.xml"&gt;
 * &lt;/hlm:createPackageMapping&gt;
 * </pre>
 * 
 * The outcome will be the mapping file E:\sdk\mapping.ini. 
 * 
 * @ant.task name="createPackageMapping" category="Sysdef"
 */
public class CreatePackageMappingTask extends Task {

    public static final String PACKAGE_DEFINITION_FILENAME = "package_definition.xml";
    public static final String PACKAGE_MAP_FILENAME = "package_map.xml";
    private List<ResourceCollection> resourceCollections = new ArrayList<ResourceCollection>();
    private boolean failOnError = true;

    private Map<File, File> pkgMapping = new HashMap<File, File>();
    private File epocroot;
    private File destFile;
    private String filteredDirSet;

    /**
     * Populate the pkgMapping based on the packages found.
     * @param pkgMapFile a pointer to a package map file.
     * @throws PackageMapParsingException 
     */
    protected void retrievePackageMapping(File pkgMapFile, List<File> filterDirs) throws PackageMapParsingException {
        PackageMap parser = new PackageMap(pkgMapFile);
        log("parent file: " + pkgMapFile.getParentFile(), Project.MSG_DEBUG);
        log("parent file: " + getEpocroot() + parser.getRoot() + "/" + parser.getLayer() +
                "/" + pkgMapFile.getParentFile().getName(), Project.MSG_DEBUG);
        if (filterDirs == null) {
            pkgMapping.put(pkgMapFile.getParentFile(), 
                    new File(getEpocroot(), parser.getRoot() + "/" + parser.getLayer() +
                        "/" + pkgMapFile.getParentFile().getName()));
        } else {
            for (File dir : filterDirs) {
                if (pkgMapFile.getParentFile().equals(dir)) {
                    pkgMapping.put(pkgMapFile.getParentFile(), 
                            new File(getEpocroot(), parser.getRoot() + "/" + parser.getLayer() +
                                "/" + pkgMapFile.getParentFile().getName()));
                    return;
                }
            }
        }
    }

    @SuppressWarnings("unchecked")
    protected List<File> getFilterDir() throws IOException {
        if (filteredDirSet != null) {
            Hashtable<String, Object> references = getProject().getReferences();
            Object filteredDirSetObject = references.get(filteredDirSet);
            if (filteredDirSetObject != null) {
                if (!(filteredDirSetObject instanceof DirSet)) {
                    throw new BuildException("filteredDirSet is not of type "
                            + "dirset");
                }
                List<File> fileList = new ArrayList<File>();
                DirSet dset = (DirSet)filteredDirSetObject;
                DirectoryScanner ds = dset.getDirectoryScanner(getProject());
                String[] includedFiles = ds.getIncludedDirectories();
                for (String file : includedFiles) {
                    fileList.add(new File(ds.getBasedir(), file));
                }
                return fileList;
            } else {
                throw new BuildException("Id '" + filteredDirSet + "' doesn't reference a type.");                
            }
        }
        return null;
    }
    /**
     * Generates the ini file.
     * @throws FileNotFoundException in case of missing file.
     * @throws IOException in case of error while generating the file.
     */
    @SuppressWarnings("unchecked")
    protected void createIniFile(File mappingFile) throws IOException {
        List<File> filterDirs = getFilterDir();
        for (ResourceCollection rc : resourceCollections) {
            Iterator<Resource> ri = (Iterator<Resource>)rc.iterator();
            while (ri.hasNext()) {
                Resource resource = ri.next();
                File pkgFile = new File(resource.toString()); // toString is representing the abs path
                log("Checking " + pkgFile.getName(), Project.MSG_DEBUG);
                if (pkgFile.getName().equalsIgnoreCase(PACKAGE_DEFINITION_FILENAME) 
                        && pkgFile.exists()) {
                    File pkgMapFile = new File(pkgFile.getParentFile(), 
                            PACKAGE_MAP_FILENAME);
                    log("Checking " + PACKAGE_MAP_FILENAME + " file: "
                            + pkgMapFile, Project.MSG_DEBUG);
                    if (pkgMapFile.exists()) {
                        log("Found package: " + pkgFile);
                        try {
                            retrievePackageMapping(pkgMapFile, filterDirs);
                        } catch (PackageMapParsingException e) {
                            log(e.getMessage(), Project.MSG_ERR);
                            if (shouldFailOnError()) {
                                throw new BuildException(e.getMessage(), e);
                            }
                        }
                    } else if (!(new File(pkgFile.getParentFile(),
                            "../../" + PACKAGE_MAP_FILENAME).exists())) {
                        log("Could not find: " + pkgMapFile.getAbsolutePath(), 
                                Project.MSG_ERR);
                        if (shouldFailOnError()) {
                            throw new BuildException("Package under "
                                    + pkgMapFile.getParent() +
                                    " is invalid because of the following missing file: "
                                    + pkgMapFile.getAbsolutePath());
                        }
                    }
                } else if (pkgFile.getName().equalsIgnoreCase(PACKAGE_DEFINITION_FILENAME)
                        && !pkgFile.exists()) {
                    log("Could not find package definition file: "
                            + pkgFile.getAbsolutePath(), Project.MSG_ERR);
                    if (shouldFailOnError()) {
                        throw new BuildException("Package under " + pkgFile.getParent() +
                                " is invalid because of the following missing file: " + pkgFile.getAbsolutePath());
                    }                    
                } else {
                    log("Ignoring file: " + pkgFile.getAbsolutePath(), Project.MSG_VERBOSE);
                }
            }
        }
        Properties properties = new Properties();
        for (File key : pkgMapping.keySet()) {
            log("Adding package mapping entry for: " + key.getAbsolutePath(), 
                    Project.MSG_DEBUG);
            String replacedKey = key.getAbsolutePath().replace('\\', '/');
            String replacedValue = 
                pkgMapping.get(key).getAbsolutePath().replace('\\', '/');
            properties.setProperty(replacedKey, 
                    replacedValue);
        }
        if (properties.isEmpty() && filteredDirSet != null) {
            log("Empty mapping after filtering (filter: " +
                    filteredDirSet + ")", Project.MSG_WARN);
        }
        log("Creating " + mappingFile);
        FileOutputStream fos = new FileOutputStream(mappingFile);
        properties.store(fos, "DO NOT EDIT - File generated automatically");
        fos.close();
    }
    
    /**
     * {@inheritDoc}
     */
    public void execute() {
        if (getEpocroot() == null) {
            throw new BuildException("The 'epocroot' attribute is not defined");
        }
        if (destFile == null) {
            throw new BuildException("The 'destFile' attribute is not defined");
        }
        
        try {
            createIniFile(destFile);
        } catch (FileNotFoundException e) {
            throw new BuildException("Error generating the output file: " + e.getMessage(), e);
        } catch (IOException e) {
            throw new BuildException("Error generating the output file: " + e.getMessage(), e);
        }
    }

    /**
     * Defines quality dir set location
     * @param qualityDir - directory fileset which needs to be compared
     * with sysdef path and map it for quality targets to use it.
     * @ant.required
     */
    public void setFilterDirSet(String filterDir) {
        filteredDirSet = filterDir;
    }
    
    /**
     * Defines epocroot location
     * @param epocroot
     * @ant.required
     */
    public void setEpocroot(File epocroot) {
        this.epocroot = epocroot;
    }

    /**
     * Get epocroot.
     * @return epocroot location
     */
    public File getEpocroot() {
        return epocroot;
    }

    /**
     * Shall the task fails in case of error.
     * @return
     */
    public boolean shouldFailOnError() {
        return failOnError;
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
     * Defines the location of the generated INI file.
     * @param destFile
     * @ant.required
     */
    public void setDestFile(File destFile) {
        this.destFile = destFile;
    }

    /**
     * Get the destFile.
     * @return the destination file wanted.
     */
    public File getDestFile() {
        return destFile;
    }
    
    /**
     * Support of nested resource collection like path or fileset.
     * Those nested element should define where to find the 
     * packages. 
     * @param resourceCollection
     */
    public void add(ResourceCollection resourceCollection) {
        resourceCollections.add(resourceCollection);
    }
}