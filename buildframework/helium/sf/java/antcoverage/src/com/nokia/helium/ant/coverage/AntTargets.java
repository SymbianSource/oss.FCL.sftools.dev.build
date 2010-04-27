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
package com.nokia.helium.ant.coverage;

import java.util.Vector;

import org.apache.tools.ant.Target;

/**
 * To store anttarget information.
 */

public class AntTargets {

    private Vector<TargetHolder> antTargets = new Vector<TargetHolder>();

    /**
     * To add target name into list.
     * 
     * @param target
     */
    public void add(Target target) {
        for (TargetHolder th : antTargets) {
            if (th.equals(target)) {
                th.add(target);
                return;
            }
        }
        if (!antTargets.contains(target.getName())) {
            TargetHolder th = new TargetHolder();
            th.add(target);
            antTargets.add(th);
        }
    }

    /**
     * To get number of targets.
     * 
     * @return
     */
    public int getCount() {
        return this.antTargets.size();
    }

    /**
     * To check is test target present in the Ant targets list.
     * 
     * @param targetName
     * @return
     */
    public boolean isTargetPresent(String targetName) {
        return antTargets.contains(targetName);
    }

    /**
     * 
     * @param targetName
     */
    public void markAsExecuted(String targetName) {
        for (TargetHolder th : antTargets) {
            if (th.equals(targetName)) {
                th.markAsExecuted();
                return;
            }
        }
    }
    
    /**
     * The count of distinct executed target.
     * @return the number of distinct executed target.
     */
    public int getExecutedCount() {
        int count = 0;
        for (TargetHolder th : antTargets) {
            if (th.isExecuted()) {
                count++;
            }
        }
        return count;
    }
    
    /**
     * Holder class that store equivalent target: different name but
     * same implementation location.
     *
     */
    public class TargetHolder {

        private Vector<Target> instances = new Vector<Target>();
        private boolean executed;
       
        /**
         * Add a new variant of the target.
         * @param t
         */
        public void add(Target t) {
            instances.add(t);
        }
        
        /**
         * Depends on the type of the given object:
         * For Strings it will compare with nested name of target object.
         * For Target comparison will be based on the location.
         */
        public boolean equals(Object obj) {
            if (obj instanceof String) {
                String str = (String)obj;
                for (Target t : instances) {
                    if (t.getName().equals(str)) {
                        return true;
                    }
                }
            } else if (obj instanceof Target) {
                Target target = (Target) obj;
                for (Target t : instances) {
                    if (t.getLocation().equals(target.getLocation())) {
                        return true;
                    }
                }
            }
            return false;
        }

        /**
         * {@inheritDoc}
         */
        public int hashCode() {
            return super.hashCode();
        }

        /**
         * Mark as executed.
         */
        public void markAsExecuted() {
            this.executed = true;
        }
        
        /**
         * As this target been executing?
         */
        public boolean isExecuted() {
            return executed;
        }
    }
}
