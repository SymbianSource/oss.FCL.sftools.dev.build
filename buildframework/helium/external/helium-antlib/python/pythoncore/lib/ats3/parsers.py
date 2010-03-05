# -*- encoding: latin-1 -*-

#============================================================================ 
#Name        : parsers.py 
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

""" The ATS related parsers """


# pylint: disable-msg=W0142,W0102
# pylint: disable-msg=C0302
# pylint: disable-msg=R0201,R0912,R0915,R0911,R0902

#W0142 => * and ** were used
#W0102 => Dangerous default value [] as argument
#C0302 => Too many lines
#R* remove during refactoring

import os
import re
import string
import logging
from path import path # pylint: disable-msg=F0401
import fnmatch
import subprocess
import codecs

_logger = logging.getLogger('ats-parser')

import configuration
def split_config_to_attributes_and_properties(specfile):
    """Split the specfile to its parts"""
    attributes = {}
    properties = {}
    builder = configuration.NestedConfigurationBuilder(specfile)
    configs = builder.getConfigurations()
    # the supported configs are either attributes or properties
    # collect each in a dictionary and return them.
    for config in configs:
        if config.name == 'attributes' :
            for attr in config:
                attributes[attr] = config[attr]
        if config.name == 'properties' :
            for prop in config:
                properties[prop] = config[prop]
    return (properties, attributes)


