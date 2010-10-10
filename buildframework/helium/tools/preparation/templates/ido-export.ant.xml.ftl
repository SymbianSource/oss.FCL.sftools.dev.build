<#--
============================================================================ 
Name        : ido-export.ant.xml.ftl 
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
<?xml version="1.0"?>
<project name="ido-copy">

    <target name="ido-copy-iby">
        <#list data?keys as name>
        <copy todir="${ant['ido.romtree']}" verbose="true" overwrite="true" flatten="true">
            <fileset dir="${data[name]}" casesensitive="no">
                <include name="**/rom/*.iby"/>
                <exclude name="**/internal/**"/>
                <exclude name="**/tsrc/**"/>
            </fileset>
        </copy>
        </#list>
    </target>

    <target name="ido-copy-cenrep">
        <#list data?keys as name>
        <copy todir="${ant['ido.cenrep.root']}" verbose="true" overwrite="true" flatten="true">
            <fileset dir="${data[name]}" casesensitive="no">
                <include name="**/cenrep/keys_*.xls"/>
            </fileset>
        </copy>
        </#list>
    </target>

</project>
