<?xml version="1.0" encoding="UTF-8"?>
<!-- 
============================================================================ 
Name        : diamonds_config.xml 
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
<configuration>
<config>
    <output-dir path="${ant['diamonds.output.dir']}"/>
    <template-dir path="${ant['diamonds.template.dir']}"/>
    
    <property name="smtpserver" value="email.smtp.server" />
    <property name="ldapserver" value="email.ldap.server" />
    <property name="initialiser-target-name" value="diamonds" />
    
    <server>
        <property name="host" value="diamonds.host" />
        <property name="port" value="diamonds.port" />
        <property name="path" value="diamonds.path" />
        <property name="tstampformat" value="yyyy-MM-dd'T'HH:mm:ss" />
        <property name="mail" value="diamonds.mail" />
        <property name="category-property" value="build.family" />
        <property name="buildid-property" value="diamonds.build.id" />
    </server>
</config>
<logger>
    <stages>
            <!-- verifying basic stage input -->
            <stage name="pre-build" start="version" end="version" />
            
            <!-- verifying basic stage input with input xml file-->
            <stage name="build" start="compile-target" end="compile-target"
                logfile="${ant['compile.log.input']}"/>
    </stages>
    <targets>
        <target name="codescanner" template-file="codescanner.xml.ftl"
            logfile="${ant['codescanner.log.input']}" />

        <!-- if no logfile provided, looks for xml file to send 
            using <build.id_target_name.xml> file or<target_name.xml> file, 
            if both doesn't exists does nothing. tries to pass ant properties
            and sends it.-->
            
        <target name="create-bom-log" />
        
    <!-- Test the defer case -->
        <target name="defer-type" template-file="tool.xml.ftl" 
            ant-properties="true" defer="true"/>
    </targets>
</logger>
</configuration>