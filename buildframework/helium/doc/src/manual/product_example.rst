.. index::
  module: Example Product

==================
Example Product
==================

.. contents::

Introduction
============

This section gives an example of a product and its configuration files which produces a complete build, link, ROM image generation and variant creation.


.. index::
  single: Example - File Structure
  
.. _product-example-label:

Legacy File Structure
=====================

The following is an example of the file structure required, 'mc' is the product root directory. The convention used here is '\' indicates a sub folder below the current folder. The mc project is saved under synergy or some other version control software. (There is a naming convention; any .xml file that contains ant configuration information is named file.ant.xml if it is purely a configuration file for the project it is named file.xml) ::

  \mc
    \helium   #contains the helium tool set.
    \build #contains the build command files and build configuration files (mostly ant configuration files).
        languages.xml
        team.ant.xml
        \number_build
            delivery.xml
            prep.xml
            rom_image_comfig.xml
            \all
                bld.bat
                build.xml
            \product
                build.xml
                bld.bat
       \teams
          teamName.ant.xml
    \config    #contains configuration files specific to the product being build e.g. which components to include.
        \product
            \rom
                \include
                    product_override.iby
        \product_edge
            \rom
                \include
                    product_override.iby
        \product_lta
            \rom
                \include
                    product_override.iby
    \overlay       #these contain files that are to overwite code supplied by S60 in the same structure as is saved in the S60 code under 2 different folders
        \common       #contains overlay files common to all products
            \files
                \config
                \epoc32
                .
                .
                .
        \product_overlay  #contains files that are to overwite S60 files that are specific to the product and not the others in the family of products.
            \files
                \config
                \epoc32
                .
                .
                .
    \sw      #contains any extra software required for the build i.e. new features to be added that are not yet in the main line code.
        \nummber_sw
            \exports
            

Within each folder there needs to be certain files which contain certain configuration information, this is all configurable, but, this example is put here to give you tsome idea of what ot put where.

.. index::
  single: Example - Main Configuration Files

Main Configuration Files
=========================            

The following example files are the main files used within the example.

.. index::
  single: Example - team.ant.xml file

team.ant.xml file
------------------

This uses the TEAM variable set up in the PC control panel environment variables. The variable name must be in upper case and the value in lower case.

.. code-block:: xml

  <?xml version="1.0" encoding="UTF-8"?>
  <project name="tools.nbuild.team">
      <property name="team" value="${env.TEAM}"/>
      <import file="teams/${team}.ant.xml"/>
  </project>

.. index::
  single: Example - languages.xml file

languages.xml
-------------

This file contains a list of all the languages used by the product, the example only shows 3.

.. code-block:: xml

  <?xml version="1.0" ?>
  <languages>
      <language id="01" name="English"><inc>0</inc><srsf>uk</srsf></language>
      <language id="02" name="French"><srsf>fre</srsf></language>
      <language id="03" name="German"><srsf>ger</srsf></language>
      <language id="326" name="Malay"><core>china</core><srsf>mly326</srsf><fallbacks>70</fallbacks></language>
  </languages>


.. index::
  single: Example - delivery.xml file

Delivery.xml
-------------

This file contains the list of projects that should be checkedout or copied (snapshot) from synergy.

.. code-block:: xml

  <build>
      <spec name="number" abstract="true">
          <set name="database" value="${ccm.database}"/>
          <set name="dir" value="${ccm.base.dir}" />
          <set name="threads" value="6" />
          <set name="use.reconfigure.template" value="false" />
          <set name="release" value="${release.tag}" />
          
          <spec name="proj1_sw-wk200832:project:db1#1" type="snapshot" />
  
          <spec name="proj2-db2#0833:project:db3#1" type="checkout" />
          <spec name="cellmo" abstract="true">
              <set name="dir" value="${ccm.base.dir}\cellmo" />
              <set name="threads" value="1" />
  
              <spec name="cellmo_bins_rmnum_product-wk08w31:project:db1#1" type="snapshot" />
              <spec name="cellmo_bins_rmnum_product_chn-wk08w31:project:db5#1" type="snapshot" />
              <spec name="cellmo_bins_rmnum_product_lta-wk08w31:project:db6#1" type="snapshot" />
          </spec>
      </spec>
  </build>
  

.. index::
  single: Example - prep.xml file

prep.xml
-----------

This file takes the checked out projects (and snapshots) and copies them to the build area, unzipping those files that need unzipping.