class CppParser(object):
    """
    Parser for CPP tool output. Returns cleaned output from the execution
    of CPP with or without parent paths included in the output.
    """

    def __init__(self):
        self.path_to_build = ""

    def get_cpp_output(self, bld_path = None, output_parameter = "n", imacros = None):
        """
        To clean out conditionals from the compilation it is necessary to 
        use C preprocessing to clean out those.
        
        If ('n' - normal) output is chosen, parser returns list of paths
        If ('e' - extended) output is chosen parser returns list of (path, parent_path) tuples
        If ('d' - dependency) output is chosen parser returns a dicitionary (can be a nested dictionary) 
                  of paths dependency (-ies). 
                  
        'imacros' can also be given as parameters for CPP options.
        
        if bld file is not given, the function will try to find the file(s) on the given location with extension ".inf"
        """
        temp_path = os.getcwd()
        if "bld.inf" in str(bld_path).lower():
            os.chdir(os.path.normpath(os.path.join(bld_path, os.pardir)))
        else:
            os.chdir(os.path.normpath(os.path.join(bld_path)))
            
        if imacros is not None:
            includedir = os.path.join(os.path.splitdrive(bld_path)[0] + os.sep, 'epoc32', 'include')
            command = r"cpp -imacros %s -I %s bld.inf" % (str(imacros), includedir)
        else:
            command = u"cpp bld.inf"
        
        process = subprocess.Popen(command, shell = True, stdout = subprocess.PIPE)
        pipe = process.stdout
        
        if output_parameter == "d":
            return self.create_dependency_dictionary(pipe, bld_path)
        
        #If not depdendency dictiontionary then create normal or extended list
        #Creates dictionary for 'n' (normal) and 'e' extended paths

        clean_path_list = []
        path_list = []
        for line in pipe.readlines():
            #_logger.debug(line.strip())
            if re.search(r"\A#\s.*?", line.strip()) or re.search(r"\A#.*?[0-9]", line.strip()):
                if line.strip() not in path_list:
                    path_list.append(line.strip())
        process.wait()
        if process.returncode == 1:
            _logger.error('CPP failed: ' + command + ' in: ' + os.getcwd())
        pipe.close()

        os.chdir(temp_path)
        if output_parameter is "n":
            for _path in self.clean_cpp_output(bld_path, path_list):
                clean_path_list.append(_path[0])
        
        elif output_parameter is "e":
            clean_path_list = self.clean_cpp_output(bld_path, path_list)

        clean_path_list = list(set(clean_path_list))

        bfp = BldFileParser()

        for tsrc in clean_path_list:
            mmp_path = bfp.get_test_mmp_files(tsrc[0])
            if tsrc[0] == tsrc[1]:
                if mmp_path == None or mmp_path == []:
                    clean_path_list.remove(tsrc)

        return clean_path_list
    
    def create_dependency_dictionary(self, _pipe_, path_to_bld):
        """
        The output from CPP is cleaned in a fashion that the output is
        a dictionary (or nested dictionary) of paths and their dependencies.
        """
        bld_parser = BldFileParser()
        pkg_parser = PkgFileParser()
        mmp_parser = MmpFileParser()
        
        temp_path = os.getcwd()
        parent = os.getcwd()
        self.path_to_build = path_to_bld
        
        test_sets = {}
        harness = ""
        main_level = ""
        test_cases = []
        output_list = []
        for line in _pipe_.readlines():
            if re.match(r"#.*", line.lower()):
                #_logger.debug(line)
                tpat =  re.findall(r'"(.*bld.inf?)"', line.lower())
                if tpat != []:
                    output_list.append((line, os.path.dirname(os.path.normpath(os.path.join(self.path_to_build, tpat[0])))))
        _pipe_.close()
        
        #Creating dependencies
        for case in output_list:
            if re.match(r".*[bld.inf][^0-9]\Z", string.strip(string.lower(case[0]))):
                
                if main_level == "":
                    main_level = case[1]
                parent = case[1]
                os.chdir(case[1])
                test_cases.append((parent, case[1]))
            elif re.match(r".*[1]\Z", string.strip(string.lower(case[0]))):
                parent = os.getcwd()
                os.chdir(case[1])
                
                test_cases.append((parent, case[1]))
            elif re.match(r".*[2]\Z", string.strip(string.lower(case[0]))):
                if test_cases:
                    for tcase in test_cases:
                        if parent in tcase[1]:
                            parent = tcase[0]
                            os.chdir(tcase[1])
                            break
                        
        for t_case in test_cases:
            if t_case[0] == t_case[1] and (not bld_parser.get_test_mmp_files(t_case[1])):
                del t_case
            elif t_case[0] in main_level:
                test_sets[t_case[1]] = {}
                test_sets[t_case[1]]['content'] = {}
                test_sets[t_case[1]]['content'][t_case[1]] = {}
                harness = mmp_parser.get_harness(t_case[1])
                #if harness == "": harness = None
                test_sets[t_case[1]]['content'][t_case[1]]['type'] = mmp_parser.get_dll_type(t_case[1])
                test_sets[t_case[1]]['content'][t_case[1]]['harness'] = harness
                test_sets[t_case[1]]['content'][t_case[1]]['pkg_files'] = pkg_parser.get_pkg_files(t_case[1], False)
                test_sets[t_case[1]]['content'][t_case[1]]['mmp_files'] = bld_parser.get_test_mmp_files(t_case[1], False)
            else:
                for key, value in test_sets.items():
                    if t_case[0] in value['content'].keys():
                        harness = mmp_parser.get_harness(t_case[1])
                        if harness is "" or harness in test_sets[key]['content'][t_case[0]]['harness']:
                            test_sets[key]['content'][t_case[1]] = {}
                            test_sets[key]['content'][t_case[1]]['type'] = mmp_parser.get_dll_type(t_case[1])
                            test_sets[key]['content'][t_case[1]]['harness'] = harness
                            test_sets[key]['content'][t_case[1]]['pkg_files'] = pkg_parser.get_pkg_files(t_case[1], False)
                            test_sets[key]['content'][t_case[1]]['mmp_files'] = bld_parser.get_test_mmp_files(t_case[1], False)
                        else:
                            test_sets[t_case[1]] = {}
                            test_sets[t_case[1]]['content'] = {}
                            test_sets[t_case[1]]['content'][t_case[1]] = {}
                            test_sets[t_case[1]]['content'][t_case[1]]['type'] = mmp_parser.get_dll_type(t_case[1])
                            test_sets[t_case[1]]['content'][t_case[1]]['harness'] = harness
                            test_sets[t_case[1]]['content'][t_case[1]]['pkg_files'] = pkg_parser.get_pkg_files(t_case[1], False)
                            test_sets[t_case[1]]['content'][t_case[1]]['mmp_files'] = bld_parser.get_test_mmp_files(t_case[1], False)

        os.chdir(temp_path)
        if test_sets == {}:
            for itm in output_list:
                _logger.debug(itm)
            for itm in test_cases:
                _logger.debug(itm)
            _logger.error(path_to_bld + ' test_sets are empty')
        return test_sets

    
    def clean_cpp_output(self, bld_path, path_list):
        """
        The output from CPP needs to be "cleaned" so that extra chars needs
        to be removed and also hierarchy which cpp is following is preserved
        and returned as an output. 
        """

        pat = ""
        value = ""
        cleaned_output = []
        if "bld.inf" in bld_path:
            path_to_parent = os.path.dirname(bld_path)
        else:
            path_to_parent = bld_path
        pat = re.compile(r'\A#\s*?.*?[\"](.*?)[\"].*?')
        for _path in path_list:
            if re.match(r".*[bld.inf]\s*?[^0-9]\Z", string.strip(string.lower(_path))):
                value = pat.match(_path.strip())
                path_to_tc = os.path.dirname(os.path.normpath(os.path.join((bld_path), value.group(1))))
                cleaned_output.append((path_to_tc, path_to_parent))
            if re.match(r".*[1]\s*?\Z", string.strip(string.lower(_path))):
                value = pat.match(_path.strip())
                path_to_tc = os.path.dirname(os.path.normpath(os.path.join(bld_path, value.group(1))))
                cleaned_output.append((path_to_tc, path_to_parent))
            if re.match(r".*[2]\s*?\Z", string.strip(string.lower(_path))):
                if cleaned_output:
                    for cout in cleaned_output:
                        if string.lower(path_to_parent) == string.lower(cout[0]):
                            path_to_tc = cout[1]
            path_to_parent = path_to_tc
        return cleaned_output


