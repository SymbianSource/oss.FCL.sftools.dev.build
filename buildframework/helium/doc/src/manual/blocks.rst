..  ============================================================================ 
    Name        : blocks.rst
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

.. index::
  module: Blocks

======
Blocks
======

.. contents::

.. _`Blocks-Intro-label`:

Blocks Introduction
====================

Blocks is a packaging framework, which allows you to create bundles 
with interdependencies (like rpm or deb packages) base on the outcome of the build.


Enabling Blocks input generation
================================

The input generation consists in gathering data from build steps throughout the build to allow the generation
of the future bundle. Not all the steps are supported, so the build engineer must keep in mind that custom
exports or modification of the binaries after a controlled build step might lead to bundles with inconsistent content.
 
In order to enable blocks input generation you simply need to define the **blocks.enabled** property to true. Intermediate 
configuration file will be generated under **blocks.config.dir**.

e.g::
   
   hlm -Dblocks.enabled=true....


Currently supported steps are:
 * SBSv2 compilation
 * Configuration export using cMaker (only if cmaker-what is called)
 * ROM image creation


Bundle generation
=================

Once the data have been gathered during the build, it is then possible to create bundles. To do so you need to call the 
**blocks-create-bundles** target. Generated bundle will be created under **blocks.bundle.dir**.

e.g::
   
   hlm -Dblocks.enabled=true .... blocks-create-bundles
   

Blocks workspace management with Helium 
=======================================

Helium allows you to use any build environment as Blocks workspace. The :hlm-t:`blocks-create-workspace` will handle the
automatic creation of workspace base on the current build.drive used. If the current build.drive represent an
already existing workspace then it will reuse it. The :hlm-p:blocks.workspace.id property will contain the Blocks workspace
id. Also when new workspace is created some repositories can be automatically added using the **blocks.repositories.id** reference
to an hlm:blocksRepositorySet object.

::
   
   <hlm:blocksRepositorySet id="blocks.repositories.id">
       <repository name="test-repo" url="file:E:\my-repo" />
   </hlm:blocksRepositorySet>
   


Installing bundles
==================
The :hlm-t:`blocks-install-bundles` target will allow you to install packages under the workspace, to do so, you can configure
the following references using patternset:

::
   
   <patternset id="blocks.bundle.filter.id">
       <include name="some.pkg.name.*" /> 
       <exclude name="some.other.pkg.name.*" /> 
   </patternset>

   <patternset id="blocks.group.filter.id">
       <include name="some.pkg.name.*" /> 
       <exclude name="some.other.pkg.name.*" /> 
   </patternset>
   
      
The **blocks.bundle.filter.id** patternset will allow you to filter bundles based on their name. And **blocks.bundle.filter.id** patternset will allow you
to install group selected group of bundles.

Finally the workspace can be updated using the :hlm-t:`blocks-update-bundles` target.
  
