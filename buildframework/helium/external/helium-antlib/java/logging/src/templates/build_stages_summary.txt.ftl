<#--
============================================================================ 
Name        : build_stages_summary.txt.ftl 
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

*** BUILD STAGE SUMMARY ***

<#assign count = 0>
<#list statusReports as report>
<#assign count = count + 1>
${count}) ${report["phaseName"]}
${""?left_pad(2)} Start Time : ${report["startTime"]}
${""?left_pad(2)} Duration   : ${report["duration"]}
${""?left_pad(2)} Status     : ${report["status"]}
<#if  report["status"] == "FAILED">
${""?left_pad(2)} Reason     : ${report["reason"]}
</#if>
</#list>
