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
import java.io.OutputStreamWriter;
import java.io.StringWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.types.ResourceCollection;

import com.nokia.helium.sysdef.PackageDefinition;
import com.nokia.helium.sysdef.PackageDefinitionParsingException;
import com.nokia.helium.sysdef.PackageMap;
import com.nokia.helium.sysdef.PackageMapParsingException;

import freemarker.cache.ClassTemplateLoader;
import freemarker.cache.FileTemplateLoader;
import freemarker.template.Configuration;
import freemarker.template.Template;
import freemarker.template.TemplateException;

/**
 * Create a root System Definition file based on a set of package_definition.xml 
 * file. All package must also have a package_data.xml file in order to retrieve
 * the root and the layer location of the package.
 *
 * Example:
 * <pre>
 * &lt;hlm:createRootSysdef epocroot="E:\sdk" destFile="E:\sdk\sysdef_root.xml" &gt;
 *     &lt;fileset dir="E:\sdk" includes="root/&#42;&#42;/package_definition.xml"&gt;
 * &lt;/hlm:createRootSysdef&gt;
 * </pre>
 *
 * @ant.task name="createRootSysdef" category="Sysdef"
 */
public class CreateRootSysdefTask extends Task {

    private File destFile;
    private List<ResourceCollection> resourceCollections = new ArrayList<ResourceCollection>(); 
    private Map<String, Map<String, List<Map<String, Object>>>> roots = new HashMap<String, Map<String, List<Map<String, Object>>>>();
    private Map<String, List<String>> layers = new HashMap<String, List<String>>();
    private File epocroot;
    private boolean failOnError = true;
    private boolean checkPackageExists;
    private File template;
    private String idNamespace;

    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public void execute() {
        if (getEpocroot() == null) {
            throw new BuildException("epocroot attribute has not been set.");
        }
        if (getDestFile() == null) {
            throw new BuildException("destFile attribute has not been set.");
        }
        if ((File.separatorChar == '/' && !getDestFile().getAbsolutePath().startsWith(getEpocroot().getAbsolutePath()))
                || (File.separatorChar == '\\' 
                    && !getDestFile().getAbsolutePath().toLowerCase().startsWith(getEpocroot().getAbsolutePath().toLowerCase()))) {
            throw new BuildException(getDestFile().getAbsolutePath() + " must be under " + getEpocroot().getAbsolutePath());
        }
        for (ResourceCollection rc : resourceCollections) {
            Iterator<Resource> ri = (Iterator<Resource>)rc.iterator();
            while (ri.hasNext()) {
                Resource resource = ri.next();
                File pkgDefFile = new File(resource.toString());
                log("Package definition file: " + pkgDefFile);
                if (!pkgDefFile.exists() || 
                        !(pkgDefFile.getName().equalsIgnoreCase(
                                CreatePackageMappingTask.PACKAGE_DEFINITION_FILENAME))) {
                    throw new BuildException("Missing Package Definition file");
                }
                File pkgDir = pkgDefFile.getParentFile();
                File pkgMapFile  = new File(pkgDir, CreatePackageMappingTask.PACKAGE_MAP_FILENAME);
                try {
                    if (pkgMapFile.exists()) {
                        log("Package map file: " + pkgMapFile);
                        if (!checkPackageExists) {
                            addPackage(pkgDefFile, pkgMapFile, pkgDir.getName());
                        } else {
                            PackageMap pkgMap = new PackageMap(pkgMapFile);
                            File destPkg = new File(epocroot, pkgMap.getRoot() + File.separator +
                                    pkgMap.getLayer() + File.separator + pkgDir.getName() + File.separator +
                                    CreatePackageMappingTask.PACKAGE_DEFINITION_FILENAME);
                            if (destPkg.exists()) {
                                addPackage(pkgDefFile, pkgMapFile, pkgDir.getName());
                            } else {
                                log("Could not find " + destPkg.getAbsolutePath() +
                                        " so entry is not added to the root system definition.", Project.MSG_ERR);
                            }
                        }
                    } else {
                        pkgMapFile = new File(pkgDir.getParentFile().getParentFile(), CreatePackageMappingTask.PACKAGE_MAP_FILENAME);
                        log("Package map file: " + pkgMapFile);
                        if (pkgMapFile.exists()) {
                            if (!checkPackageExists) {
                                // slash must be use to generate correct path.
                                addPackage(pkgDefFile, pkgMapFile, pkgMapFile.getParentFile().getName() + "/" +
                                        pkgDir.getParentFile().getName() + "/" + pkgDir.getName());
                            } else {
                                PackageMap pkgMap = new PackageMap(pkgMapFile);
                                File destPkg = new File(epocroot, pkgMap.getRoot() + File.separator +
                                        pkgMap.getLayer() + File.separator +
                                        pkgMapFile.getParentFile().getName() + File.separator +
                                        pkgDir.getParentFile().getName() + File.separator + pkgDir.getName() +
                                        File.separator +
                                        CreatePackageMappingTask.PACKAGE_DEFINITION_FILENAME);
                                if (destPkg.exists()) {
                                    addPackage(destPkg, pkgMapFile, pkgMapFile.getParentFile().getName() + "/" +
                                            pkgDir.getParentFile().getName() + "/" + pkgDir.getName());
                                } else {
                                    log("Could not find " + destPkg.getAbsolutePath() +
                                            " so entry is not added to the root system definition.", Project.MSG_ERR);
                                }
                            }
                        } else {
                            log("Could not find package_map.xml file for " + pkgDefFile.toString(), Project.MSG_ERR);
                            if (shouldFailOnError()) {
                                throw new BuildException("Could not find package_map.xml file for " + pkgDefFile.toString());
                            }
                        }
                    }
                } catch (PackageMapParsingException e) {
                    log("Invalid " + CreatePackageMappingTask.PACKAGE_MAP_FILENAME 
                            + " file: " + pkgMapFile.toString() 
                            + "(" + e.getMessage() + ")", Project.MSG_ERR);
                    if (shouldFailOnError()) {
                        throw new BuildException(e.getMessage(), e);
                    }
                } catch (PackageDefinitionParsingException e) {
                    log("Invalid " + CreatePackageMappingTask.PACKAGE_DEFINITION_FILENAME 
                            + "(" + e.getMessage() + ")", Project.MSG_ERR);
                    if (shouldFailOnError()) {
                        throw new BuildException(e.getMessage(), e);
                    }
                }
                    
            }
        }
        generateRootSysdef();
    }

