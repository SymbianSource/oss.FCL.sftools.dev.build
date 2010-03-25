.. index::
  module: Configuring Coverity Prevent Tool with raptor build.

========================
Configuring Coverity Prevent Tool with raptor build (SBS)
========================

.. contents::

This document describes requirements and how to run coverity prevent tool with sbs builds using helium. 

Requirements
-----------------

Please go through "Configuring Raptor (SBS)" before proceeding into this document.


Implementation
-----------------
- Coverity prevent tool commands are integrated with SBS task. 
- Before starting the build we need to setup the property enabled.coverity=true to enable the coverity prevent tool with build.
- Coverity task extends the "sbstask", so what ever the arguments we pass for sbstask will remain same for coverity tool also.
- For example 

.. code-block:: xml
        
        <hlm:coveritybuild  sbsinput="@{sbs.input}" 
                            sysdeffile="${build.drive}/output/build/canonical_system_definition_${sysdef.configuration}.xml"
                            layerpatternsetref="${sbs.patternset}" 
                            workingdir="${build.drive}/" 
                            execute="true"
                            failonerror="false"
                            outputlog="${sbs.log.file}" 
                            cleanlog = "${sbs.clean.log}"
                            erroroutput="${sbs.log.file}.sbs_error.log"
                            statslog="${sbs.log.file}.info.xml">
                <hlm:coverityoptions refid="coverity.build.options"/>
        </hlm:coveritybuild>
     
- In above example coverity prevent tool is integrated with sbs using task "coveritybuild".
- This task is slightly difference from sbstask as it accepts the coverity tool parameters required while running coverity tool.
- In the above example we have mentioned "coverity.build.options" which are required for cov-build command.
- coverityoptions datatype will follow below syntax.

.. code-block:: xml
        
        <hlm:coverityoptions id="coverity.build.options">
            <arg name="--config" value="${coverity.config.dir}/coverity_config.xml"/>
            <arg name="--dir" value="${coverity.inter.dir}"/>
            <arg name="--auto-diff" value=""/>
            <arg name="--preprocess-first" value=""/>
            <arg name="--record-only" value=""/>
        </hlm:coverityoptions>

- Internally "coveritybuild" task will run the "cov-build" with parameters passed with "<hlm:coverityoptions>" datatype and sbs commands.
- Above arguments are passed by default in helium. If it is required to remove/change the default parameters (by helium)into cov-build, we need to override the datatype "coverityoptions".

- Command resulted for above example is shown below with "@{sbs.input} = dfs_build_input_armv5".

    | cov-build.exe --auto-diff  --record-only  --config Y:\output\coverity/config/coverity_config.xml 
    | --preprocess-first  --dir Y:\output\coverity/intermidiate sbs -s Y:\output\build\canonical_system_definition_dfs_build.xml 
    | -c armv5 --filters=FilterMetadataLog -k --logfile Y:\output\logs\compile/ido_helloworld_tb92_blr_ci_9.2.30_armv5_dfs_build.log 
    | --makefile=Y:\output\logs\compile/ido_helloworld_tb92_blr_ci_9.2.30_armv5_dfs_build
    
Note: 
--------------------
- Helium also supports other coverity tool commands. Please refer to section to "Coverity Prevent Tool" section.
- Coverity tool prevent tool can't run with emake. emake options are disabled with <hlm:coveritybuild> task if "build.system=sbs-ec".


