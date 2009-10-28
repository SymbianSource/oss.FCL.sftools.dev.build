#============================================================================ 
#Name        : generate_vo_conf_ccmgetinput-new.py 
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

""" Helper to convert delivery.xml(new format) and prep.xml to VirtualBuildArea
    configuration file.
"""
import vbaconf
import sys    

deliveryinput = sys.argv[1]
prepinput = sys.argv[2]
ofilename = None
if len(sys.argv)==4:
    ofilename = sys.argv[3]

conv = vbaconf.ConfigConverterNewDelivery(deliveryinput, prepinput)
doc = conv.generate_config()

# Generating the output
if ofilename != None:
    file_object = open(ofilename, "w")
    file_object.write(doc.toprettyxml())
    file_object.close()
print doc.toprettyxml()