.. code-block:: xml

  <?xml version="1.0" encoding="UTF-8"?>
  <prepSpec>
      <config>
          <exclude name="abld.bat"/>
          <exclude name=".static_wa"/>
          <exclude name="_ccmwaid.inf"/>
          <exclude name="documentation/*"/>
          <exclude name="documents/*"/>
          <exclude name="doc/*"/>
      </config>
      
      <source label="Symbian" basedir="${symbian.release.dir}">
          <unzip name="${symbian.zip.prefix}${symbian.release}_src_generic_part1.zip"/>
          <unzip name="${symbian.zip.prefix}${symbian.release}_src_generic_part2.zip"/>
          <unzip name="${symbian.zip.prefix}${symbian.release}_src_generic_part3.zip"/>
          <unzip name="${symbian.zip.prefix}${symbian.release}_src_cedar.zip"/>
          <unzip name="${symbian.zip.prefix}${symbian.release}_src_common_other_sources_part2.zip"/>
  
          <!-- This is required to generate all the .jar files correctly under \epoc32\tools\ -->
          <unzip name="${symbian.zip.prefix}${symbian.release}_src_product.zip" dest="${build.drive}/src"/>
  
          <unzip name="${symbian.zip.prefix}${symbian.release}_epoc32.zip"/>
          <unzip name="${symbian.zip.prefix}${symbian.release}_epoc32_RELEASE_ARMV5.zip"/>
      </source>
  
      <!-- Unzip (ICF/ICD)'s if there are any -->
      <source name="icds" basedir="">
        <unzipicds dest="${build.drive}\">
          <!-- Unzipping from following location
               * S60
               * common
               * product
            -->
          <location name="${ccm.base.dir}/S60/S60/Symbian_ICD_ICF/${symbian.release}" />
          <location name="${number_build.dir}../../../overlay/${product.family}_overlay/common/files/s60/Symbian_ICD_ICF/${symbian.release}" />
        </unzipicds>
      </source>
  
      <!-- Unzip (ICF/ICD)'s if there are any -->
      <source name="product_icds" basedir="">
        <unzipicds dest="${build.drive}\">
          <location name="${number_build.dir}../../../overlay/${product.family}_overlay/common/files/s60/Symbian_ICD_ICF/product_ICF" />
        </unzipicds>
      </source>
  
      <!-- copying  s60 content -->
      <source label="S60" basedir="${ccm.base.dir}">
        <copy name="S60/s60"   dest="s60" />
      </source>
  
      <source label="IBUSAL51" basedir="${ccm.base.dir}/">
        <copy name="IBUSAL_RapidoYawe/IBUSAL_RapidoYawe"/>
      </source>
      
     <source label="component_SW" basedir="${ccm.base.dir}">
         <copy name="component_sw"         dest="component_sw"/>
     </source>
  
      <source label="CELLMO" basedir="${ccm.base.dir}">
         <unzip name="\cellmo\cellmo_bins_rm2num_product\cellmo_bins_rmnum_product\rmnum_product.zip" dest="${build.drive}\cellmo\${cellmo.imagename.product}"/> 
         <unzip name="\cellmo\cellmo_bins_rmnum_product_chn\cellmo_bins_rmnum_product_chn\rmnum_product_chn.zip" dest="${build.drive}\cellmo\${cellmo.imagename.product.edge}"/> 
         <unzip name="\cellmo\cellmo_bins_rmnum_product_lta\cellmo_bins_rmnum_product_lta\rmnum_product_lta.zip" dest="${build.drive}\cellmo\${cellmo.imagename.product.lta}"/> 
      </source>
      <source label="CELLMO_copy" basedir="${build.drive}\cellmo">
          <!-- product cellmo copy -->
          <copy name="${cellmo.imagename.product}\${dsp.imagename}.hex"  tofile="${build.drive}\epoc32\rom\config\PLATFORM\product\dsp.hex"/>
          <copy name="${cellmo.imagename.product}\nalo.axf"      tofile="${build.drive}\epoc32\rom\config\PLATFORM\product\nalo.axf"/>
          <copy name="${cellmo.imagename.product}\naloext.axf"    tofile="${build.drive}\epoc32\rom\config\PLATFORM\product\naloext.axf"/>
          <copy name="${cellmo.imagename.product}\3rd.bin"       tofile="${build.drive}\epoc32\rom\config\PLATFORM\product\3rd.bin"/>
          <copy name="${cellmo.imagename.product}\${cellmo.imagename.product}.out"  tofile="${build.drive}\epoc32\rom\config\PLATFORM\product\isa.out"/>
          <!-- product Edge cellmo copy -->
          <copy name="${cellmo.imagename.product.edge}\${dsp.imagename.edge}.hex"  tofile="${build.drive}\epoc32\rom\config\PLATFORM\product_edge\dsp.hex"/>
          <copy name="${cellmo.imagename.product.edge}\nalo.axf"      tofile="${build.drive}\epoc32\rom\config\PLATFORM\product_edge\nalo.axf"/>
          <copy name="${cellmo.imagename.product.edge}\naloext.axf"    tofile="${build.drive}\epoc32\rom\config\PLATFORM\product_edge\naloext.axf"/>
          <copy name="${cellmo.imagename.product.edge}\3rd.bin"       tofile="${build.drive}\epoc32\rom\config\PLATFORM\product_edge\3rd.bin"/>
          <copy name="${cellmo.imagename.product.edge}\${cellmo.imagename.product.edge}.out"  tofile="${build.drive}\epoc32\rom\config\PLATFORM\product_edge\isa.out"/>
          <!--
      </source>
      <source name="patches" basedir="">
        <unzipicds dest="${build.drive}\">
          <location name="${patch.zip.dir}" />
          <include name="*" />
        </unzipicds>
      </source>
      
  </prepSpec>
  

