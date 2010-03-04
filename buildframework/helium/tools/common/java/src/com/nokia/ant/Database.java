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
 
package com.nokia.ant;

import info.bliki.wiki.model.WikiModel;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.Reference;
import org.apache.tools.ant.types.ResourceCollection;
import org.apache.tools.ant.types.resources.FileResource;
import org.dom4j.Attribute;
import org.dom4j.CDATA;
import org.dom4j.Comment;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.DocumentHelper;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.Text;
import org.dom4j.Visitor;
import org.dom4j.VisitorSupport;
import org.dom4j.XPath;
import org.dom4j.io.OutputFormat;
import org.dom4j.io.SAXReader;
import org.dom4j.io.XMLWriter;


/**
 * Reads the current ant project and a fileset and generates a xml file with a summary of targets,
 * macros and properties.
 */
public class Database
{
    private Project project;
    private ResourceCollection rc;
    private Task task;
    private boolean debug;
    private boolean homeFilesOnly = true;
    private HashMap<String, List<String>> globalSignalList = new HashMap<String, List<String>>();
    private HashMap map = new HashMap();
    private Document signaldoc;
    
    public Database(Project project, ResourceCollection rc, Task task)
    {
        this.project = project;
        this.rc = rc;
        this.task = task;
        map.put("hlm", "http://www.nokia.com/helium");
    }

    public Project getProject() {
        return project;
    }

    public void setDebug(boolean debug) {
        this.debug = debug;
    }

    public void setHomeFilesOnly(boolean homeFilesOnly) {
        this.homeFilesOnly = homeFilesOnly;
    }

    public void log(String msg, int level) {
        if (task != null) {
            task.log(msg, level);
        } else if (debug) {            
            project.log(msg, level);
        }
    }


    public void setRefid(Reference r)
    {
        Object o = r.getReferencedObject();
        if (!(o instanceof ResourceCollection))
        {
            throw new BuildException(r.getRefId() + " doesn\'t denote a ResourceCollection");
        }
        rc = (ResourceCollection) o;
    }

    public Document createDOM() throws Exception
    {        
        //log("Building Ant project database", Project.MSG_DEBUG);
        Element root = DocumentHelper.createElement("antDatabase");
        Document outDoc = DocumentHelper.createDocument(root);
        ArrayList antFiles = getAntFiles(getProject(), homeFilesOnly);
        Iterator antFilesIter = antFiles.iterator();
        while (antFilesIter.hasNext())
        {
            String antFile = (String) antFilesIter.next();
            readSignals(root, antFile);
        }
        antFilesIter = antFiles.iterator();
        while (antFilesIter.hasNext())
        {
            String antFile = (String) antFilesIter.next();
            parseAntFile(root, antFile);
        }

        buildTaskDefs( root );

        return outDoc;
    }

    public void createXMLFile(File outputFile) {
        try {
            Document outDoc = createDOM();
            OutputStream outStream = System.out;
            if (outputFile != null) {
                outStream = new FileOutputStream(outputFile);
            }
            XMLWriter out = new XMLWriter(outStream, OutputFormat.createPrettyPrint());
            out.write(outDoc);
        } catch (Exception e) {
            throw new BuildException(e.getMessage());
        }
    }

    private void readSignals(Element root, String antFile) throws DocumentException, IOException
    {
        SAXReader xmlReader = new SAXReader();
        Document antDoc = xmlReader.read(new File(antFile));

        XPath xpath = DocumentHelper.createXPath("//hlm:signalListenerConfig");
        xpath.setNamespaceURIs(map);
        List signalNodes = xpath.selectNodes(antDoc);
        for (Iterator iterator = signalNodes.iterator(); iterator.hasNext();)
        {
            signaldoc = antDoc;
            Element propertyNode = (Element) iterator.next();
            String signalid = propertyNode.attributeValue("id");

            String signaltarget = propertyNode.attributeValue("target");
            List existinglist = globalSignalList.get(signaltarget);
            String failbuild = signalType(signalid, signaldoc);
            if (existinglist == null)
                existinglist = new ArrayList<String>();
            existinglist.add(signalid + "," + failbuild);
            globalSignalList.put(signaltarget, existinglist);
        }
    }

