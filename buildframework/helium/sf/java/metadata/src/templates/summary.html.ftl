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


<#include "/@macro/logger.ftl"/>

    <#assign table_info = pp.loadData('com.nokia.helium.metadata.ORMFMPPLoader',
        "${dbPath}") >

<head>
    <title>
<#if loginfo?? >
<#assign mykey=loginfo.info.id>
<#if (conv[mykey])?exists>
${loginfo.info.id}
</#if>
build summary</title>
    <@helium_logger_html_head/>
</head>
</#if>
<body>


<!--
    Processing the Helium log summary.
-->
<#macro logentry text, severity>
    <#assign conv={"error": "error", "warning": "warning"}>
    <#if (conv['${severity}'])?exists>
        <@helium_logger_print type="${conv[\"${severity}\"]}">${text}</@helium_logger_print>
    <#else>
        <@helium_logger_print type="">${text}</@helium_logger_print>
    </#if>
</#macro>

<#macro logfile_severity logname, priority, count, helium_node_id>
    <@helium_message_box nodeid="${helium_node_id}" type="${priority}"  count="${count}"?number />
</#macro>


<#macro logfile_entry_detail text, priority, helium_node_id>
    <@logentry "${text}", "${priority?lower_case}" />
</#macro>

<!-- Call the macros to render the log contents. -->
<#assign mykey=loginfo>
<#if (conv[mykey])?exists>
<@helium_logger_header title="${loginfo.info.id} build"/>

<@helium_logger_content title="Build overview">
    Time started: ${loginfo.info.startTime}<br/>
    Build machine: ${loginfo.info.machine}<br/>
    Is published?: ${loginfo.info.publish.status}<br/>
    <#if loginfo.info.publish.status?string == true?string>
        Published location: ${loginfo.info.publish.location}</br>
    </#if>
</@helium_logger_content>
</#if>

<@helium_logger_content title="Errors and warnings details">
<#list table_info['jpa']['select l from LogFile l'] as logentry>
    <#assign helium_node_id = helium_node_id + 1>
    <#-- -->
    <@helium_logger_node_head nodeid="${helium_node_id}" title="${logentry.path}">
        <#list table_info['jpa']['select p from Priority p where p.priority not like \'%DEFAULT%\''] as priority>
        <#assign count = table_info['jpasingle']['select Count(m.id) from MetadataEntry m where m.priorityId = ${priority.id} and m.logPathId=${logentry.id}'][0]>
            <@logfile_severity "${logentry.path}", "${priority.priority?lower_case}", 
                "${count}", 
                "${helium_node_id}" />
        </#list>
    </@helium_logger_node_head>
    <@helium_logger_node_content nodeid="${helium_node_id}">
        <#list table_info['jpa']['select c from Component c where c.logPathID=${logentry.id}'] as component>
            <#assign helium_node_id = helium_node_id + 1>
            <@helium_logger_node_head nodeid="${helium_node_id}" title="${component.component}">
                <#list table_info['jpa']['select p from Priority p where p.priority not like \'%DEFAULT%\''] as priority>
                    <@logfile_severity "${component.id}", "${priority.priority}", 
                            table_info['jpasingle']['select Count(m.id) from MetadataEntry m where m.priorityId=${priority.id} and m.componentId = ${component.id}'][0], 
                            "${helium_node_id}" />
                </#list>
            </@helium_logger_node_head>
            <@helium_logger_node_content nodeid="${helium_node_id}">
                <#list table_info['jpa']['select p from Priority p'] as priority>
                <#list table_info['native:com.nokia.helium.jpa.entity.metadata.MetadataEntry']['select * from metadataentry where metadataentry.component_id=${component.id} and metadataentry.priority_id = ${priority.id}'] as entry >
                    <#if entry.text??>
                    <#-- <#if sublog?node_name == "logfile"> --> 
                        <@logfile_entry_detail "${entry.text}", "${priority.priority}", "${helium_node_id}" />
                    </#if>
                    <#-- <#elseif sublog?node_name == "log">
                        <@antlognode sublog/>
                    </#if> -->
                </#list>
            </#list>
            </@helium_logger_node_content>
        </#list>
    </@helium_logger_node_content>
</#list>
</@helium_logger_content>
</body>
</html>
