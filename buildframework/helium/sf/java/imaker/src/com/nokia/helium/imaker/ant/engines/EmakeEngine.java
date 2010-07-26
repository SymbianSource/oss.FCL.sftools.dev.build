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
package com.nokia.helium.imaker.ant.engines;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.FileNotFoundException;
import java.io.OutputStreamWriter;
import java.io.StringWriter;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;

import com.nokia.helium.core.plexus.AntStreamConsumer;
import com.nokia.helium.core.plexus.FileStreamConsumer;
import com.nokia.helium.imaker.IMakerException;
import com.nokia.helium.imaker.ant.Command;
import com.nokia.helium.imaker.ant.Engine;
import com.nokia.helium.imaker.ant.taskdefs.IMakerTask;

import freemarker.cache.ClassTemplateLoader;
import freemarker.cache.FileTemplateLoader;
import freemarker.template.Configuration;
import freemarker.template.Template;
import freemarker.template.TemplateException;

/**
 *
 * Simplest possible definition of the type, e.g:
 * <pre>
 * &lt;emakeEngine id="imaker.ec" /&gt;
 * </pre>
 * 
 * Emake engine with some custom configuration.
 * <pre> 
 * &lt;emakeEngine id="imaker.ec" &gt;
 *     &lt;arg value="--emake-annofile=imaker.anno.xml" /&gt;
 * &lt;/emakeEngine&gt;
 * </pre>
 * 
 * @ant.type name=emakeEngine category="imaker"
 */
public class EmakeEngine extends DataType implements Engine {
    private Logger log = Logger.getLogger(getClass());
    private IMakerTask task;
    private List<Arg> customArgs = new ArrayList<Arg>(); 
    private File template;
    
    /**
     * Holder for emake custom args. 
     */
    public class Arg {
        private String value;

        /**
         * Get the value of the argument.
         * @return the argument
         */
        public String getValue() {
            return value;
        }

        /**
         * Define the additional command line parameter you want to add to emake
         * invocation.
         * @param value the additional command line parameter
         * @ant.required
         */
        public void setValue(String value) {
            this.value = value;
        }
    }

    /**
     * {@inheritDoc}
     */
    public void build(List<List<Command>> cmdSet) throws IMakerException {
        File makefile = null;
        try {
            // Writing the makefile.
            makefile = writeMakefile(cmdSet);
            
            // Running Emake
            runEmake(makefile);
        } finally {
            if (makefile != null) {
                makefile.delete();
            }
        }
    }

    /**
     * Returns the jar file name containing this class
     * @return a File object or null if not found.
     * @throws IMakerException
     */
    protected File getJarFile() throws IMakerException {
        URL url = this.getClass().getClassLoader().getResource(this.getClass().getName().replace('.', '/') + ".class");
        if (url.getProtocol().equals("jar") && url.getPath().contains("!/")) {
            String fileUrl = url.getPath().split("!/")[0];
            try {
                return new File(new URL(fileUrl).getPath());
            } catch (MalformedURLException e) {
                throw new IMakerException("Error determining the jar file where "
                        + this.getClass().getName() + " is located.", e);
            }
        }
        return null;
    }
    /**
     * Run emake using defined makefile.
     * @param makefile the makefile to build
     * @throws IMakerException
     */
    private void runEmake(File makefile) throws IMakerException {
        FileStreamConsumer output = null;
        if (task.getOutput() != null) {
            try {
                output = new FileStreamConsumer(task.getOutput());
            } catch (FileNotFoundException e) {
                throw new IMakerException("Error creating the stream recorder: " + e.getMessage(), e);
            }
        }
        try {
            Emake emake = new Emake();
            emake.setWorkingDir(task.getEpocroot());
            List<String> args = new ArrayList<String>();
            for (Arg arg : customArgs) {
                if (arg.getValue() != null) {
                    args.add(arg.getValue());
                }
            }
            args.add("-f");
            args.add(makefile.getAbsolutePath());
            args.add("all");
            if (task.isVerbose()) {
                emake.addOutputLineHandler(new AntStreamConsumer(task));
            }
            emake.addErrorLineHandler(new AntStreamConsumer(task, Project.MSG_ERR));
            if (output != null) {
                emake.addOutputLineHandler(output);
                emake.addErrorLineHandler(output);
            }
            emake.execute(args.toArray(new String[args.size()]));
        } catch (IMakerException e) {
            throw new IMakerException("Error executing emake: " + e.getMessage(), e);
        } finally {
            if (output != null) {
                output.close();
            }
        }
    }
    
    /**
     * Create the Makefile based on the cmdSet build sequence. 
     * @param cmdSet
     * @return
     * @throws IMakerException 
     * @throws IOException
     */
    private File writeMakefile(List<List<Command>> cmdSet) throws IMakerException {
        try {
            Configuration cfg = new Configuration();
            Template template = null;
            if (this.template != null) {
                if (!this.template.exists()) {
                    throw new IMakerException("Could not find template file: " + this.template.getAbsolutePath());
                }
                task.log("Loading template: " + this.template.getAbsolutePath());
                cfg.setTemplateLoader(new FileTemplateLoader(this.template.getParentFile()));
                template = cfg.getTemplate(this.template.getName());
            } else {
                cfg.setTemplateLoader(new ClassTemplateLoader(this.getClass(), ""));
                template = cfg.getTemplate("build_imaker_roms_signing.mk.ftl");
            }
            File makefile = File.createTempFile("helium-imaker", ".mk", task.getEpocroot());
            makefile.deleteOnExit();
            StringWriter out = new StringWriter();
            Map<String, Object> data = new Hashtable<String, Object>();
            data.put("cmdSets", cmdSet);
            data.put("makefile", makefile.getAbsoluteFile());
            data.put("java_home", System.getProperty("java.home"));
            File jar = getJarFile();
            if (jar != null) {
                task.log("Using " + jar + " as the utility container, make sure the file is available under an emake root.");
                data.put("java_utils_classpath", jar.getAbsolutePath());
            }
            template.process(data, out);
            log.debug(out.getBuffer().toString());
        
            OutputStreamWriter output = new OutputStreamWriter(new FileOutputStream(makefile));
            output.append(out.getBuffer().toString());
            output.close();
            return makefile;
        } catch (IOException e) {
           throw new IMakerException("Error generating the makefile: " + e.getMessage(), e);
        } catch (TemplateException e) {
            throw new IMakerException("Error while rendering the makefile template: " + e.getMessage(), e);
        }
    }
    
    /**
     * Add custom parameters for the emake invocation.
     * @return a new Arg object.
     */
    public Arg createArg() {
        Arg arg = new Arg();
        customArgs.add(arg);
        return arg;
    }
    
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void setTask(IMakerTask task) {
        this.task = task;
    }
    
    /**
     * Defines an alternate template to use to generate the build sequence for emake.
     * @ant.not-required
     */
    public void setTemplate(File template) {
        this.template = template;
    }
}
