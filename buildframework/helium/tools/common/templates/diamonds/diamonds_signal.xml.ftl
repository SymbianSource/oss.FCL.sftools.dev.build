<#--
============================================================================ 
Name        : diamonds_signal.xml.ftl 
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
<#include "diamonds_header.ftl"> 
  <signals>
      <#list ant?keys as diamondskey>
      <#if diamondskey?starts_with("diamond.signal.name.")>
      <#assign signalIndex = diamondskey?split(".")?last />
      <signal>
          <id>${signalIndex}</id>
          <#if ant?keys?seq_contains("diamond.signal.name.${signalIndex}")><name>${ant["diamond.signal.name.${signalIndex}"]?xml}</name></#if>
          <#if ant?keys?seq_contains("diamond.error.message.${signalIndex}")><message>${ant["diamond.error.message.${signalIndex}"]?xml}</message></#if>
          <#if ant?keys?seq_contains("diamond.time.stamp.${signalIndex}")><timestamp>${ant["diamond.time.stamp.${signalIndex}"]?xml}</timestamp></#if>
      </signal>
      </#if>
      </#list>
  </signals>
<#include "diamonds_footer.ftl"> 