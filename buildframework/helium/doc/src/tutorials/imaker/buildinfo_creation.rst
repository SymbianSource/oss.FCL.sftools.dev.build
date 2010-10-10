..  ============================================================================ 
    Name        : buildinfo_creation.rst
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

How to generate iMaker buildinfo using Helium
=============================================

Config location: http://helium.nmp.nokia.com/trac/browser/configs/test/test_buildinfo

The configuration
-----------------

build.xml
~~~~~~~~~

The configuration shows how to override the default Helium template by overriding the *rombuild.buildinfo.template* Ant property::

   <property name="rombuild.buildinfo.template" location="./image_conf_buildinfo.mk.ftl"/>


FTL template
~~~~~~~~~~~~

It is possible to extract custom data by updating the templete using the `FreeMarker <http://fmpp.sourceforge.net/freemarker/>`_ Template Language (http://fmpp.sourceforge.net/freemarker/). 
The following example extract all ant properties starting with *"build."*:
[[IncludeSource(/configs/test/test_buildinfo/image_conf_buildinfo.mk.ftl,include_templates/include_text)]]

Creating the configuration
--------------------------

To create the file on your build area (Z: drive in our case) you simply need to invoke *rombuild-imaker-create-buildinfo* Helium target:
(Just make sure you have defined HELIUM_HOME first)

::
   
   > hlm.bat -Dbuild.drive=Z: rombuild-imaker-create-buildinfo

The output
~~~~~~~~~~

The file image_conf_buildinfo.mk should be generated under /epoc32/rom/config, and should contains something similar to::

   ##########################################################################
   #
   # Helium - iMaker buildinfo template. 
   #
   ##########################################################################

   BUILD_LOGGING_KEY_STAGES = prep,build-ebs-main,postbuild,flashfiles,java-certification-rom,zip-main,publish-generic,variants-core,variants-elaf,variants-china,variants-thai,variants-japan,variants,mobilecrash-prep,localise-tutorial-content,hdd-images,zip-flashfiles,zip-localisation,data-packaging-prep
   BUILD_SUMMARY_FILE_2 = Z:\output\logs\summary\x_16_wk2008_summary.log2.xml
   BUILD_LOG = Z:\output\logs\x_16_wk2008_ant_build.log
   BUILD_NAME = x
   BUILD_CACHE_LOG_DIR = C:\DOCUME~1\x\LOCALS~1\Temp\helium\x_16_wk2008\logs
   BUILD_SYSTEM = ebs
   BUILD_LOG_DIR = Z:\output\logs
   BUILD_CACHE_DIR = C:\DOCUME~1\x\LOCALS~1\Temp\helium\x_16_wk2008
   BUILD_OUTPUT_DIR = Z:\output
   BUILD_SUMMARY_FILE = Z:\output\logs\x_16_wk2008_build_summary.xml
   BUILD_VERSION = 0.0.1
   BUILD_SYSTEM_EBS = Not used
   BUILD_SISFILES_DIR = Z:\output\sisfiles
   BUILD_ERRORS_LIMIT = 0
   BUILD_DRIVE = Z:
   BUILD_NUMBER = 1
   BUILD_DUPLICATES_LOG = Z:\output\logs\x_16_wk2008_build_duplicates.xml
   BUILD_LOGGING_START_STAGE = check-env-prep
   BUILD_ID = x_16_wk2008


Download the example: `buildinfo_creation.zip <buildinfo_creation.zip>`_