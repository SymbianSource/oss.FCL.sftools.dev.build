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
 
package com.nokia.ant.taskdefs;

import java.io.*;
import java.util.*;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.FileSet;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.tools.ant.BuildException;

import org.dom4j.io.SAXReader;
import org.dom4j.Document;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.VisitorSupport;
import org.dom4j.Visitor;
import org.xml.sax.*;
import org.xml.sax.helpers.DefaultHandler; 

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
import java.util.regex.*;

/**
 * AntLint Task. This task checks for common coding conventions 
 * and errors in Ant XML script files.
 * 
 * <p>The current checks include: 
 * <ul>
 * <li>Macro names.
 * <li>Preset def names.
 * <li>Target names. 
 * <li>Property names and Indentation.
 * <li>Project names.</li>
 * <li>Project description is present.</li>
 * <li>Ant file names.</li>
 * <li>runtarget calls a target that has dependencies.</li>
 *  <li>antcall is used with no param elements and calls a target
 * with no dependencies (could use runtarget instead).</li>
 * </ul>
 * </p>
 *
 * <p>Checks to be added:
 * <ul>
 * <li>Help target is defined.</li>
 * <li>Optional to thrown warnings about deprecated targets (rename, copydir, copyfile).</li>
 * </ul>
 * </p>
 * @ant.task category="Quality"
 *
 */
public class AntLintTask extends Task
{
    private ArrayList propertiesVisited = new ArrayList();
    private ArrayList antFileSetList = new ArrayList();
    private ArrayList<AntFile> antFilelist = new ArrayList<AntFile>();
    
    private String configurationPath;
    
    private boolean tabCharacterCheck;
    private boolean propertyNameCheck;
    private boolean targetNameCheck;
    private boolean indentationCheck;
    private boolean presetDefMacroDefNameCheck;
    private boolean projectNameCheck;
    private boolean descriptionCheck;
    private boolean fileNameCheck;
    private boolean runTargetCheck;
    private boolean antcallCheck;
    
    private String propertyNamePattern;
    private String targetNamePattern;
    private String presetDefMacroDefNamePattern;
    private String projectNamePattern;
    private String fileNamePattern;
    
    private AntFile currentFile;
    
    private class AntFile implements Comparable<AntFile>
    {
        private String name;
        private int warningCount;
        private int errorCount;
        
        public AntFile(String n) { name = n; }
        public void incWarningCount() { warningCount++; }
        public int getWarningCount() { return warningCount; }
        public void incErrorCount() { errorCount++; }
        public int getErrorCount() { return errorCount; }
        
        public String toString()
        {
            if (errorCount > 0)
                throw new BuildException(errorCount + " errors found in " + name); 
            return warningCount + " warnings " + name;
        }
        
        public int compareTo(AntFile o)
        {
            return new Integer(o.getWarningCount()).compareTo(new Integer(warningCount)) * -1;
        }
    }
    
    /**
     * AntLintTask Constructor
     */
    public AntLintTask()
    {
        setTaskName("antlint");
    }
    
    /**
     * Add a set of files to copy.
     * @param set a set of files to AntLintTask.
     * @ant.required
     */
    public void addFileset(FileSet set) {
        antFileSetList.add(set);
    }
    
    /**
     * Set the path of the configuration file to use.
     * 
     * @param configurationPath path to config file
     * @ant.required
     */
    public void setConfigFile(String configurationPath)
    {
        this.configurationPath = configurationPath;
    }
    
    public void checkDuplicateNames(Project project)
    {
        Hashtable taskdefs = project.getTaskDefinitions();
        HashSet<String> classlist = new HashSet<String>();
        Enumeration taskdefsenum = taskdefs.keys();
        ArrayList<String> macros = new ArrayList<String>();
        while (taskdefsenum.hasMoreElements ()) {
            String key = (String) taskdefsenum.nextElement();
            Class value = (Class) taskdefs.get(key);
            macros.add(key);
        }
        currentFile = new AntFile("General");
        antFilelist.add(currentFile);
        for (String x : macros)
        {
            if (macros.contains(x + "Macro") || macros.contains(x + "macro"))
                log("W: " + x + " and " + x + "Macro" + " found duplicate name");
                currentFile.incWarningCount();
        }
    }
      
