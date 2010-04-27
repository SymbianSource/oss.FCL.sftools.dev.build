===================
Configuring Logging
===================

Features
========

* Will be initiated by the ANT Listener.
* Logging will starts whenever build starts.
* Helium logging framework offers you to configure the ant logging system for different stages of builds.
* You can log the build process into seperate ant log files for each stage.
* You can configure the log system to log different level of information (ex: debug, vebose, error).

Configuration
=============

We can configure the stages for which helium should log the build process.

    * Stages
       
       * Stages are like preparation, compilation, postbuild etc.. for which we need to log build process. 
       * Stages will have attributes for start and end targets.
       * Stages will specify from which target we need log the build process and at which target we need to end logging build process.
       
       .. csv-table:: 
          :header: "Attribute", "Description", "Required"
   
              "id", "Name of Stage (preparation, compilation)","Yes"
              "starttarget", "Name of target to start logging.","Yes"
              "endtarget", "Name of target to end logging.","Yes"
      
    * Stagerecord 

       * Will record/log the build process from start target to end target mentioned in the Stage type.
       * Need provide attributes like output log file, loglevel.
       * Supports passwordfilterset datatype. If we need to filter any passwords from specific stage log files.
       
       .. csv-table:: 
          :header: "Attribute", "Description", "Required"
   
              "id", "ID for stage record entry.", "Yes"
              "defaultoutput", "File to record main ant log file" "Yes (should not have stagerefid attribute if stage record has defaultoutput)"
              "stagerefid", "Stage reference ID. Exactly as given in the Stage", "Yes"
              "output", "File to record the build process.", "Yes"
              "loglevel", "Loglevel to record type of information. ex: debug, info, vebose", "No, Default it will be info"
              "append", "To append the logging into existing file.", "No, Default it will be false"

Example
-------
.. code-block:: xml
    
        <hlm:stage id="preparation" starttarget="prep" endtarget="prep"/>
        <hlm:stage id="compilation" starttarget="compile-main" endtarget="compile-main"/>
        
        <hlm:stagerecord id="stage.default" defaultoutput="${build.log.dir}/${build.id}_main.ant.log" loglevel="info" append="true"/>
        <hlm:stagerecord id="stage.preparation" stagerefid="preparation" output="${build.log.dir}/${build.id}_prep.ant.log" loglevel="info" append="true"/>
        <hlm:stagerecord id="stage.compilation" stagerefid="compilation" output="${build.log.dir}/${build.id}_compile.ant.log" loglevel="info" append="true"/>

logreplace Task (hlm:logreplace)
================================

* LogReplace task will filter out the string from stage logging files.
* If we need to filter out any user passwords and specific word which should n't be logged can passed to stage logging through this task.
* Specified string will be filtered out from all the stages logging files.
* It will not be filtered our by hlm:record task. To filter out the same need to passed to hlm:record task through recorderfilterset or recordfilter.

Example
-------
This example will filter out unix password value from all the stage logging files.

.. code-block:: xml

        <hlm:logreplace regexp="${unix.password}"/>

Record Task (hlm:record)
========================

* Behaviour is same ANT record task with some addon features.
* Filerts the logging messages which are passed through the filters to hlm:record task.
* Will stops the logging happening by listener for any stages and resumes to stage logging once hlm:record task  finishes.
* Will take the backup of the file.

Example
-------

Below example
    * Will sets one recoderfilteset.
    * Will record the given target/tasks into ${build.id}_stagetest.log file by filtering the regexp mentioned in the recorderfilterset and recordfilter.

.. code-block:: xml
    
        <hlm:recordfilterset id="recordfilter.config">
            <hlm:recordfilter category="info" regexp="ERROR" />
        </hlm:recordfilterset>
        
        <hlm:record name="${build.log.dir}/${build.id}_stagetest.log" action="start" loglevel="info" backup="true">
            <hlm:recordfilterset refid="recordfilter.config"/>
            <hlm:recordfilter category="unix" regexp="${unix.password}" />
        </hlm:record>
        
        ... Call tasks you would like to record the output  ...
        
        <hlm:record name="${build.log.dir}/${build.id}_stagetest.log" action="stop" append="true" backup="true"/>
