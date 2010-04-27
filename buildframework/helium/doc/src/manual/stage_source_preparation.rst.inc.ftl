<#--
============================================================================ 
Name        : stage_source_preparation.rst.inc.ftl
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
  single: Stage - Source preparation

Stage: Source preparation
=========================

The build preparation consists in two parts:

 * Getting delivery content (SCM, zips...),
 * Preparing the build area.

To get SCM source you just have to run::

  hlm prep-work-area

To create 'build of materials'::

  hlm create-bom

Synergy
-------

In order for the synergy commands to be executed you must define the property ccm.enabled=true in one of the your config files or on the command line. e.g. 

.. code-block:: xml

    <property name="ccm.enabled" value="true" />

It is possible to automatically get content from Synergy using the Helium framework.
To handle that you have to configure the delivery.xml file from your family build configuration folder and reference by the property prep.delivery.file.

Example configurations like a minibuild can be found under the Helium source tree.

Example of configuration:

.. code-block:: xml

    <build>
        <config name="" abstract="true">
            <set name="database" value="fa1f"/>
            <set name="host" value="${r'$'}{ccm.engine.host}" />
            <set name="dbpath" value="${r'$'}{ccm.database.path}" />
        
            <set name="dir" value="Z:\some\location"/>
            <set name="threads" value="4"/> 
            <set name="sync" value="true"/> 
            <set name="use.reconfigure.template" value="false"/> 
            <set name="release" value="${r'$'}{release.tag}" />
            
            <config name="ppd_sw-PPD51.32_200810:project:sa1spp#1" type="checkout" >
               <set name="folders" value="jk1f#1820" />
            </config>
            
            <config name="WLANSniffer2-2007_wk21:project:e002sa08#1" type="snapshot" />
            
            <config name="NSeries08_Themes-1:project:fa1f#1" type="checkout" >
               <set name="tasks" value="jk1f#1763" />
               <set name="skip.ci" value="true"/> 
            </config>
            
            <config name="NSeries08_Themes-1:project:fa1f5133#2" type="checkout" >               
               <set name="skip.ci" value="false"/> 
               <set name="ci.custom.query" value="(release='MinibuildDomain/next')"/>
            </config>
            
            <config name="S60-S60.32_200810:project:sa1spp#1" type="checkout" >
               <set name="folders" value="jk1f#1983" />
            </config>

            <config name="ppd_sw-username:project:sa1spp#1" type="update"/>
             
            <config name="cellmo" abstract="true">
                <set name="dir" value="${r'$'}{ccm.base.dir}\cellmo" />
                <set name="threads" value="1" />
            
                <config name="cellmo_bins_rm235_PRODUCT-ncpp.ICPR71_08w24.2:project:tr1cmtsw#1" type="snapshot" />
                <config name="cellmo_bins_rm236_PRODUCT_chn-ncpp.ICPR71_08w24.2:project:tr1cmtsw#1" type="snapshot" />
                <config name="cellmo_bins_rm342_PRODUCT_lta-ncpp.ICPR71_08w24.2:project:tr1cmtsw#1" type="snapshot" />
            </config>

        </config>
    <build>
    
    
Checkout: only need to define this when extra tasks are required on top of the listed project, otherwise use the snapshot type.
    The following properties are required:
        - release : synergy release to use.
        - dir     : the location of your target snapshot.
        - database: the name of the synergy database you want to use.
    The following properties are optional:
        - thread  : optional parameter, this define the number of process to run for parallel snapshots.
        - purpose : Purpose to check out with.
        - sync : Force a sync step after the work area update.
        - version : the version to check out toward to.
        - tasks : add additional tasks to the reconfigure properties.
        - folders : add additional folders to the reconfigure properties.
        - use.reconfigure.template: enable the usage of the reconfigure templates, this means the project will just be reconfigured, the reconfigure properties will not be modified.
        - fix.missing.baselines: automatically detect new projects and check them out.
        - replace.subprojects: boolean value to enable/disable project replacement during update (default: true).
        - skip.ci: boolean value to include/exclude the project from CC modificationset checking.
        - ci.custom.query: Extend the synergy query for CC modificationset checking eg.(release='MinibuildDomain/next').
        - show.conflicts: boolean value to check for task conflicts.
        - show.conflicts.objects: boolean value to check for object conflicts.
Snapshot: define type of the spec as snapshot and name as the baseline name.
    The following properties are required:
        - dir     : the location of your target snapshot.
        - database: the name of the synergy database you want to use.
    The following properties are optional:
        - thread  : optional parameter, this define the number of process to run for parallel snapshots.

Update: define type of the spec as update and name as the project to update.
    The following properties are required:
        - database: the name of the synergy database you want to use.

Mercurial
---------

Add to ant configuration:

.. code-block:: xml

    <target name="prep-work-area">
        <hlm:scm scmUrl="scm:hg:C:/Build_C/master"> 
            <hlm:checkout baseDir="${r'$'}{ccm.project.wa_path}/GraphicsDomain"/>
            <hlm:changelog baseDir="${r'$'}{ccm.project.wa_path}/GraphicsDomain" xmlbom="${r'$'}{build.log.dir}/${r'$'}{build.id}_bom.xml" />
        </hlm:scm>
    </target>

For more information see API_

.. _API: ../helium-antlib/api/doclet/index.SCM.html
