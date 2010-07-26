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
###################################
  Development
###################################

This section contains information on how to make changes to Helium either as a tools team developer or an external developer. The developer guide contains information on the structure of the directories and some important information on how to add libraries and other miscellaneous information. It also contains details on how to test the changes made.

.. toctree::
   :maxdepth: 1

   developer_guide
   coding_conventions
<#if !ant?keys?seq_contains("sf")>
   howto_contribute
   legal
   testing
   pre_release_testing
   junit_testing
</#if>
   
   
   
