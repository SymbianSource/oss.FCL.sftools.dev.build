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
========================================
<#if !(ant?keys?seq_contains("sf"))>
See: http://configurationtools.nmp.nokia.com/builds/cone/docs/cli/generate.html?highlight=generate
</#if>

The target ``ido-gen-cenrep`` can be used to run the ConE Tool to generate cenreps.

* IDO can use the ido-gen-cenrep to generate the cenreps which are IDO specific.
* We should pass the sysdef.configurations.list as parameter to ido-gen-cenrep target. Else it will use the defualt one of helium.

Example
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


Stage: Testing
==============

The test sources or test asset is mantained by test developers, who follow certain rules and standards to create the directory/file structure and writing the tests.

Testing is performed automatically by ATS server which receives a zipped testdrop, containing test.xml file (required by ATS), ROM images, test cases, dlls, executbales and other supporting files. This testdrop is created by Helium Test Automation system. 
 
Read more: `Helium Test Automation User Guide`_

.. _`Helium Test Automation User Guide`: stage_ats.html


    

Stage: Check EPL License header
===============================

The target ``check-sf-source-header`` could be used to run to validate the source files for EPL license header.

* Include the target ``check-sf-source-header`` in the target sequence.
* This will validate source files present on the build area not to contain SFL license.
* Target could be enabled by setting ``sfvalidate.enabled`` to ``true``.

The target ``ido-check-sf-source-header`` could be used to run to validate the source files for EPL license header for IDO/Package level.

* Include the target ``ido-check-sf-source-header`` in the IDO target sequence.
* This will validate source files present on the build area to contain EPL license by extracting values from ``distribution.policy.S60`` files.
* Target could be enabled by setting ``sfvalidate.enabled`` to ``true``.

.. index::
  single: Compatibility Analyser (CA)

Stage: Compatibility Analyser
=============================

The Compatibility Analyser is a tool used to compare **binary** header and library files to ensure that the version being checked has not made any changes to the interfaces which may cause the code to not work correctly. Helium supplies a target that calls this Compatibility Analyser. 
Users who wish to use this tool first need to read the CA user guide found under: /epoc32/tools/s60rndtools/bctools/doc/S60_Compatibility_Analyser_Users_Guide.doc. 

<#if !(ant?keys?seq_contains("sf"))>
The Compatibility Analyser is supplied as part of SymSEE, there is a wiki page for the tool found at: http://s60wiki.nokia.com/S60Wiki/Compatibility_Analyser. 
</#if>
As part of the configuration a default BC template file has been provided at helium/tools/quality/compatibility_analyser/ca.cfg.xml make the necessary changes to this file (as described in the user guide). The supplied example file works with CA versions 2.0.0 and above. 

The minimum configurations that will need changing are:
 * BASELINE_SDK_DIR
 * BASELINE_SDK_S60_VERSION
 * CURRENT_SDK_DIR
 * REPORT_FILE_HEADERS
 * REPORT_FILE_LIBRARIES

The default configuration is supplied as part of tools/quality/compatibility_analyser/compatibilty.ant.xml where there are a few properties that need to be set (overriding of these is recommended in your own config file):


.. csv-table:: Compatibility Analyser Ant properties
   :header: "Property name", "Edit status", "Description"
   
    ":hlm-p:`ca.enabled`", "[must]", "Enables the bc-check and ca-generate-diamond-summary targets to be executed, when set to true."
    ":hlm-p:`bc.prep.ca.file`", "[must]", "The name and location of the file that contains all the CA configuration values like, 'BASELINE_SDK_DIR=C:\Symbian\9.2\S60_3rd_FP1_2': an example file can be found at helium/tools/quality/compatibility_analyser/test/ca.cfg.xml "
    ":hlm-p:`bc.tools.root`", "[must]", "Place where the CheckBC and FilterBC tools are e.g. /epoc32/tools/s60rndtools/bctools"
    ":hlm-p:`bc.build.dir`", "[must]", "The place that all the files created during the running of the CA tool will be placed."
    ":hlm-p:`bc.config.file`", "[must]", "The 'ca.ant.config.file' file (configuration file) will be copied from the folder it is saved in within helium to the location named as defined in this property where it will be used. You need to make sure this is not the same name as any other IDO or person using the build area. e.g. bc.config.dir/bc.config"
    ":hlm-p:`bc.check.libraries.enabled`", "[must]", "Enables the compatibility analyser for libraries when set to 'true' (default value is 'false')."
    ":hlm-p:`bc.lib.param.val`", "[optional]", "Defines the parameter that checkBC.py is called with  -la (all libraries checked) (default value) or -ls lib (single library checked) (lib = the name of library to check) or -lm file.name (multiple libraries checked) the file.name is a file that contains the names of the library(ies) to be checked. If the 'bc.what.log.entry.enabled' property is set this variable must not be set."
    ":hlm-p:`bc.check.headers.enabled`", "[must]", "Enables the compatibility analyser for headers when set to 'true' (default value is 'false')."
    ":hlm-p:`bc.head.param.val`", "[optional]", "Defines the parameter that checkBC.py is called with -ha (all headers checked) (default value) or -hs file (single header checked) (file= name of header file to check) or -hm file.name (multiple headers checked) the file.name is a file that contains the names of the header(s) to be checked. If the 'bc.what.log.entry.enabled' property is set this variable must not be set."
    ":hlm-p:`bc.check.report.id`", "[must]", "Adds this to the CA output file name to give it a unique name."
    ":hlm-p:`bc.log.file.to.scan`", "[must]", "This must be set if the 'bc.what.log.entry.enabled' property is set otherwise it is not required. It is the name of the log file that was created during the build that will be scanned in order to determine which headers or library files will be compared."
    ":hlm-p:`bc.what.log.entry.enabled`", "[optional]", "If set to true the 'whatlog' will be scanned for the list of header and/or library files that will be compared. The default is 'false'"
    ":hlm-p:`bc.fail.on.error`", "[optional]", "If set to true the build will fail if there is an error with the binary compatibility analyser (including the conversion to diamonds XML files). If set to false it will not fail the build if there is a problem with CA."

and then run the target:

::

    hlm -Dbuild.number=nnn -Dbuild.drive=n: bc_check

where nnn is the build number and n: is the substed drive letter.

The results of the output from the analysis are placed in the /output/logs/bc folder under the substed build drive and are called 'libraries_report_{bc.check.report.id}' and 'headers_report_{bc.check.report.id}', the reports can be viewed in Web-formatted layout, based on the BBCResults.xsl stylesheet which is copied to the /output/logs/bc folder on the build drive.

By running the target 'ca-generate-diamond-summary' the output is summarised and passed to diamonds where is is displayed in the 'Quality Aspects' section.
