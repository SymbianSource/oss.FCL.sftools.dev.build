<#--
============================================================================ 
Name        : cone-validate.xml.ftl 
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

<project name="cone-validate" default="all">
    
    <target name="product-cone-validate">
        <#if os?lower_case?starts_with('win')>
            <#assign exe_file="cmd.exe"/>
        <#else>
            <#assign exe_file="bash"/>
        </#if>
        <#list ant['product.list']?split(',') as product>
        <sequential>
            <echo>Validating cone configuration for ${product}_root.confml</echo>
            <exec executable="${exe_file}" dir="${ant['build.drive']}/epoc32/tools" failonerror="false">
                <#if os?lower_case?starts_with('win')>
                <arg value="/c"/>
                <arg value="cone.cmd"/>
                <#else>
                <arg value="cone"/>
                </#if>
                <arg value="validate" />
                <arg value="--project"/>
                <arg value="${ant['build.drive']}/epoc32/rom/config"/>
                <arg value="--configuration"/>
                <arg value="${product}_root.confml"/>
                <arg value="--report-type"/> 
                <arg value="xml" />
                <arg value="--report"/>
                <arg value="${ant['post.log.dir']}/${ant['build.id']}_validate_cone_${product}.xml" />
            </exec>
        </sequential>
        </#list>
    </target>
    
    <target name="all" depends="product-cone-validate" />
</project>


