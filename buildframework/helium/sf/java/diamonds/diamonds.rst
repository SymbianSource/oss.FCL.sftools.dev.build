.. index::
  module: Configuring Diamonds

====================
Configuring Diamonds
====================

.. contents::

Introduction
------------
Diamonds is web application that can collect all build related information and categorize
builds. It can represent build information in different metrics. This document describes how
to configure diamonds in helium.

Diamonds Server setup
---------------------
Please define ``diamonds.host`` property with server address and ``diamonds.port`` with server port number.
e. g. ::

    <!-- Diamonds server details -->
    <property name="diamonds.host" value="diamonds.xxx.com"/>
    <property name="diamonds.port" value="9900"/>


Initialize diamonds
-------------------
`diamonds` target is the initialize target for diamonds logging. Call diamonds target in build target sequence
and this will log the already available data to diamonds and continue to log data onward as soon as they are available.
This is done already in helium build target sequence. So user can ignore this section.

Disable diamonds logging
-------------------------------
Diamonds logging can be skipped by defining the property ``skip.diamonds`` to true.
e.g.::

    hlm -Dskip.diamonds=true 


Add targets into diamonds configuration ftl file
------------------------------------------------
Diamonds detail configurations are in helium/config/diamonds_config.xml.ftl file.
User have to add target here(this target must be already defined in configuration) 
if they want to log some additional data to diamonds after the target execution.

Define the target with the following attributes inside ``<targets>`` node:

.. csv-table:: Target
   :header: "Attribute", "Description", "Required"
   
    "name", "Name of the target","Yes"
    "template-file", "template file to process the data","No, if not defined, consider template file name same as target name"
    "logfile", "log file which will be processed","No"
    "ant-properties","set true if you need values from ant properties, default is false","No"
    "defer", "logging will be deferred and will be logged at the build finish time. Default is false","No"

e.g

.. code-block:: xml

    <target name="check-tool-dependencies" template-file="tool.xml.ftl" logfile="${ant['temp.build.dir']}/build/doc/ivy/tool-dependencies-${ant['build.type']}.xml" ant-properties="true" defer="true"/>    


If no logfile provided, looks for xml file to send using <build.id_target_name.xml> file or <target_name.xml> file, 
if both doesn't exists does nothing. tries to pass ant properties and sends it. For below example, it looks for 
<build.id_create-bom.xml> or create_bom.xml and if any one exists then it will send that data. 

::
    
    <target name="create-bom"/>


Using only ant properties for a specific target to send data

::
    
    <target name="ant-prop-target" template-file="ant-prop.xml.ftl" ant-properties="true"/>
    
