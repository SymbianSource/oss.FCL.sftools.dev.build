===============
Building Helium
===============

Prerequisite
------------

Before using bld commands please make sure your *JAVA_HOME* environment variable is pointing to the required JDK.  
All the following operation must be run from the builder folder available on the root of helium source tree.


How to build Helium?
--------------------

The following sequence of command is showing you how to get Helium built and packaged up:

::
   
   > cd builder
   > bld build
   ....
   > bld -Dconfig=sf get-deps
   ...
   > cd ..
   > hlm version
   ... This should show the helium version ...
   > cd builder
   > bld -Dconfig=sf create-releasable


Building
--------

Run the following command on the route of your delivery `bld` or `bld -Dcomponent=<component_name>` to build only one component.
   
Cleaning
--------

To cleanup the generated files under each component just run `bld clean`
Removing the build temp folder run `bld clean`.
   
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


Using components inside Helium structure
----------------------------------------

Once you have been buidling and testing components you can then use them under Helium.
In order to get all Helium dependencies copied just run:
::
   
   > bld -Dconfig=<config> get-deps

Creating a deliverable package
------------------------------

In order to create a simplified delivery of Helium which contains only deliverable, run the following command:
::
   
   > bld -Dconfig=<config> create-releasable

   
How to get the list of target supported by the builder?
-------------------------------------------------------

::
   
   > bld -p
 