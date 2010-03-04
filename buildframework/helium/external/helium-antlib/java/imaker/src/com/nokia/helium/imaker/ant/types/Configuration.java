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
 
package com.nokia.helium.imaker.ant.types;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.PatternSet;

import com.nokia.helium.imaker.IMaker;
import com.nokia.helium.imaker.IMakerException;
import com.nokia.helium.imaker.ant.Command;
import com.nokia.helium.imaker.ant.IMakerCommandSet;

import java.io.File;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.Vector;
import java.util.regex.Pattern;

/**
 * The imakerconfiguration enables the build manager to configure his iMaker
 * builds based on introspection.
 *
 * The makefileset element will configure the filtering of the "imaker help-config"
 * command. Then for each of the configuration found the targetset elements will be used
 * to filter the output from the "imaker -f <i>configuration.mk</i> help-target-*-list"
 * command. Finally a set of command will be generated.
 *
 * Each command will then be configure using the set of variables defined by the variableset
 * elements. Only the WORKDIR variable is under the task control to ensure call safety during the
 * parallelization. 
 * 
 * The usage of the variablegroup will allow you to duplicate the common set of commands 
 * and apply additional variables.    
 *
 * Example: 
 * <pre>
 *     &lt;imakerconfiguration regionalVariation="true"&gt;
 *         &lt;makefileset&gt;
 *             &lt;include name="*&#42;/product/*ui.mk"/&gt;
 *         &lt;/makefileset&gt;
 *         &lt;targetset&gt;
 *             &lt;include name="^core$" /&gt;
 *             &lt;include name="langpack_\d+" /&gt;
 *             &lt;include name="^custvariant_.*$" /&gt;
 *             &lt;include name="^udaerase$" /&gt;
 *         &lt;/targetset&gt;
 *         &lt;variableset&gt;
 *             &lt;variable name="USE_FOTI" value="0"/&gt;
 *             &lt;variable name="USE_FOTA" value="1"/&gt;
 *         &lt;/variableset&gt;
 *         &lt;variablegroup&gt;
 *             &lt;variable name="TYPE" value="rnd"/&gt;
 *         &lt;/variablegroup&gt;
 *         &lt;variablegroup&gt;
 *             &lt;variable name="TYPE" value="subcon"/&gt;
 *         &lt;/variablegroup&gt;
 *     &lt;/imakerconfiguration&gt;
 * </pre>
 *
 * This configuration might produce the following calls :
 * <pre>
 * imaker -f /epoc32/rom/config/platform/product/image_conf_product_ui.mk TYPE=rnd USE_FOTI=0 USE_FOTA=1 core
 * imaker -f /epoc32/rom/config/platform/product/image_conf_product_ui.mk TYPE=subcon USE_FOTI=0 USE_FOTA=1 core
 * imaker -f /epoc32/rom/config/platform/product/image_conf_product_ui.mk TYPE=rnd USE_FOTI=0 USE_FOTA=1 langpack_01
 * imaker -f /epoc32/rom/config/platform/product/image_conf_product_ui.mk TYPE=subcon USE_FOTI=0 USE_FOTA=1 langpack_01
 * </pre>
 * 
 * @ant.type name="imakerconfiguration" category="imaker"
 */
public class Configuration extends DataType implements IMakerCommandSet {
    
    private Vector<PatternSet> makefiles = new Vector<PatternSet>();
    private Vector<MakefileSelector> selectors = new Vector<MakefileSelector>();
    private Vector<PatternSet> targets = new Vector<PatternSet>();
    private Vector<VariableSet> variables = new Vector<VariableSet>();
    private Vector<VariableGroup> variablegroups = new Vector<VariableGroup>();
    private boolean regionalVariation;
    
    /**
     * Create a makefileset element.
     * Makefileset elements are based on regular Ant PatternSet.
     * @return a PatternSet object.
     */
    public PatternSet createMakefileSet() {
        PatternSet makefile =  new PatternSet();
        makefiles.add(makefile);
        return makefile;
    }
    
    /**
     * Get the list of makefileset element.
     * @return a vector of PatternSet objects.
     */
    public Vector<PatternSet> getMakefileSet() {
        return makefiles;
    }
    
    /**
     * Add a Makefile selector configuration (e.g: products)
     * @param filter
     */
    public void add(MakefileSelector filter) {
        selectors.add(filter);
    }
    
    /**
     * Create a targetset element.
     * Targetset elements are based on regular Ant PatternSet.
     * @return a PatternSet object.
     */
    public PatternSet createTargetSet() {
        PatternSet target =  new PatternSet();
        targets.add(target);
        return target;
    }
    
    /**
     * Get the list of targetset.
     * @return a vector of PatternSet objects.
     */
    public Vector<PatternSet> getTargetSet() {
        return targets;
    }

    /**
     * Create a VariableSet element.
     * @return a VariableSet object.
     */
    public VariableSet createVariableSet() {
        VariableSet var =  new VariableSet();
        variables.add(var);
        return var;
    }
        
    /**
     * Create a VariableSet element.
     * @return a VariableSet object.
     */
    public VariableGroup createVariableGroup() {
        VariableGroup var =  new VariableGroup();
        variablegroups.add(var);
        return var;
    }
        
    /**
     * Get the list of variableset.
     * @return a vector of VariableSet objects.
     */
    public Vector<VariableSet> getVariableSet() {
        return variables;
    }

