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

<#macro logfile_severity logname, severity, count, helium_node_id>
    <@helium_message_box nodeid="${helium_node_id}" type="${severity}" count="${count}"?number />
</#macro>


<#macro logfile_entry_detail text, severity, helium_node_id>
    <@logentry "${text}", "${severity?lower_case}" />
</#macro>

<#macro metadata_entry_detail logentry, helium_node_id, component_name, component_id>
    <#assign title_text="general">
    <#assign component_query=" is NULL">
    <#assign c_id="${logentry.path}">
    
    <#if !(component_name == "")>
        <#assign title_text="${component_name}">
        <#assign component_query="=${component_id}">
        <#assign c_id="${component_id}">
    </#if>
    <@helium_logger_node_head nodeid="${helium_node_id}" title="${title_text}">
        <#list table_info['jpa']['select p from Severity p where p.severity not like \'INFO\''] as severity>
            <@logfile_severity "${c_id}", "${severity.severity?lower_case}", 
                    table_info['jpasingle']['select Count(m.id) from MetadataEntry m where m.severityId=${severity.id} and m.componentId ${component_query} and m.logFileId = ${logentry.id}'][0], 
                    "${helium_node_id}" />
        </#list>
    </@helium_logger_node_head>

    <@helium_logger_node_content nodeid="${helium_node_id}">
        <#list table_info['jpa']['select p from Severity p'] as severity>
        <#list table_info['jpa']['select m from MetadataEntry m where m.componentId ${component_query} and m.severityId=${severity.id} and m.logFileId = ${logentry.id}'] as entry>
            <#if entry.text??>
                <@logfile_entry_detail "${entry.text}", "${severity.severity?lower_case}", "${helium_node_id}" />
            </#if>
        </#list>
    </#list>
    </@helium_logger_node_content>
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
        <#list table_info['jpa']['select p from Severity p where p.severity not like \'INFO\''] as severity>
        <#assign count=table_info['jpasingle']['select Count(m.id) from MetadataEntry m where m.severityId=${severity.id} and m.logFileId=${logentry.id}'][0]>
            <@logfile_severity "${logentry.path}", "${severity.severity?lower_case}", 
                "${count}", 
                "${helium_node_id}" />
        </#list>
    </@helium_logger_node_head>
    <@helium_logger_node_content nodeid="${helium_node_id}">
        <#assign count_default_component = table_info['jpasingle']['select Count(m.id) from MetadataEntry m where m.logFileId=${logentry.id} and m.componentId is NULL'][0]>
        <#if count_default_component &gt; 0>
            <#assign helium_node_id = helium_node_id + 1>
            <@metadata_entry_detail logentry, "${helium_node_id}", "", ""/>
        </#if>
        <#list table_info['jpa']['select c from Component c where c.logFileId=${logentry.id}'] as component>
            <#assign helium_node_id = helium_node_id + 1>
            <@metadata_entry_detail logentry, "${helium_node_id}", "${component.component}", "${component.id}" />
        </#list>
    </@helium_logger_node_content>
</#list>
</@helium_logger_content>
</body>
</html>
