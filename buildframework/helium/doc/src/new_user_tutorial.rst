..  ============================================================================ 
    Name        : new_user_tutorial.rst
    Part of     : Helium 
    
    Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
    
########################
Helium New User Tutorial
########################

.. index::
  module: Helium New User Tutorial

.. contents::

Introduction
============

This tutorial covers the basic information to get up and running using the Helium build framework. Check the `Helium manual`_ for more detailed information.

.. _`Helium manual`: manual/index.html


Setting up a simple build file
===============================

Helium is based on `Apache Ant`_, a build tool written in Java that uses XML configuration files. A Helium build configuration must start with a ``build.xml`` file in the directory where Helium commands are run from::

    <?xml version="1.0" encoding="UTF-8"?>
    <project name="full-build">
        <!-- Import environment variables as Ant properties. -->
        <property environment="env"/>

        <!-- A basic property definition -->
        <property name="build.family" value="10.1"/>
        
        <!-- helium.dir will always refer to the directory of the Helium instance being used.
        
        All build configurations must import helium.ant.xml to use Helium. -->
        <import file="${helium.dir}/helium.ant.xml"/>
    </project>

.. _`Apache Ant`: http://ant.apache.org/
.. _`Ant manual`: http://ant.apache.org/manual

Helium looks for a ``build.xml`` project file in the current directory. It will parse this and additional imported Ant files to create the project configuration.


Basic structure
===============

The main components of Ant project files are targets, types and tasks. 

Targets define a set of tasks to be run as a build step. A target can depend on other targets, so a complete build process can be built up using a chain of targets. A simple target to echo some text to the console might look like this::

    <target name="print-hello">
        <echo>Hello!</echo>
    </target>

Types are information elements for configuring the build. The most common are properties that define a single value or location::

    <property name="build.family" value="10.1"/>
    
Properties representing locations are normalised to full paths when the ``location`` attribute is used::

    <property name="helium.build.dir" location="${helium.dir}/build"/>
    
.. note:: Once a property is defined it is immutable. The value of a property is defined by the first definition that is found.

Another common type is a fileset that represents a collection of files, typically using wildcard selection::

    <fileset id="foo.bar" dir="${helium.build.dir}">
        <include name="**/*.xml"/>
    </fileset>
    
This will select all XML files under the ``helium.build.dir`` directory. Note the use of ``${}`` to insert the value of a property.

There are a number of other types such as dirset, filelist, patternset which may be used for some configuration. See the "Concepts and Types" section of the `Ant manual`_ for more details.


Import statements
-----------------

Import statements are used to pull additional Ant project file content into the main project::

    <import file="${helium.dir}/helium.ant.xml"/>

Here the order of elements is significant:
    
Properties
  Must be defined before the import to override a property value in an imported file. See the `properties list <api/helium/properties_list.html>`_ for default values.
  
Types
  Other types such as filesets, dirsets that are referenced by ``ID`` must be defined after the import.
  
Targets
  Can be defined anywhere in the file.
  
``helium.ant.xml`` is the root file to import from Helium, which will pull in all the Helium content.


Run a command
=============

Make sure Helium is on the ``PATH``. Then the ``hlm`` command can be run from the project directory containing the ``build.xml`` file. Try a quick test::

    hlm hello
    
This should echo "Hi!" to the console, which shows that Helium can be imported successfully.

A target can be run using its name as a command::

    hlm [target]
    
Often it can be useful to define or override property values on the command line, like this::

    hlm [target] -Dname=value
    

Setting up a build
==================

An actual build process is defined by chaining together a number of major build stages, e.g. preparation, compilation, ROM building, etc. So a top-level build process target called from the command line might look like this::

    <target name="run-custom-tool">
        <exec executable="foo.exe">
            <arg name="bar"/>
        </exec>
    </target>
    
    <target name="full-build" depends="prep,run-custom-tool,compile-main,rombuild,final"/>
    
In this case an additional target is defined and run after prep but before compilation. The full build is then run by calling::

    hlm full-build -Dbuild.number=1
    