    /**
     * Enables the sorting of images per region. 
     * @deprecated The usage of this feature is now ignored.
     * @param value the state of the regional variation
     * @ant.not-required Default is false - The usage of this feature is now ignored.
     */
    @Deprecated
    public void setRegionalVariation(boolean value) {
        log(this.getDataTypeName() + ": the usage of the regionalVariation attribute is now ignored.", Project.MSG_WARN);
        regionalVariation = value;
    }

    /**
     * Get the status of the regional variation enabling.
     * @deprecated The usage of this feature is now ignored.
     * @return returns true is the regional variation should be enabled.
     */
    public boolean getRegionalVariation() {
        return regionalVariation;
    }

    /**
     * Check if name is matching any of the pattern under patterns list.
     * @param name the string to match
     * @param patterns a list of PatternSet
     * @return Returns true if name matches at least one pattern.
     */
    protected boolean isIncluded(String name, Vector<PatternSet> patterns) {
        for (PatternSet patternSet : patterns) {
            if (patternSet.isReference()) {
                patternSet = (PatternSet) patternSet.getRefid().getReferencedObject();
            }
            String[] includes = patternSet.getIncludePatterns(getProject());
            if (includes != null) {
                for (String pattern : includes) {
                    if (Pattern.matches(pattern, name)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
     * Check if name is matching any of the pattern under patterns list.
     * @param name the string to match
     * @param patterns a list of PatternSet
     * @return Returns true if name matches at least one pattern.
     */
    protected boolean isExcluded(String name, Vector<PatternSet> patterns) {
        for (PatternSet patternSet : patterns) {
            if (patternSet.isReference()) {
                patternSet = (PatternSet) patternSet.getRefid().getReferencedObject();
            }
            String[] excludes = patternSet.getExcludePatterns(getProject());
            if (excludes != null) {
                for (String pattern : excludes) {
                    if (Pattern.matches(pattern, name)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    /**
     * Get a configured matcher.
     * @return a configured makefile matcher.
     */
    protected Matcher getMakefileMatcher() {
        Matcher matcher = new Matcher();
        List<String> includes = new ArrayList<String>(); 
        List<String> excludes = new ArrayList<String>(); 
        for (PatternSet patternSet : makefiles) {
            if (patternSet.isReference()) {
                patternSet = (PatternSet) patternSet.getRefid().getReferencedObject();
            }
            String[] patterns = patternSet.getIncludePatterns(getProject());
            if (patterns != null) {
                for (String pattern : patterns) {
                    includes.add(pattern);
                }
            }
            patterns = patternSet.getExcludePatterns(getProject());
            if (patterns != null) {
                for (String pattern : patterns) {
                    excludes.add(pattern);
                }
            }
        }    
        matcher.setIncludes(includes.toArray(new String[includes.size()]));
        matcher.setExcludes(excludes.toArray(new String[excludes.size()]));
        return matcher;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public List<List<Command>> getCommands(IMaker imaker) {
        List<List<Command>> cmdSet = new ArrayList<List<Command>>();
        List<Command> cmds = new ArrayList<Command>();
        // Let's add one fake group.
        if (variablegroups.size() == 0) {
            variablegroups.add(new VariableGroup());
        }
        try {
            for (String configuration : getConfigurations(imaker.getConfigurations())) {
                log("Including configuration: " + configuration);
                for (String target : imaker.getTargets(configuration)) {
                    if (isIncluded(target, targets) && !isExcluded(target, targets)) {
                        log("Including target: " + target);
                        for (VariableGroup group : variablegroups) {
                            if (group.isReference()) {
                                group = (VariableGroup)group.getRefid().getReferencedObject();
                            }
                            Command cmd = new Command();
                            cmd.setCommand("imaker");
                            cmd.addArgument("-f");
                            cmd.addArgument(configuration);
                            // Adding variables
                            for (VariableSet vs : variables) {
                                cmd.addVariables(vs.toMap());
                            }
                            // Adding variables from groups
                            cmd.addVariables(group.toMap());
                            cmd.setTarget(target);
                            cmds.add(cmd);
                        }
                    }
                }
            }
        } catch (IMakerException e) {
            throw new BuildException(e.getMessage());
        }
        // adding all the commands.
        if (cmds.size() > 0) {
            cmdSet.add(cmds);
        }
        return cmdSet;
    }
    
    /**
     * Select which iMaker configuration should be built.
     * @param configurations
     * @return
     */
    protected Set<String> getConfigurations(List<String> configurations) {
        Set<String> result = new HashSet<String>();
        if (makefiles.size() > 0) {
            Matcher matcher = getMakefileMatcher();
            for (String configuration : configurations) {
                if (matcher.match(configuration)) {
                    result.add(configuration);
                }
            }
        }
        for (MakefileSelector selector : selectors) {
            result.addAll(selector.selectMakefile(configurations));
        }
        return result;
    }
    
    /**
     * Matcher object to filter discovered configurations.
     * iMaker configuration.
     */
    public class Matcher extends DirectoryScanner {
        
        /**
         * Check is a particular configuration can
         * is selected.
         * @param path the string to match.
         * @return return true is the path is selected.
         */
        public boolean match(String path) {
            String vpath = path.replace('/', File.separatorChar).
                replace('\\', File.separatorChar);
            return isIncluded(vpath) && !isExcluded(vpath);
        }
    }

}
