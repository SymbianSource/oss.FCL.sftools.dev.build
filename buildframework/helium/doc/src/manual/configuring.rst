.. index::
  module: Configuring Helium

==================
Configuring Helium
==================

.. contents::

Introduction
============

This describes the key aspects of configuring a Helium build and other aspects of using the Helium build toolkit.

Helium consists of several phases (the   stages_ section explains these in detail) these are briefly outlined here:

* pre-build   - performs several checks on the environment and creates the Bill of Materials (BOM) before copying the relevant files from synergy to the build area and unzipping them.
* build       - compiles the  files.
* post-build  - creates SIS files (system Installation files), creates ROM images, zips the build area for releasing, publishes releases, creates localised images, produces data packages, reports results to diamonds server.

.. _stages: stages.html

.. index::
  single: Configuration files

Configuration files
===================

Defining a Helium build configuration can be a simple or complicated task depending on the requirements. Helium supports a lot of build 
functionality but much of it is optional. All configuration files are based on XML using a number of different XML schemas or formats. 
Over time more consistency and harmonisation of the formats will be implemented. Below is a list of the key formats:
    
.. csv-table:: Helium configuration file types
   :header: "Format", "Where used"
   
    "Apache Ant", "All build configurations must start with at least a ``build.xml`` file in the directory where builds will be run, that contains the minimum of Helium Ant properties to configure the build."
    "Common configuration", "Several build stages: ROM build, zipping, SIS file creation."
    "Environment/shell variables", "Configuring the PATH and other environment settings."
    "Preparation", "Creation of a build area, using copy and unzip steps."

.. index::
  single: Ant configuration

Ant configuration
-----------------

The Ant format is the most important because at least one Ant file is required to run any kind of build command. Read the `Using Ant`_ section of the Ant manual that describes how to write generic Ant files.

.. _`Using Ant`: 

In the context of Helium, some specific elements and properties should be used. Here is an example of a very basic Helium Ant file::

    <?xml version="1.0" encoding="UTF-8"?>
    <project default="product-build">
        <!-- Import environment variables as Ant properties. -->
        <property environment="env"/>

        <!-- A basic property definition -->
        <property name="product.name" value="PRODUCT"/>
        
        <!-- helium.dir will always refer to the directory of the Helium instance being used.
        
        All build configurations must import helium.ant.xml to use Helium. -->
        <import file="${helium.dir}/helium.ant.xml"/>
    </project>

Note that here the default target is ``product-build`` so this would be used for a product build configuration. In reality it would need many more properties to be complete.

Refer to the `configuration reference`_ for a full list of all Helium Ant properties.

.. _`configuration reference`: ../api/helium/index.html

.. index::
  single: Common configuration format

.. _common-configuration-format-label:

Common configuration format
---------------------------

Several parts of the build require more complex configuration than basic ``name=value`` properties. A common format is introduced for these configurations that is closely matching the future Raptor build system format in concept.

