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
package com.nokia.maven.scm.provider.hg;

import java.io.File;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileStatus;
import org.apache.maven.scm.log.ScmLogger;
import org.apache.maven.scm.provider.hg.HgUtils;
import org.apache.maven.scm.provider.hg.command.HgCommandConstants;
import org.apache.maven.scm.provider.hg.command.HgConsumer;

/**
 * Custom version of the HgUtils helper
 * class.
 * It currently implement a fix function
 * to get the current revision 
 * number.
 *
 */
public final class HgUtilsInternal {
    
    private HgUtilsInternal() {
    }

    public static long getCurrentRevisionNumber(ScmLogger logger, File workingDir)
        throws ScmException {

        String[] revCmd = new String[] { HgCommandConstants.REVNO_CMD };
        HgRevNoConsumer consumer = new HgRevNoConsumer(logger);
        HgUtils.execute(consumer, logger, workingDir, revCmd);

        return consumer.getCurrentRevisionNumber();
    }

    /**
     * Get current (working) revision.
     * <p/>
     * Resolve revision to the last integer found in the command output.
     */
    private static class HgRevNoConsumer extends HgConsumer {

        private long revNo;

        HgRevNoConsumer(ScmLogger logger) {
            super(logger);
        }

        /**
         * {@inheritDoc}
         * Parse the output of the ID command
         * line will be split by space and first parameter
         */
        @Override
        public void doConsume(ScmFileStatus status, String line) {
            String[] elements = line.split("\\s+");
            if (elements.length > 0) {
                // If the clone is modified then the id contains the character '+'
                String strId = elements[0].trim().replace("+", "");
                if (this.getLogger().isDebugEnabled()) {
                    this.getLogger().debug("Parsing: " + strId);
                }
                try {
                    revNo = Long.parseLong(strId, 16);
                } catch (NumberFormatException e) {
                    this.getLogger().error(e);
                }
            }
        }

        long getCurrentRevisionNumber() {
            return revNo;
        }
    }

}
