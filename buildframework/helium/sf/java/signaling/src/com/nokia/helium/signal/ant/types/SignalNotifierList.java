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

 
package com.nokia.helium.signal.ant.types;

import java.util.Vector;

import org.apache.tools.ant.types.DataType;

import com.nokia.helium.signal.ant.Notifier;

    
/**
 * Helper class to store the list of notifiers.
 *
 * Example:
 * <pre>
 *   &lt;hlm:notifierList id="defaultSignalFailNotifier"&gt;
 *       &lt;hlm:emailNotifier templateSrc="${helium.dir}/tools/common/templates/log/email_new.html.ftl" title="[signal] ${signal.name}"
 *          smtp="${email.smtp.server}" ldap="${email.ldap.server}" notifyWhen="fail"&gt;
 *       &lt;/hlm:emailNotifier&gt;
 *   &lt;/hlm:notifierList&gt;
 * </pre>
 * @ant.task name="notifierList" category="Signaling" 
 */
public class SignalNotifierList extends DataType {

    private Vector<Notifier> notifierlist = new Vector<Notifier>();
    
    /**
     * Adding a Notifier.
     * @param notifier
     */
    public void add(Notifier notifier) {
        notifierlist.add(notifier);
    }
            
    /**
     * Returns the list of variables available in the VariableSet 
     * @return variable list
     */
    public Vector<Notifier> getNotifierList() {
        return notifierlist;
    }
}
