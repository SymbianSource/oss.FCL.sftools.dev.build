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

 
package com.nokia.helium.core.ant.types;

import java.util.List;

import org.apache.tools.ant.types.DataType;
import java.util.ArrayList;
import com.nokia.helium.core.ant.Message;
    
/**
 * Helper class to store the list of targets to be recorded and to be sent for diamonds.
 *
 * Example 1:
 * <pre>
 *    &lt;hlm:targetMessageTrigger id="diamonds.id" target="diamonds"&gt;
 *        &lt;hlm:fmppMessage&gt;
 *            &lt;converterTask id="tools-conversion" sourceFile="${helium.dir}/tools/common/templates/diamonds/tool.xml.ftl" outputFile="${build.output.dir}/tool.xml"&gt;
 *                &lt;data expandProperties="yes"&gt;
 *                    ant: antProperties()
 *                &lt;/data&gt;
 *            &lt;/converterTask&gt;
 *        &lt;/hlm:fmppMessage&gt;
 *    &lt;/hlm:targetMessageTrigger&gt;
 * <pre>
 * @ant.type name="TargetMessageTrigger" category="Core" 
 */
 
 
public class TargetMessageTrigger extends DataType {

    private String targetName;
    
    private boolean condition = true;
    
    private List<Message> messageList = new ArrayList<Message>();

    /**
     * Helper function to add message to the list.
     * 
     * @param message message to be added to the list
     */
    public void add(Message message) {
        messageList.add(message);
    }

    public void setCondition(boolean condition) {
        this.condition = condition;
    }
    public boolean isTriggerNeeded() {
        return condition;
    }
    /**
     * To get the message list to be processed further.
     * 
     * @return the message list. 
     */
    public List<Message> getMessageList() {
        return messageList;
    }

    /**
     * Sets the target name for which the message to be processed.
     * 
     * @param name of the target.
     */
    public void setTarget(String name) {
        targetName = name;
    }
    
    /**
     * Helper function to get the target name for which the message is processed.
     * 
     * @return target name.
     */
    public String getTargetName() {
        return targetName;
    }
}