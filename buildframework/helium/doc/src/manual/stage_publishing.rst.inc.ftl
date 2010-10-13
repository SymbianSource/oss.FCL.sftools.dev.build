<#--
============================================================================ 
Name        : stage_publishing.rst.inc.ftl
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
  single: Stage - Publishing

Stage: Publishing
=================

.. index::
  single: Uploading to Diamonds

Uploading build information to Diamonds
---------------------------------------

Diamonds is a utility tool that keeps track of build and release information. See the **Metrics** manual under section `Helium Configuration`_ for more info.

.. _Helium Configuration: metrics.html#helium-configuration


.. index::
  single: Zipping Build area

Zipping of the build area
-------------------------

The Engineering English build area is archived in the :hlm-t:`zip-ee` target. Zipping of the localised build area is done by :hlm-t:`zip-localised` target. These properties need to be set:

:hlm-p:`zip.config.file`
    Location of the config file.
    
:hlm-p:`zips.ee.spec.name`
    Spec name for ee zipping (e.g. "ee").
    
:hlm-p:`zips.localised.spec.name`
    Spec name for localised build area zipping (e.g. "localised").

The :hlm-p:`zip.config.file` property defines the path to a :ref:`common-configuration-format-label` file that defines the content of the zips created. It can consist of multiple configs, e.g.

.. code-block:: xml

    <build>
        <config name="ee" abstract="true">
            <set name="max.uncompressed.size" value="2000000000"/>
            <set name="max.files.per.archive" value="65000"/>
            <set name="archive.tool" value="7za"/>
            <set name="root.dir" value="${r'$'}{build.drive}\"/>
            <set name="archives.dir" value="${r'$'}{build.output.dir}\build_area\engineering_english_test"/>
            <set name="temp.build.dir" value="${r'$'}{temp.build.dir}"/>
            <config>
                <set name="name" value="${r'$'}{build.id}_dev_flashfiles"/>
                <set name="include" value="output\development_flash_images\"/>
                </config>
                <config>
                    <set name="name" value="${r'$'}{build.id}_release_flashfiles"/>
                    <set name="include" value="output\release_flash_images\"/>
                </config>
            </config>
            <config name="localised" abstract="true">
                <set name="max.uncompressed.size" value="2000000000"/> 
                <set name="max.files.per.archive" value="65000"/>    
                <set name="archive.tool" value="7za"/>
                <set name="root.dir" value="${r'$'}{build.drive}\"/>
        
                <set name="archives.dir" value="${r'$'}{build.output.dir}\build_area\localised"/>
                <set name="temp.build.dir" value="${r'$'}{temp.build.dir}"/>
    
                <config>
                    <set name="name" value="${r'$'}{build.id}_dev_flashfiles_ee"/>
                    <set name="include" value="output\development_flash_images\engineering_english\"/>
                </config>
                
                <config>
                    <set name="name" value="${r'$'}{build.id}_dev_flashfiles_localised"/>
                    <set name="include" value="output\development_flash_images\localised\"/>
                </config>
            </config>
        </config>
      
        <config name="policy">
            <config>
                <set name="name" value="${r'$'}{build.id}_dev_flashfiles"/>
                <set name="include" value="output\development_flash_images\"/>
                <set name="mapper" value="policy"/>
                <set name="policy.internal.name" value="really_confidential_stuff"/>
                <set name="policy.filenames" value="Distribution.Policy.S60"/>
                <set name="split.on.uncompressed.size.enabled" value="true"/>
            </config>
        </config>

        <config name="policy.remover">
            <config>
                <set name="name" value="${r'$'}{build.id}_s60_osext"/>
                <set name="include" value="s60\osext\"/>
                <set name="mapper" value="policy.remover"/>
                <set name="policy.internal.name" value="really_confidential_stuff"/>
                <set name="policy.filenames" value="Distribution.Policy.S60"/>
                <set name="policy.root.dir" value="${r'$'}{root.dir}/s60"/>
                <set name="split.on.uncompressed.size.enabled" value="true"/>
            </config>
        </config>
      
        <config name="scanner">
            <config>
                <set name="name" value="${r'$'}{build.id}_dev_flashfiles"/>
                <set name="scanners" value="abld.what"/>
                <set name="abld.buildpath" value="path/to/component/group"/>
                <set name="exclude" value="**/*.dll"/>
                <set name="exclude.lst" value="${r'$'}{build.drive}/exclude.lst"/>
            </config>
        </config>

    </build>



.. csv-table:: Common property descriptions
   :header: "Property", "Description", "Values"   

   "``temp.build.dir``", "Directory to store temporary files generated during the process.", ""
   "``name``", "The name of the zip file.", ""


.. csv-table:: File System scanner property descriptions (default)
   :header: "Property", "Description", "Values"

   "``include``", "Path to include files/directories in the zip. Follows the Ant fileset convention.", ""
   "``exclude``", "Path to exclude files/directories in the zip. Follows the Ant fileset convention.", ""
   "``exclude.lst``", "Location of a file containing an exclude list(one pattern per line).", ""
   "``distribution.policy.s60``", "Defines that the included files will be filtered based on the value of the ``Distribution.Policy.S60`` files. The file found closest to the root will override those in subdirectories.", "The value found in the file, e.g. 0 or 1. This can be negated by putting a '!' in front."


