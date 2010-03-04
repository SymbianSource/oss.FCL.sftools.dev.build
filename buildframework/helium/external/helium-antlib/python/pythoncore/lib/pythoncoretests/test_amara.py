#============================================================================ 
#Name        : test_ant.py 
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

""" amara.py module tests. """


import amara
from xmlhelper import node_scan, recursive_node_scan

def test_amara():
    x = amara.parse(r'<commentLog><branchInfo category="" error="kkk" file="tests/data/comments_test.txt" originator="sanummel" since="07-03-22">Add rofsfiles for usage in paged images</branchInfo></commentLog>')
    assert str(x.commentLog.branchInfo) == 'Add rofsfiles for usage in paged images'
    
    x = amara.parse(r'<commentLog><branchInfo>1</branchInfo><branchInfo>2</branchInfo></commentLog>')
    for y in x.commentLog.branchInfo:
        assert str(y) == '1'
        break
          
    myxml = """<DpComponent DpType="File" name="dp.cfg.xml" fileType="Binary" fileSubType="1" fileIndex="1" owner="SwUpdate" extract="true" signed="true" optional="true" crc="true" useCases="Refurbish,BackupRestore" variantPackage="true" include="true" EnableCRCVerification="true" parameters="test"/>"""
    xcf = amara.parse(myxml)
    assert xcf.DpComponent['name'] == 'dp.cfg.xml'
    
    myxml2 = """<bomDelta><buildFrom>ido_raptor_mcl_abs_MCL.52.57</buildFrom><buildTo>mock</buildTo><content/></bomDelta>"""
    xcf2 = amara.parse(myxml2)
    assert xcf2.bomDelta[0].buildFrom[0] == "ido_raptor_mcl_abs_MCL.52.57"
    
    print xcf.DpComponent.xml_attributes
    
    doc = amara.create_document(u'bom')
    s60_input_node = doc.xml_create_element(u'input')
    s60_input_node.xml_append(doc.xml_create_element(u'name', content=(unicode("s60"))))
    print s60_input_node.xml()
    
    s60_input_source = s60_input_node.xml_create_element(u'source')
    s60_input_source.xml_append(doc.xml_create_element(u'type', content=(unicode("grace"))))
    print s60_input_source.xml()
          
    doc = amara.create_document(u'bom')
    doc.bom.xml_append(doc.xml_create_element(u'build', content=unicode("a")))
    
    doc = amara.create_document(u'bomDelta')
    content_node = doc.xml_create_element(u'content')
    doc.bomDelta.xml_append(content_node)
    content_node.xml_append(content_node.xml_create_element(u'b', content=unicode('a')))
    assert doc.bomDelta.xml(indent=False) == '<bomDelta><content><b>a</b></content></bomDelta>'
    
    recursive_node_scan(doc, 'a')
    
    amara.create_document()
    
    xcf3 = amara.parse(r'<VariantPackingList><Variant/></VariantPackingList>')
    assert hasattr(xcf3.VariantPackingList.Variant,"FileList") == False
    if not hasattr(xcf3.VariantPackingList.Variant,"FileList"):
        xcf3.VariantPackingList.Variant.xml_append(xcf3.xml_create_element(u"FileList"))
    xcf3.VariantPackingList.Variant.FileList.xml_append_fragment(doc.xml(omitXmlDeclaration=u"yes"))
    
    xcf4 = amara.parse(r"<a><p name='1'/><p name='1'/></a>")
    found = False
    for p in xcf4.xml_xpath("//p"):
        assert str(p.name) == '1'
        found = True
    assert found
    
    #xcf5 = amara.parse(open(r'C:\USERS\helium\helium-dev-forbuilds\helium\tests\data\bom\build_model_bom.xml'))
    #u'%s' % xcf5.bom.content.project.folder.task.synopsis