.. index::
  single: Example - rom_image_config.xml file

Legacy rom_image_config.xml file
--------------------------------

This file contains all the information necessary to create the rom image, i.e. what variants are to be created and which libraries are to go in each variant.

.. code-block:: xml

  <?xml version="1.0" encoding="UTF-8"?>
  <build xmlns:xi="http://www.w3.org/2003/XInclude">
      <spec name="mc" abstract="true">
          <set name="ui.platform" value="mcnumber"/>
          <set name="zips.loc.dir" value="${zips.loc.dir}" />
          <set name="languages.xml.location" value="${localisation.language.file}" />
          <set name="variation.dir" value="${build.drive}\mc\config\number_config\product\variation" />
          <set name="rombuild.config.file" value="${rombuild.config.file.parsed}" />
          <set name="version.product.name" value="N78"/>
          <set name="imaker.languagepack.automation" value="0"/>
          <set name="enable.romsymbol" value="1"/>
          <set name="today" value="$(TODAY)"/>
          <set name="languagepack.id" value="000"/> <!-- language pack id is 000 in case of EE. -->
          <set name="customer.id" value="000"/> <!-- customer id is 000 in case of EE. -->
          <set name="uda.id" value="000" />
          <set name="massmemory.id" value="000" />
          <set name="memorycard.id" value="000" />
          <set name="customer.revision" value="1"/>
          <set name="uda.revision" value="1"/>
          <set name="massmemory.revision" value="1" />
          <set name="memorycard.revision" value="1" />
      
    <!-- This property can be overriden by variant team -->
          <set name="rommake.flags.vt" value=""/>
          <set name="rommake.flags" value="-es60ibymacros -DXTI_TRACES -DNO_PLATSEC ${rommake.flags.vt}"/>
          <set name="version.bandvariant" value="0"/>
          <set name="version.pd.milestone" value="${major.version}"/>
          <set name="version.pr" value="${pr}"/>
          <set name="version.m.step" value="${m.step}"/>
          <set name="version.bandvariant" value="0"/>
          <set name="version.rimcycle" value="${minor.version}"/>
  
          <set name="image.version.name" value="${version.pr}.${build.number}${fota.a.build}" />
          <set name="rombuild.id" value="${rommake.product.type}_${image.version.name}"/>
  
          <set name="rom.output.dir" value="${build.output.dir}"/>
          <set name="image.type" value="prd,rnd"/>
          <set name="customer.type" value="vanilla"/>
          <set name="uda.type" value="vanilla"/>
          <set name="image.master.iby" value="\epoc32\rom\master.oby"/>
          <set name="image.variant.iby" value="\epoc32\rom\number_variant_imaker.oby"/>
          <set name="include.rnd.oby" value="$(if $(subst rnd,,$(TYPE)),0,1)" /> <!-- include rnd applications only in rnd images -->
          <set name="image.override.iby" value="\epoc32\rom\override.oby"/>
          <set name="version.copyright" value="(C) Nokia"/>
          <set name="build.drive" value="${build.drive}"/>
          <set name="customer.image.version.name" value="${image.version.name}" />
          <set name="uda.image.version.name" value="${image.version.name}" />
          <set name="massmemory.image.version.name" value="${image.version.name}" />
          <set name="memorycard.image.version.name" value="${image.version.name}" />
      
  
          <!-- Template full outputdir  (used by iMaker for ROM generation) -->
          <set name="flash.output.dir" value="${rom.output.dir}/development_flash_images/engineering_english/${image.type}"/>
          <set name="core.output.dir" value="${rom.output.dir}/${core.image.path}"/>
          <set name="languagepack.output.dir" value="${rom.output.dir}/${languagepack.image.path}"/>
          <set name="customer.output.dir" value="${rom.output.dir}/${customer.image.path}"/>
          <set name="uda.output.dir" value="${rom.output.dir}${uda.image.path}"/>
          <set name="eraseuda.output.dir" value="${rom.output.dir}"/>
          <set name="flash.config.publish.dir" value="${build.output.dir}/${flash.config.path}"/> 
          
          <!-- Template relative paths  -->
          <set name="core.image.path" value="release_flash_images/${image.type}/core" />
          <set name="languagepack.image.path" value="release_flash_images/${image.type}/language/${description}_${languagepack.id}" />
          <set name="customer.image.path" value="release_flash_images/${image.type}/customer/${customer.type}/${description}_${customer.id}" />
          <set name="uda.image.path" value="release_flash_images/${image.type}/uda/${uda.type}/${description}_${uda.id}" />
          <set name="memorycard.image.path" value="release_flash_images/memorycard/${description}_${memorycard.id}" />
          <set name="massmemory.image.path" value="release_flash_images/massmemory/${description}_${massmemory.id}" />
          <set name="flash.config.path" value="${customer.image.path}" />
  
          <!-- Template names  -->
          <set name="flash.image.name" value="${rombuild.id}_${image.type}_${flash.id}"/>    
          <set name="eraseuda.image.name" value="${rombuild.id}_${build.version}"/>    
          <set name="empty.eraseuda.image.name" value="${rombuild.id}_${build.version}_empty"/>    
          <set name="core.image.name" value="${rombuild.id}_${image.type}"/>
          <set name="languagepack.image.name" value="${rombuild.id}_${languagepack.id}_${image.type}"/>
          <set name="customer.image.name" value="${rommake.product.type}_${customer.image.version.name}_${customer.id}.${customer.revision}_${image.type}"/>
          <set name="uda.image.name" value="${rommake.product.type}_${uda.image.version.name}_${uda.id}.${uda.revision}_${image.type}"/>
          <set name="memorycard.image.name" value="${rommake.product.type}_${memorycard.image.version.name}_${memorycard.id}.${memorycard.revision}"/>
          <set name="massmemory.image.name" value="${rommake.product.type}_${massmemory.image.version.name}_${massmemory.id}.${massmemory.revision}"/>
          <set name="flash.config.name" value="${languagepack.image.name}_${customer.image.version.name}.${customer.id}.${customer.revision}_${image.type}_${uda.image.version.name}.${uda.id}.${uda.revision}_${image.type}_${massmemory.id}.${massmemory.revision}_${memorycard.id}.${memorycard.revision}.config.xml"/>
          
  
          <!-- fwid generation -->
          <set name="rofs1.fwid.id" value="core"/>
          <set name="rofs2.fwid.id" value="language"/>
          <set name="rofs3.fwid.id" value="customer"/>
          <set name="rofs1.fwid.version" value="${version.product.type}_${core.version.info}"/>
          <set name="rofs2.fwid.version" value="${rofs2.version.info}"/>
          <set name="rofs3.fwid.version" value="${rofs3.version.info}"/>
          <set name="fota.fwid" value="${rofs1.fwid.version} ${rofs2.fwid.version} ${rofs3.fwid.version}"/>
  
  
          <!-- Core version string format-->
          <set name="core.template" value="${core.version.info}\\n${today}\\n${version.product.type}\\n(C)Nokia"/>
          <set name="languagepack.template" value="${rofs2.version.info}\\n${today}\\n${version.product.type}" />
          <set name="variant.template" value="${languagepack.template}" /> <!-- Backward compatibility -->
          <set name="customer.template" value="${rofs3.version.info}\\\n${today}"/>
          <set name="model.template" value="${version.copyright} ${version.product.name}"/>
          <set name="uda.template" value="${pr}.${version.bandvariant}.${build.number}\\n${today}\\n${product.type}\\n${copyright} ${version.product.name} (${uda.id})"/>
  
          <!-- default localisation settings -->
          <set name="variation" value="western"/>
          <set name="languagepack.revision" value="1"/>
          <set name="description" value=""/>
  
          <!-- Do not build target in parallel by default -->
          <set name="build.parallel" value="false" />
  
          <!-- templates to generate the makefiles -->
          <set name="output.makefile.filename" value="${rombuild.makefile.name}"/>
          <set name="main.makefile.template" value="${build.drive}\mc\config\number_config\rombuild\main.mk"/>
          <set name="flash.makefile.template" value="${build.drive}\mc\config\number_config\rombuild\flash.mk"/>
          <set name="core.makefile.template" value="${build.drive}\mc\config\number_config\rombuild\core.mk"/>
          <set name="languagepack.makefile.template" value="${build.drive}\mc\config\number_config\rombuild\languagepack.mk"/>
          <set name="customer.makefile.template" value="${build.drive}\mc\config\number_config\rombuild\customer.mk"/>
          <set name="uda.makefile.template" value="${build.drive}\mc\config\number_config\rombuild\uda.mk"/>
          <set name="eraseuda.makefile.template" value="${build.drive}\mc\config\number_config\rombuild\eraseuda.mk"/>
          <set name="flash.config.template" value="${build.drive}\mc\config\number_config\rombuild\template.config.xml"/>
          <set name="flash.config.makefile.template" value="${build.drive}\mc\config\number_config\rombuild\flash_config.mk"/>
          <set name="makeupct_core.makefile.template" value="..\..\mc\config\number_config\rombuild\makeupct_core.mk"/>
          
          <spec name="product" abstract="true">
      
              <set name="config.name" value="product"/>
              <set name="version.bandvariant" value="0"/>
  
              <set name="rommake.hwid" value="num1"/>
              <set name="version.product.type" value="RM-num"/>
              <set name="rommake.product.name" value="product"/>
              <set name="rommake.product.type" value="RM-num"/>
  
              <spec name="ee_group" abstract="true">
                  <set name="image.type" value="rnd,prd"/>
                  <set name="variant.txt.path" value="\epoc32\data\z\resource\versions\langsw.${config.name}.txt"/>
                  <set name="image.type.version" value="EE$(if $(subst rnd,,$(TYPE)),,RD)" /> <!-- EE for Prd, EERD for R&D -->               
  
                  <!-- GUI images -->
                  <spec name="ee_roms" abstract="true">
                      <set name="build.parallel" value="true" />
                      <set name="flash.image.name" value="${rombuild.id}_${image.type}"/>                  
                      
                      <spec name="ee_rnd" abstract="true">
                          <set name="image.type" value="rnd"/>
                          
                          <spec type="flash">                            
                              <set name="flash.id" value="ui" />
                              <set name="use.foti" value="0"/>
                              <set name="use.fota" value="0"/>                       
                          </spec>                    
                          
                          <spec type="eraseuda"/>
                      </spec>
  
                      <spec name="ee_prd" abstract="true">
                          <set name="image.type" value="prd"/>
                          
                          <spec type="flash">                            
                              <set name="flash.id" value="ui" />
                              <set name="use.foti" value="1"/>
                              <set name="use.fota" value="1"/>                       
                          </spec>                                        
                          
                          <spec type="eraseuda"/>
                      </spec>
                  </spec>
      
                  <spec name="subcon_roms" abstract="true">
                      <set name="build.parallel" value="true" />
                      <set name="image.type" value="subcon"/>
                      
                      <spec type="flash">
                          <set name="flash.id" value="ui" />
                      </spec>
      
                      <spec type="eraseuda"/>
                  </spec>
      
      
                  <spec name="traces" abstract="true">
                      <set name="build.parallel" value="false" />
                      <set name="flash.output.dir" value="${rom.output.dir}/${rommake.product.name}/${flash.id}_traces"/>    
                          
          
                      <spec type="flash">
                          <set name="flash.id" value="wakeup_trace" />
                          <set name="image.type" value="rnd"/>
                          <set name="mytraces.binaries" value="
                              SysStartlib1.exe" />
                      </spec>
          
                      <spec type="flash">
                          <set name="flash.id" value="telephony" />
                          <set name="image.type" value="rnd"/>
                          <set name="mytraces.binaries" value="
                              telephontlib1.LIB"/>
                      </spec>
          
                      <spec type="flash">
                          <set name="flash.id" value="audio" />
                          <set name="image.type" value="rnd"/>
                          <set name="mytraces.binaries" value="
                              audiolibrary1.dll,
                              audiolibrary2.dll"/>
                      </spec>
          
                      <spec type="flash">
                          <set name="flash.id" value="videotelephony" />
                          <set name="image.type" value="rnd"/>
                          <set name="mytraces.binaries" value="
                              videolibrary1.dll,
                              videolibrary2.dll"/>
                      </spec>
          
                      <spec type="flash">
                          <set name="flash.id" value="mms" />
                          <set name="image.type" value="rnd"/>
                          <set name="mytraces.binaries" value="
                              mmslib1.dll,
                              mmslib2.dll"/>
                      </spec>
          
                      <spec type="flash">
                          <set name="flash.id" value="sms" />
                          <set name="image.type" value="rnd"/>
                          <set name="mytraces.binaries" value="
                              smsslib1.dll"/>
                      </spec>
          
      
                  </spec>
              </spec>
          
              <!-- Language pack and Variant -->
              <spec name="variants" abstract="true">
                  <set name="build.parallel" value="false" />        
                  <!-- core -->
                  <spec type="core">
                      <set name="core.id" value="000" />
                      <spec type="makeupct_core" />
                  </spec>
           
                  <!-- western group -->
                  <spec name="western" abstract="true">
                      <set name="build.parallel" value="true" />
                      <spec type="languagepack">
                          <set name="languagepack.id" value="001" />
                          <set name="default" value="01"/>
                          <set name="languages" value="01,02,03,05,04,13"/>
                          <set name="description" value="EURO1"/>
                          <set name="variation" value="western"/>
                      </spec> 
                      <spec type="languagepack">
                          <set name="languagepack.id" value="002"/>
                          <set name="default" value="01"/>
                          <set name="languages" value="01,02,03,14,05,18"/>
                          <set name="description" value="EURO2"/>
                      </spec>
                      <spec type="languagepack">
                          <set name="languagepack.id" value="003"/>
                          <set name="default" value="01"/>
                          <set name="languages" value="01,09,06,08,15,07"/>
                          <set name="description" value="SCANDINAVIA"/>
                      </spec>
     
           
                  <!-- china group -->
                  <spec  name="china" abstract="true">
                      <set name="build.parallel" value="true" />
                      <set name="variation" value="china" />
                      <spec type="languagepack">
                          <set name="languagepack.id" value="011"/>
                          <set name="default" value="29"/>
                          <set name="languages" value="29,157"/>
                          <set name="description" value="CHINESE_TAIWAN"/>
                      </spec>
                  </spec>
              
                  <!-- japan group -->
                  <spec  name="japan" abstract="true">
                      <set name="build.parallel" value="true" />
                      <set name="variation" value="japan" />
                      <spec  type="languagepack">
                          <set name="languagepack.id" value="014"/>
                          <set name="default" value="160"/>
                          <set name="languages" value="160,32"/>
                          <set name="description" value="JAPAN"/>
                      </spec>
                  </spec>
              </spec>
          </spec>
  
          <!--
            product edge configuration
          -->
          <spec name="product_edge" abstract="true">
              <set name="config.name" value="product_edge"/>
              <set name="variation.dir" value="${build.drive}\mc\config\number_config\product_edge\variation" />
              <set name="version.bandvariant" value="1"/>
              <set name="zips.loc.dir" value="${zips.loc.dir}" />
              <set name="variation" value="western"/>
              <set name="config.name" value="product_edge"/>
              <set name="rommake.product.name" value="product_edge"/>
              <set name="version.product.type" value="RM-num"/>
              <set name="rommake.product.type" value="RM-num"/>
        
              <set name="rommake.hwid" value="2100"/>
  
              <spec type="TemplateBuilder">
                  <set name="template.build.id" value="${pr}.${build.number}" />
                  <set name="template.file" value="${build.drive}\config\s60_32_config\number_config\number_product_edge_config\config\data\CenrepVar_productedge\data\VariantData_productedge_template.xml" />
                  <set name="output.file" value="${build.drive}\config\s60_32_config\number_config\number_product_edge_config\config\data\CenrepVar_productedge\data\VariantData_productedge.xml" />
              </spec>
  
              <spec name="ee_group" abstract="true">
                  <set name="image.type" value="rnd,prd"/>
                  <set name="variant.txt.path" value="\epoc32\data\z\resource\versions\langsw.${config.name}.txt"/>
                  <set name="image.type.version" value="EE$(if $(subst rnd,,$(TYPE)),,RD)" /> <!-- EE for Prd, EERD for R&D -->
                  
  
                  <!-- GUI images -->
                  <spec name="ee_roms" abstract="true">
                      <set name="build.parallel" value="true" />   
                      <set name="flash.image.name" value="${rombuild.id}_${image.type}"/>               
                      
                      <spec name="ee_rnd" abstract="true">
                          <set name="image.type" value="rnd"/>
                          
                          <spec type="flash">                            
                              <set name="flash.id" value="ui" />
                              <set name="use.foti" value="0"/>
                              <set name="use.fota" value="0"/>                       
                          </spec>                    
                          
                          <spec type="eraseuda"/>
                      </spec>
  
                      <spec name="ee_prd" abstract="true">
                          <set name="image.type" value="prd"/>
                          
                          <spec type="flash">                            
                              <set name="flash.id" value="ui" />
                              <set name="use.foti" value="1"/>
                              <set name="use.fota" value="1"/>                       
                          </spec>                                        
                          
                          <spec type="eraseuda"/>
                      </spec>
                  </spec>
      
                  <spec name="subcon_roms" abstract="true">
                      <set name="build.parallel" value="true" />
                      <set name="image.type" value="subcon"/>
                      
                      <spec type="flash">
                          <set name="flash.id" value="ui" />
                      </spec>
      
                      <spec type="eraseuda"/>
                  </spec>
      
      
                  <spec name="traces" abstract="true">
                      <set name="build.parallel" value="false" />
                      <set name="flash.output.dir" value="${rom.output.dir}/${rommake.product.name}/${flash.id}_traces"/>    
                          
          
                      <spec type="flash">
                          <set name="flash.id" value="wakeup_trace" />
                          <set name="image.type" value="rnd"/>
                          <set name="mytraces.binaries" value="
                              SysStartlib1.exe" />
                      </spec>
          
                      <spec type="flash">
                          <set name="flash.id" value="telephony" />
                          <set name="image.type" value="rnd"/>
                          <set name="mytraces.binaries" value="
                              telephonylib1.LIB"/>
                      </spec>
          
                      <spec type="flash">
                          <set name="flash.id" value="audio" />
                          <set name="image.type" value="rnd"/>
                          <set name="mytraces.binaries" value="
                              audiolib1.dll"/>
                      </spec>
          
                      <spec type="flash">
                          <set name="flash.id" value="videotelephony" />
                          <set name="image.type" value="rnd"/>
                          <set name="mytraces.binaries" value="
                              videolib1.dll"/>
                      </spec>
          
                  </spec>
              </spec>
  
              <spec name="variants" abstract="true">
                  <set name="variation" value="china"/>
                  <set name="build.parallel" value="false" />      
                  <!-- core -->
                  <spec type="core">
                      <set name="core.id" value="000" />
                      <set name="image.type" value="rnd,prd"/>
                      <spec type="makeupct_core" />
                  </spec>
  
                  <!-- customer -->
                  <spec  type="customer">
                      <set name="customer.id" value="053"/>
                      <set name="customer.revision" value="1"/>
                      <set name="description" value="edge_customer_variant"/>
                  </spec>
  
                  <spec type="languagepack">
                      <set name="languagepack.id" value="020"/>
                      <set name="default" value="31"/>
                      <set name="languages" value="159,31"/>
                      <set name="description" value="CHINAPRC_NoFMTX"/>
                  </spec>
      <xi:include href="${product_edge.variant.config}"/>
  
              </spec>
          </spec>
    
      
          </spec>    
      </spec>
  </build>


