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

package com.nokia.ant;

import junit.framework.*;

/**
 * Test class for Helium Logger.
 * 
 */
public class HeliumLoggerTest extends TestCase {
    
    /**
     * Basic test to check if the property
     * is set correctly. 
     */
    public void testSetStopLogToConsole() {
        HeliumLogger logger = new HeliumLogger();
        logger.setStopLogToConsole(true);
        assert logger.getStopLogToConsole();
    }
}
