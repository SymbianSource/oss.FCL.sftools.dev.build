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
   *** WARNING: Can't find vcvars32.bat - MS Visual Studio not present.
   Buildfile: build.xml
   
   create-data-model-db:
   
   validate-at-startup:
      [python] ERROR: Description has no content for 'read.build.int'
      [python] WARNING: Required property not defined: sysdef.configurations.list
      [python] WARNING: Required property not defined: tsrc.data.dir
      [python] WARNING: Required property not defined: ats3.pathToDrop
      [python] WARNING: Required property not defined: ats3.host
      [python] WARNING: Required property not defined: ats.flash.images
      [python] WARNING: Required property not defined: ats.image.type
      [python] WARNING: Required property not defined: ats.drop.file
      [python] WARNING: Required property not defined: ats3.username
      [python] WARNING: Required property not defined: cache.drive
      [python] WARNING: Required property not defined: ats.product.name
      [python] WARNING: Required property not defined: ats3.password

   rombuild-imaker-create-buildinfo:
        [fmpp] File processed.
   
   BUILD SUCCESSFUL
   Total time: 3 seconds


The output
~~~~~~~~~~

The file image_conf_buildinfo.mk should be generated under /epoc32/rom/config, and should contains something similar to::

   ##########################################################################
   #
   # Helium - iMaker buildinfo template. 
   #
   ##########################################################################

   BUILD_LOGGING_KEY_STAGES = prep,build-ebs-main,postbuild,flashfiles,java-certification-rom,zip-main,publish-generic,variants-core,variants-elaf,variants-china,variants-thai,variants-japan,variants,mobilecrash-prep,localise-tutorial-content,hdd-images,zip-flashfiles,zip-localisation,data-packaging-prep
   BUILD_SUMMARY_FILE_2 = Z:\output\logs\summary\pf_5250_16_wk2008_summary.log2.xml
   BUILD_LOG = Z:\output\logs\pf_5250_16_wk2008_ant_build.log
   BUILD_NAME = pf_5250
   BUILD_CACHE_LOG_DIR = C:\DOCUME~1\wbernard\LOCALS~1\Temp\helium\pf_5250_16_wk2008\logs
   BUILD_SYSTEM = ebs
   BUILD_LOG_DIR = Z:\output\logs
   BUILD_CACHE_DIR = C:\DOCUME~1\wbernard\LOCALS~1\Temp\helium\pf_5250_16_wk2008
   BUILD_OUTPUT_DIR = Z:\output
   BUILD_SUMMARY_FILE = Z:\output\logs\pf_5250_16_wk2008_build_summary.xml
   BUILD_VERSION = 0.0.1
   BUILD_SYSTEM_EBS = Not used
   BUILD_SISFILES_DIR = Z:\output\sisfiles
   BUILD_ERRORS_LIMIT = 0
   BUILD_DRIVE = Z:
   BUILD_NUMBER = 1
   BUILD_DUPLICATES_LOG = Z:\output\logs\pf_5250_16_wk2008_build_duplicates.xml
   BUILD_LOGGING_START_STAGE = check-env-prep
   BUILD_ID = pf_5250_16_wk2008



Download the example: `buildinfo_creation.zip <buildinfo_creation.zip>`_