.. index::
  single: Example - bld.bat

bld.bat
--------------------

This file is the one called when you start helium and it simply calls the hlm.bat file in the helium directory. ::

  @echo off
  
  if not defined HELIUM_HOME set HELIUM_HOME=%~dp0..\..\..\helium
  
  %HELIUM_HOME%\hlm.bat %*


.. index::
  single: Example - build.xml

build.xml
--------------------

This file contains all the initial product specific configuration required  by helium.

.. code-block:: xml

  <?xml version="1.0" encoding="UTF-8"?>
  <project>
      <property environment="env"/>                                         #the PC property 'ENVIRONMENT' is replaced with 'env'
      <import file="../../team.ant.xml"/>                                   #where to get the config file containing the team specific information.
      
      <property name="product.list" value="product,product_edge,product_lta"/> #the list of products to be built
      <!-- build.number should be defined as a commandline parameter -->
      <property name="major.version" value="14"/>                           #release version
      <property name="minor.version" value="PR14"/>
      <property name="pr" value="14" />
      <property name="m.step" value="3" />
          
      <property name="armv5.only" value="1" />                              #only build for armv5
      <property name="build.version" value="${pr}.${build.number}" />       #create the build version
      
      <property name="local.free.space" value="102400" />
  
      #these are the configuration files specific to each variant
      <property name="product.variant.config" location="${build.drive}/build/family_build/dummy_variant_config.xml" />
      <property name="product_edge.variant.config" location="${build.drive}/build/family_build/dummy_variant_config.xml" />
      <property name="product_lta.variant.config" location="${build.drive}/build/family_build/dummy_variant_config.xml" />
  
      <property name="build.errors.limit" value="-1" />
      <property name="flash.config.enabled" value="enabled" />
      
       <!-- -->
      <import file="../family_build.ant.xml"/>                 #include the family product config file

      <path id="system.definition.files">                       #locations of various system configuration files.
          <pathelement path="${build.drive}/build/family_build/family_System_Definition.xml"/>
          <pathelement path="${build.drive}/build/family_build/family_SDF_loc.xml"/>
          <pathelement path="${build.drive}/build/ibusal_51_build/IBUSAL51_System_Definition.xml" />
          <fileset dir="${build.drive}/s60/tools/build_platforms/build/data" includes="S60_System*.xml"/>
          <pathelement path="${build.drive}/build/family_build/product/product_System_Definition.xml" />
          <pathelement path="${build.drive}/MULTIMEDIA_SW/ME_SCD_DESW/ME_SCD_DESW/sysdef/System_Definition_product.xml" />
      </path>
  
  </project>
  

