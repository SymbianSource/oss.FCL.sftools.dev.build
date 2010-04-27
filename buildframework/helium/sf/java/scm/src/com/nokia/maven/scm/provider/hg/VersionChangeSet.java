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


import org.apache.maven.scm.ChangeSet;
import org.apache.maven.scm.ScmVersion;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ChangeFile;

import java.util.ArrayList;
import java.util.List;

/**
 * A version changeset.
 */
public class VersionChangeSet extends ChangeSet
{

    private static final String DATE_PATTERN = "yyyy-MM-dd";
    private static final String TIME_PATTERN = "HH:mm:ss";
    private List<ScmVersion> scmVersionList;

    /**
     * Constructor used when attributes aren't available until later
     */
    public VersionChangeSet()
    {
        super();
        scmVersionList = new ArrayList<ScmVersion>();
    }

    /**
    * Setter for ScmVersion
    */
    public void setScmVersion(ScmVersion scmVersion) throws ScmException
    {
        scmVersionList.add(scmVersion);
    }
    
    /**
     * Getter for ChangeFile list.
     *
     * @return List of ScmVersion list.
    */
    public List<ScmVersion> getScmVersion()
    {
        return scmVersionList;
    }
    
    /**
    * Added tbranch\tag\revision and changed format to match "hg log --verbose" output. 
    * File version has been removed, showing only file name
    * @return String to output the VersionChangeSet result
    */
    @SuppressWarnings("unchecked")
    @Override
    public String toString()
    {
        String result = "";
        for (ScmVersion versions : getScmVersion()) {
           if (!versions.getName().equals("")) 
           {
               result += versions.getType().toLowerCase() + ":" + versions.getName() + "\n";
            }
        }
        if (getAuthor() != null)
            result += "user:" + getAuthor() + "\n";
        if (getDate() != null)
            result += "date:" + getDate() + "\n";
        List<ChangeFile> files = getFiles();
        if ( files.size() != 0 )
        {
            result += "files:";
            for ( ChangeFile changeFile : files )
            {
                result += changeFile.getName() + " ";
            }
        }
        if (!getComment().equals(""))
            result += "\ndescription:" + getComment() + "\n";
        return result;
    }
    
     /**
     * Provide the changelog entry as an XML snippet.
     *
     * @return a changelog-entry in xml format
     * @task make sure comment doesn't contain CDATA tags - MAVEN114
     */

    @SuppressWarnings("unchecked")
    @Override
    public String toXML()
    {
        StringBuffer buffer = new StringBuffer();

        buffer.append( "\t<changelog-entry>\n" );

        if ( getDate() != null )
        {
            buffer.append( "\t\t<date pattern=\"" + getDateFormatted() + "\">" )
                .append( getDateFormatted() )
                .append( "</date>\n" )
                .append( "\t\t<time pattern=\"" + TIME_PATTERN + "\">" )
                .append( getTimeFormatted() )
                .append( "</time>\n" );
        }

        for (ScmVersion versions : getScmVersion()) {
           if (!versions.getName().equals("")) 
           {
               buffer.append("\t\t<" + versions.getType().toLowerCase() + ">\n")
                     .append("\t\t\t<name>")
                     .append(versions.getName())
                     .append("</name>\n");
               buffer.append("\t\t</" + versions.getType().toLowerCase() + ">\n");
            }
        }

        buffer.append( "\t\t<author><![CDATA[" )
            .append( getAuthor() )
            .append( "]]></author>\n" );
        
        List<ChangeFile> changeFiles = getFiles();
        for ( ChangeFile changeFile :  changeFiles)
        {
            buffer.append( "\t\t<file>\n" )
                .append( "\t\t\t<name>" )
                .append( escapeValue( changeFile.getName() ) )
                .append( "</name>\n" )
                .append( "\t\t\t<revision>" )
                .append( changeFile.getRevision() )
                .append( "</revision>\n" );
            buffer.append( "\t\t</file>\n" );
        }
        buffer.append( "\t\t<msg><![CDATA[" )
            .append( removeCDataEnd( getComment() ) )
            .append( "]]></msg>\n" );
        buffer.append( "\t</changelog-entry>\n" );

        return buffer.toString();
    }

     /**
     * remove a <code>]]></code> from comments (replace it with <code>] ] ></code>).
     *
     * @param message The message to modify
     * @return a clean string
     */

    private String removeCDataEnd( String message )
    {
        // check for invalid sequence ]]>
        int endCdata;
        while ( message != null && ( message.indexOf( "]]>" ) ) > -1 )
        {
            endCdata = message.indexOf( "]]>" );
            message = message.substring( 0, endCdata ) + "] ] >" + message.substring( endCdata + 3, message.length() );
        }
        return message;
    }
}