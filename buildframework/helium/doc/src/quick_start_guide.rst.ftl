<#--
============================================================================ 
Name        : quick_start_guide.rst.ftl
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
########################
Helium Quick-Start Guide 
########################

.. index::
  module: Helium Quick-Start Guide

.. contents::

Introduction
============

This document is a quick-start guide for the Ant-based Helium build framework. More information can be found from `Helium manual`_.

.. _`Helium manual`: manual/index.html


.. index::
  single: Helium configuration


Installation
=============

<#if !ant?keys?seq_contains("sf")>
Helium can be retrieved from the Hydra_ service:

.. _Hydra: http://wikis.in.nokia.com/Hydra

:URL: http://trhdr001.nmp.nokia.com/services/90?page=1 
:Service: SoftwareBuildSolutions_Tools
:Product: BuildEnvironment

</#if>

<#if ant?keys?seq_contains("sf")>

.. include:: sf.rst

</#if>


Configuration
=============

- Helium is configured using a combination of Ant configuration elements (properties, filesets, etc) and other XML files for more complex
  configuration of particular parts of the build. For initial tests run in this quick-start guide you do not need to configure anything, but 
  do please read the following references for more information:

  - `Using Ant <http://ant.apache.org/manual/using.html>`_: specifically the Projects and Properties sections.
  - `Configure Helium  <manual/configuring.html>`_: `common configuration format <manual/configuring.html#common-configuration-format>`_ and `Helium stages <manual/stages.html>`_.
  - `Helium glossary <api/helium/properties-table.html>`_: lists the specific properties used in Helium.
  
  
.. index::
  single: Running builds with Helium

.. _Running-helium-label:

Running builds with Helium
==========================

After configuring the framework, running builds with Helium is simple. The command-line interface is the same as for Apache Ant. 
Please read `Running Ant <http://ant.apache.org/manual/running.html>`_ for more information.

You start the build with ``hlm`` command. Navigate into 'helium' directory (should contain the file ``hlm.bat``) and type::

    hlm [target] [-D<property>=<value>] [-f <ant_build_file>] [-h] [-p -v]
    
    [target]                        Run Ant target
    [-D<property>=<value>]          Set an Ant property
    [-f <ant_build_file>]           Use another Ant build file
    [-h]                            Print Ant help text
    [-p -v]                         List all Ant targets
    
    Variable properties for helium:
    -Dsysdef.configuration=default set build configuration, default value is 'default'
    -Dbuild.system=ebs             set build system, default value is 'ebs'
                                      - possible values are 'ebs' and 'ec'
    
    Usage examples:
    hlm                            build the default build target
    hlm -Dbuild.system=ec-helium   use electric cloud build system


Eg:: 

    hlm -Dbuild.number=1 hi
    
This is a very simple task found in the file ``\helium\tool\common\common.ant.xml``

The code is shown below::

    <!-- A simple test target that prints a simple message -->  This is a comment line <!--  --> 
                                                                indicates comment text
    <target name="hello">                                       This is the target name 'hello'
        <echo message="Hello!"/>                                what the task does echo the 
                                                                word 'hello'
        <if>                                                    Conditional branch
            <isset property="build.number"/>                    If the property build.number is
                                                                present 
            <then>                                              then 
                <echo message="Ant libs found OK"/>             echo additional text 'Ant libs 
                                                                found OK'
            </then>                                             end of 'then' action
        </if>                                                   end of 'if' action
    </target>                                                   end of target/task
    
    
    <target name="hi" depends="hello"/>                         this is the called target which
                                                                depends upon the target 'hello' 
                                                                being run before
                                                                this target is run.
    
Users' Flow Diagram
==========================

The diagram below illustrates some pathways and key documents to review for different proficiency levels.

.. raw:: html

   <img src="user_graph.dot.png" alt="Flow Diagram" usemap="#flowdiagram" style="border-style: none"/>
   <map name="flowdiagram" id="flowdiagram">

.. raw:: html
   :file: user_graph.dot.cmap

.. raw:: html

   </map>