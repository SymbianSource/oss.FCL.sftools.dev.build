#============================================================================ 
#Name        : test_packager_io.py 
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

# pylint: disable=E0602
import unittest
import logging
from unittestadditions import skip
skipTest = False
try:
    import packager.io
    from Blocks.Packaging.BuildData import *
except ImportError:
    skipTest = True

#logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger('nokiatest.datasources')

class BuildDataSerializerTest(unittest.TestCase):
    """ Check the de/serialisation of PlainBuildData objects. """
    
    @skip(skipTest)
    def test_serialization_deserialization(self):
        """ Check if a serialized PlainBuildData can be deserialized correctly. """
        bd = PlainBuildData()
        bd.setComponentName("foobar")
        bd.setComponentVersion("99")
        bd.setSourceRoot('/src')
        bd.setTargetRoot('/epoc32')
        bd.addSourceFiles(['src.txt', 'cmp/src.txt'])
        bd.addTargetFiles(['release/armv5/urel/target.dll', 'release/armv5/lib/target.lib'])
        data_xml = packager.io.BuildDataSerializer(bd).toXml()
        bdx = packager.io.BuildDataSerializer().fromXml(data_xml)
        self.assertEquals(bd.getComponentName(), bdx.getComponentName())
        self.assertEquals(bd.getComponentVersion(), bdx.getComponentVersion())
        self.assertEquals(bd.getSourceRoot(), bdx.getSourceRoot())
        self.assertEquals(bd.getTargetRoot(), bdx.getTargetRoot())
        self.assertEquals(bd.getSourceFiles(), bdx.getSourceFiles())
        self.assertEquals(bd.getTargetFiles(), bdx.getTargetFiles())
        self.assertEquals(len(bdx.getSourceFiles()), 2)
        self.assertEquals(len(bdx.getTargetFiles()), 2)
        assert 'release/armv5/urel/target.dll' in bdx.getTargetFiles()
        assert 'release/armv5/lib/target.lib' in bdx.getTargetFiles()
        assert 'src.txt' in bdx.getSourceFiles()
        assert 'cmp/src.txt' in bdx.getSourceFiles()

class BdFileSerializerTest(unittest.TestCase):
    """ Verifying the datasource interface. """
    
    @skip(skipTest)
    def test_serialization_deserialization(self):
        """ Check if a serialized BdFile can be deserialized correctly. """
        bd = BdFile("epoc32/release/armv5/urel/target.dll")
        bd.getVariantPlatform()
        bd.addSourceDependency("/src/src.txt")
        bd.addOwnerDependency("/epoc32/release/armv5/urel/target.dll")
        data_xml = packager.io.BdFileSerializer(bd).toXml()
        bdx = packager.io.BdFileSerializer().fromXml(data_xml)
        self.assertEquals(bd.getPath(), bdx.getPath())
        self.assertEquals(bd.getVariantPlatform(), bdx.getVariantPlatform())
        self.assertEquals(bd.getVariantType(), bdx.getVariantType())
        self.assertEquals(bd.getSourceDependencies(), bdx.getSourceDependencies())
        self.assertEquals(bd.getOwnerDependencies(), bdx.getOwnerDependencies())

        assert len(bd.getSourceDependencies()) == 1
        assert len(bd.getOwnerDependencies()) == 1

        assert "/src/src.txt" in bd.getSourceDependencies()
        assert '/epoc32/release/armv5/urel/target.dll' in bd.getOwnerDependencies()
        
        
class BuildDataMergerTest(unittest.TestCase):
    """ Unit test case for packager.io.BuildDataMerger """
    @skip(skipTest)
    def test_merge(self):
        """ Testing a simple merge. """
        bd = PlainBuildData()
        bd.setComponentName("foobar")
        bd.setComponentVersion("99")
        bd.setSourceRoot('/src')
        bd.setTargetRoot('/epoc32')
        bd.addSourceFiles(['src.txt', 'cmp/src.txt'])
        bd.addTargetFiles(['release/armv5/urel/target.dll', 'release/armv5/lib/target.lib'])
        
        bd2 = PlainBuildData()
        bd2.setComponentName("foobar")
        bd2.setComponentVersion("99")
        bd2.setSourceRoot('/src')
        bd2.setTargetRoot('/epoc32')
        bd2.addSourceFiles(['src.txt', 'cmp/src.txt', 'cmp2/src.txt'])
        bd2.addTargetFiles(['release/armv5/urel/target2.dll'])
        
        m = packager.io.BuildDataMerger(bd)
        m.merge(bd2)
        
        assert len(bd.getSourceFiles()) == 3
        assert len(bd.getTargetFiles()) == 3        
        