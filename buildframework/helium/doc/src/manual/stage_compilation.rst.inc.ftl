<#--
============================================================================ 
Name        : stage_compilation.rst.inc.ftl
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
  single: Stage - Compilation

Stage: Compilation
==================

Compilation is based on configuration using Symbian System Definition XML files.
See http://developer.symbian.org/wiki/index.php/System_Definition

Every System Definition file can contain content for two separate sections:

System model
    A definition of the system describing the components that exist, broken into layers, modules, etc.
    
Build model
    Build configurations that define what is to be built and how it will be built. Separate unitLists define groups of components.

The steps to configure a Helium build for main compilation are as follows:

1. Put together a list of the System Definition files that define the components needing to be built in the system model sections. This could be one or several files depending on what components need building. They should be defined in an Ant ``<path>`` type with an ``id`` atttribute set to ``system.definition.files``, e.g:

.. code-block:: xml

    <path id="system.definition.files">
        <fileset dir="${r'$'}{build.drive}/src/common/generic/tools/build" includes="System_Definition*.xml"/>
        <pathelement path="${r'$'}{build.drive}/build/ibusal_40_build/ibusal_40/IBUSAL40_System_Definition.xml"/>
        <fileset dir="${r'$'}{build.drive}/s60/tools/build_platforms/build/data" includes="S60_System*.xml"/>
        <pathelement path="${r'$'}{build.drive}/me/me_scd_desw/sysdef/System_Definition_PRODUCT.xml"/>
        <pathelement path="${r'$'}{build.drive}/build/${r'$'}{product.family}_build/_System_Definition.xml"/>
    </path>
    
The order of the files is significant. If building Symbian OS, the Symbian System Definition file must come first. Here both ``fileset`` and ``pathelement`` are used. ``pathelement`` selects just one file whereas a ``fileset`` can use wildcards to select multiple files or handle problems of filenames changing across different platform releases.

2. Determine if an existing build configuration in any of the build model sections of the files are suitable for what needs to be built. A build configuration typically looks something like this:

.. code-block:: xml

    <configuration name="foo_config" description="Build foo">
         <unitListRef unitList="foo_list"/>
        
         <task><buildLayer command="bldmake bldfiles" unitParallel="Y"/></task>
         <task><buildLayer command="abld export" unitParallel="Y"/></task>
         <task><buildLayer command="abld makefile" targetList="default" unitParallel="Y" targetParallel="N"/></task>
         <task><buildLayer command="abld resource" targetList="default" unitParallel="N" targetParallel="N"/></task>
         <task><buildLayer command="abld library" targetList="default" unitParallel="N" targetParallel="N"/></task>
         <task><buildLayer command="abld target" targetList="default" unitParallel="Y" targetParallel="Y"/></task>
         <task><buildLayer command="abld final" targetList="default" unitParallel="N" targetParallel="N"/></task>
         <task><buildLayer command="abld -what export" unitParallel="Y"/></task>
         <task><buildLayer command="abld -what target" targetList="default" unitParallel="Y" targetParallel="Y"/></task>
         <task><buildLayer command="abld help" unitParallel="Y"/></task>
         <task><buildLayer command="abld -check build" targetList="default" unitParallel="Y" targetParallel="Y"/></task>
    </configuration>

A ``unitListRef`` includes a ``unitList`` defined somewhere else as part of this configuration. The ``buildLayer`` elements define ``abld`` steps to run on each component. If an existing configuration is not sufficient a new one must be defined in a separate file (which should be included in the ``path`` type).

3. Define the :hlm-p:`sysdef.configurations.list` Ant property to contain a comma-separated list of build configuration names that must match the ``name`` attribute of the ``configuration`` element. Each configuration will be built in turn in the :hlm-t:`compile-main` Ant target.

Note: Build will fail if compilation error exceeds the number specified in ``build.errors.limit``. Default value is ``0`` and set it to ``-1`` to ignore this.

.. index::
  triple: Builds; EBS; EC

EBS and EC compilation
----------------------

To switch the compiler version define the ``HLM_RVCT_VERSION`` environment variable (Nokia specific feature)::

    set HLM_RVCT_VERSION=22_593

By default Helium is configured to run EBS builds. The :hlm-p:`build.system` property determines what build system to use. An EC build can be run from the command line using::

    hlm <build target> -Dbuild.system=ec-helium


An EC build could be configured to run in parallel (default) or in serial mode (1 node build)::

    hlm <build target> -Dbuild.system=ec-helium -Dec.mode=serial

Also the ``--emake-debug`` flag could be configured either by the environment using the ``EMAKE_DEBUG`` variable or using the ``emake_debug_flag`` property. Its default value is ``g``.


Raptor compilation
------------------

Enabling CTC integration
   It is possible to enable CTC instrumenting while building with SBSv2. To proceed you need to define the **sbs.build.ctc** to true.
   If default options are not satisfying (default command line arguments: "-i m"), you can override the **ctc.instrument.type** property to
   define an another instrumentation type. Or if you need to define additional arguments you can then override 
   the argSet referenced by **ctc.build.options**. 
   
   