    private String signalType(String signalid, Document antDoc)
    {
        XPath xpath2 = DocumentHelper.createXPath("//hlm:signalListenerConfig[@id='" + signalid + "']/signalNotifierInput/signalInput");
        xpath2.setNamespaceURIs(map);
        List signalNodes3 = xpath2.selectNodes(antDoc);

        for (Iterator iterator3 = signalNodes3.iterator(); iterator3.hasNext();)
        {
            Element propertyNode3 = (Element) iterator3.next();
            String signalinputid = propertyNode3.attributeValue("refid");

            XPath xpath3 = DocumentHelper.createXPath("//hlm:signalInput[@id='" + signalinputid + "']");
            xpath3.setNamespaceURIs(map);
            List signalNodes4 = xpath3.selectNodes(antDoc);
            for (Iterator iterator4 = signalNodes4.iterator(); iterator4.hasNext();)
            {
                Element propertyNode4 = (Element) iterator4.next();
                return propertyNode4.attributeValue("failbuild");
            }
        }
        return null;
    }

    /**
     * @param root
     * @param antFile
     * @throws DocumentException
     * @throws IOException
     */
    private void parseAntFile(Element root, String antFile) throws DocumentException, IOException
    {
        log("Processing Ant file: " + antFile, Project.MSG_DEBUG);
        SAXReader xmlReader = new SAXReader();
        Document antDoc = xmlReader.read(new File(antFile));

        // Element targetElement =
        // DocumentHelper.createElement("target");
        Element projectElement = root.addElement("project");
        Element nameElement = projectElement.addElement("name");
        String projectName = antDoc.valueOf("/project/@name");

        nameElement.setText(projectName);
        // Element descriptionElement =
        // projectElement.addElement("description");

        String description = antDoc.valueOf("/project/description");
        insertDocumentation(projectElement, description);

        // descriptionElement.setText(description);

        if (!antFile.contains("antlib.xml") && description.equals(""))
        {
            log("Project has no comment: " + projectName, Project.MSG_WARN);
        }

        Element defaultElement = projectElement.addElement("default");
        defaultElement.setText(antDoc.valueOf("/project/@default"));

        // Project import statements
        List importNodes = antDoc.selectNodes("//import");
        for (Iterator iterator = importNodes.iterator(); iterator.hasNext();)
        {
            Element importCurrentNode = (Element) iterator.next();
            addTextElement(projectElement, "fileDependency", importCurrentNode
                    .attributeValue("file"));
        }

        projectElement.addElement("pythonDependency");

        // Project exec statements
        List execNodes = antDoc.selectNodes("//exec//arg");
        for (Iterator iterator = execNodes.iterator(); iterator.hasNext();)
        {
            Element argNode = (Element) iterator.next();
            String argValue = argNode.attributeValue("value");

            if (argValue == null)
                argValue = argNode.attributeValue("line");

            if (argValue != null)
            {
                Pattern filePattern = Pattern.compile(".pl|.py|.bat|.xml|.txt");
                Matcher fileMatcher = filePattern.matcher(argValue);
                if (fileMatcher.find())
                {
                    addTextElement(projectElement, "fileDependency", argValue);
                }
            }
        }

        List targetNodes = antDoc.selectNodes("//target");
        for (Iterator iterator = targetNodes.iterator(); iterator.hasNext();)
        {
            Element targetNode = (Element) iterator.next();
            processTarget(targetNode, projectElement);
        }

        // Process macrodef and scriptdef tasks
        // TODO - maybe scriptdefs should be separate?
        List macroNodes = antDoc.selectNodes("//macrodef | //scriptdef");
        for (Iterator iterator = macroNodes.iterator(); iterator.hasNext();)
        {
            Element macroNode = (Element) iterator.next();
            processMacro(macroNode, projectElement, antFile);
        }

        // Project properties
        List propertyNodes = antDoc.selectNodes("//property");
        for (Iterator iterator = propertyNodes.iterator(); iterator.hasNext();)
        {
            Element propertyNode = (Element) iterator.next();
            processProperty(propertyNode, projectElement);
        }
    }

