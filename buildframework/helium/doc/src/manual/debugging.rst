.. index::
  module: Debugging

#########
Debugging
#########


.. contents::
   
   
.. _Troubleshooting-label:

Troubleshooting
===============

This section contains details on how to find errors and problems within helium itself (for helium contributors) and within the configuration files
and ANT tasks etc. for the build managers and subcons.

.. index::
  single: Output Logs

.. index::
  single: Logs

Output Logs
-----------

When running Helium there are a large number of output logs created to assist with debugging and determining what has been performed and what has not.
All of the log files are generated in the build area, usually under the ``output\logs`` folder. Many of the logs are created in different formats
e.g. the Bill Of Materials log file exists as .html, .xml and .txt (all the same information). Some of the logs exist as different file formats giving
different information at various stages of the activity, e.g. the cenrep logs in which case generally the .html files are a summary of the whole activity.
For mc product builds the following log files are created 
where xx is the name of the build + build id e.g. 12.030_ant_env.log
where nn is the variant number(s):

.. csv-table:: build logs
   :header: "Log name", "File type", "Purpose"

    "xx_ant_env.log", "Ant environment Log", "Lists all the environment varaibles"
    "xx_ant_build.log", "Ant build Log", "Lists all the ANT tasks that have been executed"
    "xx_BOM.html", "BOM listing", "lists all the projects and tasks included in the build"
    "xx_bom_delta.html", "BOM delta listing", "lists all the delta projects and tasks included in the build"
    "xx.roms.log", "ROM creation log", "lists all the .iby, .txt, etc. files included in the ROM creation, including missing files"
    "xx_scan2.html", "Compilation summary", "Lists all the components built with their errors (0 if no errors)"
    "xx_zips_scan2.html", "zips creation log", "lists all the zip files created and whether there are any errors"
    "hlm_listener.log", "Helium debug log", "Helium debug log for internal data [Helium runtime information] and it can be found inside HELIUM_CACHE_DIR folder"
    "hlm_debug.log", "Helium debug log", "Helium debug log for all other debug log (all java logs) and it can be found inside HELIUM_CACHE_DIR folder"
       
Targets and their log
;;;;;;;;;;;;;;;;;;;;;

.. image:: ../images/dependencies_log.grph.png

.. index::
  single: Troubleshooting


Troubleshooting - Helium
------------------------

Use the ``diagnostics`` command provide debugging information when reporting problems. It lists all the environment variables and all the ANT 
properties and all the ANT targets within Helium
so you might find it useful to pipe it to a log file so that you can read all of the output at your leisure.

To run the diagnostics command type in a command window where the hlm.bat file is:

hlm diagnostics > diag.log

.. index::
  single: Failing early in the build

Failing early in the build
;;;;;;;;;;;;;;;;;;;;;;;;;;;

The ``failonerror`` property is defined in ``helium.ant.xml`` and has the default value ``false``. It is used to control whether the <exec> 
tasks fail when errors occur or the build execution just continues. The build can be configured to "fail fast" if this is set to ``true``, 
either on the command line or in a build configuration before importing ``helium.ant.xml``. Given that many ``exec`` tasks will return an 
error code due to build errors, it is not recommended to set this to true for regular builds.

