===================
Helium Feature List
===================
 
.. index::
  module: Helium Feature List

.. contents::

.. index::
  single: feature - Framework

Framework
=========

.. index::
  single: feature - Logging

Logging
-------

* Individual log files created for most build stages.
* A summary log file is created from individual log files.

  * Shows categorized messages divided into errors, significant warnings and warnings.

.. index::
  single: feature - Signalling

Signaling
----------

* Build engineer can be signaled via email and SMS at many key points during the build.

  * The triggering and choice of when to signal can be configured.
  
.. index::
  single: feature - Validation

Validation
----------

* Validate an Ant configuration against the data model.

.. index::
  single: feature - Password Handling

Password handling
-----------------

* Query passwords from a .netrc file or request via a dialog.

.. index::
  single: feature - Diamonds logging

Diamonds logging
----------------
* Can upload build id, start and end time, creator, host name, release label.
* Can upload stage start and end time based on the configuration of stages
* Can upload build tools name and its version information.
* Can upload release location.
* Can parse multiple scan log file.
* Can upload build faults related information.
* Can upload BOM contents.
* Can upload "number of object files" and "number of generated files".
* Can upload build system and number of processors.
* Can upload distribution policy file related errors like missing, invalid encoding and error type A, B, C.
* Can upload List of Illegal APIs names if disable.analysis.tool is not set.
* Can upload custom build tags.
* Logging can be skipped if desired.


.. index::
  single: feature - Documentation

Documentation
-------------

* Quick start, manual, tutorials, How-To's and development guidelines in HTML format.
* Helium API documents the Ant targets and properties.
* Documentation for Python and Java APIs and custom Ant tasks.


.. index::
  single: feature - build stages

Build stages
============

.. index::
  single: feature - startup

Startup
-------

* A number of build configurations can be run on several machines from a single work area.
* A subcon release can be bootstrapped to download required libraries for building ROMs.

.. index::
  single: feature Synergy operations

Synergy operations
------------------

* Update a Synergy work area.

  * Create snapshots.
  * Checkout projects and update with folders and tasks.
  
* Build management functions.

.. index::
  single: feature Mercurial operations

Mercurial operations
--------------------

* Set or show the current branch name
* Checkout a repository
* Export the header and diffs for one or more changesets
* Display information about an item
* Create a new repository in the given directory
* Show revision history of entire repository or files
* Pull changes from the specified source
* Remove the specified files on the next commit
* Add one or more tags for the current or given revision
* List repository tags
* Update working directory

.. index::
  single: feature - Preparation

Preparation
-----------

* Checking the build machine environment for required tools.
* Build drive creation through subst'ing.
* Preparation of the build area.

  * Copy operations, with content filtering.
  * Unzip operations, with content filtering.
  * Extraction of ICDs/ICFs in order.
  * Checks content is available before starting preparation steps.

* Support for Dragonfly workspace creation.
* BOM and BOM delta creation.

  * HTML and plain text output files.

* Unarchive a release from network.

.. index::
  single: feature - compilation

Compilation
-----------

* Compilation using System Definition XML format.

  * The System Definition files are pre-processed to insert Ant properties

* Different build systems can be selected.

  * Symbian EBS.
  * Electric Cloud (EC) with history file management.
  * Symbian Build System (Raptor).
  
* A clean target allows a clean configuration to be built.
  
* cMaker support (clean, export, what).

.. index::
  single: feature - SIS files

SIS files
---------

* SIS files can be built.

.. index::
  single: feature - Quality Assurance

Quality assurance
-----------------
* Policy file validation.
* Build duplicates detection.
* Internal exports detection.
* Codescanner task.

.. index::
  single: feature - Publishing

Publishing
----------

* Create zips of the EE build area.

  * Content can be split across zips depending on number of files and file sizes.
  * In release metadata it holds md5checksum value and size of all the zip files.
* Zipping using EBS / EC based on the build system.
* Create delta zips for each localised region.
* Publish at several points during the build to a network directory.
* Zip content selected based on distribution.policy file content.
* Zip content selected based on component exports.

.. index::
  single: feature - Localisation

Localisation
------------
  
* S60 5.0.x support

  * DTD localisation.
  * Regional variation.

.. index::
  single: feature - iMaker image creation

iMaker image creation
---------------------

* Build information generation for iMaker (as an input to the naming convention).
* Accelerated image creation using local parallelization or ECA cluster

.. index::
  single: feature - Release Notes Creation

Release notes creation
----------------------

* Modifies a RTF template with values from build.
* Adds table of errors and warnings.
* Generates list of baselines, projects and tasks used.

.. index::
  single: feature - Delta Releasing

Delta releasing
---------------

* Creates a MD5 list of files in a build area.
* Compares a set of these files and zips new/ changed.
* Generates a XML file for SymDEC of files deleted.
 
.. index::
  single: feature - Testing

Testing
-------

 ATS test package generation for API (unit and/or Module) and UI test

 ============== ======== =========== === ======= ========= ===========
 Test Framework PKG File Dir Parsing CTC Tracing sis files Test Assets
 ============== ======== =========== === ======= ========= ===========
 **STIF**          -          -       -     -        -          
 **TEF**           -
 **RTEST**         -
 **MTF**           -
 **EUnit**         -                  -     -        -          
 **ASTE**                                                       -
 ============== ======== =========== === ======= ========= ===========

 - Supported
  
  
.. index::
  single: feature - IDO builds

IDO builds
----------
* Codescanner integration for IDO.
* Build area preparation for IDO (ADO base copying).

Other features
==============

.. index::
  single: feature - Miscallaneous

Miscellaneous
-------------

* Clean the build areas root directory of old builds based on a dialog selection.
* Print a list of target dependencies.
* The source code can be scanned for words that are classed as 'bad words' i.e. words that should not be used within the code e.g. Nokia product names, competitor names and competitor product names, these ''bad words'' are counted and displayed at the end of the build process

.. index::
  single: feature - Supported SCM tools

Supported SCM tools
-------------------

* Synergy
* Mercurial

.. index::
  single: feature - Nokia Build stages

Nokia Build stages
==================

.. index::
  single: feature - FOTA update packages creation

FOTA update packages creation 
-----------------------------
* Generation of FOTA packages between 2 published releases.
* Generation of FOTA toggle packages for TRUE test.

.. index::
  single: feature - Data packaging

Data packaging
--------------

* Generates VPL and DCP and signature files.
* Compresses images.
* Flashes phone to generate SPR.
* Creates input for gMES and NSU.
* Installer creation using InstallShield.

.. index::
  single: feature - UDA creation

UDA and Mass Memory Creation
----------------------------

* UDA creation using iMaker
* Mass Memory using ImageTool


NSIS installer file creation
----------------------------

* Installer executables based on the NSIS installation software can be created.

  * Plugins include environment setting modification.

.. index::
  single: feature - Releasing

Releasing
---------

* Upload content to network.