    public ArrayList getAntFiles()
    {
        return getAntFiles(getProject(), true);
    }

    public ArrayList getAntFiles(Project project)
    {
        return getAntFiles(project, true);
    }

    /**
     * Get the list of all Ant files we want to process. These can be project
     * and antlib files.
     * 
     * @return antFiles a list of ant files to be processed
     */
    public ArrayList getAntFiles(Project project, boolean homeOnly)
    {
        ArrayList antFiles = new ArrayList();

        Map targets = project.getTargets();
        Iterator targetsIter = targets.values().iterator();

        String projectHome = null;
        try {
            projectHome = new File(project.getProperty("helium.dir")).getCanonicalPath();

            while (targetsIter.hasNext())
            {
                Target target = (Target) targetsIter.next();
                String projectPath = new File(target.getLocation().getFileName()).getCanonicalPath();

                if (!antFiles.contains(projectPath))
                {
                    if (homeOnly)
                    {
                        if (!projectPath.contains(projectHome))
                        {
                            antFiles.add(projectPath);
                        }
                    }
                    else
                        antFiles.add(projectPath);
                }
            }

            if (rc != null)
            {
                Iterator extraFilesIter = rc.iterator();
                while (extraFilesIter.hasNext())
                {
                    FileResource f = (FileResource) extraFilesIter.next();
                    String extrafile = f.getFile().getCanonicalPath();

                    if (!antFiles.contains(f.toString()) && !f.getFile().getName().startsWith("test_"))
                    {
                        if (homeOnly)
                        {
                            if (!extrafile.contains(projectHome))
                            {
                                antFiles.add(extrafile);
                            }
                        }
                        else
                            antFiles.add(extrafile);
                    }
                }
            }

        } catch (Exception e) { 
            log(e.getMessage(), Project.MSG_ERR); 
            e.printStackTrace();
            }
        return antFiles;
    }

    //--------------------------------- PRIVATE METHODS ------------------------------------------

    private void processMacro(Element macroNode, Element outProjectNode, String antFile)
    throws IOException, DocumentException
    {
        String macroName = macroNode.attributeValue("name");
        log("Processing macro: " + macroName, Project.MSG_DEBUG);

        Element outmacroNode = outProjectNode.addElement("macro");
        addTextElement(outmacroNode, "name", macroNode.attributeValue("name"));
        addTextElement(outmacroNode, "description", macroNode.attributeValue("description"));

        // Add location
        // Project project = getProject();
        // Macro antmacro = (Macro) project.getTargets().get(macroName);
        // System.out.println(project.getMacroDefinitions());
        // System.out.println(macroName);
        // MacroInstance antmacro = (MacroInstance)
        // project.getMacroDefinitions().get("http://www.nokia.com/helium:" +
        // macroName);

        // Add the location with just the file path for now and a dummy line
        // number.
        // TODO - Later we should find the line number from the XML input.
        addTextElement(outmacroNode, "location", antFile + ":1:");

        List<Node> statements = macroNode.selectNodes("//scriptdef[@name='" + macroName + "']/attribute | //macrodef[@name='" + macroName + "']/attribute");
        String usage = "";
        for (Node statement : statements)
        {
            String defaultval = statement.valueOf("@default");
            if (defaultval.equals(""))
                defaultval = "value";
            else
                defaultval = "<i>" + defaultval + "</i>";
            usage = usage + " " + statement.valueOf("@name") + "=\"" + defaultval + "\"";
        }

        String macroElements = "";
        statements = macroNode.selectNodes("//scriptdef[@name='" + macroName + "']/element | //macrodef[@name='" + macroName + "']/element");
        for (Node statement : statements)
        {
            macroElements = "&lt;" + statement.valueOf("@name") + "/&gt;\n" + macroElements;
        }
        if (macroElements.equals(""))
            addTextElement(outmacroNode, "usage", "&lt;hlm:" + macroName + " " + usage + "/&gt;");
        else
            addTextElement(outmacroNode, "usage", "&lt;hlm:" + macroName + " " + usage + "&gt;\n" + macroElements + "&lt;/hlm:" + macroName + "&gt;");


        // Add dependencies
        // Enumeration dependencies = antmacro.getDependencies();
        // while (dependencies.hasMoreElements())
        // {
        // String dependency = (String) dependencies.nextElement();
        // Element dependencyElement = addTextElement(outmacroNode,
        // "dependency", dependency);
        // dependencyElement.addAttribute("type","direct");
        // }

        callAntTargetVisitor(macroNode, outmacroNode, outProjectNode);

        // Add documentation
        // Get comment element before the macro element to extract macro doc
        List children = macroNode.selectNodes("preceding-sibling::node()");
        if (children.size() > 0)
        {
            // Scan past the text nodes, which are most likely whitespace
            int index = children.size() - 1;
            Node child = (Node) children.get(index);
            while (index > 0 && child.getNodeType() == Node.TEXT_NODE)
            {
                index--;
                child = (Node) children.get(index);
            }

            // Check if there is a comment node
            String commentText = null;
            if (child.getNodeType() == Node.COMMENT_NODE)
            {
                Comment macroComment = (Comment) child;
                commentText = macroComment.getStringValue().trim();
                log(macroName + " comment: " + commentText, Project.MSG_DEBUG);
            }
            else
            {
                log("Macro has no comment: " + macroName, Project.MSG_WARN);
            }

            insertDocumentation(outmacroNode, commentText);

            Node previousNode = (Node) children.get(children.size() - 1);
        }

        // Get names of all properties used in this macro
        ArrayList properties = new ArrayList();
        Visitor visitor = new AntPropertyVisitor(properties);
        macroNode.accept(visitor);
        for (Iterator iterator = properties.iterator(); iterator.hasNext();)
        {
            String property = (String) iterator.next();
            addTextElement(outmacroNode, "propertyDependency", property);
        }
    }