    private void addPackage(File pkgDefinition, File pkgMapFile, String pkgPath) throws
        PackageMapParsingException, PackageDefinitionParsingException {
        // Some quick validity checking. 
        PackageDefinition pkg = new PackageDefinition(pkgDefinition);
        if (idNamespace == null && (pkg.getIdNamespace() != null && pkg.getIdNamespace().length() > 0)) {
            idNamespace = pkg.getIdNamespace();
        } else if (idNamespace != null && !idNamespace.equals(pkg.getIdNamespace())) {
            log("Warning: " + pkgDefinition.toString() +
                    " namespace doesn't match the default one. (" 
                    + idNamespace + " != " + pkg.getIdNamespace(), Project.MSG_WARN);
        }
            
        // Adding the package in the structure.
        log("Adding: " + pkgMapFile, Project.MSG_DEBUG);
        PackageMap pkgMap = new PackageMap(pkgMapFile);
        if (!roots.containsKey(pkgMap.getRoot())) {
            roots.put(pkgMap.getRoot(), new HashMap<String, List<Map<String, Object>>>());
        }
        if (!roots.get(pkgMap.getRoot()).containsKey(pkgMap.getLayer())) {
            roots.get(pkgMap.getRoot()).put(pkgMap.getLayer(), new ArrayList<Map<String, Object>>());
            layers.put(pkgMap.getLayer(), new ArrayList<String>());
        }
        Map<String, Object> data = new HashMap<String, Object>();
        data.put("path", pkgPath);
        data.put("id", pkg.getId());
        data.put("namespaces", pkg.getNamespaces());
        roots.get(pkgMap.getRoot()).get(pkgMap.getLayer()).add(data);
        layers.get(pkgMap.getLayer()).add(pkgPath);
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
     * Get the destination file.
     * @return the dest file.
     */
    public File getDestFile() {
        return destFile;
    }

    /**
     * Get epocroot.
     * @return epocroot location
     */
    public File getEpocroot() {
        return epocroot;
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
        return failOnError;
    }

    /**
     * Defines if the task should check the existence of the 
     * target package_definition.xml under epocroot.
     * @param checkPackageExists
     * @ant.not-required Default false
     */
    public void setCheckPackageExists(boolean checkPackageExists) {
        this.checkPackageExists = checkPackageExists;
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

    /**
     * Defines a custom Freemarker template to generate the root sysdef file.
     * @param template
     * @ant.not-required
     */
    public void setTemplate(File template) {
        this.template = template;
    }

    /**
     * Get the template location.
     * @return
     */
    public File getTemplate() {
        return template;
    }

    /**
     * Generate the a root sysdef file based on the discovered package. 
     */
    protected void generateRootSysdef() {
        try {
            Configuration cfg = new Configuration();
            Template template = null;
            // Use custom template of default one?
            if (getTemplate() != null) {
                log("Loading template: " + this.getTemplate().getAbsolutePath());
                cfg.setTemplateLoader(new FileTemplateLoader(this.getTemplate().getParentFile()));
                template = cfg.getTemplate(this.getTemplate().getName());
            } else {
                cfg.setTemplateLoader(new ClassTemplateLoader(this.getClass(), "/com/nokia/helium/sysdef/templates"));
                template = cfg.getTemplate("root_sysdef_model.xml.ftl");
            }
            Map<String, Object> data = new Hashtable<String, Object>();
            // Content by root
            data.put("roots", roots);
            // Content by layer
            data.put("layers", layers);
            // id-namespace
            if (idNamespace != null) {
                data.put("idnamespace", idNamespace);
            }
            // Environment location
            data.put("epocroot", getEpocroot().getAbsolutePath());
            // Relative path from destFile to epocroot.
            data.put("dest_dir_to_epocroot", getRelativeDiff());
            StringWriter out = new StringWriter();
            template.process(data, out);

            // Writing the output.
            log("Creating " + getDestFile().getAbsolutePath());
            OutputStreamWriter output = new OutputStreamWriter(new FileOutputStream(getDestFile()));
            output.append(out.getBuffer().toString());
            output.close();            
        } catch (IOException e) {
            log("Error while creating output file: " + e.getMessage(), Project.MSG_ERR);
            if (this.shouldFailOnError()) {
                throw new BuildException("Error while creating output file: " + e.getMessage(), e);
            }
        } catch (TemplateException e) {
            log("Error while creating output file: " + e.getMessage(), Project.MSG_ERR);
            if (this.shouldFailOnError()) {
                throw new BuildException("Error while creating output file: " + e.getMessage(), e);
            }
        }
    }

    /**
     * Get the relative path to go to epocroot from destdir.
     * @return the path relative path to go to root.
     */
    protected String getRelativeDiff() {
        String rel = getEpocroot().toURI().relativize(getDestFile().getParentFile().toURI()).getPath();
        if (rel.length() > 0) {
            String[] relArray = rel.split("/"); // This is an URI not a File.
            rel = ""; //"." + File.separatorChar;
            for (@SuppressWarnings("unused") String string : relArray) {
                rel += ".." + File.separatorChar; 
            }
        } else {
            rel = "." + File.separatorChar;
        }
        return rel;
    }
}
