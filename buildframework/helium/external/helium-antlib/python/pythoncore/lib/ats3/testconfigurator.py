# -*- encoding: latin-1 -*-

#============================================================================ 
#Name        : testconfigurator.py 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description:
#===============================================================================

"""Parse Symbian SW component for ATS3 testing related information"""

# pylint: disable-msg=R0902,R0912,R0901,R0915,R0201
#R* remove during refactoring

from path import path # pylint: disable-msg=F0401
import ats3.parsers as parser
import logging
import os
import subprocess

_logger = logging.getLogger('ats')

class Ats3ComponentParser(object):
    """
    Parse Symbian SW component for ATS3 testing related information.
    
    Parses a component's source directories for testing related settings and
    files, and generates a TestPlan out of the findings.
    
    """

    def __init__(self, config):
        
        self.target_platform = config.target_platform
        self.pkg_parser = parser.PkgFileParser(self.target_platform.replace(" ", "_")+".pkg", config.specific_pkg)
        
        self.bld_parser = parser.BldFileParser()
        self.mmp_parser = parser.MmpFileParser()
        
        self.data_dirs = config.data_dir
        self.flash_images = [path(p) for p in config.flash_images]
        self.tsrc_dir = None
        self.build_drive = config.build_drive
        self.target_platform = config.target_platform
        self.sis_files = config.sis_files
        self.cfg_harness = config.harness
        self.test_timeout = config.test_timeout
        self.trace_enabled = config.trace_enabled
        self.excludable_dlls = []
        self.custom_dir = None

    def insert_testset_stif(self, src_dst, pkg_paths):
        """Inserts test set data to test plan for stif"""
        if not pkg_paths:    
            try:
                
                tsrc_testdata_files = self.tsrc_data_files()
                for data_file in tsrc_testdata_files:
                    if "\\mmc\\" in data_file.lower():
                        src_dst.append((data_file, path(r"e:\testing\data").joinpath(data_file.name), "data"))
                    elif "\\c\\" in data_file.lower():
                        src_dst.append((data_file, path(r"c:\testing\data").joinpath(data_file.name), "data"))
                    else:
                        src_dst.append((data_file, path(r"c:\testing\data").joinpath(data_file.name), "data"))
            except OSError:
                _logger.warning("No testdata folder" )
                tsrc_testdata_files = None

        else:
            try:
                src_dst = pkg_paths
            except OSError:
                _logger.warning("No pkg file found in the directory ( %s )" % self.tsrc_pkg_dir)
                src_dst = []
            except IndexError:
                _logger.warning("No pkg file found in the directory ( %s )" % self.tsrc_pkg_dir)
                src_dst = []
        
        return src_dst
                
    def insert_test_set(self, test_plan, tsrc_dir, _paths_dict_):
        """Parse tsrc directory, storing data into the test plan."""
        self.tsrc_dir = path(tsrc_dir)  # Store current test source dir.
        tsrc_testdata_files = []
        tsrc_config_files = []
        self.custom_dir = None
        engine_ini_file = None
        test_harness = self.cfg_harness
        src_dst = []
        pmd_files = []
        trace_activation_files = []
        
        if not os.path.exists( self.tsrc_dir ):
            _logger.error("Missing test source directory: %s", self.tsrc_dir)
        else:
            self.custom_dir = self.tsrc_dir.joinpath("custom")
            _logger.debug("using customized testing from %s" % self.custom_dir)
            if os.path.exists(self.tsrc_bld_dir.joinpath("group","bld.inf")):
                mmp_files = self.bld_parser.get_test_mmp_files(self.tsrc_bld_dir.joinpath("group","bld.inf"))                
            else:
                mmp_files = self.bld_parser.get_test_mmp_files(self.tsrc_bld_dir.joinpath("bld.inf"))
                
            test_harness = self.mmp_parser.get_harness(mmp_files)
            
            pkg_paths = self.pkg_parser.get_data_files(self.tsrc_pkg_files(_paths_dict_), self.build_drive)
            if self.trace_enabled == "True":
                try:
                    pmd_files = self.tsrc_pmd_files()
                except OSError:
                    _logger.warning("No pmd file in output-folder.")
                try:
                    trace_activation_files = self.tsrc_trace_activation_files()
                except OSError:
                    _logger.warning("No trace activation files in trace init folder")
                if trace_activation_files and not pmd_files:
                    _logger.warning("Trace activation files available but NOT pmd file.")
                elif pmd_files and not trace_activation_files:
                    _logger.warning("Pmd file available but NO trace activation files.")
            
            if test_harness == "STIF" or test_harness == "STIFUNIT" or test_harness == "GENERIC":
                src_dst = self.insert_testset_stif(src_dst, pkg_paths)
                        
            elif test_harness == "EUNIT":
                try:
                    src_dst  = self.pkg_parser.get_data_files(self.tsrc_pkg_files(_paths_dict_), self.build_drive)

                except OSError:
                    _logger.warning("No pkg file found in the directory ( %s )" % self.tsrc_pkg_dir)
                    src_dst = []
                except IndexError:
                    _logger.warning("No pkg file found in the directory ( %s )" % self.tsrc_pkg_dir)
                    src_dst = []
            try:
                testmodule_files = self.tsrc_dll_files()

                for dll_file in testmodule_files:
                    if not self.check_dll_duplication(dll_file.name, src_dst):
                        _dll_type_ = self.mmp_parser.get_dll_type(self.tsrc_bld_dir)

                        if dll_file.name in self.excludable_dlls:
                            src_dst.append((dll_file, path(r"c:\sys\bin").joinpath(dll_file.name), "data:%s" % _dll_type_))
                        else:
                            src_dst.append((dll_file, path(r"c:\sys\bin").joinpath(dll_file.name), "testmodule"))

            except OSError:
                _logger.warning("No dll files in dll folders" )
                tsrc_testdata_files = None

            if test_plan['multiset_enabled'] == 'True':
                backup = []
                temp_src_dst = {}
                for x_temp in src_dst:
                    if len(x_temp) < 4:
                        backup.append(x_temp)
                for x_temp in src_dst:
                    if len(x_temp) > 3:
                        if temp_src_dst.has_key(x_temp[3]):
                            temp_src_dst[x_temp[3]].append(x_temp)
                        else:
                            temp_src_dst[x_temp[3]] = [x_temp] + backup
                
                for pkg in temp_src_dst.keys():
                    src_dst = temp_src_dst[pkg]
                    
                    if self.trace_enabled == "True":
                        test_plan.insert_set(data_files=tsrc_testdata_files,
                                             config_files=tsrc_config_files,
                                             engine_ini_file=engine_ini_file,
                                             image_files=self.flash_images,
                                             sis_files=self.sis_files,
                                             #testmodule_files=self.tsrc_dll_files(),
                                             test_timeout=list(self.test_timeout),
                                             test_harness=test_harness,
                                             src_dst=src_dst,
                                             pmd_files=pmd_files,
                                             trace_activation_files=trace_activation_files,
                                             custom_dir=self.custom_dir,
                                             component_path=tsrc_dir)
                    else:
                        test_plan.insert_set(image_files=self.flash_images,
                                             sis_files=self.sis_files,
                                             test_timeout=list(self.test_timeout),
                                             test_harness=test_harness,
                                             src_dst=src_dst,
                                             custom_dir=self.custom_dir,
                                             component_path=tsrc_dir)
            else:
                if self.trace_enabled == "True":
                    test_plan.insert_set(data_files=tsrc_testdata_files,
                                         config_files=tsrc_config_files,
                                         engine_ini_file=engine_ini_file,
                                         image_files=self.flash_images,
                                         sis_files=self.sis_files,
                                         #testmodule_files=self.tsrc_dll_files(),
                                         test_timeout=list(self.test_timeout),
                                         test_harness=test_harness,
                                         src_dst=src_dst,
                                         pmd_files=pmd_files,
                                         trace_activation_files=trace_activation_files,
                                         custom_dir=self.custom_dir,
                                         component_path=tsrc_dir)
                else:
                    test_plan.insert_set(image_files=self.flash_images,
                                         sis_files=self.sis_files,
                                         test_timeout=list(self.test_timeout),
                                         test_harness=test_harness,
                                         src_dst=src_dst,
                                         custom_dir=self.custom_dir,
                                         component_path=tsrc_dir)

    def check_dll_duplication(self, _dll_file_, _src_dst_ ):
        """Checks if the dll is already in the dictionary, created by pkg file"""
        for item in _src_dst_:
            first = item[0]
            return _dll_file_.lower() in first.lower()
            
    @property
    def tsrc_bld_dir(self):
        """Component's build directory."""
        return self.tsrc_dir

    @property
    def tsrc_conf_dir(self):
        """Component's configuration file directory."""
        return self.tsrc_dir.joinpath("conf")

    @property
    def tsrc_custom_dir(self):
        """Component's test customization directory."""
        return self.tsrc_dir.joinpath("custom")


    @property
    def tsrc_data_dirs(self):
        """Component's data directories."""
        return [self.tsrc_dir.joinpath(d) for d in self.data_dirs]

    @property
    def tsrc_init_dir(self):
        """Component's initialization file directory."""
        return self.tsrc_dir.joinpath("init")
    
    @property
    def tsrc_pkg_dir(self):
        """Component's .pkg -file directory"""
        return self.tsrc_dir
    
    @property
    def tsrc_trace_activation_dir(self):
        """Component's trace activation file directory"""
        return self.tsrc_dir.joinpath("trace_init")

    @property
    def tsrc_pmd_dir(self):
        """Component's pmd file directory"""
        pmd_dir = self.build_drive + os.sep
        return pmd_dir.joinpath("output", "pmd")

    def tsrc_pmd_files(self):
        """Component's trace pmd files from the {build_drive}\output directory"""
        return list(self.tsrc_pmd_dir.walkfiles("*.pmd"))

    def tsrc_trace_activation_files(self):
        """Component's trace activation files, from the rtace_init directory."""
        return list(self.tsrc_trace_activation_dir.walkfiles("*.xml"))
    
    def tsrc_config_files(self):
        """Component's configuration files, from the conf directory."""
        return list(self.tsrc_conf_dir.walkfiles("*.cfg"))

    def tsrc_ini_files(self):
        """Component's initialiation files, from the ini directory."""
        return list(self.tsrc_init_dir.walkfiles("*.ini"))

    def tsrc_data_files(self):
        """Component's data files, from data directories."""
        files = []
        files2 = []
        for data_dir in self.tsrc_data_dirs:            
            if data_dir.exists():
                files.extend(list(data_dir.walkfiles()))        
        
        #Remove dist policy files
        for data_file in files:
            if data_file.name.lower() != "distribution.policy.s60":
                files2.append(data_file)
        return files2

    def tsrc_dll_files(self):
        """Component's DLL files, reported by ABLD BUILD."""

        dlls = []
        orig_dir = os.getcwd()
        try:
            os.chdir(self.tsrc_bld_dir)
            #os.system("abld test build %s" % self.target_platform)
            
            if os.environ.has_key("SBS_HOME"):
                process = subprocess.Popen("sbs --what -c %s.test" % self.target_platform.replace(' ', '_'), shell=True, stdout=subprocess.PIPE)
            else:
                os.system("bldmake bldfiles")
                process = subprocess.Popen("abld -w test build %s" % self.target_platform, shell=True, stdout=subprocess.PIPE)
            pipe = process.communicate()[0]
            
            for line in pipe.split('\n'):
                _logger.debug(line.strip())
                target = path(line.strip())
                if target.ext == ".dll":
                    
                    build_target = self.build_drive.joinpath(target).normpath()
                    if not build_target.exists():
                        _logger.warning("not found: %s" % build_target)
                    else:
                        dlls.append(build_target)
        finally:
            os.chdir(orig_dir)
        return dlls

    def tsrc_pkg_files(self, _dict_):
        """Component's package files, from the group directory"""
        pkg_dirs = []
        for sub_component in _dict_[self.tsrc_pkg_dir]['content'].keys():
            pkg_dirs.append(sub_component)
        return pkg_dirs
