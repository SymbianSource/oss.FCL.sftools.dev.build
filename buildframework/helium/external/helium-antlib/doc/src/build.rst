======================
Building Helium Antlib
======================

Prerequisite
------------

Before using bld commands please make sure your *JAVA_HOME* environment variable is pointing to the required JDK.  


Building
--------

Simply run the following command on the route of your delivery:

::
   
   > bld build
   Buildfile: build.xml
   
   build:
   
   compile:
        [echo] Compiling helium-core
       [mkdir] Created dir: C:\development\workspace\helium-antlib-dragonfly-trunk\sf\build\core\classes
       [javac] Compiling 25 source files to C:\development\workspace\helium-antlib-dragonfly-trunk\sf\build\core\classes
       [javac] Note: Some input files use unchecked or unsafe operations.
       [javac] Note: Recompile with -Xlint:unchecked for details.
   
   ...
   
   build:
        [echo] helium-signaling is built.
   
   BUILD SUCCESSFUL
   Total time: 6 seconds
   
Cleaning
--------

To cleanup the generated files just run:

::
   
   > bld clean
   Buildfile: build.xml
   
   clean:
   
   clean:
        [echo] Cleaning helium-core
      [delete] Deleting directory C:\development\workspace\helium-antlib-dragonfly-trunk\sf\build\core\classes
      [delete] Deleting: C:\development\workspace\helium-antlib-dragonfly-trunk\sf\bin\helium-core.jar

   clean:
        [echo] Cleaning helium-diamonds
      [delete] Deleting directory C:\development\workspace\helium-antlib-dragonfly-trunk\sf\build\diamonds\classes
      [delete] Deleting: C:\development\workspace\helium-antlib-dragonfly-trunk\sf\bin\helium-diamonds.jar
   
   clean:
        [echo] Cleaning helium-metadata
      [delete] Deleting directory C:\development\workspace\helium-antlib-dragonfly-trunk\sf\build\metadata\classes
      [delete] Deleting: C:\development\workspace\helium-antlib-dragonfly-trunk\sf\bin\helium-metadata.jar
   
   clean:
        [echo] Cleaning helium-quality
      [delete] Deleting directory C:\development\workspace\helium-antlib-dragonfly-trunk\sf\build\quality\classes
      [delete] Deleting: C:\development\workspace\helium-antlib-dragonfly-trunk\sf\bin\helium-quality.jar

   clean:
        [echo] Cleaning helium-scm
      [delete] Deleting directory C:\development\workspace\helium-antlib-dragonfly-trunk\sf\build\scm\classes
      [delete] Deleting: C:\development\workspace\helium-antlib-dragonfly-trunk\sf\bin\helium-scm.jar
   
   clean:
        [echo] Cleaning helium-signaling
      [delete] Deleting directory C:\development\workspace\helium-antlib-dragonfly-trunk\sf\build\signaling\classes
      [delete] Deleting: C:\development\workspace\helium-antlib-dragonfly-trunk\sf\bin\helium-signaling.jar
      
   clean:
        [echo] Cleaning helium-logging
      [delete] Deleting directory C:\development\workspace\helium-antlib-dragonfly-trunk\sf\build\logging\classes
      [delete] Deleting: C:\development\workspace\helium-antlib-dragonfly-trunk\sf\bin\helium-logging.jar
   
   BUILD SUCCESSFUL
   Total time: 1 second
   
Testing
-------

To run all the testing (junit + antunit):

::
   
   > bld test


JUnit testing:
::
   
   > bld junit

AntUnit testing:
::
   
   > bld unittest

