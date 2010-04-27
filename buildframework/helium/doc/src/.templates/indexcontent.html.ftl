<#--
============================================================================ 
Name        : indexcontent.html.ftl
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
{% extends "defindex.html" %}
{% block tables %}
  <p><strong>Parts of the documentation:</strong></p>
  <table class="contentstable" align="center"><tr>
    <td width="50%">
      <p class="biglink"><a class="biglink" href="{{ pathto("releasenotes/index") }}">Release notes</a><br/>
         <span class="linkdescr">what's new</span></p>
      <p class="biglink"><a class="biglink" href="{{ pathto("quick_start_guide") }}">Quick Start Guide</a><br/>
         <span class="linkdescr">start here</span></p>
<#if !(ant?keys?seq_contains("sf"))>
      <p class="biglink"><a class="biglink" href="http://lmp.nokia.com/lms/lang-en/taxonomy/TAX_Search.asp?UserMode=0&SearchStr=helium">E-learning</a><br/>
         <span class="linkdescr">multimedia introduction</span></p>
</#if>
      <p class="biglink"><a class="biglink" href="{{ pathto("feature_list") }}">Feature list</a><br/>
         <span class="linkdescr">what is supported</span></p>
      <p class="biglink"><a class="biglink" href="{{ pathto("manual/index") }}">Manual</a><br/>
         <span class="linkdescr">reference docs</span></p>
    </td><td width="50%">
      <p class="biglink"><a class="biglink" href="{{ pathto("tutorials/index") }}">HowTos</a><br/>
         <span class="linkdescr">specific use cases</span></p>
      <p class="biglink"><a class="biglink" href="{{ pathto("api/helium/index") }}">Helium API</a><br/>
         <span class="linkdescr">reference for Helium configuration</span></p>
      <p class="biglink"><a class="biglink" href="{{ pathto("helium-antlib/index") }}">Ant libraries</a><br/>
         <span class="linkdescr">when you just have to customize</span></p>
      <p class="biglink"><a class="biglink" href="{{ pathto("development/index") }}">Development</a><br/>
         <span class="linkdescr">for helium hackers everywhere</span></p>
      <p class="biglink"><a class="biglink" href="{{ pathto("architecture") }}">Architecture</a><br/>
         <span class="linkdescr">many pieces, loosely joined</span></p>
    </td></tr>
  </table>

  <p><strong>Customer documentation:</strong></p>
  <table class="contentstable" align="center"><tr>
    <td width="50%">
      <p class="biglink"><a class="biglink" href="http://helium.nmp.nokia.com/doc/ido">IDO</a><br/>
         <span class="linkdescr">integration domains</span></p>
    </td><td width="50%">
      <p class="biglink"><a class="biglink" href="http://helium.nmp.nokia.com/doc/teamci">TeamCI</a><br/>
         <span class="linkdescr">development teams</span></p>
    </td></tr>
  </table>

{% endblock %}
