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
  module: Stages

=============
Helium stages
=============

.. contents::

This section gives details of each of the phases of a Helium build and what they do.


.. include:: stage_startup.rst.inc

.. include:: stage_source_preparation.rst.inc

.. include:: stage_preparation.rst.inc

.. include:: stage_compilation.rst.inc

.. include:: stage_post_build.rst.inc

.. include:: stage_publishing.rst.inc

.. include:: stage_releasing.rst.inc

Cenrep creation (S60 3.2.3 - 5.x)
=================================
<#if !(ant?keys?seq_contains("sf"))>
See: http://configurationtools.nmp.nokia.com/builds/cone/docs/cli/generate.html?highlight=generate
</#if>

The target ``ido-gen-cenrep`` can be used to run the ConE Tool to generate cenreps.

* IDO can use the ido-gen-cenrep to generate the cenreps which are IDO specific.
* We should pass the sysdef.configurations.list as parameter to ido-gen-cenrep target. Else it will use the defualt one of helium.

Example:
-------

Below example will generate the cenrep only for IDO specific confml files.

.. code-block:: xml

    <target name="ido-generate-cenrep">
        <antcall target="ido-gen-cenrep">
            <param name="sysdef.configurations.list" value="dfs_build"/>    
        </antcall>
    </target>

Below example will generate the cenreps for S60 SDK.

.. code-block:: xml

    <target name="generate-s60-cenrep">
        <hlm:conEToolMacro>
            <arg name="output" value="<Path to output log file>"/>
            <arg name="path" value="build.drive/epoc32/tools/" />
            <arg name="-v" value="5" />
            <arg name="-p" value="\epoc32\rom\config" />
            <arg name="-o" value="\epoc32\release\winscw\urel\z " />
            <arg name="-c" value="s60_root.confml" />
        </hlm:conEToolMacro>
    </target>

By using conEToolMacro you can pass any arguments which are mentioned in the above link.

.. code-block:: xml

    <target name="generate-s60-cenrep">
        <hlm:conEToolMacro>
            <arg name="output" value="<Path to output log file>"/>
            <arg name="path" value="<path to cone.cmd file>" />
            <arg name="-v" value="<verbose level 0 - NONE (all), 1- CRITICAL, 2- ERROR, 3- WARNING, 4- INFO, 5- DEBUG>" />
            <arg name="-p" value="<path to root folder containing conml file>" />
            <arg name="-o" value="<path to output folder on the SDK to generate output files.> " />
            <arg name="-c" value="<confml file name>" />
        </hlm:conEToolMacro>
    </target>
        
After running this command generated file can be found from <temp.build.dir>/<build.id>_cenrep_includefile.txt


.. include:: stage_integration.rst.inc

.. include:: stage_ats.rst.inc

.. include:: stage_matti.rst.inc