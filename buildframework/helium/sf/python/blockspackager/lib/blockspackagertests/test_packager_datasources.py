#============================================================================ 
#Name        : test_packager_datasources.py 
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
import unittest
from unittestadditions import skip
skipTest = False
try:
    import packager.datasources
except ImportError:
    skipTest = True
import os
from StringIO import StringIO
import tempfile
import xml.sax
import logging
import sys

#logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('nokiatest.datasources')

class DataSourceInterfaceTest(unittest.TestCase):
    """ Verifying the datasource interface. """
    
    @skip(skipTest)
    def test_datasource_getComponent(self):
        """ Check that getComponent is not implemented. """
        ds = packager.datasources.DataSource('/')
        self.assertRaises(NotImplementedError, ds.getComponents)

    @skip(skipTest)
    def test_datasource_getHelp(self):
        """ Check that no help is defined. """
        ds = packager.datasources.DataSource('/')
        self.assertEqual(None, ds.getHelp())
        self.assertEqual(ds.help, ds.getHelp())       
    
class CMakerDataSourceTest(unittest.TestCase):
    """ Unit test for CMakerDataSource """
    @skip(skipTest)
    def test_whatlog_missing(self):
        """ getComponent should fail if whatlog is missing. """
        data = {}
        ds = packager.datasources.CMakerDataSource('/', data)
        self.assertRaises(packager.datasources.MissingProperty, ds.getComponents)
        
    @skip(skipTest)
    def test_configdir_missing(self):
        """ getComponent should fail if configdir is missing. """
        data = {'whatlog': 'somevalue'}
        ds = packager.datasources.CMakerDataSource('/', data)
        self.assertRaises(packager.datasources.MissingProperty, ds.getComponents)
    
    @skip(skipTest)
    def test_invalid_whatlog_invalid_configdir(self):
        """ getComponent should fail because whatlog doesn't exists. """
        data = {'whatlog': 'somevalue', 'configdir': 'somevalue'}
        ds = packager.datasources.CMakerDataSource('/', data)
        self.assertRaises(Exception, ds.getComponents)

    @skip(skipTest)
    def test_valid_whatlog_invalid_configdir(self):
        """ getComponent should fail because configdir doesn't exists. """
        data = {'whatlog': __file__, 'configdir': 'somevalue'}
        ds = packager.datasources.CMakerDataSource('/', data)
        self.assertRaises(Exception, ds.getComponents)
        
    @skip(skipTest)
    def test_install_log_parsing(self):
        """ Test the parsing of a regular cmaker install log. """
        log = r"""C:\APPS\actperl\bin\perl.exe -e 'use File::Copy; copy(q(src/env.mk),q(/epoc32/tools/cmaker/env.mk))'
C:\APPS\actperl\bin\perl.exe -e 'use File::Copy; copy(q(src/functions.mk),q(/epoc32/tools/cmaker/functions.mk))'
C:\APPS\actperl\bin\perl.exe -e 'use File::Copy; copy(q(src/include_template.mk),q(/epoc32/tools/cmaker/include_template.mk))'
C:\APPS\actperl\bin\perl.exe -e 'use File::Copy; copy(q(src/settings.mk),q(/epoc32/tools/cmaker/settings.mk))'
C:\APPS\actperl\bin\perl.exe -e 'use File::Copy; copy(q(src/tools.mk),q(/epoc32/tools/cmaker/tools.mk))'
C:\APPS\actperl\bin\perl.exe -e 'use File::Copy; copy(q(src/utils.mk),q(/epoc32/tools/cmaker/utils.mk))'
C:\APPS\actperl\bin\perl.exe -e 'use File::Copy; copy(q(bin/mingw_make.exe),q(/epoc32/tools/rom/mingw_make.exe))'
C:\APPS\actperl\bin\perl.exe -e 'use File::Copy; copy(q(src/cmaker.cmd),q(/epoc32/tools/cmaker.cmd))'
"""
        (handle, filename) = tempfile.mkstemp()
        os.write(handle, log)
        os.close(handle)
        
        data = {'whatlog': filename, 'configdir': os.path.dirname(__file__)}
        ds = packager.datasources.CMakerDataSource('/', data)
        components = ds.getComponents()
        assert len(components) == 1
        assert len(components[0].getTargetFiles()) == 8
        assert 'epoc32/tools/rom/mingw_make.exe' in components[0].getTargetFiles()
        
        os.remove(filename)
        
        
    @skip(skipTest)
    def test_what_log_parsing_windows(self):
        """ Test the parsing of a regular cmaker what log (windows). """
        if sys.platform == 'win32':
            log = r"""\epoc32\tools\rom\image.txt
\CreateImage.cmd
cd \config\overlay && xcopy *.* \ /F /R /Y /S
0 File(s) copied
cd \tools\toolsmodTB92 && xcopy *.* \ /F /R /Y /S
Y:\tools\toolsmodTB92\epoc32\tools\abld.pl -> Y:\epoc32\tools\abld.pl
Y:\tools\toolsmodTB92\epoc32\tools\bldmake.pl -> Y:\epoc32\tools\bldmake.pl
"""
            (handle, filename) = tempfile.mkstemp()
            os.write(handle, log)
            os.close(handle)
            
            data = {'whatlog': filename, 'configdir': os.path.dirname(__file__)}
            ds = packager.datasources.CMakerDataSource('/', data)
            components = ds.getComponents()
            assert len(components) == 1
            assert len(components[0].getTargetFiles()) == 2
            print components[0].getTargetFiles()
            assert 'CreateImage.cmd' in components[0].getTargetFiles()
            assert 'epoc32/tools/rom/image.txt' in components[0].getTargetFiles()
            assert 'epoc32/tools/abld.pl' not in components[0].getTargetFiles()
            assert 'epoc32/tools/bldmake.pl' not in components[0].getTargetFiles()
        
            os.remove(filename)

    @skip(skipTest)
    def test_what_log_parsing_linux(self):
        """ Test the parsing of a regular cmaker what log (linux). """
        if sys.platform != 'win32':
            log = r"""/epoc32/tools/rom/image.txt/CreateImage.cmd
"""
            (handle, filename) = tempfile.mkstemp()
            os.write(handle, log)
            os.close(handle)
        
            data = {'whatlog': filename, 'configdir': os.path.dirname(__file__)}
            ds = packager.datasources.CMakerDataSource('/', data)
            components = ds.getComponents()
            assert len(components) == 1
            assert len(components[0].getTargetFiles()) == 2
            print components[0].getTargetFiles()
            assert 'CreateImage.cmd' in components[0].getTargetFiles()
            assert 'epoc32/tools/rom/image.txt' in components[0].getTargetFiles()
        
            os.remove(filename)

        
    @skip(skipTest)
    def test_getHelp(self):
        """ Check that help is defined for CMakerDataSource. """
        ds = packager.datasources.CMakerDataSource('/', {})
        self.assertNotEqual(None, ds.getHelp())
        self.assertEqual(ds.help, ds.getHelp())       


