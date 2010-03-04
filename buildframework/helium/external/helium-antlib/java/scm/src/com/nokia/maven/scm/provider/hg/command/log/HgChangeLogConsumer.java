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

package com.nokia.maven.scm.provider.hg.command.log;

import com.nokia.maven.scm.provider.hg.VersionChangeSet;

import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmTag;
import org.apache.maven.scm.ScmBranch;
import org.apache.maven.scm.ScmRevision;
import org.apache.maven.scm.ChangeFile;
import org.apache.maven.scm.ScmFileStatus;
import org.apache.maven.scm.log.ScmLogger;
import org.apache.maven.scm.provider.hg.command.HgConsumer;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.text.SimpleDateFormat;

/**
 * Consumer of 'hg changelog' command output.
 */
public class HgChangeLogConsumer extends HgConsumer {

    private static final String TIME_PATTERN = "EEE MMM dd HH:mm:ss yyyy Z";

    private static final String REVNO_TAG = "changeset: ";

    private static final String TAG_BRANCH = "branch: ";

    private static final String TAG_TAG = "tag: ";

    private static final String AUTHOR_TAG = "user: ";

    private static final String TIME_STAMP_TOKEN = "date: ";

    private static final String MESSAGE_TOKEN = "description:";

    private static final String MERGED_TOKEN = "merged: ";

    private static final String FILES_TOKEN = "files: ";

    private String prevLine = "";

    private String prevPrevLine = "";

    private ArrayList<VersionChangeSet> logEntries = new ArrayList<VersionChangeSet>();

    private VersionChangeSet currentChange;

    private VersionChangeSet lastChange;

    private boolean isMergeEntry;

    private String currentRevision;

    private String currentTag; // don't know what to do with this

    private String currentBranch;

    private String userDatePattern;

    private boolean spoolingComments;

    private List<String> currentComment;

    public HgChangeLogConsumer(ScmLogger logger, String userDatePattern) {
        super(logger);
        this.userDatePattern = userDatePattern;
    }

    public List<VersionChangeSet> getModifications() {
        return logEntries;
    }

    /** {@inheritDoc} */
    public void consumeLine(String line) {

        // override default behavior which tries to pick through things for
        // some standard messages. that
        // does not apply here
        doConsume(null, line);
    }

    /** {@inheritDoc} */
    public void doConsume(ScmFileStatus status, String line) {
        String tmpLine = line;
        // If current status == null then this is a new entry
        // If the line == "" and previous line was "", then this is also a new
        // entry
        if ((line.equals("") && (prevLine.equals("") && prevPrevLine.equals("")))
                || currentComment == null) {
            if (currentComment != null) {
                StringBuffer comment = new StringBuffer();
                int i = 0;
                for (String eachComment : currentComment) {
                    comment.append(eachComment);
                    if (i + 1 < currentComment.size() - 1) {
                        comment.append('\n');
                    }
                    i += 1;
                }
                currentChange.setComment(comment.toString());
            }

            spoolingComments = false;

            // If last entry was part a merged entry
            if (isMergeEntry && lastChange != null) {
                String comment = lastChange.getComment();
                comment += "\n[MAVEN]: Merged from "
                        + currentChange.getAuthor();
                comment += "\n[MAVEN]:    " + currentChange.getDateFormatted();
                comment += "\n[MAVEN]:    " + currentChange.getComment();
                lastChange.setComment(comment);
            }

            // Init a new changeset
            currentChange = new VersionChangeSet();
            currentChange.setFiles(new ArrayList<ChangeFile>());
            logEntries.add(currentChange);

            // Reset member vars
            currentComment = new ArrayList<String>();
            currentRevision = "";
            isMergeEntry = false;
        }

        if (spoolingComments) {
            currentComment.add(line);
        } else if (line.startsWith(MESSAGE_TOKEN)) {
            spoolingComments = true;
        } else if (line.startsWith(MERGED_TOKEN)) {
            // This is part of lastChange and is not a separate log entry
            isMergeEntry = true;
            logEntries.remove(currentChange);
            if (logEntries.size() > 0) {
                lastChange = logEntries.get(logEntries
                        .size() - 1);
            } else {
                getLogger().warn("First entry was unexpectedly a merged entry");
                lastChange = null;
            }
        } else if (line.startsWith(REVNO_TAG)) {
            tmpLine = line.substring(REVNO_TAG.length()).trim();
            currentRevision = tmpLine;
            try {
                currentChange.setScmVersion(new ScmRevision(tmpLine));
            } catch (ScmException se) {
                getLogger().warn(se.getMessage());
            }
        } else if (line.startsWith(TAG_TAG)) {
            tmpLine = line.substring(TAG_TAG.length()).trim();
            currentTag = tmpLine;
            try {
                currentChange.setScmVersion(new ScmTag(tmpLine));
            } catch (ScmException se) {
                getLogger().warn(se.getMessage());
            }
        } else if (line.startsWith(TAG_BRANCH)) {
            tmpLine = line.substring(TAG_BRANCH.length()).trim();
            currentBranch = tmpLine;
            try {
                currentChange.setScmVersion(new ScmBranch(tmpLine));
            } catch (ScmException se) {
                getLogger().warn(se.getMessage());
            }
        } else if (line.startsWith(AUTHOR_TAG)) {
            tmpLine = line.substring(AUTHOR_TAG.length());
            tmpLine = tmpLine.trim();
            currentChange.setAuthor(tmpLine);
        } else if (line.startsWith(TIME_STAMP_TOKEN)) {
            tmpLine = line.substring(TIME_STAMP_TOKEN.length()).trim();
            Date date = null;
            try {
                SimpleDateFormat format = new SimpleDateFormat(TIME_PATTERN);
                date = format.parse(tmpLine);
                currentChange.setDate(date);
            } catch (Exception e) {
                getLogger().warn(
                        "Consumer Change Log Date Format not supported:"
                                + e.getMessage());
            }
        } else if (line.startsWith(FILES_TOKEN)) {
            tmpLine = line.substring(FILES_TOKEN.length()).trim();
            String[] files = tmpLine.split(" ");
            for (String eachFile : files) {
                ChangeFile changeFile = new ChangeFile(eachFile, currentRevision);
                currentChange.addFile(changeFile);
            }
        } else {
            if (!line.equals("")) {
                getLogger().warn("Could not figure out: " + line);
            }
        }

        // record previous line
        prevLine = line;
        prevPrevLine = prevLine;
    }
}
