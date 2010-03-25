<#--
============================================================================ 
Name        : cust.mk.ftl 
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
java_home:${java_home}
java_utils_classpath:${java_utils_classpath}
makefile:${makefile}
<#list cmdSets as cmds>
Group:
    <#list cmds as cmd>
    + <#list cmd.getArguments() as arg>${arg} </#list>${cmd.getTarget()}
    </#list>
</#list>