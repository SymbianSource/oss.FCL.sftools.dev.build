<#--
============================================================================ 
Name        : 
Part of     : Helium 

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.
This component and the accompanying materials are made available
under the terms of the License "Eclipse Public License v1.0"
which accompanies this distribution, and is available
at the URL "http://www.eclipse.org/legal/epl-v10.html".

Initial Contributors:
Nokia Corporation - initial contribution.

Contributors:

Description:

============================================================================
-->

strict digraph G {
    compound=true;
    subgraph cluster_0 {
        node [style=filled];
        <#if !(ant?keys?seq_contains("sf"))>
            Ant -> "Quick Guide"[dir=none];
            "Quick Guide" -> "Setting up Helium at Nokia"[dir=none];
            "Setting up Helium at Nokia" -> "Running Helium"[dir=none];
            "Running Helium" -> "Feature List"[dir=none];
            "Feature List" -> Diamonds[dir=none];
            Diamonds -> "Helium Wiki"[dir=none];
            "Helium Wiki" -> "Helium Forum"[dir=none];
        <#else>
            Ant -> "Quick Guide"[dir=none];
            "Quick Guide" -> "Setting up Helium"[dir=none];
            "Setting up Helium" -> "Running Helium"[dir=none];
            "Running Helium" -> "Feature List"[dir=none];
        </#if>
        label = "Beginners";
    }

    subgraph cluster_1 {
        node [style=filled];
        <#if !(ant?keys?seq_contains("sf"))>
            "Configure Helium" -> IDO[dir=none];
            "Configure Helium" -> TeamCI[dir=none];
            "Configure Helium" -> MCL[dir=none];
        <#else>
            "Configure Helium";
        </#if>
        label = "Intermediate";
    }
    
    subgraph cluster_2 {
        node [style=filled];
        "ROM Image" -> "Helium Stages"[dir=none];
        <#if !(ant?keys?seq_contains("sf"))>
            "Helium Stages" -> "Helium Nokia Stages"[dir=none];
        </#if>
        label = "Advanced";
    }
    

    subgraph cluster_4 {
        node [style=filled];
        <#if !(ant?keys?seq_contains("sf"))>
            "Helium Developer Guide" -> "Coding Convention"[dir=none];
            "Coding Convention" -> "Helium Test Plan"[dir=none];
            "Helium Test Plan" -> Python[dir=none];
            Python -> Java[dir=none];
            Java -> FMPP[dir=none];
            FMPP -> "DOS Scripting"[dir=none];
        <#else>
            "Helium Developer Guide" -> "Coding Convention"[dir=none];
            "Coding Convention" -> Python[dir=none];
            Python -> Java[dir=none];
            Java -> FMPP[dir=none];
            FMPP -> "DOS Scripting"[dir=none];
        </#if>
        label = "Helium Developer";
    }
    
    <#if !(ant?keys?seq_contains("sf"))>
        subgraph cluster_2_1{
            node [style=filled, rankdir=LR];
            EBS [fontcolor=navyblue,fontsize=12,shape=box,href="http://s60wiki.nokia.com/S60Wiki/EBS"];
            Raptor [fontcolor=navyblue,fontsize=12,shape=box,href="http://s60wiki.nokia.com/S60Wiki/Raptor"];
            "Electric Cloud" [fontcolor=navyblue,fontsize=12,shape=box,href="http://www.connecting.nokia.com/nmp/tpm/nmpglosw.nsf/document/ES21T6K9FM4?OpenDocument"];
            ATS [fontcolor=navyblue,fontsize=12,shape=box,href="manual/stages.html#stage-ats3-stif-and-eunit"];
    }
    </#if>
    
    subgraph cluster_4_1 {
        node [style=filled, rankdir=LR];
        ANTUnit [fontcolor=navyblue,fontsize=12,shape=box,href="http://ant.apache.org/antlibs/antunit/"];
        NOSE [fontcolor=navyblue,fontsize=12,shape=box,href="http://ivory.idyll.org/articles/nose-intro.html"];
        JUnit [fontcolor=navyblue,fontsize=12,shape=box,href="http://helium.nmp.nokia.com/trac/wiki/JUnit"];
    }
    
    Start -> Ant [lhead=cluster_0];
    Start -> "Configure Helium" [lhead=cluster_1];
    Start -> "ROM Image" [lhead=cluster_2];
    Start -> "Helium Developer Guide" [lhead=cluster_4];
    <#if !(ant?keys?seq_contains("sf"))>
        "Helium Nokia Stages" -> "Electric Cloud"[dir=none, lhead=cluster_2_1, ltail=cluster_2];
    </#if>
    "DOS Scripting" -> NOSE[dir=none, lhead=cluster_4_1, ltail=cluster_4];
   
    
    Start [fontcolor=navyblue,fontsize=12,style=filled,href="introduction.html"];
    
    Ant [fontcolor=navyblue,fontsize=12,shape=box,href="http://ant.apache.org/manual/"];
    "Quick Guide" [fontcolor=navyblue,fontsize=12,shape=box,href="quick_start_guide.html"];
    "Running Helium" [fontcolor=navyblue,fontsize=12,shape=box,href="manual/running.html"];
    
    <#if (ant?keys?seq_contains("sf"))>
        "Setting up Helium" [fontcolor=navyblue,fontsize=12,shape=box,href="sf.html"];
    </#if>
    
    "Feature List" [fontcolor=navyblue,fontsize=12,shape=box,href="feature_list.html"];
    "Configure Helium" [fontcolor=navyblue,fontsize=12,shape=box,href="manual/configuring.html"];
    "Helium Stages" [fontcolor=navyblue,fontsize=12,shape=box,href="manual/stages.html"];
    
    "ROM Image" [fontcolor=navyblue,fontsize=12,shape=box,href="tutorials/rom_image.html"];
    
    <#if !(ant?keys?seq_contains("sf"))>
        "Setting up Helium at Nokia" [fontcolor=navyblue,fontsize=12,shape=box,href="nokia/nokia.html"];
        "Helium Nokia Stages" [fontcolor=navyblue,fontsize=12,shape=box,href="nokia/nokiastages.html"];
        Diamonds [fontcolor=navyblue,fontsize=12,shape=box,href="http://diamonds.nmp.nokia.com/diamonds/"];
        "Helium Wiki" [fontcolor=navyblue,fontsize=12,shape=box,href="http://delivery.nmp.nokia.com/trac/helium/wiki"];
        "Helium Forum" [fontcolor=navyblue,fontsize=12,shape=box,href="http://forums.connecting.nokia.com/forums/forum.jspa?forumID=262"];
        MCL [fontcolor=navyblue,fontsize=12,shape=box,href="http://s60wiki.nokia.com/S60Wiki/S60_Software_Asset_Management/Organization/Delivery_Services/Howto_build_DFS70.91.91_/_S60.MCL_with_Helium"];
        IDO [fontcolor=navyblue,fontsize=12,shape=box,href="ido/index.html"];
        TeamCI [fontcolor=navyblue,fontsize=12,shape=box,href="teamci/index.html"];
        "Helium Test Plan" [fontcolor=navyblue,fontsize=12,shape=box,href="nokia/testing.html"];
    </#if>
      
    "Helium Developer Guide" [fontcolor=navyblue,fontsize=12,shape=box,href="developer_guide.html"];
    "Coding Convention" [fontcolor=navyblue,fontsize=12,shape=box,href="coding_conventions.html"];
    Python [fontcolor=navyblue,fontsize=12,shape=box,href="http://www.python.org/"];
    Java [fontcolor=navyblue,fontsize=12,shape=box,href="http://java.sun.com/j2se/"];
    FMPP [fontcolor=navyblue,fontsize=12,shape=box,href="http://fmpp.sourceforge.net/"];
    "DOS Scripting" [fontcolor=navyblue,fontsize=12,shape=box,href="http://en.wikipedia.org/wiki/Batch_script"];
    ANTUnit [fontcolor=navyblue,fontsize=12,shape=box,href="http://ant.apache.org/antlibs/antunit/"];
    NOSE [fontcolor=navyblue,fontsize=12,shape=box,href="http://ivory.idyll.org/articles/nose-intro.html"];
}
