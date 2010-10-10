<#--
============================================================================ 
Name        : tdriver_template_instructions.rst.ftl
Part of     : Helium 

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.
This component and the accompanying materials are made available
under the terms of the License "Eclipse Public License v1.0"
which accompanies this distribution, and is available
at the URL "http://www.eclipse.org/legal/epl-v10.html".

Initial Contributors:
Nokia Corporation - initial contribution.

Contributors:

Description:

============================================================================
-->

.. index::
  single: TDriver


=======================
TDriver Custom Template
=======================


.. contents::


Instructions for creating custom templates for TDriver
======================================================

Creating custom template for TDriver is very simple and easy. It requires a bit of knowledge of `Python`_, `Python dictionary`_ and `Jinja templates`_, however, it is not mandatory. There will be an example template below, which may help to understand how to create new/modify TDriver template. 

.. _`Python`:  http://wiki.python.org/moin/BeginnersGuide
.. _`Python dictionary`:  http://docs.python.org/tutorial/datastructures.html#dictionaries
.. _`Jinja templates`:  http://jinja.pocoo.org/2/documentation/templates


The test.xml template consists of two parts 
 - Explicit (hardcoded part of the test.xml) and 
 - Implicit (logical/processed data from the TDriver scripts)


Explicit template data
----------------------

This consists of normal template structure, obvious properties, attributes and their values.

For example:

.. code-block:: xml

    <?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>
    <testrun>
        <metadata>
        </metadata>
    </testrun>
    <!-- it also includes several other keywords (true, flase, yes, no, name, value, alias, defaultAgent) 
    and xml tags (execution, initialization, task, type, property, parameters, parameter) -->


It does not make any sense without parameters and values. However, explicit data does not require any logic or it is not the data coming from any script either.


Implicit template data
----------------------

- This is complete processed data from several sources. 
- In case of TDriver template, this is a dictionary, ``xml_dict``, which has hierarchical data structure.
- The contents of the dictionary can be categorized into:

**Pre-Data** (non-itterative data and comes before the execution block in the beginning of the test.xml) 


.. csv-table:: Pre-Data (Data structure)
    :header: "Variable name", "Description", "Usage example"
 
    "diamonds_build_url", "Non-iterative - string", "xml_dict['diamonds_build_url']" 
    "testrun_name", "Non-iterative - string", "xml_dict['testrun_name']"
    "device_type", "Non-iterative - string", "xml_dict['device_type']"
    "alias_name", "Non-iterative - string", "xml_dict['alias_name']"



**Execution-Block** (itterative, which is dependet on number of execution blocks. Please see the template example for exact usage)


.. csv-table:: Pre-Data (Data structure)
    :header: "Variable name", "Description", "Usage example"
 
    "execution_blocks", "Iterative - dictionary. It has the following members", "for exe_block in xml_dict['execution_blocks']"
    "image_files", "Iterative - list of ROM images.", "for image_file in exe_block['image_files']"
    "install_files", "Iterative - list of files to be installed", "for file in exe_block['install_files']"
    "tdriver_sis_files", "Iterative - list of sisfiles to be installed. This unpacks three values of sisfiles (src, dst_on_ats_server, dst_on_phone).", "for sisfile in exe_block['tdriver_sis_files']"
    "tdriver_task_files", "Iterative - list of task files, .pro or .rb files, depending on the value of :hlm-p:`tdriver.tdrunner.enabled`.", "for task_file in exe_block['tdriver_task_files']"   
    "asset_path", "Non-iterative - string", "exe_block['asset_path']" 
    "test_timeout", "Non-iterative - string", "exe_block['test_timeout']"
    "tdriver_parameters", "Non-iterative - string", "exe_block['tdriver_parameters']"
    "tdrunner_enabled", "Non-iterative - boolean", "exe_block['tdrunner_enabled']"
    "tdrunner_parameters", "Non-iterative - string", "exe_block['tdrunner_parameters']"
    "ctc_enabled", "Non-iterative - boolean", "exe_block['ctc_enabled']"



