<#--
============================================================================ 
Name        : clean_pc.ant.ftl 
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
    

<project default="do-clean-build-areas">
    <target name="do-clean-build-areas">
        <antform title="Clean build areas">
        <#list buildAreaDirs as dir>
            <booleanProperty label="${dir}" property="${dir_index}"/>
        </#list>
        </antform>
        
        <parallel threadCount="${r'$'}{number.of.threads}">
            <#list buildAreaDirs as dir>
            <if>
                <isset property="${dir_index}"/>
                <then>
                    <shellscript shell="cmd.exe" tmpsuffix=".bat" dir="${prepRootDir}">
                        <arg value="/c"/>
                        <arg value="call"/>
                        rmdir /s/q ${dir}
                    </shellscript>
                </then>
            </if>
            </#list>
        </parallel>
    </target>
</project>