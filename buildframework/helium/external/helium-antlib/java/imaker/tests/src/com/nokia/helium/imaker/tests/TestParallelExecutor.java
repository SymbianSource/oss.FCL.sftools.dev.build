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
package com.nokia.helium.imaker.tests;

import java.io.File;
import org.junit.Test;
import com.nokia.helium.imaker.utils.ParallelExecutor;

/**
 * Basic testing of the ParallelExecutor
 *
 */
public class TestParallelExecutor {
	private File testdir = new File(System.getProperty("testdir"));
	
	/**
	 * Nothing should happen.
	 */
	@Test
	public void executionWithNoArgs() {
		String args[] = new String[0];
		ParallelExecutor.main(args);
	}

	/**
	 * Will list current directory content twice.
	 */
	@Test
	public void executionWithTextFile() {
		String args[] = new String[1];
        if (System.getProperty("os.name").toLowerCase().startsWith("win")) {
        	args[0] = new File(testdir, "tests/parallelexecutor_data/windows.txt").getAbsolutePath();
        } else {
        	args[0] = new File(testdir, "tests/parallelexecutor_data/linux.txt").getAbsolutePath();
        }
		ParallelExecutor.main(args);
	}

}
