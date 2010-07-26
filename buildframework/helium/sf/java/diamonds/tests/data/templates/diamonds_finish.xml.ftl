<#--
============================================================================ 
Name        : finish.xml.ftl 
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
<#include "header.ftl">
  <build>
    <#if ant?keys?seq_contains("diamonds.end.time")><finished>${ant["diamonds.end.time"]}</finished></#if>
  </build>
<#include "footer.ftl">