class BldFileParser(object):
    """
    Parser for bld.inf files. Returns MACRO values.
    Parsing Paths can be done using CPP parser  
    """
    def __init__(self):
        self.mmp_files = []

    #def get_mmp_files():
    #    """
    #    returns mmp files from PRJ_MMPFILES macro
    #   """    

    def get_test_mmp_files(self, bld_file_path = None, with_full_path = True):
        """
        returns a list of test mmp files 
        Usage: if "x:\abc\bldfile", "PRJ_TESTMMPFILES". 
        1. get_test_mmp_files("x:\abc\bldfile") - with full paths e.g. ["x:\abc\abc.mmp"]
        2. get_test_mmp_files("x:\abc\bldfile", False) - without full paths e.g. ["abc.mmp"]
        
        if bld file is not given, the function will try to find the file(s) on the given location with extension ".inf"
        """
        
        if bld_file_path == None:
            _logger.warning("Incorrect bld file")
            return None
        else:
            bld_file_path = path(bld_file_path)
            if not "bld.inf" in str(bld_file_path).lower():
                bld_file_path = os.path.join(os.path.normpath(bld_file_path), "bld.inf")

            if not os.path.exists(bld_file_path):
                _logger.error(r"bld file path does not exist: '%s'" % bld_file_path)
                return None

        return self.get_files(path(bld_file_path), "PRJ_TESTMMPFILES", with_full_path)


    def get_files(self, bld_inf_path, bld_macro, with_full_path = True):
        """
        Component's MMP files, as stored in BLD.INF.
        """
        
        bld_inf_path = path(bld_inf_path)
        bld_inf = bld_inf_path.text()
        if bld_inf.count(bld_macro) > 1:
            _logger.error(bld_macro + ' in ' + bld_inf_path + ' more than once')
        try:
            bld_inf = re.compile(r"%s" % bld_macro).split(bld_inf)[1].strip()
            bld_inf = re.compile(r"PRJ_+\S").split(bld_inf)[0].strip()
            
        except IndexError:
            try:
                bld_inf = re.compile(r"%s" % bld_macro).split(bld_inf)[0].strip()
                bld_inf = re.compile(r"PRJ_+\S").split(bld_inf)[0].strip()
                
            except IndexError:
                _logger.warning("Index Error while parsing bld.inf file")
        
        comments_free_text = self.ignore_comments_from_input(bld_inf)
        
        self.mmp_files = re.findall(r"(\S+?[.]mmp)", comments_free_text)
        
        
        
        if with_full_path:
            bld_dir = bld_inf_path.dirname()
            return [path.joinpath(bld_dir, mmp).normpath()
                    for mmp in self.mmp_files]
        else:
            return self.mmp_files

    def ignore_comments_from_input(self, input_str = ""):
        """
        Removes comments from the input string. Enables the use of examples
        in bld.inf.
        """
        _input = ""
        for i in input_str.split("\n"):
            _input += "\n" + i.split("//")[0]

        if not _input == "":
            input_str = _input
        count = input_str.count("/*")
        count2 = input_str.count("*/")
        if (count == count2):
            idx_1 = input_str.find('/*')
            idx_2 = input_str.find('*/') + 2
            while count > 0:
                substr_1 = input_str[:idx_1].strip()
                substr_2 = input_str[idx_2:].strip()
                input_str = substr_1 + " " + substr_2
                idx_1 = input_str.find('/*')
                idx_2 = input_str.find('*/') + 2
                count = input_str.count('/*')
            return input_str.strip()
        else:
            _logger.warning("Comments in bld.inf-file inconsistent. "
                            "Check comments in bld.inf.")
            return input_str.strip()


    #def get_exports():
    #    """
    #    returns exports from the macro PRJ_EXPORTS
    #    """

