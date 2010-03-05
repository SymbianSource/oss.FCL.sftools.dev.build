.. index::
  module: Configuring CTC for SBS

=======================
Configuring CTC for SBS
=======================

The following commands will generate mon.sym files in the root of your build area which are sent to the ATS server to generate coverage information.

Clean components:

hlm compile-main -Dbuild.drive=z: -Dsysdef.configurations.list=build_ctc_clean -Dbuild.system=sbs

Build for CTC:

hlm compile-main -Dbuild.drive=z: -Dsysdef.configurations.list=build_ctc -Dsbs.build.ctc=true -Dbuild.system=sbs

Ant configuration:

.. code-block:: xml
        
    <hlm:sbsoptions id="commonSBS">
        <arg line="-k" />
        <arg name="--filters" value="FilterMetadataLog"/>
    </hlm:sbsoptions>
    
    <hlm:sbsoptions id="armv5_CTC_SBS">
            <argset refid="commonSBS" />
            <arg line="-c armv5_udeb" />
    </hlm:sbsoptions>
    
    <hlm:sbsinput id="armv5-ctc-sbs">
        <sbsoptions refid="armv5_CTC_SBS" />
    </hlm:sbsinput>

    <hlm:sbsinput id="build_ctc_input_armv5">
        <sbsInput refid="armv5-ctc-${build.system}" />
        <sbsOptions>
            <arg name="--logfile" value="${compile.log.dir}/${build.id}_armv5_build_ctc.log" />
        </sbsOptions>
    </hlm:sbsinput>

    <hlm:sbsbuild id="sbs.build_ctc">
        <sbsInput refid="build_ctc_input_armv5" />
    </hlm:sbsbuild>

    <hlm:sbsoptions id="cleanCommon">
            <arg line="REALLYCLEAN" />
            <arg line="-c armv5" />
    </hlm:sbsoptions>

    <hlm:sbsoptions id="armv5Clean">
        <argset refid="cleanCommon" />
    </hlm:sbsoptions>

    <hlm:sbsinput id="armv5-sbs-clean">
        <sbsoptions refid="armv5Clean" />
    </hlm:sbsinput>
    
    <hlm:sbsinput id="build_input_clean_armv5">
        <sbsInput refid="armv5-${build.system}-clean" />
        <sbsOptions>
            <arg name="--logfile" value="${compile.log.dir}/${build.id}_armv5_build_clean.log" />
            <arg name="--makefile" value="${compile.log.dir}/${build.id}_armv5_build_clean" />
        </sbsOptions>
    </hlm:sbsinput>

    <hlm:sbsbuild id="sbs.build_ctc_clean">
        <sbsInput refid="build_input_clean_armv5" />
    </hlm:sbsbuild> 