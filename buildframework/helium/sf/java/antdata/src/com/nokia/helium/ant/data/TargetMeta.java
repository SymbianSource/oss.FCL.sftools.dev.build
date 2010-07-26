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

package com.nokia.helium.ant.data;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.StringTokenizer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.Project;
import org.dom4j.Attribute;
import org.dom4j.CDATA;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.Text;
import org.dom4j.Visitor;
import org.dom4j.VisitorSupport;

/**
 * Meta object representing a target.
 */
public class TargetMeta extends TaskContainerMeta {

    public TargetMeta(AntObjectMeta parent, Node node) throws IOException {
        super(parent, node);
        // callAntTargetVisitor();
    }

    public String getIf() {
        return getAttr("if");
    }

    public String getUnless() {
        return getAttr("unless");
    }

    public String getDescription() {
        return getAttr("description");
    }

    /**
     * Use the standard Ant description element if there is no summary in a
     * comment.
     */
    public String getSummary() {
        String summary = super.getSummary();
        if (summary.length() == 0) {
            summary = getDescription();
        }
        return summary;
    }

    public List<String> getDepends() {
        String dependsAttr = getAttr("depends");
        StringTokenizer st = new StringTokenizer(dependsAttr, ",");
        List<String> depends = new ArrayList<String>();
        while (st.hasMoreTokens()) {
            depends.add(st.nextToken().trim());
        }
        return depends;
    }

    public List<String> getSignals() {
        List<String> signals = super.getSignals();
        List<String> additionalSignals = getDatabase().getSignals(getName());
        if (additionalSignals != null) {
            signals.addAll(additionalSignals);
        }
        return signals;
    }

    public List<String> getPropertyDependencies() {
        ArrayList<String> properties = new ArrayList<String>();
        Visitor visitor = new AntPropertyVisitor(properties);
        getNode().accept(visitor);
        return properties;
    }

    private class AntPropertyVisitor extends VisitorSupport {
        private List<String> propertyList;

        public AntPropertyVisitor(List<String> propertyList) {
            this.propertyList = propertyList;
        }

        public void visit(Attribute node) {
            String text = node.getStringValue();
            extractUsedProperties(text);
        }

        public void visit(CDATA node) {
            String text = node.getText();
            extractUsedProperties(text);
        }

        public void visit(Text node) {
            String text = node.getText();
            extractUsedProperties(text);
        }

        public void visit(Element node) {
            if (node.getName().equals("property")) {
                String propertyName = node.attributeValue("name");
                if (propertyName != null && !propertyList.contains(propertyName)) {
                    propertyList.add(propertyName);
                    // System.out.println("prop "+propertyName);
                    log("property matches :" + propertyName, Project.MSG_DEBUG);
                }
            }
        }

        private void extractUsedProperties(String text) {
            Pattern p1 = Pattern.compile("\\$\\{([^@$}]*)\\}");
            Matcher m1 = p1.matcher(text);
            log(text, Project.MSG_DEBUG);
            while (m1.find()) {
                String group = m1.group(1);
                if (!propertyList.contains(group)) {
                    propertyList.add(group);
                    // System.out.println("m1 "+group + " "+ text);
                }
                log("property matches: " + group, Project.MSG_DEBUG);
            }

            Pattern p2 = Pattern.compile("\\$\\{([^\n]*\\})\\}");
            Matcher m2 = p2.matcher(text);
            log(text, Project.MSG_DEBUG);
            while (m2.find()) {
                String group = m2.group(1);
                if (!propertyList.contains(group)) {
                    propertyList.add(group);
                    // System.out.println("m2 "+group + " "+ text);
                }
                log("property matches: " + group, Project.MSG_DEBUG);
            }

            Pattern p3 = Pattern.compile("\\$\\{(\\@\\{[^\n]*)\\}");
            Matcher m3 = p3.matcher(text);
            log(text, Project.MSG_DEBUG);
            while (m3.find()) {
                String group = m3.group(1);
                if (!propertyList.contains(group)) {
                    propertyList.add(group);
                    // System.out.println("m3 "+group + " "+ text);
                }
                log("property matches: " + group, Project.MSG_DEBUG);
            }
        }
    }

}
