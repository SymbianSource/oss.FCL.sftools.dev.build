

Basic Helium configuration
==========================

These two files define the smallest Helium configuration possible: 

First the build.xml, it consists in two Ant instructions:
   
   * The creation of a 'env' property which stores current environment variables (see http://ant.apache.org/manual/CoreTasks/property.html).
   * Then the inclusion of Helium features importing the ${helium.dir}/helium.ant.xml, the helium.dir is automatically defined by the Helium bootstrapper.

build.xml:

.. code-block:: xml
   
   <?xml version="1.0" encoding="UTF-8"?>
   <project name="simple-config">
       <property environment="env"/>
       <import file="${helium.dir}/helium.ant.xml"/>   
   </project>


Finally the Helium bootstrapper, which consists in a simple batch file (or shell script under Linux).
Its job is to redirect calls to the hlm.bat script under the HELIUM_HOME dir. Additional checks could be added there e.g:
   
   * check if the user has defined the HELIUM_HOME environment variable. 
   * set/modify environment
   * define the HELIUM_HOME if Helium is in a known location

hlm.bat::
   
   @echo off
   setlocal
   if not defined HELIUM_HOME  ( 
   echo HELIUM_HOME is not defined.
   goto :eof 
   )
   %HELIUM_HOME%\hlm.bat %*
   endlocal



Download the example:
`simple_config.zip <simple_config.zip>`_
  
