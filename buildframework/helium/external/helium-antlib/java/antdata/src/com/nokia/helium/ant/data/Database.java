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

import freemarker.cache.ClassTemplateLoader;
import freemarker.cache.FileTemplateLoader;
import freemarker.cache.MultiTemplateLoader;
import freemarker.cache.TemplateLoader;
import freemarker.template.Configuration;
import freemarker.template.DefaultObjectWrapper;
import freemarker.template.Template;
import freemarker.template.TemplateException;
import java.io.File;
import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.DocumentHelper;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.XPath;
import org.dom4j.io.SAXReader;

import com.nokia.helium.freemarker.WikiMethod;

/**
 * Reads the current ant project and a fileset and generates a xml file with a
 * summary of targets, macros and properties.
 */
public class Database {
    /** The default scope filter if no scope filter is defined. */
    public static final String DEFAULT_SCOPE = "public";

    private Project rootProject;
    private Map<String, AntFile> antfilesMap;
    private Map<String, PackageMeta> packagesMap;
    private String scopeFilter;

    private HashMap<String, String> namespaceMap = new HashMap<String, String>();
    private HashMap<String, List<String>> globalSignalList = new HashMap<String, List<String>>();
    private Document signaldoc;

    public Database(Project project) throws IOException {
        this(project, DEFAULT_SCOPE);
    }

    @SuppressWarnings("unchecked")
    public Database(Project project, String scopeFilter) throws IOException {
        this.rootProject = project;
        this.scopeFilter = scopeFilter;
        antfilesMap = new HashMap<String, AntFile>();
        packagesMap = new HashMap<String, PackageMeta>();
        namespaceMap.put("hlm", "http://www.nokia.com/helium");

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

        Collection<AntFile> antFiles = getAntFiles();
        Iterator<AntFile> antFilesIter = antFiles.iterator();
        while (antFilesIter.hasNext()) {
            AntFile antFile = (AntFile) antFilesIter.next();
            readSignals(antFile.getFile().getCanonicalPath());
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
            readSignals(antFilePath);

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

    @SuppressWarnings("unchecked")
    private void readSignals(String antFile) throws IOException {
        SAXReader xmlReader = new SAXReader();
        Document antDoc;
        try {
            antDoc = xmlReader.read(new File(antFile));
        }
        catch (DocumentException e) {
            throw new IOException(e.getMessage());
        }

        XPath xpath = DocumentHelper.createXPath("//hlm:signalListenerConfig");
        xpath.setNamespaceURIs(namespaceMap);
        List<Node> signalNodes = xpath.selectNodes(antDoc);
        for (Iterator<Node> iterator = signalNodes.iterator(); iterator.hasNext();) {
            signaldoc = antDoc;
            Element propertyNode = (Element) iterator.next();
            String signalid = propertyNode.attributeValue("id");
            String signaltarget = propertyNode.attributeValue("target");
            List<String> existinglist = globalSignalList.get(signaltarget); 
            String failbuild = findSignalFailMode(signalid, signaldoc);
            if (existinglist == null) {
                existinglist = new ArrayList<String>();
            }
            existinglist.add(signalid + "," + failbuild);
            globalSignalList.put(signaltarget, existinglist);
        }
    }

    public List<String> getSignals(String target) {
        return globalSignalList.get(target);
    }

    @SuppressWarnings("unchecked")
    private String findSignalFailMode(String signalid, Document antDoc) {
        XPath xpath2 = DocumentHelper.createXPath("//hlm:signalListenerConfig[@id='" + signalid
                + "']/signalNotifierInput/signalInput");
        xpath2.setNamespaceURIs(namespaceMap);
        List signalNodes3 = xpath2.selectNodes(antDoc);

        for (Iterator iterator3 = signalNodes3.iterator(); iterator3.hasNext();) {
            Element propertyNode3 = (Element) iterator3.next();
            String signalinputid = propertyNode3.attributeValue("refid");

            XPath xpath3 = DocumentHelper.createXPath("//hlm:signalInput[@id='" + signalinputid + "']");
            xpath3.setNamespaceURIs(namespaceMap);
            List signalNodes4 = xpath3.selectNodes(antDoc);
            for (Iterator iterator4 = signalNodes4.iterator(); iterator4.hasNext();) {
                Element propertyNode4 = (Element) iterator4.next();
                return propertyNode4.attributeValue("failbuild");
            }
        }
        return null;
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
        // antfiles.addAll(antfilesMap.values());
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

    public List<PropertyMeta> getProperties() throws IOException {
        List<PropertyMeta> propertiesList = new ArrayList<PropertyMeta>();
        for (AntFile antfile : antfilesMap.values()) {
            RootAntObjectMeta rootMeta = antfile.getRootObjectMeta();
            if (rootMeta instanceof ProjectMeta) {
                propertiesList.addAll(((ProjectMeta) rootMeta).getProperties());
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
