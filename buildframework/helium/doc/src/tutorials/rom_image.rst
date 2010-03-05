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
element to configure what needs to be built (please check the Helium Antlib documentation).
 

.. index::
   single: iMaker tutorials

iMaker tutorials
================

This section lists all available tutorials on how to configure and use iMaker.

.. toctree::
   :maxdepth: 1

   imaker/buildinfo_creation
