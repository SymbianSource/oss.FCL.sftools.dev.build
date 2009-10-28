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


import org.apache.tools.ant.types.DataType;
import com.nokia.helium.signal.Notifier;
import java.util.List;

public class SMSNotifier extends DataType implements Notifier {

    public SMSNotifier() {
    }
    /**
     * Sends the data to the requested sender list with specified notifier
     * @param senderList sends the data to the list of requested user.
     */
    public void sendData(String signalName, boolean failStatus,
            NotifierInput notifierInput) {
    }

    /**
     * Sends the data to the requested sender list with specified notifier
     * 
     * @deprecated
     *    sends the data to the list of requested user.
     */
    public void sendData(String signalName, boolean failStatus,
            List<String> fileList) {
    }
}