.. index::
  module:  Minibuild compile configuration

===============================
Minibuild compile configuration
===============================


.. index::
  single:  Minibuild compile configuration - coverage

Coverage
========

* prep target except:
   * prep-drive
   * dragonfly-prep-drive and deps
   * do-prep-work-area and deps
   * create-bom and deps
   * check-env-prep and deps
   * prep-copy and deps
* compile-main
* imaker-test-new-impl (experimental testing)
* zip-ee
   * Regular archive creation
   * Policy archive creation
   * Abld what scanner
   * Metadata generation
   * All systems:
      * Ant
      * Light EC acceleration
      * Full EC acceleration


.. index::
  single:  Minibuild compile configuration - setup

Minibuild setup
===============

What is required?
-----------------

* Build machine
* Build Area with a valid S60 environment (eg. PF5250)
* Helium (obviously)


Current Dragonfly configuration
-------------------------------

The current minibuild environment is using PF5250 wk25 release from a Dragonfly server.
The Dragonfly workspace has been created with share flag enabled so anybody should be able to access it.

Information related to the share are logged during the build::

   ...
   ------------ Build Drive Info -----------------
   Local name        T:
   Remote name       \\tribld03\shared_workspaces\helium_test_wk25
   Resource type     Disk
   ...
   -----------------------------------------------
   ...


  
.. index::
  module:  Minibuild compile configuration - how to run the build

How to run the build?
---------------------

The command line to run the build is the following::

   hlm -Dbuild.drive=%BUILD_DRIVE% -Dbuild.number=01 mini-build


You only need to provide the following properties:
* build.drive: location of the build area
* build.number: the build number


