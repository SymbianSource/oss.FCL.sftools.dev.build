<#--
============================================================================ 
Name        : stages.rst.ftl
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

Stage: Cenrep creation (S60 3.2.3 - 5.x)
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

Stage: Check EPL License header.
=================================

The target ``check-sf-source-header`` could be used to run to validate the source files for EPL license header.

* Include the target ``check-sf-source-header`` in the target sequence.
* This will validate source files present on the build area to contain EPL license. 

.. index::
  single: Compatibility Analyser (CA)

Stage: Compatibility Analyser
=============================

The Compatibility Analyser is a tool used to compare **binary** header and library files to ensure that the version being checked has not made any changes to the interfaces which may cause the code to not work correctly. Helium supplies a target that calls this Compatibility Analyser. Users who wish to use this tool first need to read the CA user guide found under SW DOcMan at: http://bhlns002.apac.nokia.com/symbian/symbiandevdm.nsf/WebAllByID2/DSX05526-EN/s60_compatibility_analyser_users_guide.doc. 

The Compatibility Analyser is supplied as part of SymSEE, there is a wiki page for the tool found at http://s60wiki.nokia.com/S60Wiki/Compatibility_Analyser. As part of the configuration a default BC template file has been provided at Helium\tools\quality\CompatibilityAnalyser\config_template.txt make the necessary changes to this file (as described in the user guide). The supplied example file works with CA versions 2.0.0 and above which is available in SymSEE version 12.1.0 and above. The configurations that will need changing are:
 * BASELINE_SDK_DIR
 * BASELINE_SDK_S60_VERSION
 * CURRENT_SDK_DIR
 * REPORT_FILE_HEADERS
 * REPORT_FILE_LIBRARIES

The default configuration is supplied as part of tools\quality\CompatibilityAnalyser\compatibilty.ant.xml where there are a few properties that need to be set (overriding of these is recommended in your own config file):


.. csv-table:: Compatibility Analyser Ant properties
   :header: "Property name", "Edit status", "Description"
   
    ":hlm-p:`ca.enabled`", "[must]", "Enables the bc-check and ca-generate-diamond-summary targets to be executed, when set to true."
    ":hlm-p:`bctools.root`", "[must]", "Place where the CheckBC and FilterBC tools are e.g. C:/APPS/carbide/plugins/com.nokia.s60tools.compatibilityanalyser.corecomponents_2.0.0/BCTools"
    ":hlm-p:`default.bc.config`", "[must]", "Place where the CheckBC default configuration file is, it is copied from this location to the output folder for use by checkBC.py e.g. helium/tools/quality/compatibility_analyser/ca_config_template.txt"
    ":hlm-p:`bc.config.dir`", "[must]", "The bc_config_template.txt file (default configuration file) will be copied from the folder it is saved in within helium to the location named in this property where it will be used ( in conjunction with the bc.config.file property). e.g. build.log.dir/bc"
    ":hlm-p:`bc.config.file`", "[must]", "The bc_config_template.txt file (default configuration file) will be copied from the folder it is saved in within helium to the location named and named as defined in this property where it will be used. You need to make sure this is not the same name as any other IDO or person using the build area. e.g. bc.config.dir/bc.config"
    ":hlm-p:`bc.check.libraries.enabled`", "[must]", "Enables the Binary Comparison for libraries when set to 'true'."
    ":hlm-p:`lib.param.val`", "[must]", "Defines the parameter that checkBC.py is called with  -la (all libraries checked)  or -ls lib (single library checked) (lib = the name of library to check) or -lm file.name (multiple libraries checked) the file.name is a file that contains the names of the library(ies) to be checked."
    ":hlm-p:`bc.check.headers.enabled`", "[must]", "Enables the Binary Comparison for headers when set to 'true'."
    ":hlm-p:`head.param.val`", "[must]", "Defines the parameter that checkBC.py is called with -ha (all headers checked) or -hs file (single header checked) (file= name of header file to check) or -hm file.name (multiple headers checked) the file.name is a file that contains the names of the header(s) to be checked"
    ":hlm-p:`bc.check.report.id`", "[must]", "Adds this to the CA output file name to give it a unique name."
    ":hlm-p:`ido.ca.html.output.dir`", "[must]", "Defines the location of CA output and the input for the diamonds creation target. e.g. build.log.dir/build.id_ca"

and then run the target:

::

    hlm -Dbuild.number=nnn -Dbuild.drive=n: bc_check

where nnn is the build number and n: is the substed drive letter.

The results of the output from the analysis are placed in the \output\logs\BC folder under the substed build drive and are called libraries_report_?.xml and headers_report_?.xml, the reports can be viewed in Web-formatted layout, based on the BBCResults.xsl stylesheet which is copied to the \output\logs\BC folder on the build drive.


.. include:: stage_final.rst.inc