Configuring build stages
------------------------

Configuring each build stage typically involves defining or overriding properties and other types that are needed for that stage. In some cases special XML file formats are used. Please refer to the `appropriate sections <manual/stages.html>`_ of the manual for information on configuring each stage.

There are a number of individual features that can be enabled or disabled using flag properties. See `this list <manual/configuring_features.html>`_.


Overriding and extending targets
================================

If the build sequence needs customizing or extending, it is useful to be able to define new targets and potentially override existing Helium targets. Targets can be defined anywhere within the XML file. If multiple targets have the same name the first one to be parsed in the order of importing Ant files will be executed when called by name. Any target can be called explicitly by using its fully-qualified name which is constructed by prepending the name of the enclosing project, e.g.::

    hlm common.hello
    
This calls the ``hello`` target which is located in the common project file. It can be seen in the `API documentation`_.

.. _`API documentation`: api/helium/project-common.html#hello

Any existing target can be extended by overriding it and adding custom steps at the start or the end. To add steps to the start of a target, override it defining a new custom target and the original one as dependencies, e.g. to run a step before preparation::

    <target name="custom-step">
        <echo>Run before original target.</echo>
    </target>
    
    <target name="prep" depends"custom-step,preparation.prep">
    
Additional steps could be added to the end of a target using a similar method, or just include them in the overriding target thus::

    <target name="prep" depends="preparation.prep">
        <echo>Run after original target.</echo>
    </target>
    

Basic operations
================

Simple file-based tasks
-----------------------

Ant has core support for wide range of file-based tasks. Here are a few simple examples:

Copying all HTML log files by wildcard::

    <copy todir="${build.drive}/html_logs">
        <fileset dir="${build.drive}/output/logs">
            <includes name="**/*.html"/>
        </fileset>
    </copy>

Zip all the log files::

    <fileset id="html.logs.id" dir="${build.drive}/output/logs">
        <includes name="**/*"/>
    </fileset>
    
    <zip destfile="${build.drive}/html_logs.zip">
        <fileset refid="html.logs.id"/>
    </zip>
    
Deleting text log files::

    <delete verbose="true">
        <fileset id="html.logs.id" dir="${build.drive}/output/logs">
            <includes name="**/*.txt"/>
        </fileset>
    </delete>
    
See the Ant Tasks section of the `Ant manual`_ for a full list of available tasks.


Running an external tool
------------------------

The ``<exec>`` task can be used to run an external tool::

    <target name="run-custom-tool">
        <exec executable="custom.exe">
            <arg name="bar"/>
        </exec>
    </target>

See the `Ant manual entry <http://ant.apache.org/manual/Tasks/exec.html>`_ for more details on how to use the ``<exec>`` task. Use ``<exec>`` along with the customisation methods above to call additional tools at suitable places during the build. The `Setting up a build`_ section shows how a custom tool target could be called during a full build process.

External scripts can be run by calling the appropriate runtime executable and providing the script as an argument::

    <exec executable="python.exe">
        <arg name="custom-script.py"/>
    </exec>
        
        
Simple macros
-------------

Defining a macro is a useful method of combining a set of task steps to avoid repetition. This example defines a macro called ``testing`` and calls it::

    <macrodef name="testing">
       <attribute name="v" default="NOT SET"/>
       <element name="some-tasks" optional="yes"/>
       <sequential>
          <echo>v is @{v}</echo>
          <some-tasks/>
       </sequential>
    </macrodef>
    
    <testing v="This is v">
       <some-tasks>
          <echo>this is a test</echo>
       </some-tasks>
    </testing>


Getting help
============

There are several sources of further information:

 * The `Helium manual`_.
 * The `Helium API`_ of `targets`_, `properties`_ and `macros`_.
 * Command line help. Try running::
 
    hlm help [name]
    
   to get help on a specific target or property.

.. _`Helium API`: api/helium/index.html
.. _`targets`: api/helium/targets_list.html
.. _`properties`: api/helium/properties_list.html
.. _`macros`: api/helium/macros_list.html

