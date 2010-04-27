<#--
============================================================================ 
Name        : stage_releasing.rst.inc.ftl
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
  single: Stage - Releasing

Stage: Releasing
================

A published build can be made into a release by running the command::

    hlm release

from the root of the directory on the network where the build is located. This will create a matching release directory and copy the appropriate files there. The selected files are defined in ``release.ant.xml``.

.. index::
  single: Stage - Delta Releasing

Stage: Delta releasing
======================

Introduction:

A delta release is a zip file with only the changed and new files between two build areas. A XML file is also generated that contains the list of files removed between the two build areas. This XML file is read by SymDEC and deletes these files.

Prequisities for automated use:

- Publish is run after this stage

Each build should run the :hlm-t:`delta-zip` target which creates a delta from a previous build to the current one. (This target looks at previous builds in the publish dir for the md5 file and chooses the most recent one).

Optionally: A previous build's MD5 can be passed as an argument, this might be the last bi-weekly release or used when builds are not published (the last build would have run the :hlm-t:`delta-zip` target)::

  hlm delta-zip -Dold.md5.file=e:\wk01_build\output\build_area\delta_zip\0.0742.3.X.15.md5 -Dold.md5.file.present=y
  
Exclude directories from the zip::

  <property name="delta.exclude.commasep" value="epoc32_save.zip,output/**/*,delta_zips/**/*,temp/**/*"/>

Output::

  Z:\output\build_area\delta_zip
   + delta_zip.zip
   + specialInstructions.xml
   + release_metadata.xml


.. index::
  single: Stage - Release Notes

Stage: Release notes
====================

Introduction:

This generates a release note by modifying a template (that you can edit yourself) with values from the build and Synergy.

Usage::

  hlm release-notes -Dbuild.number=1

Define in the build configuration the path to the release notes configuration::

  e.g. <property name="relnotes.config.dir" value="${r'$'}{helium.dir}/../config/${r'$'}{product.family}_config/${r'$'}{build.name}/relnotes"/>

The contents of "config_template" in ``helium/extensions/nokia/config/relnotes`` should be copied to the appropriate directory, e.g. ``config/config/relnotes``.

Contents of template:
 * ``logo.png`` : the logo of your product
 * ``template.rtf`` : the document that is modified to form the output
 * ``relnotes_properties.ant.xml`` : the names of the tokens in template.rtf that will be replaced
                  Many of the values are commented out as they change rapidly and will need to be added to the output RTF file manually.
 * ``relnotes.properties`` : the values of the tokens
                         New values can be added e.g. token1=1.0 and referenced in relnotes.xml by ${r'$'}{token1}
                         If you want a link to a file start with .\\filename or .\\folder\\filename or \\\\share1\\file

Project names can be looked up from the BOM and are set into properties, see ``config_template/relnotes/relnotes_properties.ant.xml`` for example.

If you want to add a new value to the output that is dynamic then you should:

1) Open your ``template.rtf`` in Word and add some text that is unique eg. NewValueHere
2) Open your ``template.rtf`` in a plain text editor such as UltraEdit and search for your value. You may find it is split over two lines or contains RTF markup language mixed into the value e.g. New\\pardValueHere
   If this is the case reformat so you get the value all on one line and remove extra markup.
3) Check your template still works in Word.
4) Add a new property to ``relnotes.properties`` or use existing properties from Helium or your build config files.
5) Add a new replace statement to ``relnotes_properties.ant.xml`` that references the property in step 4.

Output::

  Z:\output\relnotes
