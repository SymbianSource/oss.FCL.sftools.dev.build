..  ============================================================================ 
    Name        : developer_guide.rst
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
  module: Developer Guide

###################################
Developer Guide
###################################

.. contents::

Introduction
============

This describes various practices, procedures and conventions used within Helium. It should be read by all contributors to Helium along with the `Coding Conventions`_.

.. _`Coding Conventions`: coding_conventions.html

.. index::
  single: Directory Structure

Directory structure
===================

The ``/helium`` directory structure consists of:

``/build``
    This is not under source control. It is created on demand to store generated documentation, testing and coverage output and so on.
    
``/config``
    Configuration files for parts of Helium. Some of these may only need to be defined in Helium, whereas others may be default configuration that may be overridden by a user.
    
``/doc``
    All documentation related to Helium. Files are in .rst format (HTML versions can be generated under ``/build/doc`` using the ``hlm doc`` command).
    
``/external``
    Applications and libraries that are maintained outside of the Helium team.

``/tests``
    Test data for unit tests. All unit tests are co-located with the code under test.

``/tools``
    A number of subdirectories for each stage of the build. Each directory may contain Ant scripts and other tools and scripts related to that stage.

``/tools/common``
    Common libraries for Java, Perl and Python and XML schemas.
    

Ant script structure
--------------------

The ``helium.ant.xml`` file in the project root should be imported by each build configuration. This in turn imports the root files for each of the key build stages defined in the ``/tools`` directory. ``helium.ant.xml`` also defines a number of common Ant default properties.


.. index::
  single: Custom Ant library

Custom Ant libraries
====================

All custom Ant tasks, types and loggers should be added as new components under the ``/sf`` folder. If the component being created is Java-based, then add it inside the ``/java`` folder. The component directory must contain a ``build.xml`` file that imports ``${builder.dir}/java/macros.ant.xml``. Also the name of the project must be the name of the future JAR file e.g::

   <?xml version="1.0"?>
   <project name="mycomponent">
       <import file="${builder.dir}/java/macros.ant.xml" />
   </project> 

The component also need an Ivy file (``ivy.xml``) in order to be detected and built. The file must define the correct list of dependencies for the component so it get built in the correct order.

.. index::
  single: How to build the delivery?

How to build the delivery?
==========================   

From Helium 9.0 onward, the delivery will be released as source code, without any pre-built binaries. In order to build the release please follow the next instructions.

Building the dependencies
-------------------------

In order to build the Helium components you need to use the builder available under the helium directory::

   > cd builder
   > bld build

This will build all the components needed to create the Helium release: egg or jar files.

Retrieving Helium dependencies
------------------------------

Building the dependency will not bring Helium in a workable stage. It is a preparation stage where components could be unit tested in isolation for example. Retrieving Helium dependencies based on the version of Helium you desire is then needed. The builder can achieve this operation by running the following command::

   > cd builder
   > bld -Dconfig=sf get-deps
  
The previous command will retrieve Helium sf configuration dependencies.

Packaging up the built version
------------------------------

A deliverable ZIP package of binary version of Helium can be created using the following commands::

    > cd builder
    > bld -Dconfig=sf create-releasable

The archive can be found at ``build/helium-bin.zip``.

.. index::
  single: Testing
  
Testing
=======

Components
-----------

Component tests can be run using::

    > cd builder
    > bld unittest
   
A specific type of tests can be selected using::

    > bld -Dcomponent.type=java unittest
   
A specific component can be selected using::

    > bld -Dcomponent=sbs unittest

Debug logs for component tests can be found at ``/build/components/<component>/xunit``.


.. index::
  single: Assertions

Assertions
==========

There are some basic assertion macros defined in ``common.ant.xml``. These can be used to check for correctness at the end of a target, e.g. checking that a file exists which the target was supposed to create.

The assertions can be enabled by defining the ``hlm.enable.asserts``. If ``hlm.enable.asserts`` is not enabled, macro will print warnings only.
There are several macros:

``hlm:assert``
    A basic assertion that will check any task contained within it.
    
``hlm:assertFileExists``
    Takes a file attribute and asserts that the file exists.

.. index::
  single: Ivy Configuration

Ivy Configuration
=================

Ibiblio
-------

Libraries in Maven2 Ibiblio_ repository can use: ``helium/config/ivy/ivy.xml``

.. _Ibiblio: http://mirrors.ibiblio.org/pub/mirrors/maven2/

These parameters should be used, if library has passed legal tests: ``transitive="false"``, ``conf="subcon"``
Otherwise use: ``transitive="false"``, ``conf="core_install"``

Direct URLs
------------

Use these for a direct url link, if the library is needed for the subcon release::

    helium/config/ivy/modules/jars_subcon-1.0.ivy.xml
    helium/config/ivy/modules/eggs_subcon-1.0.ivy.xml

Otherwise add to these files for non subcon libraries::

    helium/config/ivy/modules/eggs-1.0.ivy.xml
    helium/config/ivy/modules/jars-1.0.ivy.xml
    
A new Ivy config file can be added for a non-jar or egg type file.