.. index::
  single: Example - teamName.ant.xml

teamName.ant.xml
--------------------

This file contains all the configuration required by a particular team, it lists where the servers are and the locations of synergy variables, GRACE variables etc.:

.. code-block:: xml

  <?xml version="1.0" encoding="UTF-8"?>
  <project name="teamName">
      <property name="publish.root.dir" value="\\faba\df\r1120\NT\Build_and_Release\temp"/>
      <property name="prep.root.dir" value="E:/${user.name}/BuildArea"/>
      <property name="build.drive" value="z:"/>
      
      
      <!-- Synergy configuration -->
      <property name="ccm.database" value="fa1ffamily" />
      <property name="ccm.database.path" value="/nokia/fa/grps/dbs/${ccm.database}" />
      <property name="ccm.engine.host" value="faweh.erp.company.com" />
          <!-- used to set ccm.base.dir -->
      <property name="ccm.home.dir" location="E:/${user.name}/ccm_wa/${ccm.database}" />
      
      
      <!-- Root path for all Synergy work areas. -->    
      <property name="nss.zip.dir" value="\\faba\df\r1120\NT\Build_and_Release\GRACE\MC\NSS" />
      <property name="symbian.root.dir" value="\\faba\df\r1120\NT\Build_and_Release\GRACE\MC\SOS"/>
      <property name="s60.root.dir" value="\\faba\df\r1120\NT\Build_and_Release\GRACE\MC\S60"/>
      <property name="cellmo.root.dir" value="\\faba\df\r1120\NT\Build_and_Release\GRACE\MC\Cellmo\product"/>
      <property name="error.email.to.list" value="${env.EMAIL}"/> <!-- BM should set it throught environment -->
      <property name="ec.cluster.manager" value="fa001"/>
      <property name="ec.build.class" value="ISISBR"/>
      <property name="work.area.temp.dir" location="\\vcer02\prj2\Juno\SWBuilds\WorkAreaCopyCache"/>
          <!-- Grace releasing configuration -->
      <property name="release.grace.configurationfile" value="./grace_upload_configuration.ant.xml" />
      
      <property name="release.dir.root" value="\\faba\df\r1120\NT\Build_and_Release\family_Off-Cycle\Increment_Releases" />
      
      <!-- FOTA -->
      <property name="fota.publish.root.dir" value="${publish.root.dir}"/>
      <property name="fota.unix.publish.root.dir" value="/nokia/fa/grps/r1120/NT/Build_and_Release/temp"/>
      <property name="fota.upct.server.address" value="farem02" />
  
      <!-- Grace settings -->
      <property name="release.grace.server" value="fam01.europe.company.com" />
      <property name="release.grace.service" value="ISIS" />
      <property name="release.grace.product" value="${product.family}" />
      <property name="release.grace.sambaserver" value="\\fa01.europe.company.com\GRACE" />
      
      <!-- Mail settings -->
      <property name="release.grace.mail.host" value="ca01.noe.company.com" />
      <property name="release.grace.mail.port" value="25" />
      <property name="release.grace.mail.from" value="email address of person to email" />
      <property name="release.grace.mail.to" value="email address" />
      <property name="release.grace.mail.replyto" value="${release.grace.mail.to}" />
      <property name="release.grace.mail.subject" value="Grace upload for ${release.grace.product} ${rel_label} completed" />
      <property name="release.grace.mail.message" value="Grace upload for ${release.grace.product} ${rel_label} completed SUCCESFULLY." />
      
      <property name="build.completed.mail.to" value="M-MC-MCSS-INTEGRATION-PLATFORM DG" />
      <property name="build.completed.mail.subject" value="NIGHTLY BUILD ${build.id} at ${env.COMPUTERNAME} has been completed" />
      <property name="build.completed.message" 
        value="This is an automated e-mail, reply to address: ${release.grace.mail.from}${line.separator}${line.separator}
        ${product.name} NIGHTLY BUILD ${build.id} on ${env.COMPUTERNAME}${line.separator}
        ================================================================================${line.separator}
        NB has been completed at ${time.completed}${line.separator}
        Build area at \\${env.COMPUTERNAME}\Build_D$\BA\${build.id}${line.separator}
        Server: ${env.COMPUTERNAME}${line.separator}
        ${line.separator}
        Engineering english build files created${line.separator}
        "
      />
  </project>
 
 