**Post-Data** (non-itterative data and comes after the execution block in the end of the test.xml)


.. csv-table:: Pre-Data (Data structure)
    :header: "Variable name", "Description", "Usage example"
 
    "report_email", "Non-iterative - string", "xml_dict['report_email']" 
    "email_format", "Non-iterative - string", "xml_dict['email_format']"
    "email_subject", "Non-iterative - string", "xml_dict['email_subject']"
    "report_location", "Non-iterative - string", "xml_dict['report_location']"



Example template
================


.. code-block:: xml

    {% import 'ats4_macros.xml' as macros with context %}
    
    <testrun>
        <metadata>
            {% if xml_dict['diamonds_build_url'] -%}
            <meta name="diamonds-buildid">{{ xml_dict['diamonds_build_url'] }}</meta> 
            <meta name="diamonds-testtype">Smoke</meta>
            {% endif %}
            <meta name="name">{{ xml_dict['testrun_name'] }}</meta> 
        </metadata>
        
        <agents>
            <agent alias="{{ xml_dict['alias_name'] }}">
                <property name="hardware" value="{{ xml_dict["device_type"] }}"/>
            </agent>
        </agents>
        
        
        {% for exe_block in xml_dict['execution_blocks'] -%}
        <execution defaultAgent="{{ xml_dict['alias_name'] }}">        
            <initialization>
            
                {% if exe_block['image_files'] -%}
                <task agents="{{ xml_dict['alias_name'] }}">
                    <type>FlashTask</type>
                    <parameters>
                    {% set i = 1 %}
                    {% for img in exe_block['image_files'] -%}
                        <parameter name="image-{{ i }}" value="images\{{ os.path.basename(img) }}" />
                        {% set i = i + 1 %}
                    {% endfor -%}
                    </parameters>
                </task>
                {% endif %}
    
                {% if exe_block['install_files'] != [] -%}
                  {% for file in exe_block['install_files'] -%}            
                <task agents="{{ xml_dict['alias_name'] }}">
                    <type>FileUploadTask</type>
                    <parameters>
                        <parameter name="src" value="{{exe_block['name']}}{{ atspath.normpath(atspath.normpath(file[0]).replace(atspath.normpath(exe_block['asset_path']).rsplit("\\", 1)[0], "")) }}"/>
                        <parameter name="dst" value="{{ atspath.normpath(file[1]) }}"/>
                    </parameters>
                </task>
                  {% endfor -%}
                {% endif %}
                
                {% if exe_block['tdriver_sis_files'] != [] -%}
                  {% for sisfile in exe_block['tdriver_sis_files'] -%}            
                <task agents="{{ xml_dict['alias_name'] }}">
                    <type>FileUploadTask</type>
                    <parameters>
                        <parameter name="src" value="sisfiles\{{ os.path.basename(sisfile[0]) }}"/>
                        <parameter name="dst" value="{{ sisfile[2] }}"/>
                    </parameters>
                </task>
                  {% endfor -%}
                {% endif %}
    
              {% for sis_file in exe_block["tdriver_sis_files"] -%}
                <task agents="{{ xml_dict['alias_name'] }}">
                   <type>InstallSisTask</type>
                   <parameters>
                        <parameter name="software-package" value="{{ sis_file[2] }}"/>
                        <parameter name="timeout" value="{{ exe_block["test_timeout"] }}"/>
                        <parameter name="upgrade-data" value="true"/>
                        <parameter name="ignore-ocsp-warnings" value="true"/>
                        <parameter name="ocsp-done" value="true"/>
                        <parameter name="install-drive" value="{{ sis_file[2].split(":")[0] }}"/>
                        <parameter name="overwrite-allowed" value="true"/>
                        <parameter name="download-allowed" value="false"/>
                        <parameter name="download-username" value="user"/>
                        <parameter name="download-password" value="passwd"/>
                        <parameter name="upgrade-allowed" value="true"/>
                        <parameter name="optional-items-allowed" value="true"/>
                        <parameter name="untrusted-allowed" value="true"/>
                        <parameter name="package-info-allowed" value="true"/>
                        <parameter name="user-capabilities-granted" value="true"/>
                        <parameter name="kill-app" value="true"/>
                   </parameters>
                </task>
              {%- endfor -%}
    
                <task agents="{{ xml_dict['alias_name'] }}">
                    <type>RebootTask</type>
                    <parameters/>                
                </task>
                <task agents="{{ xml_dict['alias_name'] }}">
                    <type>CreateDirTask</type>
                    <parameters>                
                        <parameter value="c:\logs\testability" name="dir"/>
                    </parameters>
                </task>
                
                {% if exe_block["ctc_enabled"] == "True" -%}
                {{ macros.ctc_initialization(exe_block) }}
                {%- endif %}
            </initialization>
    
            {% if exe_block["tdriver_task_files"] -%}
                {% for task_file in exe_block["tdriver_task_files"] -%}
            <task agents="{{ xml_dict['alias_name'] }}">
               <type>TestabilityTask</type>
               <parameters>
                  <parameter value="{{ exe_block["name"] }}\tdriver_testcases\" name="script"/>
                  <parameter value="{{ exe_block["name"] }}\tdriver_testcases\tdriverparameters\{{ os.path.basename(exe_block["tdriver_parameters"][0]) }}" name="xml"/>
                  <parameter value="{{ exe_block['test_timeout'] }}" name="timeout"/>
                  <parameter value="{{ exe_block["tdrunner_enabled"] }}" name="tdrunner"/>
                  <parameter value="{{ exe_block["tdrunner_parameters"] }} -e %TEST_RUN_SANDBOX%/{{ exe_block["name"] }}/{{ task_file }} test_unit" name="executable-parameters"/>
               </parameters>
            </task>
                {% endfor -%}
            {% endif %}
            
            <finalization>
            {% if exe_block["ctc_enabled"] == "True" -%}
            {{ macros.ctc_finalization(exe_block) }}
            {%- endif %}
              
              <task agents="{{ xml_dict['alias_name'] }}">
                <type>CleanupTask</type>
                <parameters>
                  <parameter value="true" name="upload-files"/>
                </parameters>
              </task>
            </finalization>
        </execution>    
        {% endfor -%}
        
        <postActions>
            <action>
              <type>EmailAction</type>
              <parameters>
                <parameter value="{{ xml_dict['email_subject'] }}" name="subject"/>
                <parameter value="{{ xml_dict['report_email'] }}" name="to"/>
                <parameter value="{{ xml_dict['email_format'] }}" name="format"/>
              </parameters>
            </action>
            {% if xml_dict['report_location'] -%}
            <action>
              <type>FileStoreAction</type>
              <parameters>
                <parameter value="{{ xml_dict['report_location'] }}\%START_DATE%_%START_TIME%_%SERVER_TOKEN%" name="dst"/>
                <parameter value="true" name="overwrite"/>
              </parameters>
            </action>
            {% endif %}
            {% if xml_dict['diamonds_build_url'] -%}
            <action>
                <type>DiamondsAction</type>
                {% if xml_dict['execution_blocks'] != [] and xml_dict['execution_blocks'][0]["ctc_enabled"] == "True" -%}
                <parameters>
                    <parameter value="true" name="send-ctc-data" /> 
                </parameters>
                {%- endif %}
            </action>
            {%- endif %}
        </postActions>
        
    </testrun>



Setting Custom Template for execution
=====================================

To execute custom template, set property :hlm-p:`tdriver.template.file`, for example:

.. code-block:: xml

    <property name="tdriver.template.file" value="x:\dir\templates\tdriver_template_2.xml" />
    
    
