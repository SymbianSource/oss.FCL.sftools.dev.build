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

/**
 * To store antscriptdef information.
 */
public class AntScriptDefs {
    private Vector<ScriptDefHolder> antScriptdefs = new Vector<ScriptDefHolder>();

    /**
     * To add scriptdef into list.
     * 
     * @param scriptDef
     */
    public void add(String scriptDef) {
        for (ScriptDefHolder sh : antScriptdefs) {
            if (sh.equals(scriptDef))
                return;
        }
        this.antScriptdefs.add(new ScriptDefHolder(scriptDef));
    }

    /**
     * To get number of scriptdefs.
     * 
     * @return
     */
    public int getCount() {
        return this.antScriptdefs.size();
    }

    /**
     * To check is the scriptdef present.
     * 
     * @param scriptDef
     * @return
     */
    public boolean isScriptDefPresent(String scriptDef) {
        return antScriptdefs.contains(scriptDef);
    }

    /**
     * 
     * @param targetName
     */
    public void markAsExecuted(String targetName) {
        for (ScriptDefHolder mh : antScriptdefs) {
            if (mh.equals(targetName)) {
                mh.markAsExecuted();
                return;
            }
        }
    }

    /**
     * The count of distinct executed target.
     * 
     * @return the number of distinct executed target.
     */
    public int getExecutedCount() {
        int count = 0;
        for (ScriptDefHolder mh : antScriptdefs) {
            if (mh.isExecuted()) {
                count++;
            }
        }
        return count;
    }

    /**
     * Holder class to contains scriptdef related informations.
     * 
     */
    public class ScriptDefHolder {
        private String name;
        private boolean executed;

        /**
         * Create a scripdef holder.
         * 
         * @param name
         */
        public ScriptDefHolder(String name) {
            this.name = name;
        }

        /**
         * Is this holder matching a particular object.
         */
        public boolean equals(Object obj) {
            return this.name.equals(obj);
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