class MmpFileParser(object):
    """
    Parser for .mmp files. Returns wanted information from the mmp-file
    - file type (executable dll, plugin, exe, etc)
    - test harness (STIF, EUNIT) if mmp is related to the test component
    - file name
    - libraries listed in the mmp
    """

    def __init__(self):
        self.mmp_files = []
        self.path_to_mmp = ""

    def get_target_filetype(self, path_to_mmp = None):
        """
        Filetype given using TARGETTYPE in .mmp file is returned.
        If "c:\path\to\mmp" is a location where mmp file is stored
        get_target_filetype("c:\path\to\mmp")
        
        if mmp file is not given, the function will try to find the file(s) on the given location with extension ".mmp"
        """
        return self.read_information_from_mmp(path_to_mmp, 4)

    def get_target_filename(self, path_to_mmp = None):
        """
        Filename given using TARGET in .mmp file is returned
        If "c:\path\to\mmp" is a location where mmp file is stored
        get_target_filename("c:\path\to\mmp")
        
        if mmp file is not given, the function will try to find the file(s) on the given location with extension ".mmp"
        """
        return self.read_information_from_mmp(path_to_mmp, 3)

    def get_libraries(self, path_to_mmp = None):
        """
        Libraries listed in the MMP file are returned in a list
        If "c:\path\to\mmp" is a location where mmp file is stored
        get_libraries("c:\path\to\mmp")
        
        if mmp file is not given, the function will try to find the file(s) on the given location with extension ".mmp"
        """
        return self.read_information_from_mmp(path_to_mmp, 5)

    def get_harness(self, path_to_mmp = None):
        """
        Returns harness of test component
        If "c:\path\to\mmp" is a location where mmp file is stored
        get_harness("c:\path\to\mmp")
        
        if mmp file is not given, the function will try to find the file(s) on the given location with extension ".mmp"
        """
        return self.read_information_from_mmp(path_to_mmp, 6)

    def get_dll_type(self, path_to_mmp = None):
        """
        Returns type of test whether 'executable' or 'dependent' (dependent can be a stub or plugin)
        If "c:\path\to\mmp" is a location where mmp file is stored
        get_dll_type("c:\path\to\mmp")
        
        if mmp file is not given, the function will try to find the file(s) on the given location with extension ".mmp"
        """
        return self.read_information_from_mmp(path_to_mmp, 7)

    def read_information_from_mmp(self, path_to_mmp, flag = 0):
        """
        Returns wanted information - user can define 
        the wanted information level by setting a flag
        value following way:
        0 - (targetfilename, filetype, libraries, harness)
        1 - (targetfilename, filetype, libraries)
        2 - (targetfilename, filetype)
        3 - targetfilename
        4 - filetype
        5 - libraries
        6 - harness (in case of test component)
        7 - mmpfilename
        """


        filename = ""
        filetype = ""
        dll_type = ""
        libraries = []
        lst_mmp_paths = []
        harness = ""
        stif = False
        eunit = False
        stifunit = False
        tef = False
        self.path_to_mmp = path_to_mmp
        try:
            if isinstance(path_to_mmp, list):
                lst_mmp_paths = self.path_to_mmp
            else:    
                self.path_to_mmp = path(self.path_to_mmp)
                if not ".mmp" in str(self.path_to_mmp).lower():
                    bld_parser = BldFileParser()
                    self.mmp_files = bld_parser.get_test_mmp_files(self.path_to_mmp, False)
    
                    for mpath in self.mmp_files:
                        lst_mmp_paths.append(os.path.join(self.path_to_mmp, mpath))
                else:
                    lst_mmp_paths.append(self.path_to_mmp)

            for mmp in lst_mmp_paths:
                mmp_file = open(mmp, 'r')
                for line in mmp_file:
                    if re.match(r"\A(target\s).*([.]\w+)", string.strip(string.lower(line))):
                        filename = re.findall(r"\Atarget[\s]*(\w+[.]\w+)", string.lower(line))[0]
                    elif re.match(r"\A(targettype\s).*", string.strip(string.lower(line))):
                        filetype = re.findall(r"\Atargettype[\s]*(\w+)", string.lower(line))[0]

                libraries = libraries + re.findall(r"\b(\w+[.]lib)\b", mmp.text().lower())
                if '//rtest' in mmp.text().lower() or '* rtest' in mmp.text().lower() or '// rtest' in mmp.text().lower():
                    libraries.append('rtest')
            
            if libraries:
                if "stiftestinterface.lib" in libraries:
                    stif = True
                if "eunit.lib" in libraries or "qttest.lib" in libraries:
                    eunit = True
                if "stifunit.lib" in libraries:
                    stifunit = True
                elif "testexecuteutils.lib" in libraries or 'testframeworkclient.lib' in libraries or 'rtest' in libraries:
                    tef = True

            if tef:
                harness = "GENERIC"
            elif stif and eunit:
                #_logger.warning("both eunit.lib and stiftestinterface.lib listed in mmp file - choosing STIF.")
                harness = "STIF"
            elif stif and not eunit:
                harness = "STIF"
            elif eunit and not stif:
                harness = "EUNIT"
            elif stifunit and not stif and not eunit:
                harness = "STIFUNIT"

            if harness is "":
                dll_type = "dependent"
            elif harness is "EUNIT":
                dll_type = "executable"
            elif harness is "STIF":
                dll_type = "executable"

        finally:
            if flag == 0:
                return (filename, filetype, libraries, harness)
            elif flag == 1:
                return (filename, filetype, libraries)
            elif flag == 2:
                return (filename, filetype)
            elif flag == 3:
                return filename
            elif flag == 4:
                return filetype
            elif flag == 5:
                return libraries
            elif flag == 6:
                return harness
            elif flag == 7:
                return dll_type

