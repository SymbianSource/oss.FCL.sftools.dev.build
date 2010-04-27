<#--
============================================================================ 
Name        : stage_post_build.rst.inc.ftl
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
  single: Stage - Post Build

Stage: Post Build
=================

.. index::
  single: SIS Files

Sis Files
---------
SIS files can be built during the postbuild stage. The :hlm-p:`sis.config.file` property defines the path to a :ref:`common-configuration-format-label` file, e.g.

.. code-block:: xml

    <build>
        <config abstract="true">
            <set name="makesis.tool" value="${r'$'}{build.drive}\epoc32\tools\makesis.exe"/>
            <set name="signsis.tool" value="${r'$'}{build.drive}\epoc32\tools\signsis.exe"/>
            <set name="build.sisfiles.dir" value="${r'$'}{build.sisfiles.dir}"/>
            <set name="key" value="${r'$'}{build.drive}\s60\tools\taskmgr\internal\sis\RDTest_02.key"/>
            <set name="cert" value="${r'$'}{build.drive}\s60\tools\taskmgr\internal\sis\RDTest_02.der"/>
            <config>
                <set name="name" value="ScreenGrabber_3"/>
                <set name="path" value="${r'$'}{build.drive}\s60\tools\screengrabber\sis"/>
            </config>
            <config>
                <set name="name" value="app_trk"/>
                <set name="path" value="${r'$'}{build.drive}\s60\tools\trk\sis"/>
            </config>
        </config>
    </build>

The propertes are:

.. csv-table:: Property descriptions
   :header: "Property", "Description", "Values"

   "``makesis.tool``", "The path for the makesis tool that builds a .sis file.", ""
   "``signsis.tool``", "The path for the signsis tool that signs a .sis file to create a .sisx file.", ""
   "``publish.unsigned``", "This will copy .sis files into ${r'$'}{build.output.dir}/sisfiles.", "true, false"
   "``build.sisfiles.dir``", "The directory where the .sis file should be put.", ""
   "``key``", "The key to use for signing.", ""
   "``cert``", "The certificate to use for signing.", ""
   "``name``", "The name of the .pkg file to parse.", ""
   "``sis.name``", "The name of the .sis file to create. If omitted it will default to the name of the .pkg file.", ""
   "``path``", "The path where the .pkg file exists as input to building the .sis file.", ""
   
Configuration enhancements
::::::::::::::::::::::::::

*Since Helium 7.0.*

The configuration method above will be replaced by a more flexible approach:

.. csv-table:: Property descriptions
   :header: "Property", "Description", "Values"

   "``makesis.tool``", "The path for the makesis tool that builds a .sis file.", ""
   "``signsis.tool``", "The path for the signsis tool that signs a .sis file to create a .sisx file.", ""
   "``build.sisfiles.dir``", "The directory where the .sis file should be put.", ""
   "``key``", "The key to use for signing.", ""
   "``cert``", "The certificate to use for signing.", ""
   "``input``", "The full path and filename of the input file. This can be a .pkg file, for generating a SIS file, a .sis file for signing, or a .sisx file for multiple signing.", ""
   "``output``", "The full path and filename of the output file. This is only needed if the location or name needs to be different from the default, which is that the file extension changes appropriately.", ""

Also a ``sis.config.name`` property is added that allows the name of a <config> block to be supplied. This can be overridden to allow particular subsets of configurations to be built.

Checking Stub SIS files
-----------------------
This step involves checking stub sis files published to ``z:/epoc32/data/z/system/install`` and it ensures that only valid stub sis files are published.The target is included in postbuild and using ParseStubSis.pl script to do the work, it will run automatically and save the output in stubresult.log.xml. It can also be run from the command line by using::

    hlm check-stub-sis
    
It checks all files in the target folder and renames the invalid sis files with ``.bak`` extention. 
