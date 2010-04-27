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
 * To store antmacro information.
 */
public class AntMacros {
    private Vector<MacroHolder> antMacros = new Vector<MacroHolder>();

    /**
     * To add macro.
     * 
     * @param macro
     */
    public void add(String macro) {
        for (MacroHolder mh : antMacros) {
            if (mh.equals(macro))
                return;
        }
        this.antMacros.add(new MacroHolder(macro));
    }

    /**
     * To get number of ant macros.
     * 
     * @return
     */
    public int getCount() {
        return this.antMacros.size();
    }

    /**
     * To check is the macro present in the list.
     * 
     * @param macroName
     * @return
     */
    public boolean isMacroPresent(String macroName) {
        return antMacros.contains(macroName);
    }

    /**
     * 
     * @param targetName
     */
    public void markAsExecuted(String targetName) {
        for (MacroHolder mh : antMacros) {
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
        for (MacroHolder mh : antMacros) {
            if (mh.isExecuted()) {
                count++;
            }
        }
        return count;
    }

    /**
     * Holder class to contains macro related informations.
     * 
     */
    public class MacroHolder {
        private String name;
        private boolean executed;

        /**
         * Create a scripdef holder.
         * 
         * @param name
         */
        public MacroHolder(String name) {
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