    private void callAntTargetVisitor(Element targetNode, Element outTargetNode, Element outProjectNode)
    {
        // Add antcall/runtarget dependencies
        ArrayList antcallTargets = new ArrayList();
        ArrayList<String> logs = new ArrayList<String>();
        ArrayList<String> signals = new ArrayList<String>();
        ArrayList<String> executables = new ArrayList<String>();
        Visitor visitorTarget = new AntTargetVisitor(antcallTargets, logs, signals, executables);
        targetNode.accept(visitorTarget);
        for (Iterator iterator = antcallTargets.iterator(); iterator.hasNext();)
        {
            String antcallTarget = (String) iterator.next();
            Element dependencyElement = addTextElement(outTargetNode, "dependency", antcallTarget);
            dependencyElement.addAttribute("type", "exec");
        }

        for (String log : logs)
        {
            addTextElement(outTargetNode, "log", log);
        }

        if (globalSignalList.get(targetNode.attributeValue("name")) != null)
            signals.addAll(globalSignalList.get(targetNode.attributeValue("name")));

        for (String signal : signals)
        {
            addTextElement(outTargetNode, "signal", signal);
        }

        for (String executable : executables)
        {
            addTextElement(outTargetNode, "executable", executable);
        }
    }

    private void processTarget(Element targetNode, Element outProjectNode) throws IOException, DocumentException
    {
        String targetName = targetNode.attributeValue("name");
        log("Processing target: " + targetName, Project.MSG_DEBUG);

        // Add documentation
        // Get comment element before the target element to extract target doc
        String commentText = "";
        List children = targetNode.selectNodes("preceding-sibling::node()");
        if (children.size() > 0)
        {
            // Scan past the text nodes, which are most likely whitespace
            int index = children.size() - 1;
            Node child = (Node) children.get(index);
            while (index > 0 && child.getNodeType() == Node.TEXT_NODE)
            {
                index--;
                child = (Node) children.get(index);
            }

            // Check if there is a comment node
            if (child.getNodeType() == Node.COMMENT_NODE)
            {
                Comment targetComment = (Comment) child;
                commentText = targetComment.getStringValue().trim();

                log(targetName + " comment: " + commentText, Project.MSG_DEBUG);
            }
            else
            {
                log("Target has no comment: " + targetName, Project.MSG_WARN);
            }

            Node previousNode = (Node) children.get(children.size() - 1);
        }

        if (!commentText.contains("Private:"))
        {
            Element outTargetNode = outProjectNode.addElement("target");

            addTextElement(outTargetNode, "name", targetNode.attributeValue("name"));
            addTextElement(outTargetNode, "ifDependency", targetNode.attributeValue("if"));
            addTextElement(outTargetNode, "unlessDependency", targetNode.attributeValue("unless"));
            addTextElement(outTargetNode, "description", targetNode.attributeValue("description"));
            addTextElement(outTargetNode, "tasks", String.valueOf(targetNode.elements().size()));

            // Add location
            Project project = getProject();
            Target antTarget = (Target) project.getTargets().get(targetName);

            if (antTarget == null)
                return;

            addTextElement(outTargetNode, "location", antTarget.getLocation().toString());

            // Add dependencies
            Enumeration dependencies = antTarget.getDependencies();
            while (dependencies.hasMoreElements())
            {
                String dependency = (String) dependencies.nextElement();
                Element dependencyElement = addTextElement(outTargetNode, "dependency", dependency);
                dependencyElement.addAttribute("type", "direct");
            }

            callAntTargetVisitor(targetNode, outTargetNode, outProjectNode);

            // Process the comment text as MediaWiki syntax and convert to HTML
            insertDocumentation(outTargetNode, commentText);

            // Get names of all properties used in this target
            ArrayList properties = new ArrayList();
            Visitor visitor = new AntPropertyVisitor(properties);
            targetNode.accept(visitor);
            for (Iterator iterator = properties.iterator(); iterator.hasNext();)
            {
                String property = (String) iterator.next();
                addTextElement(outTargetNode, "propertyDependency", property);
            }

            // Add the raw XML content of the element
            String targetXml = targetNode.asXML();
            // Replace the CDATA end notation to avoid nested CDATA sections
            targetXml = targetXml.replace("]]>", "] ]>");

            addTextElement(outTargetNode, "source", targetXml, true);
        }
    }

