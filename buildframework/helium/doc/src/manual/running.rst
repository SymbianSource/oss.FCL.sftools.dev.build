..  ============================================================================ 
    Name        : running.rst
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
  module: Running Helium

##############
Running Helium
##############


.. contents::


.. index::
  single: Command line

Command line
============

The Helium command line interface is basically the same as the Ant command line, the main difference being that ``hlm`` is used instead of ``ant``. Please make sure to read the `Ant documentation`_.

.. _`Ant documentation`: http://ant.apache.org/

.. index::
  single: Command line help

Command line help
-----------------

To get a help summary on the command line, run ``hlm`` or ``hlm help``.

To get help on a specific command, run ``hlm help <command>``.

.. index::
  single: Basic Commands

Basic commands
--------------

::

    hlm hello
    
Prints Hello to the command line. Very simple way to check the configuration is runnable.

::

    hlm version

Prints out the Helium version information.

::

    hlm config

Prints the Ant configuration properties.

::

    hlm diagnostics

Prints various diagnostic information that is useful for debugging.
 

.. index::
  single: Configuration validation

Configuration validation
========================

An Ant configuration can be validated against the Helium data model using the command::

    hlm check
    
This will check for a number of things:

* Warn about deprecated properties that are defined.
* Warn about required properties in groups where at least one other property from that group is used. A group is a set of related properties for a feature. If that feature is to be used some properties may then be required and some may still be optional within that group.
* Show for information any properties that are in the configuration but not in the data model. A particular build configuration may want to define some properties that are additional to those recognised by Helium.


.. index::
  single: Build output

Build output
================

When a build is running the targets being executed are listed on the screen there is no need to pipe this to a file as the ant targets are logged in the   ``\*_main.ant.log`` for product and IDO builds. Once the build is complete it will say on the screen whether the build was successful or failed. If it has failed it should give an indication of where and why it failed on the screen but for more information you must examine the output logs. If the build says it was successfult this does not necessarily mean that the build compiled all components successfully, you must examine the logs to check that all is compiled and linked correctly.

The result of the build (compiled files, linked (flash) files etc.) are  stored in the usual folders and directories under the ``\epoc32`` directory.

.. index::
  single: Running build operations

Running build operations
========================

Setting the build number
-------------------------

The :hlm-p:`build.number` property is typically not defined in a configuration file, as it changes for every new build. It should be defined as a command line parameter::

    -Dbuild.number=123

A shortcut can also be used::    

    -Dbn=123    

.. index::
  single: Setting the team property

.. _Setting-Team_properties-label:

Setting the team property
--------------------------

``SET TEAM=<team-name>`` (this defines which team-specific XML file from ``../site/${r'$'}{env.TEAM}.ant.xml`` is used for build configuration).


.. index::
  single: Logging
  
Logging
=======

Diamonds
--------
Logging to the Diamonds metrics database could be disabled by setting the property:: 

    diamonds.enabled=false

Internal data
-------------

Helium can collect internal data about builds for the purpose of improving support. This can be disabled by setting an environment variable::

    set HLM_DISABLE_INTERNAL_DATA=1
    
Output logs
-----------

There are a large number of output logs created to assist with understanding the build and determining what has been performed and what has not. All of the log files are generated in the build area, usually under the ``output/logs`` folder. Many of the logs are created in different formats, e.g. the Bill Of Materials log file exists as HTML, XML and text (all the same information). Some of the logs exist as different file formats giving different information at various stages of the activity, e.g. the cenrep logs in which case generally the HTML files are a summary of the whole activity.

.. image:: dependencies_log.grph.png

 
Troubleshooting
================

This section contains details on how to find errors and problems within Helium itself (for helium contributors) and within the configuration files
and Ant tasks etc. for build managers and subcons.

Diagnostics
------------

Use the :hlm-t:`diagnostics` command provide debugging information when reporting problems. It lists all the environment variables and all the Ant 
properties and all the Ant targets within Helium::

    hlm diagnostics > diag.log

Failing early in the build
---------------------------

The :hlm-p:`failonerror` property is defined in ``helium.ant.xml`` and has the default value ``false``. It is used to control whether the ``<exec>`` 
tasks fail when errors occur or the build execution just continues. The build can be configured to "fail fast" if this is set to ``true``, 
either on the command line or in a build configuration before importing ``helium.ant.xml``. Given that many ``exec`` tasks will return an 
error code due to build errors, it is not recommended to set this to true for regular builds.