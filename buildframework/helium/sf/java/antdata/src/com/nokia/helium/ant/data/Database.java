/*
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

package com.nokia.helium.ant.data;

import java.io.File;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;

import com.nokia.helium.freemarker.WikiMethod;

import freemarker.cache.ClassTemplateLoader;
import freemarker.cache.FileTemplateLoader;
import freemarker.cache.MultiTemplateLoader;
import freemarker.cache.TemplateLoader;
import freemarker.template.Configuration;
import freemarker.template.DefaultObjectWrapper;
import freemarker.template.Template;
import freemarker.template.TemplateException;

/**
 * Reads the current ant project and a fileset and generates a xml file with a summary of targets,
 * macros and properties.
 */
public class Database {
    /** The default scope filter if no scope filter is defined. */
    public static final String DEFAULT_SCOPE = "public";
    public static final Map<String, String> NAMESPACE_MAP;

    private Project rootProject;
    private Map<String, AntFile> antfilesMap;
    private Map<String, PackageMeta> packagesMap;
    private String scopeFilter;

    static {
        Map<String, String> tempMap = new HashMap<String, String>();
        tempMap.put("hlm", "http://www.nokia.com/helium");
        NAMESPACE_MAP = Collections.unmodifiableMap(tempMap);
    }

    public Database(Project project) throws IOException {
        this(project, DEFAULT_SCOPE);
    }

    @SuppressWarnings("unchecked")
    public Database(Project project, String scopeFilter) throws IOException {
        this.rootProject = project;
        this.scopeFilter = scopeFilter;
        antfilesMap = new HashMap<String, AntFile>();
        packagesMap = new HashMap<String, PackageMeta>();

        if (project != null) {
            Map<String, Target> targets = project.getTargets();
            Iterator<Target> targetsIter = targets.values().iterator();

            while (targetsIter.hasNext()) {
                Target target = targetsIter.next();
                String antFilePath = new File(target.getLocation().getFileName()).getCanonicalPath();

                if (!antfilesMap.containsKey(antFilePath)) {
                    addAntFile(antFilePath);
                }
            }
        }
    }

    private void log(String string, int level) {
        if (rootProject != null) {
            rootProject.log(string, level);
        }
    }

    public void addAntFilePaths(List<String> antFilePaths) throws IOException {
        for (String antFilePath : antFilePaths) {
            addAntFile(antFilePath);
        }
    }

    private void addAntFile(String antFilePath) throws IOException {
        if (!antfilesMap.containsKey(antFilePath)) {
            log("Adding project to database: " + antFilePath, Project.MSG_DEBUG);
            AntFile antfile = new AntFile(this, antFilePath, scopeFilter);
            antfile.setProject(rootProject);
            antfilesMap.put(antFilePath, antfile);

            // See if project is part of a package
            checkPackageMembership(antfile);

            // See if any antlibs are defined
            List<AntFile> antlibFiles = antfile.getAntlibs();
            for (AntFile antFile2 : antlibFiles) {
                antfilesMap.put(antFile2.getFile().getCanonicalPath(), antFile2);
                checkPackageMembership(antFile2);
            }
        }
    }

    private void checkPackageMembership(AntFile antfile) throws IOException {
        RootAntObjectMeta rootObjectMeta = antfile.getRootObjectMeta();
        String packageStr = rootObjectMeta.getPackage();
        if (!packagesMap.containsKey(packageStr)) {
            PackageMeta packageMeta = new PackageMeta(packageStr);
            packageMeta.setRuntimeProject(rootProject);
            packagesMap.put(packageStr, packageMeta);
        }
        PackageMeta packageMeta = packagesMap.get(packageStr);
        packageMeta.addObject(rootObjectMeta);
    }

    public void setScopeFilter(String scopeFilter) {
        if (!(scopeFilter.equals("public") || scopeFilter.equals("protected") || scopeFilter.equals("private"))) {
            throw new IllegalArgumentException("Invalid scope value");
        }
        this.scopeFilter = scopeFilter;
    }

    public void toXML(Writer out) throws IOException {
        // Setup configuration
        Configuration cfg = new Configuration();
        TemplateLoader[] loaders = null;
        ClassTemplateLoader ctl = new ClassTemplateLoader(getClass(), "");
        File testingDir = new File("src/com/nokia/helium/ant/data/taskdefs");
        if (testingDir.exists()) {
            FileTemplateLoader ftl1 = new FileTemplateLoader(testingDir);
            loaders = new TemplateLoader[] { ftl1, ctl };
        }
        else {
            loaders = new TemplateLoader[] { ctl };
        }
        MultiTemplateLoader mtl = new MultiTemplateLoader(loaders);
        cfg.setTemplateLoader(mtl);
        cfg.setObjectWrapper(new DefaultObjectWrapper());

        // Create the data model
        List<ProjectMeta> projects = new ArrayList<ProjectMeta>();
        List<AntlibMeta> antlibs = new ArrayList<AntlibMeta>();
        for (AntFile antfile : antfilesMap.values()) {
            antfile.setScope(scopeFilter);
            RootAntObjectMeta rootObject = antfile.getRootObjectMeta();
            if (rootObject instanceof ProjectMeta) {
                projects.add((ProjectMeta) rootObject);
            }
            else {
                antlibs.add((AntlibMeta) rootObject);
            }
        }
        Map<String, Object> root = new HashMap<String, Object>();
        root.put("projects", projects);
        root.put("antlibs", antlibs);
        root.put("packages", getPackages());

        // Add a custom wiki formatting method
        WikiMethod wikiMethod = new WikiMethod();
        root.put("wiki", wikiMethod);

        // Process template
        Template template = cfg.getTemplate("database.xml.ftl");
        try {
            template.process(root, out);
        }
        catch (TemplateException e) {
            e.printStackTrace();
            throw new IOException(e.getMessage());
        }
        out.flush();
    }

    public Collection<AntFile> getAntFiles() {
        return antfilesMap.values();
    }

    public List<PropertyMeta> getProperties() {
        List<PropertyMeta> propertiesList = new ArrayList<PropertyMeta>();
        for (AntFile antfile : antfilesMap.values()) {
            RootAntObjectMeta rootMeta = antfile.getRootObjectMeta();
            if (rootMeta instanceof ProjectMeta) {
                propertiesList.addAll(((ProjectMeta) rootMeta).getProperties());
            }
        }
        return propertiesList;
    }
    
    public List<PropertyCommentMeta> getCommentProperties() {
        List<PropertyCommentMeta> propertiesList = new ArrayList<PropertyCommentMeta>();
        for (AntFile antfile : antfilesMap.values()) {
            RootAntObjectMeta rootMeta = antfile.getRootObjectMeta();
            if (rootMeta instanceof ProjectMeta) {
                propertiesList.addAll(((ProjectMeta) rootMeta).getPropertyCommentBlocks());
            }
        }
        return propertiesList;
    }

    public List<PackageMeta> getPackages() throws IOException {
        List<PackageMeta> packages = new ArrayList<PackageMeta>();
        for (PackageMeta packageMeta : packagesMap.values()) {
            packages.add(packageMeta);
        }
        return packages;
    }
}
