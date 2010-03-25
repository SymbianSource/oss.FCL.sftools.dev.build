======================
Building Helium Antlib
======================

Prerequisite
------------

Before using bld commands please make sure your *JAVA_HOME* environment variable is pointing to the required JDK.  


Building
--------

Run the following command on the route of your delivery `bld` or `bld -Dcomponent=module_name` to build only one module.
   
Cleaning
--------

To cleanup the generated files just run `bld clean`
   
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

