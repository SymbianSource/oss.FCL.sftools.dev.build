.. index::
  module: How to create a ROM Image

################################
How to create a ROM Image
################################

.. contents::

This tutorial explains how to create a ROM image and all the configurations required to achieve this.


Introduction
=============

The ROM image is the end product which is flashed (downloaded) in to the phone and makes the phone behave the way it is supposed to behave (or not if there are problems present). ROM images are created within Helium using the S60 tool iMaker. iMaker is a ROM-image creation tool which provides a simple, standardized and configurable ROM-image creation framework. iMaker is based on the standardized GNU Make system and is therefore platform-independent. iMaker is a tool that creates a flash image from a set of Symbian binary and data files. iMaker mainly functions on top of the Symbian buildrom utility. 

The iMaker tool itself runs the Make tool and consists of thin layer of Perl. 
iMaker offers a standardized framework for defining configuration parameters for the ROM-image 
creation. The framework tools and configurability can easily be extended in the end customer interface, 
without changing the core iMaker functionality. 

Within Helium there are a series of targets that can be run that call iMaker and hence build the ROM image. 
This section is targeting build managers and IDOs who need to configure Helium to build ROM images using iMaker.
 

In order to use Helium for ROM-image creation your ROMs need to be configured to
be created using Helium. The creation is supported by the iMaker task which supports the  '''imakerconfigurationset'''
element to configure what needs to be built.

.. index::
   single: How to Install iMaker

How to Install iMaker
=====================

iMaker comes as part of S60 code and therefore should be automatically installed when S60 is installed. However, if you are not using S60
it is also available via Helium under the 'helium_trunk/external/imaker/bin' directory, the main executable is called 'mingw_make.exe'.


.. index::
   single: ROM Creation Commands

ROM Creation Commands
======================

To build an Engineering English (EE) version of the ROM use the target 'ee-roms' for localised images use the target
'localisation'. These are both for product builds and need several parameters to be configured before they will work successfully.
For details on how to configure helium for ROM image creation click :ref:`ROM-creation-label`.

.. index::
   single: Engineering English - brief description

Engineering English - brief description
----------------------------------------

EE builds are the basic builds that contain all the required components but the only available language is English. 
It is often used to prove that a build can be made or for basic testing, without the added complication of different languages.

.. index::
   single: Localisation - brief description

Localisation - brief description
---------------------------------

Localisation is the process used to create the different variants for different parts of the world. For each different language
available in a phone there is one or more text files that contain the text to be displayed, e.g. contacts, options, exit, keypad locked,
all have to be translated to the relevent language text. There are various regional variations as well which need to be implemented
so the correct files need to be included, this is all part of the configuration for localisation.

 
.. index::
   single: iMaker User Guide

.. _iMaker-label:

iMaker User Guide
=================

There is an `iMaker User Guide` available from helium in the \\helium-trunk\\external\\imaker\\doc folder 
it is a PDF file (S60_iMaker_User_Guide.pdf) and explains 
everything you need to know about iMaker. iMaker is based on `GNU Make`_ click on the link to view a .html version of `GNU Make`_ documentation. 

.. _`GNU Make`: http://www.gnu.org/software/make/manual/make.html

.. index::
   single: iMaker tutorials

iMaker tutorials
================

This section lists all available tutorials on how to configure and use iMaker.

.. toctree::
   :maxdepth: 1

   imaker/buildinfo_creation
