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
.. index::
  module:  Minibuild test configurations

Minibuild test configurations
=============================

Minibuilds are buildbots (automated test systems) that are used to test parts of Helium. For each platform/family of products e.g. 5132 and 5152 
a buildbot is created that tests the platform using 
a subset of the complete build. All build bots are automatically executed each time something is checked in to the Helium subversion trunk.

.. index::
  single:  Minibuild test configurations- getting started

Getting Started
---------------

.. toctree::
   
<#list project.getReference('internal.ref.minibuilds')?split(';') as filename>
   ${filename?replace('\\', '/')}
</#list>
