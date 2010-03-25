<#--
============================================================================ 
Name        : 
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
.. Helium Documentation documentation master file, created by sphinx-quickstart on Fri May 09 09:49:44 2008.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

.. index::
  module:  Helium Documentation

====================
Helium documentation
====================

.. toctree::
   :maxdepth: 1

.. raw:: html

   <table border="0" cellspacing="0" cellpadding="10">
   <tr valign="top">
   <td width="50%" style="border-right: 1px solid black">
 
.. index::
  single: Getting Started
   
Getting Started
================

This section contains instructions on how to get started with Helium including where to get it from and how to use it at the very simplest level. 
<#if !(ant?keys?seq_contains("sf"))>
This section also has a link to an elearning that goes through Helium at a very high level.
</#if>

.. toctree::
   :maxdepth: 1
   
   introduction
   quick_start_guide
   feature_list
   user-graph

<#if !(ant?keys?seq_contains("sf"))>
* Elearning_

.. _Elearning: http://lmp.nokia.com/lms/lang-en/taxonomy/TAX_Search.asp?UserMode=0&SearchStr=helium
</#if>

.. raw:: html

   </td><td width="50%">


Tutorials and HOWTOs
=====================
This section lists all the available tutorials on Helium and how to configure and use it.

.. toctree::
   :maxdepth: 1
   
   tutorials/configuration/SimplestConfiguration
   tutorials/configuration/UseHlmTasksInConfiguration
   tutorials/rom_image
   tutorials/qt_build

.. raw:: html

   </td></tr>
   <tr valign="top">
   <td width="50%" style="border-right: 1px solid black" rowspan="2">

.. index::  single: Helium Manual
  
Helium Manual
==============

This section contains the details of the various activities that can be performed by Helium, you should look
here for specific information about a task or action.

.. toctree::
   :maxdepth: 1

<#if !ant?keys?seq_contains("sf")>   
   nokia/support
   nokia/nokia
   nokia/retrieving
</#if>
   sf
   manual/running
   manual/configuring
   
.. raw:: html

   <script type="text/javascript" language="JavaScript"><!--
    function ReverseContentDisplay(d) {
        if(d.length < 1) { return; }
    
         var elem = document.getElementsByTagName('div');
         for(var i = 0; i < elem.length; i++)
         {
             if(elem[i].style.display == "block" && elem[i] != document.getElementById(d)) {
                 elem[i].style.display = "none";
             }
         }
    
        if(document.getElementById(d).style.display == "none") { document.getElementById(d).style.display = "block"; }
        else { document.getElementById(d).style.display = "none"; }
   }
   //--></script>
   <ul><li class="toctree-l1"><a href="javascript:ReverseContentDisplay('stages')">Stages</a></li></ul>
   <div id="stages" style="display:none; position:absolute; border-style: solid; background-color: white; padding: 5px;">
   
.. toctree::
   :maxdepth: 2
   
   manual/stages
   
.. raw:: html

   </div>
<#if !ant?keys?seq_contains("sf")>
   <ul><li class="toctree-l1"><a href="javascript:ReverseContentDisplay('nokiastages')">Nokia Stages</a></li></ul>
   <div id="nokiastages" style="display:none; position:absolute; border-style: solid; background-color: white; padding: 5px;">

.. toctree::
   :maxdepth: 2
   
   nokia/nokiastages
   
.. raw:: html

   </div>
</#if>
.. toctree::
   :maxdepth: 1
   
<#if !ant?keys?seq_contains("sf")>
   nokia/quality
</#if>
   manual/debugging
   metrics
   
.. raw:: html

   <ul><li class="toctree-l1"><a href="javascript:ReverseContentDisplay('api')">API</a></li></ul>
   <div id="api" style="display:none; position:absolute; border-style: solid; background-color: white; padding: 5px;">
   
* `Helium API`_
* `Helium Antlib`_
* `Ant Tasks`_

.. _`Ant Tasks`: api/ant/index.html
.. _`Helium API`: api/helium/index.html
.. _`Helium Antlib`: helium-antlib/index.html

<#if !(ant?keys?seq_contains("sf"))>
* `Python API`_
* `Java API`_
* `IDO API`_
* `DFS70501 API`_

.. _`Python API`: api/python/index.html
.. _`Java API`: api/java/index.html
.. _`IDO API`: <#if ant['helium.version']?matches("^\\d+\\.0(?:\\.\\d+)?$")>../</#if>ido/api/helium/index.html
.. _`DFS70501 API`: dfs70501/api/helium/index.html
</#if>

.. raw:: html

   </div>
   
<#if !ant?keys?seq_contains("sf")>
.. toctree::
   :maxdepth: 1
   
   api_changes
   nokia/releasenotes
</#if>

.. raw:: html

   </td><td>

Helium Framework configuration
==============================

.. toctree::
   :maxdepth: 3
   
   helium-antlib/index
   
.. toctree::
   :maxdepth: 1
   
   manual/cruisecontrol

<#if !ant?keys?seq_contains("sf")>
Customer docs
=============

* IDO_

.. _IDO: <#if ant['helium.version']?matches("^\\d+\\.0(?:\\.\\d+)?$")>../</#if>ido

* TeamCI_

.. _TeamCI: <#if ant['helium.version']?matches("^\\d+\\.0(?:\\.\\d+)?$")>../</#if>teamci

</#if>

Helium Architecture
===================

This section describes the architecture of Helium. It also contains a link to the style guide to be used for 
coding conventions.


.. toctree::
   :maxdepth: 1
 
   architecture
  
.. raw:: html

   </td></tr>
   <tr valign="top"><td>

Developer Guide
==================
This section contains information on how to make changes to Helium either as a tools team developer or an external 
developer. The 'developer guide' link contains information on the structure of the directories and some important
information on how to add libraries and other miscellaneous information.
It also contains details on how to test the changes made.

.. toctree::
   :maxdepth: 1

<#if !ant?keys?seq_contains("sf")>
   nokia/howto-contribute
   nokia/legal
   nokia/testing
</#if>
   developer_guide
   coding_conventions

.. raw:: html

   </td></tr>
   </table>
   
Indices and Tables
==================

* :ref:`genindex`
* :ref:`search`