    private void processProperty(Element propertyNode, Element outProjectNode) throws IOException
    {
        String propertyName = propertyNode.attributeValue("name");
        log("Processing Property: " + propertyName, Project.MSG_DEBUG);

        Element outPropertyNode = outProjectNode.addElement("property");
        addTextElement(outPropertyNode, "name", propertyNode.attributeValue("name"));
        if (propertyNode.attributeValue("value") == null)
        {
            addTextElement(outPropertyNode, "defaultValue", propertyNode.attributeValue("location"));
        }
        else
        {
            addTextElement(outPropertyNode, "defaultValue", propertyNode.attributeValue("value"));
        }
    }

    private void insertDocumentation(Element outNode, String commentText) throws IOException, DocumentException
    {
        if (commentText != null)
        {
            WikiModel wikiModel = new WikiModel("", "");
            if (!commentText.contains("</pre>") && (commentText.contains("**") || commentText.contains("==") || commentText.contains("- -")))
            {
                commentText = commentText.replace("**", "").replace("==", "").replace("- -", "").trim();
                log("Warning: Comment code has invalid syntax: " + commentText, Project.MSG_WARN);
            }
            if (commentText.startsWith("-"))
                commentText = commentText.replace("-", "");
            commentText = commentText.trim();

            String commentTextCheck = commentText.replace("deprecated>", "").replace("tt>", "").replace("todo>", "");
            if (commentTextCheck.contains(">") && !commentTextCheck.contains("</pre>"))
                log("Warning: Comment code needs <pre> tags around it: " + commentText, Project.MSG_WARN);

            commentText = filterTextNewlines(commentText);
            commentText = wikiModel.render(commentText);

            // If <deprecated> tag exists in the comment, then parse the
            // deprecated message.
            if (commentText.indexOf("&#60;deprecated&#62;") != -1)
            {
                int deprecatedMsgStart = commentText.indexOf("&#60;deprecated&#62;") + 20;
                int deprecatedMsgEnd = commentText.indexOf("&#60;/deprecated&#62;");

                // Add deprecated element.
                String deprecatedMsg = commentText.substring(deprecatedMsgStart, deprecatedMsgEnd);
                addTextElement(outNode, "deprecated", deprecatedMsg);

                // remove <deprecated> part from description field.
                int commentTextLength = commentText.length();
                String documentationMsgStart = commentText.substring(1, deprecatedMsgStart - 20);
                String documentationMsgEnd = commentText.substring(deprecatedMsgEnd + 21,
                        commentTextLength);
                String documentationMsg = documentationMsgStart.concat(documentationMsgEnd);
                commentText = documentationMsg.trim();
            }
        }
        else
        {
            commentText = "";
        }
        // Get the documentation element as a document
        String documentationText = "<documentation>" + commentText +
                                 "</documentation>";
        Document docDoc = DocumentHelper.parseText(documentationText);
        outNode.add(docDoc.getRootElement());
        log("HTML comment: " + commentText, Project.MSG_DEBUG);
    }

