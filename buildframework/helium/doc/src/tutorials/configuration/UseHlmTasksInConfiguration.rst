

How to use Helium  ant tasks in configuration
=============================================

Sometimes customer may need to use helium ant tasks from their configurations and in the 
following way customer can use helium ant tasks by importing helium_preinclude.ant.xml:

Here is a example of build.xml:
   
   * The creation of a 'env' property which stores current environment variables (see http://ant.apache.org/manual/CoreTasks/property.html).
   * Import ${helium.dir}/helium_preinclude.ant.xml  to include helium ant tasks. 
   * Then a target which is using a helium ant task.
   * Then the inclusion of Helium features importing the ${helium.dir}/helium.ant.xml, the helium.dir is automatically defined by the Helium bootstrapper.

build.xml:

.. code-block:: xml

    <project name="helium-test" default="test" xmlns:hlm="http://www.nokia.com/helium"> 
        <description>
        Helium pre include test.
        </description>
        <property environment="env"/>
        <import file="${helium.dir}\helium_preinclude.ant.xml"/>   
            
        <target name="test">
           <hlm:logtoconsole action="stop"/>
                <echo>Should not print anything.</echo>
           <hlm:logtoconsole action="resume"/>
           <echo>Should print something.</echo>       
        </target>
        
        <import file="${helium.dir}\helium.ant.xml"/>           
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