    public final void execute()
    {
        try
        {
            log("Running antlint..", Project.MSG_DEBUG);
            Project project = getProject();
            
            getConfiguration();//loads configuration file
            
            checkDuplicateNames(project);
            
            for (Iterator iterator = antFileSetList.iterator(); iterator.hasNext();)
            {
                FileSet fs = (FileSet) iterator.next();
                DirectoryScanner ds = fs.getDirectoryScanner(project);
                String[] srcFiles = ds.getIncludedFiles();
                String basedir = ds.getBasedir().getPath();
                
                for (int i = 0; i < srcFiles.length; i++) 
                {    
                    String antFileName = basedir + File.separator + srcFiles[i];
                    log("*************** Ant File: " + antFileName);
                    
                    currentFile = new AntFile(antFileName);
                    antFilelist.add(currentFile);
                    
                    checkFileName(new File(antFileName).getName());
                                       
                    SAXReader saxReader = new SAXReader();
                    Document doc = saxReader.read(new File(antFileName));
                    treeWalk(doc);
                    
                    SAXParserFactory saxFactory = SAXParserFactory.newInstance();
                    saxFactory.setNamespaceAware(true);
                    saxFactory.setValidating(true);
                    SAXParser parser = saxFactory.newSAXParser();
                    AntLintHandler handler = new AntLintHandler();
                    parser.parse(new File(antFileName), handler);
                }
                
                Collections.sort(antFilelist);
            }  
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
        
        for (AntFile s : antFilelist)
        {
            log(s.toString());
        }
    }

    public final void treeWalk(final Document document)
    {
        Element rootElement = document.getRootElement();
        Visitor visitorRootElement = new AntProjectVisitor();
        rootElement.accept(visitorRootElement);
        treeWalk(rootElement);        
    }

    public final void treeWalk(final Element element)
    {
        for ( int i = 0, size = element.nodeCount(); i < size; i++ ) 
        {
            Node node = element.node(i);
            if ( node instanceof Element ) 
            {
                Visitor visitorElement = new AntXMLVisitor();
                node.accept(visitorElement);
                treeWalk( (Element) node );
            }
        }
    }
    
    private void checkFileName(String text)
    {
        try
        {
            boolean found = false;
            Pattern p1 = Pattern.compile(fileNamePattern);
            Matcher m1 = p1.matcher(text);
            while (m1.find())
            {
                found = true;            
            }
            if (!found && fileNameCheck) {
                log("W: INVALID File Name: " + text);
                currentFile.incWarningCount();
            }
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
    }
    
    public final void getConfiguration()
    {
        try
        {
            SAXReader saxConfigReader = new SAXReader();
            Document docConfig = saxConfigReader.read(new File(configurationPath));
        
            Element rootConfig = docConfig.getRootElement();
    
            // iterate through child elements of root
            for ( Iterator i = rootConfig.elementIterator(); i.hasNext(); ) {
                Element elementConfig = (Element) i.next();
                String attrName = elementConfig.attributeValue("name");
                if (attrName.equals("TabCharacter")) {
                        tabCharacterCheck = true;
                }
                else if (attrName.equals("PropertyName")) {
                        propertyNameCheck = true;
                        propertyNamePattern = elementConfig.getText();
                }
                else if (attrName.equals("TargetName")) {
                        targetNameCheck = true;
                        targetNamePattern = elementConfig.getText();
                }
                else if (attrName.equals("Indentation")) {
                        indentationCheck = true;
                }
                else if (attrName.equals("PresetDefMacroDefName")) {   
                        presetDefMacroDefNameCheck = true;
                        presetDefMacroDefNamePattern = elementConfig.getText();
                }
                else if (attrName.equals("ProjectName")) {
                        projectNameCheck = true;
                        projectNamePattern = elementConfig.getText();
                }
                else if (attrName.equals("Description")) {
                        descriptionCheck = true;
                }
                else if (attrName.equals("FileName")) {
                        fileNameCheck = true;
                        fileNamePattern = elementConfig.getText();
                }
                else if (attrName.equals("RunTarget")) {
                        runTargetCheck = true;
                }
                else if (attrName.equals("AntCall")) {
                        antcallCheck = true;
                }
            }
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }

    }
    
    private class AntXMLVisitor extends VisitorSupport
    {    
        public void visit(Element node)
        {
            String name = node.getName();
            if (name.equals("target"))
            {
                checkTarget(node);
            }
            if (name.equals("property"))
            {
                String text = node.attributeValue("name");
                if (text != null && propertyNameCheck)
                {
                    checkPropertyName(text);
                }
            }
            if (name.equals("equals"))
            {
                String text = node.attributeValue("arg2");
                if (text.equals("true") || text.equals("yes"))
                {
                    log("E: " + node.attributeValue("arg1") + " uses 'equals' should use 'istrue' task");
                    currentFile.incErrorCount();
                }
            }
            if (name.equals("presetdef") || name.equals("macrodef"))
            {
                String text = node.attributeValue("name");
                if (text != null && presetDefMacroDefNameCheck)
                {
                    checkDefName(text);
                }
            }
            
            if (name.equals("scriptdef"))
            {
                String scriptdefname = node.attributeValue("name");
                String language = node.attributeValue("language");
                
                checkScriptdef(scriptdefname, node);
                
                if (language.equals("beanshell"))
                {
                    writeBeanshellFile(scriptdefname, node.getText());
                }

                if (language.equals("jep") || language.equals("jython"))
                {
                    writeJepFile(scriptdefname, node.getText());
                    checkJepPropertiesInText(node.getText());
                }
            }
        }
        
        private void checkTarget(Element node)
        {
            String target = node.attributeValue("name");
            if (target != null && targetNameCheck)
            {
                checkTargetName(target);
            }
            else
            {
                log("W: Target name not specified!");
                currentFile.incWarningCount();
            }
            checkUseOfIf(node);
            checkSizeOfScript(node);
            checkTabsInScript(node);
            if ((node.elements("runtarget") != null) && runTargetCheck)
            {
                List runTargetList = node.elements("runtarget");
                for (Iterator iterator = runTargetList.iterator(); iterator.hasNext();)
                {
                    Element runTargetElement = (Element) iterator.next();
                    String runTargetName = runTargetElement.attributeValue("target");
                    if (checkTargetDependency(runTargetName))
                    {
                        log("W: <runtarget> calls the target " +  runTargetName + " that has dependencies!");
                        currentFile.incWarningCount();
                    }
                }
            }
            if ((node.elements("antcall") != null) && antcallCheck)
            {
                List antcallList = node.elements("antcall");
                for (Iterator iterator = antcallList.iterator(); iterator.hasNext();)
                {
                    Element antcallElement = (Element) iterator.next();
                    String antcallName = antcallElement.attributeValue("target");
                    if ((node.elements("param") == null) && !checkTargetDependency(antcallName))
                    {
                        log("R: <antcall> is used with no param elements and calls the target " +  antcallName + " that has no dependencies! (<runtarget> could be used instead.)");
                        currentFile.incWarningCount();
                    }
                }
            }
            
            List scriptList = node.selectNodes("//target[@name='" + target + "']/descendant::script");
            for (Iterator iterator = scriptList.iterator(); iterator.hasNext();)
            {
                Element scriptElement = (Element) iterator.next();
                String language = scriptElement.attributeValue("language");
                if (language.equals("jep") || language.equals("jython"))
                {
                    writeJepFile("target_" + target, scriptElement.getText());
                    checkJepPropertiesInText(scriptElement.getText());
                }
            }

            List scriptList2 = node.selectNodes("//target[@name='" + target + "']/descendant::scriptcondition");
            for (Iterator iterator = scriptList2.iterator(); iterator.hasNext();)
            {
                Element scriptElement2 = (Element) iterator.next();
                String language2 = scriptElement2.attributeValue("language");
                if (language2.equals("jep") || language2.equals("jython"))
                {
                    writeJepFile("scriptcondition_" + target, scriptElement2.getText());
                    checkJepPropertiesInText(scriptElement2.getText());
                }
            }
            
            List pythonList = node.selectNodes("//target[@name='" + target + "']/descendant::*[name()=\"hlm:python\"]");
            int i = 0;
            for (Iterator iterator = pythonList.iterator(); iterator.hasNext();)
            {
                Element pythonElement = (Element) iterator.next();
                writePythonFile(i + "_" + target, pythonElement.getText());
                i++;
            }
        }
        
        private void writePythonFile(String scriptdefname, String text)
        {
            try {
            String heliumpath = new File(project.getProperty("helium.build.dir")).getCanonicalPath();
            new File(heliumpath + File.separator + "python").mkdirs();
            File file = new File(heliumpath + File.separator + "python" + File.separator + "target" + scriptdefname + ".py");
            PrintWriter output = new PrintWriter(new FileOutputStream(file));
            output.write(text);
            output.close();
            checkPropertiesInText(text);
            } catch (Exception e) { e.printStackTrace(); }
        }
        
        private void writeBeanshellFile(String scriptdefname, String text)
        {
            scriptdefname = "Beanshell" + scriptdefname;
            try {
            String heliumpath = new File(project.getProperty("helium.build.dir")).getCanonicalPath();
            new File(heliumpath + File.separator + "beanshell").mkdirs();
            File file = new File(heliumpath + File.separator + "beanshell" + File.separator + scriptdefname + ".java");
            PrintWriter output = new PrintWriter(new FileOutputStream(file));
            
            for (String line : text.split("\n"))
            {
                if (line.trim().startsWith("import"))
                    output.write(line + "\n");
            }
            
            output.write("/**\n * x\n */\npublic final class " + scriptdefname + " {\n");
            output.write("private " + scriptdefname + "() { }\n");
            output.write("public static void main(String[] args) {\n");
            for (String line : text.split("\n"))
            {
                if (!line.trim().startsWith("import"))
                    output.write(line + "\n");
            }
            output.write("} }");
            output.close();
            } catch (Exception e) { e.printStackTrace(); }
        }
        
        private void writeJepFile(String scriptdefname, String text)
        {   
            if (text.contains("${"))
            {
                log("E: ${ found in " + scriptdefname);
                currentFile.incErrorCount();
            }
          
            try {
            String heliumpath = new File(project.getProperty("helium.build.dir")).getCanonicalPath();
            new File(heliumpath + File.separator + "jep").mkdirs();
            File file = new File(heliumpath + File.separator + "jep" + File.separator + scriptdefname + "_jep.py");
            PrintWriter output = new PrintWriter(new FileOutputStream(file));
            output.write("attributes = {} # pylint: disable-msg=C0103\n");
            output.write("elements = {} # pylint: disable-msg=C0103\n");
            output.write("project = None # pylint: disable-msg=C0103\n");
            output.write("self = None # pylint: disable-msg=C0103\n");
            text = text.replace(" File(", " self.File(");
            
            output.write(text);
            output.close();
            
            if (text.contains("import "))
            {
                File file2 = new File(heliumpath + File.separator + "test_jython.xml");
                PrintWriter output2 = new PrintWriter(new FileOutputStream(file2, true));
                output2.write("try:\n");
                for (String line : text.split("\n"))
                {
                    if (line.trim().startsWith("import ") || line.trim().startsWith("from "))
                        output2.write("    " + line + "\n");
                }
                
                output2.write("except ImportError, e:\n");
                output2.write("    print '" + scriptdefname + " failed: ' + str(e)\n");
                output2.close();
            }
            } catch (Exception e) { e.printStackTrace(); }
        }
        
        private void checkJepPropertiesInText(String text)
        {
            Pattern p1 = Pattern.compile("getProperty\\([\"']([a-zA-Z0-9\\.]*)[\"']\\)");
            Matcher m1 = p1.matcher(text);
            ArrayList<String> props = new ArrayList<String>();
            while (m1.find())
            {
                props.add(m1.group(1));
            }
            for (String group : props)
                checkPropertyInModel(group);
        }
        
        private void checkPropertiesInText(String text)
        {
            Pattern p1 = Pattern.compile("r[\"']\\$\\{([a-zA-Z0-9\\.]*)\\}[\"']");
            Matcher m1 = p1.matcher(text);
            ArrayList<String> props = new ArrayList<String>();
            while (m1.find())
            {
                props.add(m1.group(1));
            }
            for (String group : props)
                checkPropertyInModel(group);
        }
        
        public void checkScriptdef(String name, Node node)
        {   
            List<Node> statements = node.selectNodes("//scriptdef[@name='" + name + "']/attribute");
            
            Pattern p1 = Pattern.compile("attributes.get\\([\"']([^\"']*)[\"']\\)");
            Matcher m1 = p1.matcher(node.getText());
            ArrayList<String> props = new ArrayList<String>();
            while (m1.find())
            {
                props.add(m1.group(1));
            }
            
            ArrayList<String> attributes = new ArrayList<String>();
            for (Node statement : statements)
            {
                attributes.add(statement.valueOf("@name"));
            }
            for (String x : props)
            {
                if (!attributes.contains(x))
                {
                    log("E: Scriptdef " + name + " does not have attribute " + x);
                    currentFile.incErrorCount();
                }
            }
            
            if (!statements.isEmpty() && props.isEmpty())
            {
                log("W: Scriptdef " + name + " doesn't reference attributes directly, poor style");
                currentFile.incWarningCount();
            }
            else
            {
                for (Node statement : statements)
                {                
                    if (!props.contains(statement.valueOf("@name")))
                    {
                        //for (String x : props)
                        //    log(x);
                        log("E: Scriptdef " + name + " does not use " + statement.valueOf("@name"));
                        currentFile.incErrorCount();
                    }
                }
            }
        }
        
        public void checkPropertyInModel(String customerProp)
        {
            SAXReader xmlReader = new SAXReader();
            Document antDoc = null;
            
            try {
            File model = new File(project.getProperty("data.model.parsed"));
            antDoc = xmlReader.read(model);
            } catch (Exception e) { e.printStackTrace(); }
            
            List<Node> statements = antDoc.selectNodes("//property");
            
            for (Node statement : statements)
            {
                if (customerProp.equals(statement.valueOf("name")))
                {
                    return;
                }
            }
            log("W: " + customerProp + " not in data model");
            currentFile.incWarningCount();
        }
                  
        private void checkTargetName(String text)
        {     
            try
            {
                Pattern p1 = Pattern.compile(targetNamePattern);
                Matcher m1 = p1.matcher(text);
                if (!m1.matches())
                {
                    log("W: INVALID Target Name: " + text);
                    currentFile.incWarningCount();
                }
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }
        }
        
        private void checkUseOfIf(Element node)
        {
            String target = node.attributeValue("name");
            String targetxpath = "//target[@name='" + target + "']/if";
            
            List conditiontest = node.selectNodes(targetxpath + "/then/property");
            if (conditiontest != null && conditiontest.size() == 1)
            {
                if (node.selectSingleNode(targetxpath + "/else") == null)
                {
                    log("W: Target " + target + " poor use of if-then-property statement, use condition task");
                    currentFile.incWarningCount();
                }
                else
                {
                    List conditiontest2 = node.selectNodes(targetxpath + "/else/property");
                    if (conditiontest2 != null && conditiontest2.size() == 1)
                    {
                        log("W: Target " + target + " poor use of if-else-property statement, use condition task");
                        currentFile.incWarningCount();
                    }
                }
            }
            
            List statements = node.selectNodes("//target[@name='" + target + "']/*");
            if (!(statements.size() > 1))
            {
                if (node.selectSingleNode(targetxpath + "/else") == null)
                {
                    if (node.selectSingleNode(targetxpath + "/isset") != null || node.selectSingleNode(targetxpath + "/not/isset") != null)
                    {
                        log("W: Target " + target + " poor use of if statement, use <target if|unless=\"prop\"");
                        //log(node.selectSingleNode(targetxpath).asXML());
                        currentFile.incWarningCount();
                    }
                }
            }
        }
        
        private void checkSizeOfScript(Element node)
        {
            String target = node.attributeValue("name");
            
            List<Node> statements = node.selectNodes("//target[@name='" + target + "']/script | //target[@name='" + target + "']/*[name()=\"hlm:python\"]");
            
            for (Node statement : statements)
            {
                int size = statement.getText().length();
                
                if (size > 1000)
                {
                    log("W: Target " + target + " has a script with " + size + " characters, code should be inside a python file");
                    currentFile.incWarningCount();
                }
            }
        }
        
        private void checkTabsInScript(Element node)
        {
            String target = node.attributeValue("name");
            
            List<Node> statements = node.selectNodes("//target[@name='" + target + "']/script | //target[@name='" + target + "']/*[name()=\"hlm:python\"]");
            
            for (Node statement : statements)
            {
                if (statement.getText().contains("\t"))
                {
                    log("E: Target " + target + " has a script with tabs");
                    currentFile.incErrorCount();
                }
            }
        }
                
            
        
        private void checkPropertyName(String text)
        {
            try
            {
                Pattern p1 = Pattern.compile(propertyNamePattern);
                Matcher m1 = p1.matcher(text);
                if (!m1.matches() && !propertiesVisited.contains(text))
                {
                    log("W: INVALID Property Name: " + text);
                    propertiesVisited.add(text);
                    currentFile.incWarningCount();
                }
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }
        }
        
        private void checkDefName(String text)
        {
            try
            {
                Pattern p1 = Pattern.compile(presetDefMacroDefNamePattern);
                Matcher m1 = p1.matcher(text);
                if (!m1.matches())
                {
                    log("W: INVALID PRESETDEF/MACRODEF Name: " + text);
                    currentFile.incWarningCount();
                }
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }
        }
        
        private boolean checkTargetDependency(String text)
        {     
            boolean dependencyCheck = false;
            try
            {
                Target targetDependency = (Target) project.getTargets().get(text);
                if (targetDependency != null)
                {
                    if (targetDependency.getDependencies().hasMoreElements())
                    {
                        dependencyCheck = true;
                    }
                }
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }
            finally
            {
                return dependencyCheck;
            }
        }   
    }
    
    private class AntProjectVisitor extends VisitorSupport
    {    
        public void visit(Element node)
        {
            String name = node.getName();
            if (name.equals("project"))
            {
                String text = node.attributeValue("name");
                if (text != null && projectNameCheck)
                {
                    checkProjectName(text);
                }
                else
                {
                    log("W: Project name not specified!");
                    currentFile.incWarningCount();
                } 
                if ((node.element("description") == null) && descriptionCheck)
                {
                    log("W: Description not specified!");
                    currentFile.incWarningCount();
                }
            }
        }
        
        private void checkProjectName(String text)
        {
            try
            {
                Pattern p1 = Pattern.compile(projectNamePattern);
                Matcher m1 = p1.matcher(text);
                if (!m1.matches())
                {
                    log("W: INVALID Project Name: " + text);
                    currentFile.incWarningCount();
                }
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }
        }
    }
    
    private class AntLintHandler extends DefaultHandler
    {
        private int indentLevel;
        private int indentSpace;
        private Locator locator;
        private boolean textElement;
        private int currentLine;
        private StringBuffer strBuff = new StringBuffer();
        
        public AntLintHandler()
        {
            super();
        }
        
        public void setDocumentLocator(Locator locator)
        {
            this.locator = locator;
        }
        
        public void startDocument ()
        {
            indentLevel -= 4;
        }
    
    
        public void endDocument ()
        {
            
        }
        
        public void startElement(String uri, String name,
                  String qName, Attributes atts)
        {
            countSpaces();
            indentLevel += 4; //When an element start tag is encountered, indentLevel is increased 4 spaces.
            checkIndent();
            currentLine = locator.getLineNumber();
        }

        public void endElement(String uri, String name, String qName)
        {
            countSpaces();
            //Ignore end tags in the same line
            if (currentLine != locator.getLineNumber()) {
                checkIndent();
            }
            indentLevel -= 4; //When an element end tag is encountered, indentLevel is decreased 4 spaces.
            textElement = false;
        }
        
        private void checkIndent()
        {
            if (indentationCheck)
            {
                if ((indentSpace != indentLevel) && !textElement)
                {
                    log("E:" + locator.getLineNumber() + ": Bad indentation!");
                    currentFile.incErrorCount();
                }
            }           
        }
              
        public void characters(char[] ch, int start, int length)
        {
            for (int i = start; i < start + length; i++) 
            {
                strBuff.append(ch[i]);
            }
        }
        
        public void countSpaces()
        {
            //Counts spaces and tabs in every newline.
            int numSpaces = 0;
            for (int i = 0; i < strBuff.length(); i++) 
            {
                switch (strBuff.charAt(i)) {
                    case '\t':
                        numSpaces += 4;
                        if (tabCharacterCheck)
                        {
                            log("E:" + locator.getLineNumber() + ": Tabs should not be used!");
                            currentFile.incErrorCount();
                        }
                        break;
                    case '\n':
                        numSpaces = 0;
                        break;
                    case '\r':
                        break;
                    case ' ':
                        numSpaces++;
                        break;
                    default:
                        textElement = true;
                        break;
                }
            }
            indentSpace = numSpaces;
            strBuff.delete(0,strBuff.length());
        }
    }
}