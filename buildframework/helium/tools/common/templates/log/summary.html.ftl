<#--
============================================================================ 
Name        : summary.html.ftl 
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
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>


<#include "/@macro/logger/logger.ftl"/>



<head>
    <title>
<#assign mykey=doc.logSummary.info.id>
<#if (conv[mykey])?exists>
${doc.logSummary.info.id}
</#if>
build summary</title>
    <@helium_logger_html_head/>
</head>
<body>

<!--
    Processing the Helium log summary.
-->
<#macro logentry node>
    <#assign conv={"error": "error", "warn": "warning"}>
    <#assign mykey=node.@severity[0]>
    <#if (conv[mykey])?exists>
        <@helium_logger_print type="${conv[mykey]}">${node}</@helium_logger_print>
    <#else>        
        <@helium_logger_print type="">${node}</@helium_logger_print>
    </#if>
</#macro>

<#macro logfile node>
    <#assign helium_node_id = helium_node_id + 1>
    <@helium_logger_node_head nodeid="${helium_node_id}" title="${node.@name}">
        <#assign pnames=pp.newWritableHash()>
        <#assign conv={"error": "error", "warn": "warning", "info": ""}>
        <#list node.logentry as entry>
            <#assign pname=entry.@severity[0]>
            <#if (pnames[conv[pname]])?exists>                
                <@pp.set hash=pnames key="${conv[pname]}" value=pnames[conv[pname]]+1/>
            <#else>
                <@pp.set hash=pnames key="${conv[pname]}" value=1/>
            </#if>
        </#list>
        <#list pnames?keys?sort as key>
            <@helium_message_box nodeid="${helium_node_id}" type="${key}" count=pnames[key] />
        </#list>
    </@helium_logger_node_head>    
    <@helium_logger_node_content nodeid="${helium_node_id}">
        <#list node.logentry as entry>
            <@logentry entry/>
        </#list>
    </@helium_logger_node_content>
</#macro>

<!--
    Ant logger like.
-->
<#macro message node>
    <#assign conv={"error": "error", "warn": "warning", "remark": "remark", "note": "note"}>
    <#assign mykey=node.@priority[0]>
    <#if (conv[mykey])?exists>
        <@helium_logger_print type="${conv[mykey]}">${node}</@helium_logger_print>
    <#else>        
        <@helium_logger_print type="${mykey}">${node}</@helium_logger_print>
    </#if>
</#macro>

<#macro antlognode node>    
    <#assign helium_node_id = helium_node_id + 1>    
    <#if node["@name"]?size == 1 >
        <#assign title = node.@name>
    <#else>
        <#assign title = node.@filename>
    </#if>
    <@helium_logger_node_head nodeid="${helium_node_id}" title="${title}">
        <#assign pnames=pp.newWritableHash()>
        <#list node[".//message"] as msg>
            <#assign pname=msg.@priority[0]>
            <#if (pnames[pname])?exists>
                <@pp.set hash=pnames key="${pname}" value=pnames[pname]+1/>
            <#else>
                <@pp.set hash=pnames key="${pname}" value=1/>
            </#if>
        </#list>
        <#list pnames?keys?sort as key>
            <@helium_message_box nodeid="${helium_node_id}" type="${key}" count=pnames[key] />
        </#list>
    </@helium_logger_node_head>
    <@helium_logger_node_content nodeid="${helium_node_id}">
    <#list node["./build/task|./build/message|./task|./message"] as child>
        <#if child?node_name == "message"> 
            <@message child/>
        <#elseif child?node_name == "task">        
            <@antlognode child/>
        </#if>
    </#list>
    </@helium_logger_node_content>
</#macro>


<!-- Call the macros to render the log contents. -->
<#assign mykey=doc.logSummary.info>
<#if (conv[mykey])?exists>
<@helium_logger_header title="${doc.logSummary.info.id} build"/>

<@helium_logger_content title="Build overview">
    Time started: ${doc.logSummary.info.startTime}<br/>
    Build machine: ${doc.logSummary.info.machine}<br/>
    Is published?: ${doc.logSummary.info.publish.status}<br/>
    <#if doc.logSummary.info.publish.status?string == true?string>
        Published location: ${doc.logSummary.info.publish.location}</br>
    </#if>
</@helium_logger_content>
</#if>
<@helium_logger_content title="Errors and warnings details">
    <#list doc.logSummary["./logfile|./log"] as sublog>
        <#if sublog?node_name == "logfile"> 
            <@logfile sublog/>
        <#elseif sublog?node_name == "log">
            <@antlognode sublog/>
        </#if>
    </#list>
</@helium_logger_content>
</body>
</html>    