class SBSDataSourceTest(unittest.TestCase):
    """ Unit test case for SBSDataSource """
    @skip(skipTest)
    def test_getHelp(self):
        """ Check that help is defined for SBSDataSource. """
        ds = packager.datasources.SBSDataSource('/', {})
        self.assertNotEqual(None, ds.getHelp())
        self.assertEqual(ds.help, ds.getHelp())       


class SysdefComponentListTest(unittest.TestCase):
    """ Unit test case for packager.datasources.sbs.SysdefComponentList """
    sysdef = None
        
    def setUp(self):
        self.sysdef = StringIO("""<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<SystemDefinition name="main" schema="1.4.0">
    <systemModel>
    <layer name="layer1">
        <module name="module1">
            <component name="cmp1">
                <unit unitID="unit1" name="unit1.name" mrp="" filter="" bldFile="path/to/component1"/>
            </component>
        </module>
    </layer>
    <layer name="layer2">
        <module name="module2">
            <component name="cmp2">
                <unit unitID="unit2" name="unit2.name" mrp="" filter="" bldFile="path\\to\\Component2"/>
            </component>
        </module>
    </layer>
    </systemModel>
</SystemDefinition>
""")

    @skip(skipTest)
    def test_unit_parsing(self):
        """ SysdefComponentList extract correctly the units... """
        cl = packager.datasources.sbs.SysdefComponentList('/')
        p = xml.sax.make_parser()
        p.setContentHandler(cl)
        p.parse(self.sysdef)
        assert len(cl) == 2
        assert cl['unit1_name']['path'] == os.path.normpath('/path/to/component1')
        assert cl['unit2_name']['path'] == os.path.normpath('/path/to/Component2')
        assert cl['unit2_name']['name'] == 'unit2_name'

    @skip(skipTest)
    def test_get_component_name_by_path(self):
        """ Check if get_component_name_by_path is case unsensitive. """ 
        cl = packager.datasources.sbs.SysdefComponentList('/')
        p = xml.sax.make_parser()
        p.setContentHandler(cl)
        p.parse(self.sysdef)

        # reading path should be case independent.
        assert cl.get_component_name_by_path(os.path.normpath('/path/to/Component2')) == 'unit2_name'
        assert cl.get_component_name_by_path(os.path.normpath('/path/to/component2')) == 'unit2_name'

    @skip(skipTest)
    def test_get_component_name_by_path_invalid(self):
        """ Check that get_component_name_by_path is raising an exception if """
        cl = packager.datasources.sbs.SysdefComponentList('/')
        p = xml.sax.make_parser()
        p.setContentHandler(cl)
        p.parse(self.sysdef)

        # reading path should be case independent.
        try:
            cl.get_component_name_by_path(os.path.normpath('/path/to/invalid'))
        except packager.datasources.sbs.ComponentNotFound:
            pass
        else:
            self.fail("Expected get_component_name_by_path to raise an exception in case of non-existing component definition.")