.. index::
  single: Example - product_override.iby file

product_override.iby file
------------------------------
 
 This file contains details of files that will be used to create the ROM image. ::
 
 
  //FMTX stuff (to prevent from showing the missing file as there is already InternalHWRMFmTxPolicy.ini file in rom)
  data-override=empty private\101f7a02\HWRMFmTxPolicy.ini
  
  // Variating ActiveIdle theme
  
  #ifdef ACTIVEIDLE_VARIANT
  #ifndef __NO_FMTX_IN_ROM
  data-override=concat3(ZPRIVATE\10207254\themes\271012080\270513751\271063149\1.0\AI.,ACTIVEIDLE_VARIANT,.o0000)           PRIVATE\10207254\themes\271012080\270513751\271063149\1.0\AI.o0000
  data-override=concat3(ZPRIVATE\10207254\themes\271012080\270513751\271063147\1.0\CI.,ACTIVEIDLE_VARIANT,.o0000)           PRIVATE\10207254\themes\271012080\270513751\271063147\1.0\CI.o0000
  ROM_IMAGE[2] data-override=concat3(ZPRIVATE\10207254\themes\271012080\270513751\271063149\1.0\AI.,ACTIVEIDLE_VARIANT,.o0001)                                 PRIVATE\10207254\themes\271012080\270513751\271063149\1.0\AI.o0001
  ROM_IMAGE[2] data-override=concat3(ZPRIVATE\10207254\themes\271012080\270513751\271063147\1.0\CI.,ACTIVEIDLE_VARIANT,.o0001)                                 PRIVATE\10207254\themes\271012080\270513751\271063147\1.0\CI.o0001
  #endif // __NO_FMTX_IN_ROM
  #endif // ACTIVEIDLE_VARIANT
  
  // Variantion ends
  
  
  // Product customisation
  #include <commontsy.var>
  #ifdef PRODUCT_CUSTOMISATION_VAR
  define __PRODUCT_CUSTOMISATION_VAR__ PRODUCT_CUSTOMISATION_VAR
  file-override=ABI_DIR\BUILD_DIR\COMMONTSY.__PRODUCT_CUSTOMISATION_VAR__.DLL    Sys\Bin\COMMONTSY.DLL
  #endif
  
  
  ROM_IMAGE[2] {
  #ifdef LPID
  #ifdef product
  data-override=concat3(\epoc32\data\Z\Resource\bootdata\languages.product.,LPID,.txt)   "resource\Bootdata\languages.txt"
  data-override=concat3(\epoc32\data\Z\Resource\versions\lang.product.,LPID,.txt)   "resource\versions\lang.txt"
  #endif
  #ifdef product_EDGE
  data-override=concat3(\epoc32\data\Z\Resource\bootdata\languages.product_edge.,LPID,.txt)   "resource\Bootdata\languages.txt"
  data-override=concat3(\epoc32\data\Z\Resource\versions\lang.product_edge.,LPID,.txt)   "resource\versions\lang.txt"
  #endif
  #ifdef product_LTA
  data-override=concat3(\epoc32\data\Z\Resource\bootdata\languages.product_lta.,LPID,.txt)   "resource\Bootdata\languages.txt"
  data-override=concat3(\epoc32\data\Z\Resource\versions\lang.product_lta.,LPID,.txt)   "resource\versions\lang.txt"
  #endif
  #endif // LPID 
  }
 