class PkgFileParser(object):
    """
    Parses .pkg files. Returns a list of:
      a. src path of the file
      b. dst path on the phone
      c. type of the file
    for every file in the pkg file
    """

    def __init__(self, platform = None, specific_pkg = None):
        self.platform = platform
        if self.platform is not None and "_" in self.platform:
            plat_tar = re.search(r"(.*)_(.*).pkg", self.platform)
            self.build_platform, self.build_target = plat_tar.groups() 
        self.drive = ""
        self._files = []
        self.pkg_files = []
        self.pkg_file_path = None
        self.exclude = ""
        self.location = None
        self.specific_pkg = specific_pkg
        if specific_pkg:
            self.platform = specific_pkg + '.pkg'

    def get_pkg_files(self, location = None, with_full_path = True):
        """
        Returns list of PKG files on the given location. If True, full path is returned 
        otherwise only filenames. Default is set to True
        
        Assume at location "c:\abd\files", two pkg file '1.pkg' and '2.pkg', then the funtion
        can be called as:
        1. get_pkg_files("c:\abd\files")        - will return a list of pkg files with full paths. 
                                                  like ['c:\abd\files\1.pkg', 'c:\abd\files\2.pkg']
        2. get_pkg_files("c:\abd\files", False) - will return a list of pkg files only. 
                                                  like ['1.pkg', '2.pkg']
        """
        self.location = path(location)
        self.pkg_files = []
        if not self.location.exists():
            return None

        for pths, _, files in os.walk(self.location):
            pfiles = [f for f in files if self.platform != None and f.endswith(self.platform)]
            if self.platform != None and len(pfiles)>0:
                if with_full_path:
                    self.pkg_files.append(os.path.join(pths, pfiles[0]))
                else:
                    self.pkg_files.append(str(pfiles[0]))
            elif self.specific_pkg == None:
                for name in files:
                    if fnmatch.fnmatch(name, "*.pkg"):
                        if with_full_path:
                            self.pkg_files.append(os.path.join(pths, name))
                        else:
                            self.pkg_files.append(str(name))

        return self.pkg_files

    def get_data_files(self, location = [], drive = "", exclude = ""):
        """
        Returns data files, source and destination of the files to be installed 
        on the phone 
        e.g. location = tsrc\testComponent\group
        
        Function can be called in any of the following ways:
        1. get_data_files("c:\abc\abc.pkg")                 - only data files' paths are returnd 
                                                              as they are mention in the pkg file
        2. get_data_files("c:\abc\abc.pkg", "x:")           - Proper data files' paths are returnd 
                                                              with drive letter included 
        3. get_data_files("c:\abc\abc.pkg", "x:", "\.dll")  - Data files' paths are returnd with 
                                                              drive letter included but the dll 
                                                              files will be excluded if found in 
                                                              the pkg file
        
        if pkg file is not given, the function will try to find the file(s) on the given location with extension ".pkg"
        """

        self.drive = drive
        self.exclude = exclude
        self._files = []

        if type(location) is not list:
            locations = [location]
        else:
            locations = location
        
        for _file_ in locations:
            
            #if location is already a file
            if ".pkg" in str(_file_).lower():
                self._files = _file_
            else:
                self.location = path(_file_)

                if not self.location.exists():
                    continue
                for p_file in self.get_pkg_files(self.location, True):
                    self._files.append(p_file)

        return self.__read_pkg_file(self._files)

    def __map_pkg_path(self, pkg_line, pkg_file_path, pkg_file):
        """Parse package file to get the src and dst paths" for installing files"""
        mmp_parser = MmpFileParser()
        ext = ""
        val1 = ""
        val2 = ""
        map_src = ""
        map_dst = ""
        self.pkg_file_path = pkg_file_path
        
        if not self.exclude == "":
            if re.search(r'%s' % self.exclude, pkg_line) is not None:
                return None
        #searches for the file path (src and dst) in the pkg file
        #e.g.: "..\conf\VCXErrors.inc"-"C:\TestFramework\VCXErrors.inc"
        result = re.search(r'^\s*"(.*?)".*?-.*?"(.*?)"', pkg_line)

        if result is None:
            return None
        val1, val2 = result.groups()

        if val1 != "":
            
            #replacing delimiters (${platform} and ${target}) in PKG file templates, 
            #for instance, QT tests PKG files have delimeters 
            if "$(platform)" in val1.lower() and self.build_platform is not None:
                val1 = val1.lower().replace("$(platform)", self.build_platform)
            if "$(target)" in val1.lower() and self.build_target is not None:
                val1 = val1.lower().replace("$(target)", self.build_target)

            if path.isabs(path(val1).normpath()):
                map_src = str(path.joinpath(self.drive, val1).normpath())
            elif re.search(r"\A\w", val1, 1):
                map_src = str(path.joinpath(self.pkg_file_path + os.sep, os.path.normpath(val1)).normpath())
            else:
                map_src = str(path.joinpath(self.pkg_file_path, path(val1)).normpath())
            map_dst = str(path(val2).normpath())
        else:
            map_src, map_dst = val1, val2
        map_src = map_src.strip()
        
        #replaces the characters with the drive letters
        map_dst = map_dst.replace("!:", "c:")
        map_dst = map_dst.replace("$:", "c:")
        map_dst = re.sub(r'^(\w)', r'\1', map_dst).strip()
        indx = map_dst.rsplit(".")
        try:
            ext = indx[1]
        except IndexError:
            _logger.warning("Index Error in map_pkg_path()")

        _test_type_ = ""
        _target_filename_ = ""
        
        _target_filename_ = mmp_parser.get_target_filename(self.pkg_file_path)
        _test_type_ = mmp_parser.get_dll_type(self.pkg_file_path)
        _harness_ = mmp_parser.get_harness(self.pkg_file_path)
        _libraries_ = mmp_parser.get_libraries(self.pkg_file_path)
        
        if ext == "ini":
            file_type = "engine_ini"
        elif ext == "cfg":
            file_type = "conf"
        elif ext == "dll":
            #adding type of dll (executable or dependent), if file type is dll
            if _test_type_ == "dependent":
                file_type = "data" + ":%s" % _test_type_
            else:
                if "qttest.lib" in _libraries_:
                    file_type = "data" + ":qt:dependent" 
                else:
                    file_type = "testmodule"
                    
        elif ext == 'exe' and 'rtest' in _libraries_:
            file_type = "testmodule:rtest"
        elif ext == "exe":
            if _test_type_ == "dependent":
                file_type = "data" + ":%s" % _test_type_
            else:
                if "qttest.lib" in _libraries_:
                    file_type = "testmodule:qt"
                else:
                    file_type = "testmodule"

        elif ext == "sisx":
            file_type = ""
        elif ext == "xml":
            file_type = "trace_init"
        elif ext == "pmd":
            file_type = "pmd"
        elif ext == "script":
            if "testframeworkclient.lib" in _libraries_:
                file_type = "testscript:mtf"
            else:
                file_type = "testscript"
        else:
            file_type = "data"

        if not map_src or map_src == "." or not map_dst or map_dst == ".":
            return None

        return path(map_src).normpath(), path(map_dst).normpath(), file_type, pkg_file

    def __read_pkg_file(self, pkg_files):
        """Reads contents of PKG file"""
        pkg_paths = []
        for pkg_file in pkg_files:
            if not os.path.exists( pkg_file ):
                _logger.error("No PKG -file in path specified")
                continue
            else:
                file1 = codecs.open(pkg_file, 'r', 'utf16')
                try:
                    lines = file1.readlines()
                except UnicodeError:
                    file1 = open(pkg_file, 'r')
                    lines = file1.readlines()
                pkg_file_path = path((pkg_file.rsplit(os.sep, 1))[0])
                for line in lines:
                    pkg_path = self.__map_pkg_path(line, pkg_file_path, os.path.basename(pkg_file))
                    if pkg_path is None:
                        continue
                    else:
                        pkg_paths.append(pkg_path)

        return pkg_paths