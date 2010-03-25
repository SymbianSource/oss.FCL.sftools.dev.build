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
  single: Tools version checking

Tools version checking
======================

Tool version checking can be performed to ensure that all tools have correct versions present. At the same time, a path setting file will be created. Calling this file will add tools into path, so hard coding paths is no longer needed.

To perform checking run the command::

  hlm check-tool-versions


.. index::
  single: Build output

Build output
================

When a build is running the targets being executed are listed on the screen there is no need to pipe this to a file as the ant targets are logged in the   ``\*_main.ant.log`` for product and IDO builds. Once the build is complete it will say on the screen whether the build was successful or failed. If it has failed it should give an indication of where and why it failed on the screen but for more information you must examine the output logs. If the build says it was successfult this does not necessarily mean that the build compiled all components successfully, you must examine the logs to check that all is compiled and linked correctly. See :ref:`Troubleshooting-label` for information on logs and where they kept.

The result of the build (compiled files, linked (flash) files etc.) are  stored in the usual folders and directories under the ``\epoc32`` directory.


.. index::
  single: Logging
  
Logging
=======

Diamonds
--------
Logging to the Diamonds metrics database can be disabled by setting the property:: 

    skip.diamonds=true

Internal data
-------------

Helium can collect internal data about builds for the purpose of improving support. This can be disabled by setting an environment variable::

    set HLM_DISABLE_INTERNAL_DATA=1

 
Troubleshooting
================

See :ref:`Troubleshooting-label` for information on how to find faults with Helium.