Currently only \`ROM Image configuration (using iMaker)\`_ and \`SIS files\`_ are configured using this format.

Summary:

 * The XML document format consists of a ``<build>`` root element.

 * ``<config>`` subelements define specifications (configurations) to be built.

   * ``<config>`` elements can be nested, i.e. a ``<config>`` element can contain other ``<config>`` elements, etc.

   * A ``name`` attribute identifies that element. It can be used to select one or a group of configurations.

   * An ``abstract`` attribute marks that specification as being not directly buildable. Child specifications not marked as abstract may be buildable.

 * ``<set>`` elements inside ``<config>`` s define property values. A property defined in a child ``<config>`` element overrides the value of a property with the same name in a parent specification. All parent properties are inherited if not overridden.

   * Comma-separated values or repeated elements will result in a list property value when evaluated.


.. index::
  single: Passwords

Passwords
=========

Helium requires access to a few resources that require username and password authentication, like Synergy for SCM operations. To avoid the need for a password dialog request, these details can be entered in a ``.netrc`` file located on the user's HOME drive. The HOME location is one of:

Windows
  H: drive
  
Linux
  ``/home/user``
  
A ``.netrc`` file is a standard Unix file format.

The following entries are available:

Synergy::

  machine synergy login <synergy-username> password <synergy-password>

``synergy`` can be replaced by the name of a specific database if the settings should apply only to that database, e.g::

  machine vc1s60p1 login <synergy-username> password <synergy-password>

Then account could be used to override the default GSCM settings::

  machine sa1ido login <synergy-username> password <synergy-password> account /db/path@dbhost 

Nokia specific
--------------

NOE::

  machine noe login <network-username> password <network-password>
  
Lotus Notes::

  machine notes login <notes-username> password <notes-password>

nWiki::

  machine nwiki login <nwiki-username> password <nwiki-password>

**Note:- that the nWiki password is different to that used for NOE/Notes/Grace and therefore will typically require the use of the macro macro-netrc.username along with the macro macro-netrc.password.**


.. index::
  single: Signals notifications

Signals notifications
=====================

Helium contains a number of signal events that are triggered at various points during the build. These provide the following features:

* Determine whether to fail the build immediately, deferred to the end or not at all.
* Send an email alert message.
* Send an SMS alert message.

A default configuration of the signals is defined in ``config/helium_signals_default.xml``. By default the email alerts are sent to the build manager, but each signal can have a custom email list by defining a property ``<signal-name>.email.list``. 


.. index::
  single: Viewing target dependencies

Viewing target dependencies
===========================

The ``deps`` target can be used to display a list of the target dependencies for a given target. See the `manual page`_ for more information. Also the ``execlist`` command works in a similar way but shows a dialog showing a separated list of all the dependent targets and then just the top-level of dependencies, to help with continuing a build on the command line.

.. _`manual page`: ../api/helium/target-deps.html


.. index::
  single: Automating build number assignment

Automating build number assignment
==================================

Typically the build number for a build is defined on the command line. However it may be desirable to automate the allocation of a new build number using a simple text database file. To do this, add the property ``read.build.int`` to the configuration or the command line. This will look for a text file in this location::

    ${publish.root.dir}/${build.name}/builds/${build.name}_${core.build.version}_${build.tag}_build_int_db.txt
    
If the file is not present it is created with a new build number value of "001". If it does exist the value is read from the file and then incremented and written back for the next build. A ``build.tag`` property can also be defined to start the build number with a text string if needed.


.. index::
  single: Advanced configuration

Advanced configuration
======================

.. index::
  single: Custom targets

Custom targets
--------------

Custom targets are often needed in a configuration to customize, extend or otherwise modify the default behaviour and build sequences of Helium.

To override a target inside Helium define a custom target with the same name. The original target will then be named with
the prefix of the project (Ant file) name, e.g. ``common.hello``. There are three ways to customize a target:

.. index::
  single: Completely replace the target

Completely replace the target
:::::::::::::::::::::::::::::

Just define the custom target::

    <target name="hello">
        <echo message="Custom hello!"/>
    </target>
    
.. index::
  single: Run custom code after the target

Run custom code after the target
::::::::::::::::::::::::::::::::

Define the overriding custom target and make it depend on the original target::

    <target name="hello" depends="common.hello">
        <echo message="After hello!"/>
    </target>

.. index::
  single: Run custom code before the target

Run custom code before the target
:::::::::::::::::::::::::::::::::

This is a little more complicated. Two custom targets are needed, one to implement the custom behaviour, and the 2nd to override the original target and define the dependencies::

    <target name="pre-hello">
        <echo message="Before hello!"/>
    </target>
    
    <target name="hello" depends="pre-hello,common.hello"/>

.. index::
  single: Call a target with different params

Call a target with different params
:::::::::::::::::::::::::::::::::::

In rare situations you may need to override a target in helium or call it with different properties, you should create a target in your config with the same name before you import helium.ant.xml::

    <target name="localisation-roms">
        <for list="${localisation.makefile.target}" delimiter="," param="target" >
            <sequential>
                <antcall target="localisation-32.localisation-roms">
                    <param name="localisation.makefile.target" value="@{target}"/>
                </antcall>
            </sequential>
        </for>
    </target>

.. index::
  single: Using Helium internal tasks and macros

Using Helium internal tasks and macros
--------------------------------------

Helium contains a number of internal tasks and macros that are defined under a Helium XML namespace. This is to make it easier to distinguish them from standard Ant and 3rd party tasks inside the Helium Ant files. This means that namespaces must be correctly applied to most Helium tasks or macros.

Helium tasks start with the prefix ``hlm:``, for example::

    <target name="do-signal">
        <hlm:signal name="testSignal"/>
    </target>
    
To include an XML element with a ``hlm:`` prefix the Helium namespace must be defined in the root element of the XML file::

    <project name="myproject" xmlns:hlm="http://www.nokia.com/helium">
    ....
    </project>

.. index::
  single: System definition configuration files

System definition configuration files
:::::::::::::::::::::::::::::::::::::

Sysdef configuration defines the source code you actually want to compile with Helium. More information about the System definition
files can be found from: http://developer.symbian.org/wiki/index.php/System_Definition. 

helium/tests/minibuilds/qt/minibuild_compile.sysdef.xml which can be examined as a sample definition file.
It is used by the Helium test environment to test helium works. It consists of a list of components to compile and some special instructions to 
perform whilst compiling the components e.g. run toucher.exe on certain directories. You will need to make sure this file exists and contains 
the correct components when building and especialy for a product which consists of many hundreds of components. It should be possible to use 
the file supplied by S60, but you may need to copy the component compile lines from the file and add them to the existing file in helium in 
order to make sure you also get the special instructions which are required to make the builds create a ROM image successfully (or any
other action requested).
    
  