    private Element addTextElement(Element parent, String name, String text)
    {
        Element element = addTextElement(parent, name, text, false);

        return element;
    }

    private Element addTextElement(Element parent, String name, String text, boolean escape)
    {
        Element element = parent.addElement(name);
        if (text != null)
        {
            if (escape)
            {
                element.addCDATA(text);
            }
            else
            {
                element.setText(text);
            }
        }
        return element;
    }

    private String filterTextNewlines(String text) throws IOException
    {
        BufferedReader in = new BufferedReader(new StringReader(text));
        StringBuilder out = new StringBuilder();
        String line = in.readLine();
        while (line != null)
        {
            out.append(line.trim());
            out.append("\n");
            line = in.readLine();
        }
        return out.toString();
    }

    /**
     * Method adds taskdef nodes to the specified project.
     * 
     * @param outProjectNode
     * @throws IOException
     */
    private void buildTaskDefs( Element root ) throws DocumentException, IOException
    {
        Element projectElement = root.addElement("project");
        projectElement.addElement("name");
        insertDocumentation(projectElement, "");
        HashMap < String, String > tasks = getHeliumAntTasks();

        for ( String taskName : tasks.keySet() ) {
            String className = tasks.get( taskName );
            log("Processing TaskDef: " + taskName, Project.MSG_DEBUG);

            Element outTaskDefNode = projectElement.addElement("taskdef");
            addTextElement( outTaskDefNode, "name", taskName );
            addTextElement( outTaskDefNode, "classname",  className );
        }
    }

    /**
     * Method returns all the helium ant tasks in the project.
     * 
     * @return
     */
    @SuppressWarnings("unchecked")
    private HashMap < String, String > getHeliumAntTasks() {

        // 1. Get all the task definitions from the project
        Hashtable <String, Class<?> > allTaskdefs = getProject().getTaskDefinitions();
        // 2. Filter the list by applying criteria
        return filterTasks( allTaskdefs );
    }

    /**
     * Method is used to filter tasks. 
     * 
     * @param allTaskdefs
     * @param criteria
     */
    private HashMap < String, String > filterTasks ( Hashtable<String, Class<?> > allTaskdefs ) {
        HashMap <String, String> tasks = new HashMap <String, String>();

        Enumeration <String> taskdefsenum = allTaskdefs.keys();
        while ( taskdefsenum.hasMoreElements () ) {
            String key = taskdefsenum.nextElement();
            Class<?> clazz = allTaskdefs.get(key);
            String className = clazz.getName();
            if ( key.contains("nokia.com") && className.startsWith("com.nokia") && 
                    className.contains("ant.taskdefs") ) {
                tasks.put( getTaskName( key ), clazz.getName() );
            }
        }
        return tasks;
    }

    /**
     * Returns the task name delimiting the helium namespace.
     * 
     * @param text
     * @return
     */
    private String getTaskName( String text ) {
        int lastIndex = text.lastIndexOf(':');
        return text.substring( lastIndex + 1 );
    }

    //----------------------------------- PRIVATE CLASSES -----------------------------------------

    private class AntPropertyVisitor extends VisitorSupport
    {
        private List propertyList;

        public AntPropertyVisitor(List propertyList)
        {
            this.propertyList = propertyList;
        }

