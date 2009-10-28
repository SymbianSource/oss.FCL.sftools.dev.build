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
 
package com.nokia.ant.taskdefs;

import org.apache.tools.ant.Project;
import com.nokia.ant.types.LogFilterSet;

interface LogRecorderEntry
{
    void openFile(boolean append);

    void reopenFile();

    void closeFile();

    void setRecordState(boolean state);
    
    void setEmacsMode(boolean emacsMode);
    
    void setMessageOutputLevel(int level);

    void setProject(Project project);

    String getFilename();

    void setFilterSet(LogFilterSet o);
    
    void setRegexp(String regexp);
}