class SysdefComponentListSysdef3ParsingTest(unittest.TestCase):
    """ Unit test case for packager.datasources.sbs.SysdefComponentList """
    sysdef = None
        
    def setUp(self):
        self.sysdef = StringIO("""<?xml version="1.0" encoding="UTF-8"?>
<SystemDefinition schema="3.0.0" id-namespace="http://www.symbian.org/system-definition">
<systemModel name="sf_">
<layer id="app" name="app">
<package id="helloworldcons" name="helloworldcons" levels="demo">
<collection id="helloworldcons_apps" name="helloworldcons_apps" level="demo">
<component id="helloworldcons_app" name="helloworldcons app" purpose="development">
<unit bldFile="/sf/app/helloworldcons/group" mrp="/sf/app/helloworldcons/"/>
</component>
</collection>
</package>
</layer>
<layer id="mw" name="mw">
<package id="helloworldapi" name="helloworldapi" levels="demo">
<collection id="helloworld_apis" name="helloworlds APIs" level="demo">
<component id="helloworld_api" name="Hello World API" purpose="development">
<unit bldFile="/sf/mw/helloworldapi/group" mrp="/sf/mw/helloworldapi/"/>
</component>
</collection>
</package>
</layer>
</systemModel>
</SystemDefinition>
""")

    @skip(skipTest)
    def test_unit_parsing(self):
        """ SysdefComponentList extract correctly the units... """
        cl = packager.datasources.sbs.SysdefComponentList('/')
        p = xml.sax.make_parser()
        p.setContentHandler(cl)
        p.parse(self.sysdef)
        assert len(cl) == 2
        print cl
        assert cl['helloworldcons_app_sf_app_helloworldcons_group']['path'] == os.path.normpath('/sf/app/helloworldcons/group')
        assert cl['helloworld_api_sf_mw_helloworldapi_group']['path'] == os.path.normpath('/sf/mw/helloworldapi/group')
        assert cl['helloworld_api_sf_mw_helloworldapi_group']['name'] == 'helloworld_api'

    @skip(skipTest)
    def test_get_component_name_by_path(self):
        """ Check if get_component_name_by_path is case unsensitive. """ 
        cl = packager.datasources.sbs.SysdefComponentList('/')
        p = xml.sax.make_parser()
        p.setContentHandler(cl)
        p.parse(self.sysdef)

        # reading path should be case independent.
        assert cl.get_component_name_by_path(os.path.normpath('/sf/app/helloworldcons/group')) == 'helloworldcons_app_sf_app_helloworldcons_group'
        assert cl.get_component_name_by_path(os.path.normpath('/sf/mw/helloworldapi/group')) == 'helloworld_api_sf_mw_helloworldapi_group'

    @skip(skipTest)
    def test_get_component_name_by_path_invalid(self):
        """ Check that get_component_name_by_path is raising an exception if """
        cl = packager.datasources.sbs.SysdefComponentList('/')
        p = xml.sax.make_parser()
        p.setContentHandler(cl)
        p.parse(self.sysdef)

        # reading path should be case independent.
        try:
            cl.get_component_name_by_path(os.path.normpath('/path/to/invalid'))
        except packager.datasources.sbs.ComponentNotFound:
            pass
        else:
            self.fail("Expected get_component_name_by_path to raise an exception in case of non-existing component definition.")