        public void visit(Attribute node)
        {
            String text = node.getStringValue();
            extractUsedProperties(text);
        }

        public void visit(CDATA node)
        {
            String text = node.getText();
            extractUsedProperties(text);
        }

        public void visit(Text node)
        {
            String text = node.getText();
            extractUsedProperties(text);
        }

        public void visit(Element node)
        {
            if (node.getName().equals("property"))
            {
                String propertyName = node.attributeValue("name");
                if (!propertyList.contains(propertyName))
                {
                    propertyList.add(propertyName);
                    log("property matches :" + propertyName, Project.MSG_DEBUG);
                }
            }
        }

        private void extractUsedProperties(String text)
        {
            Pattern p1 = Pattern.compile("\\$\\{([^@$}]*)\\}");
            Matcher m1 = p1.matcher(text);
            log(text, Project.MSG_DEBUG);
            while (m1.find())
            {
                String group = m1.group(1);
                if (!propertyList.contains(group))
                {
                    propertyList.add(group);
                }
                log("property matches: " + group, Project.MSG_DEBUG);
            }

            Pattern p2 = Pattern.compile("\\$\\{([^\n]*\\})\\}");
            Matcher m2 = p2.matcher(text);
            log(text, Project.MSG_DEBUG);
            while (m2.find())
            {
                String group = m2.group(1);
                if (!propertyList.contains(group))
                {
                    propertyList.add(group);
                }
                log("property matches: " + group, Project.MSG_DEBUG);
            }

            Pattern p3 = Pattern.compile("\\$\\{(\\@\\{[^\n]*)\\}");
            Matcher m3 = p3.matcher(text);
            log(text, Project.MSG_DEBUG);
            while (m3.find())
            {
                String group = m3.group(1);
                if (!propertyList.contains(group))
                {
                    propertyList.add(group);
                }
                log("property matches: " + group, Project.MSG_DEBUG);
            }
        }
    }

    private class AntTargetVisitor extends VisitorSupport
    {
        private List targetList;
        private List logList;
        private List signalList;
        private List executableList;

        public AntTargetVisitor(List targetList)
        {
            this.targetList = targetList;
        }

        public AntTargetVisitor(List targetList, List logList, List signalList, List executableList)
        {
            this.targetList = targetList;
            this.logList = logList;
            this.signalList = signalList;
            this.executableList = executableList;
        }

        public void visit(Element node)
        {
            String name = node.getName();
            if (name.equals("antcall") || name.equals("runtarget"))
            {
                String text = node.attributeValue("target");
                extractTarget(text);
            }

            if (!name.equals("include") && !name.equals("exclude"))
            {
                String text = node.attributeValue("name");
                addLog(text);
                text = node.attributeValue("output");
                addLog(text);
                text = node.attributeValue("value");
                addLog(text);
                text = node.attributeValue("log");
                addLog(text);
                text = node.attributeValue("line");
                addLog(text);
                text = node.attributeValue("file");
                addLog(text);
            }

            if (name.equals("signal") || name.equals("execSignal"))
            {
                String signalid = getProject().replaceProperties(node.attributeValue("name"));
                String failbuild = signalType(signalid, signaldoc);

                if (signalList != null)
                {
                    if (failbuild != null)
                        signalList.add(signalid + "," + failbuild);
                    else
                        signalList.add(signalid);
                }
            }

            if (name.equals("exec") || name.equals("preset.exec"))
            {
                String text = node.attributeValue("executable");
                executableList.add(text);
                log("Executable: " + text, Project.MSG_DEBUG);
            }
        }

        private void addLog(String text)
        {
            if (text != null && logList != null)
            {
                for (String log : text.split(" "))
                {
                    String fulllogname = getProject().replaceProperties(log);
                    if (!logList.contains(log) && (fulllogname.endsWith(".log") || fulllogname.endsWith(".html")))
                    {
                        log = log.replace("--log=", "");
                        logList.add(log);
                    }
                }
            }
        }

        private void extractTarget(String text)
        {
            String iText = getProject().replaceProperties(text);
            targetList.add(iText);
        }

    }
}

