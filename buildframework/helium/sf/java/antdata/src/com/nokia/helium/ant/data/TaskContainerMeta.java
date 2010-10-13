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

import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.Project;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.Visitor;
import org.dom4j.VisitorSupport;

/**
 * Meta data for Ant objects that can contain other tasks.
 */
public class TaskContainerMeta extends AntObjectMeta {
    private ArrayList<String> antcallTargets;
    private ArrayList<String> logs;
    private ArrayList<String> signals;
    private ArrayList<String> executables;

    public TaskContainerMeta(AntObjectMeta parent, Node node) {
        super(parent, node);
        callAntTargetVisitor();
    }

    public List<String> getExecTargets() {
        return antcallTargets;
    }

    public List<String> getLogs() {
        return logs;
    }

    public List<String> getSignals() {
        return signals;
    }

    public List<String> getExecutables() {
        return executables;
    }

    private void callAntTargetVisitor() {
        // Add antcall/runtarget dependencies
        antcallTargets = new ArrayList<String>();
        logs = new ArrayList<String>();
        signals = new ArrayList<String>();
        executables = new ArrayList<String>();

        Visitor visitorTarget = new AntTargetVisitor(antcallTargets, logs, signals, executables);
        getNode().accept(visitorTarget);
    }

    private class AntTargetVisitor extends VisitorSupport {
        private List<String> targetList;
        private List<String> logList;
        private List<String> signalList;
        private List<String> executableList;

        public AntTargetVisitor(List<String> targetList, List<String> logList, List<String> signalList,
                List<String> executableList) {
            this.targetList = targetList;
            this.logList = logList;
            this.signalList = signalList;
            this.executableList = executableList;
        }

        @Override
        public void visit(Element node) {
            String name = node.getName();
            if (name.equals("antcall") || name.equals("runtarget")) {
                String text = node.attributeValue("target");
                targetList.add(text);
            }

            if (!name.equals("include") && !name.equals("exclude")) {
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

            if (name.endsWith("signal") || name.endsWith("execSignal")) {
                String signalid = node.attributeValue("name");

                if (signalid != null && signalid.length() > 0) {
                    signalList.add(signalid);
                }
            }

            if (name.equals("exec") || name.equals("preset.exec")) {
                String text = node.attributeValue("executable");
                executableList.add(text);
                log("Executable: " + text, Project.MSG_DEBUG);
            }
        }

        private void addLog(String text) {
            if (text != null && logList != null) {
                for (String log : text.split(" ")) {
                    String fulllogname = log;
                    if (!logList.contains(log) && (fulllogname.endsWith(".log") || fulllogname.endsWith(".html"))) {
                        log = log.replace("--log=", "");
                        logList.add(log);
                    }
                }
            }
        }
    }
}
