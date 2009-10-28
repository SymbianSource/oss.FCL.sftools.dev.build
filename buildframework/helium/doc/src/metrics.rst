####################
Helium Build Metrics
####################

.. index::
  module: Helium Build Metrics


.. contents::

Introduction
============

This describes the types of build and release metrics that can be collected using Helium and a Diamonds installation and how they can be collected.

.. index::
  single: Diamonds

Diamonds Link for builds:
=========================
    Diamonds Homepage: <http://diamonds.nmp.nokia.com/diamonds>


Helium configuration
====================
To enable logging to diamonds from Helium one needs to ensure that:

* The properties *diamonds.host* and *diamonds.port* are set correctly.
* By default they are taken from *helium/tools/common/companyproperties.ant.xml*,
  but can be overridden by using:

  * **Command line**    
  
    For example, if the Diamonds server IP address changed to **new.diamonds.server:newport** then you would use:
    
    * *hlm.bat -Ddiamonds.host=new.diamonds.server -Ddiamonds.port=newport*

  * **ANT team file** 
   
    For example, if the Diamonds server IP address changed to **new.diamonds.server:newport** then you would put the following lines in your <team>.ant.xml: 

    * *<property name="diamonds.host" value="new.diamonds.server"/>*  
    * *<property name="diamonds.port" value="newport"/>*

* If you define the property skip.diamonds to 'true' diamonds is disabled.


.. index::
  single: Diamonds server configuration

Diamonds server configuration
=============================

    Config File: helium/config/diamonds_config.xml.ftl


Properties need to be defined for successful logging:
-----------------------------------------------------

 ==========================        ============
 Property name                     Description
 ==========================        ============ 
 diamonds.host                     Diamonds server address 
 diamonds.port                     Server port number
 diamonds.path                     Builds path in diamonds server
 build.family                      Category of product
 time-stamp                        Time stamp format
 stages                            Start and end target of a stages with logical stage name
 sysdef.configurations.list        System definition name list to log component faults
 build.name                        Name of product
 release.label                     Name of release
 publish                           Set this property to publish to network
 publish.dir                       Published build environment location
 release.grace.dir                 Published location
 disable.analysis.tool             Set this property to disable API Usage Metrics
 diamonds.build.tags               Set this property to send custom build tag(s) to Diamonds
 ==========================        ============


.. index::
  single: Metrics

Metrics
=======

    
Metrics name: Build duration
----------------------------

Description
~~~~~~~~~~~~
    Build duration in hours as a function of time.

Collection method
~~~~~~~~~~~~~~~~~~~
    The started time and finished time are uploaded to diamonds automatically from Helium. 
    
Location in Diamonds
~~~~~~~~~~~~~~~~~~~~~~
    In Diamonds, Builds->Summary.  
    
    For categorization by product programs, Build->Click "category" hyperlink. For 
    categorization by build accelerators, Build->Other->Click "Build system" hyperlink.
    
    
RVCT compiler warnings 
----------------------

Description
~~~~~~~~~~~
    Number of build warnings in SW build - RVCT compiler warnings to tell about the quality of the software.
    
Collection Method
~~~~~~~~~~~~~~~~~
    Number of RVCT bad warnings, warnings and errors are send to diamond aumatically from Helium after each build.

Location in Diamonds
~~~~~~~~~~~~~~~~~~~~~~
    In Diamonds, Builds->Summary->Compilation error summary.
    

Metrics name: "number of object files" and "number of generated files"
----------------------------------------------------------------------

Description
~~~~~~~~~~~~
    Number of object files and generated files for a build    

Collection method
~~~~~~~~~~~~~~~~~~~
    Necessary data are collected from build information automatically    

    Based on helium/config/diamonds_config.xml.ftl cofiguration, Helium automatically sends the start and end time of a stage to diamonds.

        
Location in Diamonds
~~~~~~~~~~~~~~~~~~~~~~
    In Diamonds, Builds->Others->Object files & Generated files.  
   
   
Metrics name: Build stage duration
----------------------------------

Description
~~~~~~~~~~~~
    Date and time of start and finish. A=Date and time of start B= Date and time of finish.
    Metric = B-A calculated for each build stages. In the graph only the 4 main stages are shown.\

        * *1. pre-build (Synergy check outs and snapshots, build area preparation)*
        * *2. build (main build)*
        * *3. post build (Post build, China, Japan, EE images, EE zip,  Localization, Localized roms)*
        * *4. release to channels (db, ftp, network disk)*

Collection method
~~~~~~~~~~~~~~~~~~~
    The started time and finished time are uploaded to diamonds automatically from Helium. 
    
Location in Diamonds
~~~~~~~~~~~~~~~~~~~~~~
    In Diamonds, Builds->Summary. Click "Stages>>"
    
    
Metrics name: API Usage
----------------------------------

Description
~~~~~~~~~~~~
    Types of api are private, internal, domain and sdk. Illegal API is (internal+private), if  any illegal api exists it will show the Illegal API's name with path.

Collection method
~~~~~~~~~~~~~~~~~~~
    If disable.analysis.tool is not set, data will be uploaded to diamonds automatically from Helium. 
    
Location in Diamonds
~~~~~~~~~~~~~~~~~~~~~~
    In Diamonds, Builds->Other->API usage  


Metrics name: Build tags
------------------------

Description
~~~~~~~~~~~~
    Build tags are used to group builds for metric collection purposes.

Collection method
~~~~~~~~~~~~~~~~~~~
    To send custom build tags to Diamonds the property diamonds.build.tags should be set as follows:
     * For a single build tag (e.g. "build_tag1") -> hlm -Ddiamonds.build.tags="build_tag1" 
     * For multiple build tags (e.g. "build_tag1" and "build_tagN") -> hlm -Ddiamonds.build.tags="build_tag1,build_tagN" 
    
    Note:
    * Build tags should not exceed 50 characters.
    * Duplicate build tags will be ignored. 
    * If an "Available Tag" is set, then in Diamonds it gets removed from that list and transferred to "Build's Tags" list.

Location in Diamonds
~~~~~~~~~~~~~~~~~~~~~~
    In Diamonds, Builds->Tags->Build's Tags.  
    
    For categorization by tags, Click Builds->"Navigation" pane->"Build Archives"->by tags 


Metrics name: Information about "base environment" 
--------------------------------------------------

Description
~~~~~~~~~~~~
    Information about what "base environment" is unzipped.
    
Collection method
~~~~~~~~~~~~~~~~~~~
    Necessary data are collected from build information automatically if currentRelease.xml exists in the environment. 
    
Location in Diamonds
~~~~~~~~~~~~~~~~~~~~~~
    In Diamonds, Builds->Content. See "Input" for s60.
