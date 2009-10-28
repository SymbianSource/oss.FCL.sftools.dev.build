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


package com.nokia.helium.scm.ant.types;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;

public class LatestTag extends Tag {

    private String pattern;
    private List<TagSet> tagSets = new ArrayList<TagSet>();
    
    public void setPattern(String pattern) {
        this.pattern = pattern;
    }
    
    public void add(TagSet tagSet) {
        tagSets.add(tagSet);
    }

    @Override
    public String getName() {
        if (pattern == null)
            throw new BuildException("'pattern' attribute has not been defined.");

        List<Tag> tags = getCleanedList();
        Collections.sort(tags, new TagComparator<Tag>(getPattern()));
        
        if (tags.isEmpty())
            throw new BuildException("No tag found.");

        getProject().log("Latest tag: " + tags.get(0).getName());
        return tags.get(0).getName();
    }

    protected List<Tag> getCleanedList() {
        Pattern pVer = getPattern();
        List<Tag> tags = new ArrayList<Tag>();
        for (Tag tag : getTags()) {
            if (pVer.matcher(tag.getName()).matches()) {
                tags.add(tag);
            }
        }
        return tags;
    }
    
    protected Pattern getPattern() {
        // Quoting the current pattern
        getProject().log("pattern: " + pattern, Project.MSG_DEBUG);
        String qVer = pattern.replaceAll("([.\\:_()])", "\\\\$1");
        getProject().log("quoted: " + qVer, Project.MSG_DEBUG);
        // Replacing quoted \* into \d+
        qVer = qVer.replaceAll("\\*", "(\\\\d+)");        
        qVer = "^" + qVer + "$";
        getProject().log("final: " + qVer, Project.MSG_DEBUG);
        return Pattern.compile(qVer);
    }
    
    protected List<Tag> getTags() {
        List<Tag> tags = new ArrayList<Tag>();
        for (TagSet ts : tagSets) {
            if (ts.isReference()) {
                ts = (TagSet)ts.getRefid().getReferencedObject(getProject());
            }
            for (Tag tag : ts.getTags()) {
                tags.add(tag);
            }
        }
        return tags;
    }
    
    public class TagComparator<T extends Tag> implements Comparator<T> {
        
        // Pattern to match for the comparison
        private Pattern pVer;
        
        public TagComparator(Pattern pattern) {
            pVer = pattern;
        }
        
        @Override
        public int compare(T o1, T o2) {
            getProject().log("Comparing: " + o1.getName() + ">" + o2.getName(), Project.MSG_DEBUG);
            
            if (o1.getName().equals(o2.getName()))
                return 0;
            Matcher m1 = pVer.matcher(o1.getName());
            Matcher m2 = pVer.matcher(o2.getName());
            m1.matches();
            m2.matches();
            int max = (m1.groupCount() > m2.groupCount()) ? m2.groupCount() : m1.groupCount();            
            int i = 1;
            while (i <= max) {
                int i1 = Integer.decode(m1.group(i)).intValue();
                int i2 = Integer.decode(m2.group(i)).intValue();
                getProject().log("Comparing index " + i + ": " + i1 + " < " + i2, Project.MSG_DEBUG);
                if (i1 != i2) {
                    return i2 - i1;
                }
                i++;
            }
            return 0;
        }
    }
    
}
