<#--
============================================================================ 
Name        : index.rst.ftl
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
#############
Helium Manual
#############

.. raw:: html

   <table border="0" cellspacing="0" cellpadding="10">
   <tr valign="top">
   <td width="50%" style="border-right: 1px solid black">

.. toctree::
   :maxdepth: 2

   introduction
   support
<#if !ant?keys?seq_contains("sf")>
   retrieving
</#if>
   configuring
   configuring_features
   running
   stages
   
.. raw:: html

   </td><td width="50%">

.. toctree::
   :maxdepth: 2
   
<#if !ant?keys?seq_contains("sf")>
   nokiastages
   datapackage
   iad
</#if>
   documentation
   cruisecontrol
   sysdef3
   messaging
   metrics
   coverity
   final

.. raw:: html

   </td></tr>
   </table>