class ObyParserTest(unittest.TestCase):
    """ Unit test case for packager.datasources.imaker.ObyParser """
    oby = None
    
    def setUp(self):
        (hld, filename) = tempfile.mkstemp(".oby", "datasource_test")
        os.write(hld, """
rofssize=0x10000000
# file=\\epoc32\\release\\ARMV5\\urel\\COMMENT.DLL       "Sys\\Bin\\EDISP.DLL"
file=\\epoc32\\release\\ARMV5\\urel\\edisp.dll       "Sys\\Bin\\EDISP.DLL"
data=\\epoc32\\data\\Z\\Private\\10202BE9\\20000585.txt       "Private\\10202BE9\\20000585.txt"
extension[0x09080004]=\\epoc32\\release\ARMV5\urel\power_resources.dll      "Sys\\Bin\\power_resources.dll"
variant[0x09080004]=\\epoc32\\release\\ARMV5\\urel\\ecust.b23b7726cf4b5801b0dc14102b245fb8.dll         "Sys\\Bin\\ecust.dll"
# file="\\epoc32\\release\\ARMV5\\urel\\edisp.dll"       "Sys\\Bin\\EDISP.DLL"
data="/output/release_flash_images/langpack_01/rofs2/variant/private/10202be9/10281872.txt"  "private\10202be9\10281872.txt"
""")
        os.close(hld)
        self.oby = filename
        
    def tearDown(self):
        os.remove(self.oby)
        
    @skip(skipTest)
    def test_oby(self):
        """ Testing the extraction of source files from an processed Oby file. """
        print self.oby
        p = packager.datasources.imaker.ObyParser('/', self.oby)
        files = p.getSourceFiles()
        print files
        assert len(files) == 5
        assert os.path.normpath(r'\epoc32\release\ARMV5\urel\edisp.dll'.replace('\\', os.sep).replace('/', os.sep)) in files
        assert os.path.normpath(r'\epoc32\data\Z\Private\10202BE9\20000585.txt'.replace('\\', os.sep).replace('/', os.sep)) in files
        assert os.path.normpath(r'\epoc32\release\ARMV5\urel\power_resources.dll'.replace('\\', os.sep).replace('/', os.sep)) in files
        assert os.path.normpath(r'\epoc32\release\ARMV5\urel\ecust.b23b7726cf4b5801b0dc14102b245fb8.dll'.replace('\\', os.sep).replace('/', os.sep)) in files
        assert os.path.normpath(r'/output/release_flash_images/langpack_01/rofs2/variant/private/10202be9/10281872.txt'.replace('\\', os.sep).replace('/', os.sep)) in files
        

class ConEDataSourceTest(unittest.TestCase):
    """ ConfToolDataSource unittest. """
    
    @skip(skipTest)
    def test_cone_input(self):
        """ Testing ConE output log parsing. """
        log = """  Generating file '\\epoc32\\release\\winscw\\urel\\z\\private\\10202BE9\\10208dd7.txt'...
DEBUG   : cone.crml(assets/symbianos/implml/usbmanager_10285c46.crml)
  Generating file '\\epoc32\\release\\winscw\\urel\\z\\private\\10202BE9\\10285c46.txt'...
DEBUG   : cone.crml(assets/symbianos/implml/usbmanager_10286a43.crml)
  Generating file '\\epoc32\\release\\winscw\\urel\\z\\private\\10202BE9\\10286a43.txt'...
INFO    : cone
  Adding impl CrmlImpl(ref='assets/symbianos/implml/apputils_100048aa.crml', type='crml', index=0)
INFO    : cone
"""
        (handle, filename) = tempfile.mkstemp()
        os.write(handle, log)
        os.close(handle)
        data = {'filename': filename, 'name': 'cone', 'version': '1.0'}
        ds = packager.datasources.ConEDataSource('/', data)
        components = ds.getComponents()
        assert len(components) == 1
        print components[0].getTargetFiles()
        assert len(components[0].getTargetFiles()) == 3
        