.. csv-table:: Abld 'what' scanner property descriptions (abld.what)
   :header: "Property", "Description", "Values"

   "``exclude``", "Path to exclude files/directories in the zip. Follows the Ant fileset convention.", ""
   "``exclude.lst``", "Location of a file containing an exclude list(one pattern per line).", ""
   "``abld.buildpath``", "The path to an bld.inf directory. The files built from this component will be included.", ""
   "``abld.type``", "For what platform should abld be run for.", "armv5"
   "``abld.epocroot``", "To specify an EPOCROOT other than \\.", ""


.. csv-table:: Default Mappers property description (default)
   :header: "Property", "Description", "Values"

   "``name``", "The name of the zip file.", ""
   "``max.uncompressed.size``", "Maximum size in bytes of the content being included in each zip file. If the included content exceeds this, multiple zips will be created.", ""
   "``max.files.per.archive``", "Maximum number of files that can be included in an archive. If the total exceeds this, multiple zips will be created.", ""
   "``archive.tool``", "The command-line archiving tool. 7zip and zip are supported.", "7za, zip"
   "``root.dir``", "The root directory of the content being zipped.", ""
   "``archives.dir``", "The directory where the zip files are saved to.", ""
   "``zip.root.dir``", "The root directory for the content inside the zip file.", "root.dir value"


.. csv-table:: Policy Mappers property description (policy)
   :header: "Property", "Description", "Values"

   "``name``", "The name of the zip file.", ""
   "``policy.internal.name``", "Suffix of the archive that contains the confidential content.", "internal"
   "``policy.filenames``", "Comma separated list of policy filename.", "Distribution.Policy.S60"
   "``archive.tool``", "The command-line archiving tool. 7zip and zip are supported.", "7za, zip"
   "``archives.dir``", "The directory where the zip files are saved to.", ""
   "``policy.csv``", "This property defines the location of the policy definition file.", ""
   "``policy.default.value``", "This property defines the policy value when policy file is missing or invalid (e.g. wrong format).", "9999"
   "``split.on.uncompressed.size.enabled``", "To enable/disable splitting the zip files depending on source file size.", "true/false"
   

The policy mapper enables the sorting of the content compare to its policy value. The mapper is looking for a policy file in the file to archive directory.
If the distribution policy file is missing then the file will go to the ``policy.default.value`` archive. Else it tries to open the file which
MUST be ASCII encoded, and have its content matching the following expression: ``^\\d+\\s*$``.
File not matching those specifications will be reported as invalid and the assiociated content will go to the ``policy.default.value`` archive.

Archive filenames are generated the following way:

Policy value is 0::
   
   ${r'$'}{archive.dir}/${r'$'}{name}.zip

Policy value is different from 0::
   
   ${r'$'}{archive.dir}/${r'$'}{name}_${r'$'}{policy.internal.name}_<policy_value>.zip

If the policy file is missing or its content is invalid ot the olicy value is not found in the ``${r'$'}{policy.csv}``::
   
   ${r'$'}{archive.dir}/${r'$'}{name}_${r'$'}{policy.internal.name}_${r'$'}{policy.default.value}.zip


.. csv-table:: Policy Remover Mappers property description (policy)
   :header: "Property", "Description", "Values"

   "``name``", "The name of the zip file.", ""
   "``policy.internal.name``", "Suffix of the archive that contains the confidential content.", "internal"
   "``policy.filenames``", "Comma separated list of policy filename.", "Distribution.Policy.S60"
   "``archive.tool``", "The command-line archiving tool. 7zip and zip are supported.", "7za, zip"
   "``archives.dir``", "The directory where the zip files are saved to.", ""
   "``policy.root.dir``", "This property allows the user to restrict the root of policy scanning.", "root.dir value"
   "``policy.default.value``", "This property defines the policy value when policy file is missing or invalid (e.g. wrong format).", "9999"

The remover mapper in addition to policy mapper behaviour will remove the content not required for the build.
The removal process is based on the policy.csv file information, content will be kept in the following cases:

 * Included in build column is ``yes``    
 * Included in build column is ``bin``    


Two additionals removers have been introduced to support action from SFL and EPL column, you use the following
named mappers to use them:

 * ``sfl.policy.remover`` based on the 4th column of the csv
 * ``epl.policy.remover`` based on the 5th column of the csv

They support the same set of configuration properties as the default ``policy.remover``.

<#if !ant?keys?seq_contains("sf")>
.. include:: stage_metadata.rst.inc
</#if>
 
.. index::
  single: Zipping SUBCON

Subcon zipping
--------------

Subcon zipping is also configured using the same XML format as :hlm-t:`zip-ee` and implemented in the :hlm-t:`zip-subcon` target. A ``zips.subcon.spec.name`` property must be defined but currently it is still a separate configuration file.


Stage: Blocks packaging
=======================

Refer to the `Blocks integration manual`_

.. _`Blocks intergration manual`: blocks.html
