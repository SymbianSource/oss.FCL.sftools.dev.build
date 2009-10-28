.. index::
  module: Developer Guide

###################################
Developer Guide
###################################

.. contents::

Introduction
============

This describes various practices, procedures and conventions used within Helium. It should be read by all contributors to Helium along with the Coding Conventions.

.. index::
  single: Documentation

Documentation
=============

Standalone documents like this design document and the user guide are documented in reStructuredText__ format.

__ http://docutils.sourceforge.net/rst.html

HTML documentation is generated in ``/helium/build/doc`` using the ``hlm doc`` command.


.. index::
  single: Index References-creating

Creating Index References
-------------------------

In order to get things in the index you have to manually add the following code to the .rst files: ::
 
  .. index::
     module: file heading (the text in the 1st heading at the top of the page) gets added to index as module

put this text at the top of the file::

  .. index::
    single: heading text

put this just above a heading. This gets added to the index as a normal indexed link.

If you replace 'single' with 'pair' it puts 2 enteries in the index:::
 
  .. index::
     pair: iname1; ename2

In the index it becomes iname1 with ename2 below it and indented (in the 'i' section) and also ename2 with iname1 
below it and indented (in the 'e' section)

The index directive needs blank lines either side of it.


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

``/testconfig``
    Test build configurations.

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

Custom Ant library
==================

All custom Ant tasks and loggers should be added under ``/tools/common/java/src``. The command::

  hlm-jar.bat

can be run from the ``/helium`` directory. This will update the ``nokia_ant.jar`` file in ``/tools/common/java/lib``.

Each custom task must be defined inside the ``antlib.xml`` file inside ``/tools/common/java/src/nokia/ant``.


.. index::
  single: XML Schemas

XML schemas
===========

A ``validate-xml`` command can be run to check the various Helium XML files against their schema (this is run in the automated unit tests).

There are schema files for these XML file types:

* Helium data model.


.. index::
  single: Helium Data Model

Helium data model
=================

The Helium data model defines the configuration elements needed to configure Helium. It is defined in the file ``/config/helium_data_model.xml`` and contains:

* A list of configuration elements with metadata:

  * Name. Defines the name of the configuration element. Required.
  * Type. Defines the type of the configuration element, i.e. if the configuration element is a string, integer, boolean or flag. Required.
  * Usage. Defines the typical usage of the property. Must one of "must", "recommended", "allowed", "discouraged", "never". Required.
  * Description. This should be in .rst format. Required.
  * Deprecated. This is a optional element that defines the property is deprecated.

* A list of groups that group together related configuration elements and their usage requirements within that group, i.e. if that feature is to be used, what configuration is required and what is optional. All required configuration elements in a group must be defined.
  
Any Ant configuration can be checked against the model by running ``hlm check``.


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
------------------

Ibiblio
````````

Libraries in Maven2 Ibiblio_ repository can use: ``helium/config/ivy/ivy.xml``

.. _Ibiblio: http://mirrors.ibiblio.org/pub/mirrors/maven2/

These parameters should be used, if library has passed legal tests: ``transitive="false"``, ``conf="subcon"``
Otherwise use: ``transitive="false"``, ``conf="core_install"``

Direct URLs
```````````

Use these for a direct url link, if the library is needed for the subcon release::

    helium/config/ivy/modules/jars_subcon-1.0.ivy.xml
    helium/config/ivy/modules/eggs_subcon-1.0.ivy.xml

Otherwise add to these files for non subcon libraries::

    helium/config/ivy/modules/eggs-1.0.ivy.xml
    helium/config/ivy/modules/jars-1.0.ivy.xml
    
A new ivy config file can be added for a non-jar or egg type file.
