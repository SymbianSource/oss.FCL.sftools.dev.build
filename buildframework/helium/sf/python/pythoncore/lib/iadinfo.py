#============================================================================ 
#Name       : iadinfo.py 
#Part of    : Helium 

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
""" IAD info """

import sys, os
import struct
import zlib

PyASN1Availabe = True

try:
    from pyasn1.codec.der import decoder
    from pyasn1.type import base
except ImportError:
    PyASN1Availabe = False

def _findItem(item, itemParent, index, objectIdentifier):
    """find Item"""
    if isinstance(item, base.AbstractSimpleAsn1Item):
        if item == objectIdentifier:
            return itemParent[index + 1]
    else:
        for i_item in range(len(item)):
            found = _findItem(item[i_item], item, i_item, objectIdentifier)
            if found: 
                return found

def findItem(decodedCert, objectIdentifier):
    """find item"""
    return _findItem(decodedCert, None, 0, objectIdentifier)


class CertificateOrganization:
    """ This class holds organisation details of certificate issuer or signer """
    def __init__(self):
        self.commonName = None
        self.countryCode = None
        self.locality = None
        self.state = None
        self.street = None
        self.organization = None
        
    def parse(self, decodedCert):
        """parse certificate Organisation"""
        self.commonName = findItem(decodedCert, (2, 5, 4, 3))
        self.countryCode = findItem(decodedCert, (2, 5, 4, 6))
        self.locality = findItem(decodedCert, (2, 5, 4, 7))
        self.state = findItem(decodedCert, (2, 5, 4, 8))
        self.street = findItem(decodedCert, (2, 5, 4, 9))
        self.organization = findItem(decodedCert, (2, 5, 4, 10))

    def readableStr(self):
        """readable String"""
        buf = ""
        if self.commonName:
            buf += self.commonName.prettyPrint() + "\n"
        if self.countryCode:
            buf += self.countryCode.prettyPrint() + "\n"
        if self.locality:
            buf += self.locality.prettyPrint() + "\n"
        if self.state:
            buf += self.state.prettyPrint() + "\n"
        if self.street:
            buf += self.street.prettyPrint() + "\n"
        if self.organization:
            buf += self.organization.prettyPrint()
        return buf

class CertificateInfo:
    """ This class holds certificate information such as certificate signer and issuer """
    def __init__(self):
        self.issuer = None
        self.signer = None
        
    def parse(self, decodedCert):
        """parse"""
        self.issuer = CertificateOrganization()
        self.issuer.parse(decodedCert[0][3])
        
        self.signer = CertificateOrganization()
        self.signer.parse(decodedCert[0][5])
        
    def readableStr(self):
        """readable String"""
        buf = "Signer:\n      " + "\n      ".join(self.signer.readableStr().split('\n')) + "\n"
        buf += "Issuer:\n      " + "\n      ".join(self.issuer.readableStr().split('\n')) + "\n"
        return buf


class SISFileHeader:
    """ Class SIS File header """
    def __init__(self):
        self.uid1 = 0
        self.uid2 = 0
        self.uid3 = 0
        self.uidChecksum = 0

class SISField:
    """ Class SIS Field """
    def __init__(self):
        self.type_ = 0
        self.length = None
        self.subFields = []
        
    def readFieldLength(self, fileReader):
        """read Field Length"""
        length = fileReader.readBytesAsUint(4)
        if length & 0x80000000 > 0:
            length = length << 32
            length |= fileReader.readBytesAsUint(4)
        return length
        
    def findField(self, fieldType, startIndex=0):
        """find Field"""
        result = None
        index = startIndex
        
        for field in self.subFields[startIndex:]:
            if field.type_ == fieldType:
                result = field
                break
            index = index + 1
        return (result, index)
        
    def readableStr(self):
        """readable String"""
        return ""
    
    def traverse(self, handler, depth=0):
        """ traverse"""
        handler.handleField(self, depth)
        for field in self.subFields:
            field.traverse(handler, depth + 1)
        
class SISUnsupportedField(SISField):
    """ Class SIS UnsupportedField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialisation From File"""
        self.length = self.readFieldLength(fileReader)
        fileReader.readPlainBytes(self.length)

class SISStringField(SISField):
    """ Class SIS StringField """
    def __init__(self):
        SISField.__init__(self)
        self.data = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        buf = fileReader.readPlainBytes(self.length)
        self.data = u""
        while len(buf) > 0:
            temp = buf[:2]
            buf = buf[2:]
            self.data += unichr(ord(temp[0]) | ord(temp[1]) << 8)
        
    def readableStr(self):
        """readable String"""
        return self.data
        
class SISArrayField(SISField):
    """ Class SIS ArrayField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        type_ = fileReader.readBytesAsInt(4)
        l_len = self.length - 4
        while l_len > 0:
            field = SISFieldTypes[type_]()
            field.type_ = type_
            field.initFromFile(fileReader)
            self.subFields.append(field)
            
            l_len -= field.length + 4 # field length + the length field
            padding = fileReader.skipPadding()
            l_len -= padding

class SISCompressedField(SISField):
    """ Class SIS CompressedField """
    def __init__(self):
        SISField.__init__(self)
        self.algorithm = None
        self.uncompressedDataSize = None
        self.data = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        self.algorithm = fileReader.readBytesAsUint(4)
        self.uncompressedDataSize = fileReader.readBytesAsUint(8)
        data = fileReader.readPlainBytes(self.length - 4 - 8)
        if self.algorithm == 0:
            self.data = data
        elif self.algorithm == 1:
            self.data = zlib.decompress(data)
            
class SISVersionField(SISField):
    """ Class SIS VersionField """
    def __init__(self):
        SISField.__init__(self)
        self.version = (- 1, - 1, - 1)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        major = fileReader.readBytesAsInt(4)
        minor = fileReader.readBytesAsInt(4)
        build = fileReader.readBytesAsInt(4)
        self.version = (major, minor, build)
        
    def readableStr(self):
        """readable string"""
        return str(self.version)
    
class SISVersionRangeField(SISField):
    """ Class SIS VersionRangeField """
    def __init__(self):
        SISField.__init__(self)
        self.fromVersion = None
        self.toVersion = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.fromVersion = fieldParser.parseField(fileReader)
        if self.length - fieldParser.lastReadBytes > 0 :
            self.toVersion = fieldParser.parseField(fileReader)
    
class SISDateField(SISField):
    """ Class SIS DateField """
    def __init__(self):
        SISField.__init__(self)
        self.year = None
        self.month = None
        self.day = None
        
    def initFromFile(self, fileReader):
        """initialise from File"""
        self.length = self.readFieldLength(fileReader)
        self.year = fileReader.readBytesAsUint(2)
        self.month = fileReader.readBytesAsUint(1)
        self.day = fileReader.readBytesAsUint(1)
    
    def readableStr(self):
        """readable string"""
        return str(self.year) + "." + str(self.month) + "." + str(self.day)
    
class SISTimeField(SISField):
    """ Class SIS TimeField """
    def __init__(self):
        SISField.__init__(self)
        self.hours = None
        self.minutes = None
        self.seconds = None
        
    def initFromFile(self, fileReader):
        """initialise from File"""
        self.length = self.readFieldLength(fileReader)
        self.hours = fileReader.readBytesAsUint(1)
        self.minutes = fileReader.readBytesAsUint(1)
        self.seconds = fileReader.readBytesAsUint(1)
    
    def readableStr(self):
        """readable String"""
        return str(self.hours) + ":" + str(self.minutes) + ":" + str(self.seconds)
    
class SISDateTimeField(SISField):
    """ Class SIS DateTimeField """
    def __init__(self):
        SISField.__init__(self)
        self.date = None
        self.time = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.date = fieldParser.parseField(fileReader)
        self.time = fieldParser.parseField(fileReader)
    
class SISUidField(SISField):
    """ Class SIS UidField """
    def __init__(self):
        SISField.__init__(self)
        self.uid = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        self.uid = fileReader.readBytesAsUint(4)
        
    def readableStr(self):
        """readable String"""
        return hex(self.uid)
    
class SISLanguageField(SISField):
    """ Class SIS LanguageField """
    def __init__(self):
        SISField.__init__(self)
        self.language = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        self.language = fileReader.readBytesAsUint(4)
        
    def readableStr(self):
        """readable String"""
        return str(self.language)
    
class SISContentsField(SISField):
    """ Class SIS ContentsField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        field = fieldParser.parseField(fileReader)
        while field:
            if field.type_ == 3: # compressed<conroller>
                bufferReader = SISBufferReader(field.data)
                field = fieldParser.parseField(bufferReader)
            self.subFields.append(field)
            field = fieldParser.parseField(fileReader)

class SISControllerField(SISField):
    """ Class SIS ControllerField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        bufferReader = SISBufferReader(fileReader.readPlainBytes(self.length))
        field = fieldParser.parseField(bufferReader)
        while field:
            self.subFields.append(field)
            field = fieldParser.parseField(bufferReader)

class SISInfoField(SISField):
    """ Class SIS InfoField """
    def __init__(self):
        SISField.__init__(self)
        self.installType = None
        self.installFlags = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # UID
        self.subFields.append(fieldParser.parseField(fileReader)) # Vendor name unique
        self.subFields.append(fieldParser.parseField(fileReader)) # names
        self.subFields.append(fieldParser.parseField(fileReader)) # vendor names
        self.subFields.append(fieldParser.parseField(fileReader)) # version
        self.subFields.append(fieldParser.parseField(fileReader)) # creation time
        self.installType = fileReader.readBytesAsUint(1)
        self.installFlags = fileReader.readBytesAsUint(1) 
            
class SISSupportedLanguagesField(SISField):
    """ Class SISSupportedLanguagesField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # languages
        
class SISSupportedOptionsField(SISField):
    """ Class SISSupportedOptionsField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # options
            
class SISPrerequisitiesField(SISField):
    """ Class SISPrerequisitiesField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # target devices
        self.subFields.append(fieldParser.parseField(fileReader)) # dependencies
        
        
class SISDependencyField(SISField):
    """ Class SISDependencyField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # UID
        field = fieldParser.parseField(fileReader)
        # Version range field is optional
        if field.type_ == VersionRangeField:
            self.subFields.append(field) # version range
            self.subFields.append(fieldParser.parseField(fileReader)) # dependency names
        else:
            self.subFields.append(field) # dependency names
    
class SISPropertiesField(SISField):
    """ Class SISPropertiesField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # properties
    
class SISPropertyField(SISField):
    """ Class SISPropertyField """
    def __init__(self):
        SISField.__init__(self)
        self.key = None
        self.value = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        self.key = fileReader.readBytesAsInt(4)
        self.value = fileReader.readBytesAsInt(4)
    
class SISSignaturesField(SISUnsupportedField):
    """ Class SISSignaturesField There is a type for this field, but there is no definition of the field contents"""
    pass
    
class SISCertificateChainField(SISField):
    """ Class SISCertificateChainField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # certificate data
    
class SISLogoField(SISField):
    """ Class SISLogoField """
    def __init__(self):
        SISField.__init__(self)

    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # logo file
    
class SISFileDescriptionField(SISField):
    """ Class SISFileDescriptionField """
    def __init__(self):
        SISField.__init__(self)
        self.operation = None
        self.operationOptions = None
        self.compressedLength = None
        self.uncompressedLength = None
        self.fileIndex = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        
        self.subFields.append(fieldParser.parseField(fileReader))
        self.subFields.append(fieldParser.parseField(fileReader))
        field = fieldParser.parseField(fileReader)
        self.subFields.append(field)
        if field.type_ == 41: # read field was capabilities ==> there is one more field left
            self.subFields.append(fieldParser.parseField(fileReader))
        
        self.operation = fileReader.readBytesAsUint(4)
        self.operationOptions = fileReader.readBytesAsUint(4)
        self.compressedLength = fileReader.readBytesAsUint(8)
        self.uncompressedLength = fileReader.readBytesAsUint(8)
        self.fileIndex = fileReader.readBytesAsUint(4)
        
    def readableStr(self):
        """readable string"""
        return "index: " + str(self.fileIndex)
    
class SISHashField(SISField):
    """ Class SISHashField """
    def __init__(self):
        SISField.__init__(self)
        self.algorithm = None

    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.algorithm = fileReader.readBytesAsUint(4)
        self.subFields.append(fieldParser.parseField(fileReader)) # logo file
    
class SISIfField(SISField):
    """ Class SISIfField """
    def __init__(self):
        SISField.__init__(self)

    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # expression
        self.subFields.append(fieldParser.parseField(fileReader)) # install block
        self.subFields.append(fieldParser.parseField(fileReader)) # else ifs

class SISElseIfField(SISField):
    """ Class SISElseIfField """
    def __init__(self):
        SISField.__init__(self)

    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # expression
        self.subFields.append(fieldParser.parseField(fileReader)) # install block
    
class SISInstallBlockField(SISField):
    """ Class SISInstallBlockField """
    def __init__(self):
        SISField.__init__(self)
        self.files = None
        self.embeddedSISFiles = None
        self.ifBlocks = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader))
        self.subFields.append(fieldParser.parseField(fileReader))
        self.subFields.append(fieldParser.parseField(fileReader))

class SISExpressionField(SISField):
    """ Class SISExpressionField """
    def __init__(self):
        SISField.__init__(self)
        self.operator = None
        self.integerValue = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.operator = fileReader.readBytesAsUint(4)
        self.integerValue = fileReader.readBytesAsInt(4)
        
        if self.operator == 10 or self.operator == 13:
            self.subFields.append(fieldParser.parseField(fileReader))
        if self.operator == 1 or self.operator == 2 or self.operator == 3 or self.operator == 4 or self.operator == 5 or self.operator == 6 or self.operator == 7 or self.operator == 8 or self.operator == 11 or self.operator == 12:
            self.subFields.append(fieldParser.parseField(fileReader))
        if not (self.operator == 13 or self.operator == 14 or self.operator == 15 or self.operator == 16 or self.operator == 10):
            self.subFields.append(fieldParser.parseField(fileReader))
        
class SISDataField(SISField):
    """ Class SISDataField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # data units
    
class SISDataUnitField(SISField):
    """ Class SISDataUnitField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # file data
    
class SISFileDataField(SISField):
    """ Class SISFileDataField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # raw file data
    
class SISSupportedOptionField(SISField):
    """ Class SISSupportedOptionField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # names
    
class SISControllerChecksumField(SISField):
    """ Class SISControllerChecksumField """
    def __init__(self):
        SISField.__init__(self)
        self.checksum = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        self.checksum = fileReader.readBytesAsUint(2)
    
class SISDataChecksumField(SISField):
    """ Class SISDataChecksumField """
    def __init__(self):
        SISField.__init__(self)
        self.checksum = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        self.checksum = fileReader.readBytesAsUint(2)
    
class SISSignatureField(SISField):
    """ Class SISSignatureField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # signature algorithm
        self.subFields.append(fieldParser.parseField(fileReader)) # signature data
    
class SISBlobField(SISField):
    """ Class SISBlobField """ 
    def __init__(self):
        SISField.__init__(self)
        self.data = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        self.data = fileReader.readPlainBytes(self.length)
    
class SISSignatureAlgorithmField(SISField):
    """ Class SISSignatureAlgorithmField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # algorithm identifier
    
class SISSignatureCertificateChainField(SISField):
    """ Class SISSignatureCertificateChainField """
    def __init__(self):
        SISField.__init__(self)
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # signatures
        self.subFields.append(fieldParser.parseField(fileReader)) # certificate chain
    
class SISDataIndexField(SISField):
    """ Class SISDataIndexField """
    def __init__(self):
        SISField.__init__(self)
        self.dataIndex = None
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        self.dataIndex = fileReader.readBytesAsUint(4)

class SISCapabilitiesField(SISField):
    """ Class SISCapabilitiesField """
    def __init__(self):
        SISField.__init__(self)
        self.capabilities = 0
        self.readableCaps = []
        
    def initFromFile(self, fileReader):
        """initialise From File"""
        self.length = self.readFieldLength(fileReader)
        self.capabilities = fileReader.readBytesAsUint(self.length)
        
        for i in range(20):
            if (self.capabilities >> i) & 0x01:
                self.readableCaps.append(CapabilityNames[i])
                
    def readableStr(self):
        """readable string"""
        return " ".join(self.readableCaps)
    
SISFieldTypes = { 
    1: SISStringField,
    2: SISArrayField,
    3: SISCompressedField,
    4: SISVersionField,
    5: SISVersionRangeField,
    6: SISDateField,
    7: SISTimeField,
    8: SISDateTimeField,
    9: SISUidField,
    10: SISUnsupportedField,
    11: SISLanguageField,
    12: SISContentsField,
    13: SISControllerField,
    14: SISInfoField,
    15: SISSupportedLanguagesField,
    16: SISSupportedOptionsField,
    17: SISPrerequisitiesField,
    18: SISDependencyField,
    19: SISPropertiesField,
    20: SISPropertyField,
    21: SISSignaturesField,
    22: SISCertificateChainField,
    23: SISLogoField,
    24: SISFileDescriptionField,
    25: SISHashField,
    26: SISIfField,
    27: SISElseIfField,
    28: SISInstallBlockField,
    29: SISExpressionField,
    30: SISDataField,
    31: SISDataUnitField,
    32: SISFileDataField,
    33: SISSupportedOptionField,
    34: SISControllerChecksumField,
    35: SISDataChecksumField,
    36: SISSignatureField,
    37: SISBlobField,
    38: SISSignatureAlgorithmField,
    39: SISSignatureCertificateChainField,
    40: SISDataIndexField,
    41: SISCapabilitiesField
    }

[StringField,
 ArrayField,
 CompressedField,
 VersionField,
 VersionRangeField,
 DateField,
 TimeField,
 DateTimeField,
 UidField,
 UnusedField,
 LanguageField,
 ContentsField,
 ControllerField,
 InfoField,
 SupportedLanguagesField,
 SupportedOptionsField,
 PrerequisitiesField,
 DependencyField,
 PropertiesField,
 PropertyField,
 SignaturesField,
 CertificateChainField,
 LogoField,
 FileDescriptionField,
 HashField,
 IfField,
 ElseIfField,
 InstallBlockField,
 ExpressionField,
 DataField,
 DataUnitField,
 FileDataField,
 SupportedOptionField,
 ControllerChecksumField,
 DataChecksumField,
 SignatureField,
 BlobField,
 SignatureAlgorithmField,
 SignatureCertificateChainField,
 DataIndexField,
 CapabilitiesField] = range(1, 42)
     
FieldNames = {
 0: "ROOT",
 StringField: "StringField",
 ArrayField: "ArrayField",
 CompressedField: "CompressedField",
 VersionField: "VersionField",
 VersionRangeField: "VersionRangeField",
 DateField: "DateField",
 TimeField: "TimeField",
 DateTimeField: "DateTimeField",
 UidField: "UidField",
 UnusedField: "UnusedField",
 LanguageField: "LanguageField",
 ContentsField: "ContentsField",
 ControllerField: "ControllerField",
 InfoField: "InfoField",
 SupportedLanguagesField: "SupportedLanguagesField",
 SupportedOptionsField: "SupportedOptionsField",
 PrerequisitiesField: "PrerequisitiesField",
 DependencyField: "DependencyField",
 PropertiesField: "PropertiesField",
 PropertyField: "PropertyField",
 SignaturesField: "SignaturesField",
 CertificateChainField: "CertificateChainField",
 LogoField: "LogoField",
 FileDescriptionField: "FileDescriptionField",
 HashField: "HashField",
 IfField: "IfField",
 ElseIfField: "ElseIfField",
 InstallBlockField: "InstallBlockField",
 ExpressionField: "ExpressionField",
 DataField: "DataField",
 DataUnitField: "DataUnitField",
 FileDataField: "FileDataField",
 SupportedOptionField: "SupportedOptionField",
 ControllerChecksumField: "ControllerChecksumField",
 DataChecksumField: "DataChecksumField",
 SignatureField: "SignatureField",
 BlobField: "BlobField",
 SignatureAlgorithmField: "SignatureAlgorithmField",
 SignatureCertificateChainField: "SignatureCertificateChainField",
 DataIndexField: "DataIndexField",
 CapabilitiesField: "CapabilitiesField"
}
     
CapabilityNames = {
    0: "TCB",
    1: "CommDD",
    2: "PowerMgmt",
    3: "MultimediaDD",
    4: "ReadDeviceData",
    5: "WriteDeviceData",
    6: "DRM",
    7: "TrustedUI",
    8: "ProtServ",
    9: "DiskAdmin",
    10: "NetworkControl",
    11: "AllFiles",
    12: "SwEvent",
    13: "NetworkServices",
    14: "LocalServices",
    15: "ReadUserData",
    16: "WriteUserData",
    17: "Location",
    18: "SurroundingsDD",
    19: "UserEnvironment"
    }

InstallTypes = {
    0: "SA",
    1: "SP",
    2: "PU",
    3: "PA",
    4: "PP"
    }
    
class SISReader:
    """ SIS Reader """
    def __init__(self):
        self.bytesRead = 0
        
    def readUnsignedBytes(self, numBytes):
        """read Unsigned bytes"""
        buf = self.readPlainBytes(numBytes)
        if len(buf) < numBytes:
            return []
            
        format_ = ""
        for _ in range(numBytes):
            format_ += "B"
        return struct.unpack(format_, buf)
    
    def readSignedBytes(self, numBytes):
        """read signed bytes"""
        buf = self.readPlainBytes(numBytes)
        if len(buf) < numBytes:
            return []
            
        format_ = ""
        for _ in range(numBytes):
            format_ += "b"
        return struct.unpack(format_, buf)
        
    def readBytesAsUint(self, numBytes):
        """read bytes as Unit"""
        result = 0
        bytes_ = self.readUnsignedBytes(numBytes)
        if len(bytes_) == numBytes:
            for i_byte in range(numBytes):
                result |= bytes_[i_byte] << (i_byte * 8)
        
        return result
        
    def readBytesAsInt(self, numBytes):
        """read bytes as Integer"""
        result = 0
        bytes_ = self.readSignedBytes(numBytes)
        if len(bytes_) == numBytes:
            for i_byte in range(numBytes):
                result |= bytes_[i_byte] << (i_byte * 8)
        
        return result
        
    def skipPadding(self):
        """skip padding"""
        result = 0
        if self.bytesRead % 4 != 0:
            paddingLength = 4 - self.bytesRead % 4
            self.readPlainBytes(paddingLength)
            result = paddingLength
            
        return result

    def readPlainBytes(self, numBytes):
        """read plain bytes"""
        pass

class SISFileReader(SISReader): 
    """ SIS File Reader """
    def __init__(self, inStream):
        SISReader.__init__(self)
        self.inStream = inStream
        self.eof = False
        self.bytesRead = 0

    def readPlainBytes(self, numBytes):
        """read Plain byytes"""
        if self.eof:
            return ""
            
        if numBytes == 0:
            return ""
            
        buf = ""
        buf = self.inStream.read(numBytes)
        if len(buf) < numBytes:
            self.eof = True
            return ""
            
        self.bytesRead += numBytes
        
        return buf

    def isEof(self):
        """is it End of File"""
        return self.eof
        
class SISBufferReader(SISReader):
    """ SIS Buffer reader """
    def __init__(self, buffer_):
        SISReader.__init__(self)
        self.buffer_ = buffer_
        self.bytesRead = 0
        
    def readPlainBytes(self, numBytes):
        """read Plain bytes"""
        if self.isEof():
            return ""
            
        if numBytes == 0:
            return ""
            
        result = self.buffer_[self.bytesRead:self.bytesRead + numBytes]
            
        self.bytesRead += numBytes
        
        return result
            
    def isEof(self):
        """is it End of File"""
        return self.bytesRead >= len(self.buffer_)
        
class SISFieldParser:
    """ Parser to read a SIS field """
    def __init__(self):
        self.lastReadBytes = 0
        
    def parseField(self, fileReader):
        """Reads the next field from the fileReader stream and returns it"""
        field = None
        self.lastReadBytes = 0
        type_ = fileReader.readBytesAsUint(4)
        self.lastReadBytes += 4
        if type_ != 0:
            field = SISFieldTypes[type_]()
            field.type_ = type_
            field.initFromFile(fileReader)
            self.lastReadBytes += field.length + 4 # Field length + length field
            self.lastReadBytes += fileReader.skipPadding()
        return field

class SISInfo(SISField):
    """ SIS file information """
    def __init__(self):
        SISField.__init__(self)
        self.fin = None
        self.fileHeader = SISFileHeader()
        
    def parse(self, filename):
        """parse"""
        fin = open(filename, 'rb')
        fileReader = SISFileReader(fin)
        self.parseHeader(fileReader)
        self.parseSISFields(fileReader)
        
    def parseHeader(self, fileReader):
        """parse Holder"""
        self.fileHeader.uid1 = fileReader.readBytesAsUint(4)
        self.fileHeader.uid2 = fileReader.readBytesAsUint(4)
        self.fileHeader.uid3 = fileReader.readBytesAsUint(4)
        self.fileHeader.uidChecksum = fileReader.readBytesAsUint(4)
        
    def parseSISFields(self, fileReader):
        """parse SIS Fileds"""
        parser = SISFieldParser()
        while not fileReader.isEof():
            self.subFields.append(parser.parseField(fileReader))

class Handler:
    """ A handler class """
    def __init__(self):
        self.files = []
        self.fileDatas = []
        self.signatureCertificateChains = []
        
    def handleField(self, field, _):
        """handle Field"""
        if field.type_ == FileDescriptionField:
            self.files.append(field)
        elif field.type_ == FileDataField:
            self.fileDatas.append(field)
        elif field.type_ == SignatureCertificateChainField :
            self.signatureCertificateChains.append(field)

    def execute(self, options):
        """execute"""
        for f_file in self.files:
            if options.info:
                buf = "   " + f_file.findField(StringField)[0].readableStr()
                caps = f_file.findField(CapabilitiesField)[0]
                if caps:
                    buf += " [" + " ".join(f_file.findField(CapabilitiesField)[0].readableCaps) + "]"
                print buf
            if options.extract:
                parts = f_file.findField(StringField)[0].readableStr().split("\\")
                if len(parts[len(parts) - 1]) > 0:
                    path = os.path.abspath(options.extract)
                    path += os.sep + os.sep.join(parts[1: - 1])
                    if not os.path.exists(path):
                        os.makedirs(path)
                    newFile = file(path + os.sep + parts[len(parts) - 1], "wb")
                    newFile.write(self.fileDatas[f_file.fileIndex].findField(CompressedField)[0].data)
                    newFile.close()
        for sig in self.signatureCertificateChains:
            if options.certificate:
                buf = sig.findField(CertificateChainField)[0].subFields[0].data
                print "Certificate chain:"
                i_num = 1
                while len(buf) > 0:
                    print "   Certificate " + str(i_num) + ":"
                    i_num += 1
                    decoded = decoder.decode(buf)
                    cer = CertificateInfo()
                    cer.parse(decoded[0])
                    readableStr = cer.readableStr()
                    print "      " + "\n      ".join(readableStr.split('\n'))
                    buf = decoded[1]
            
class ContentPrinter:
    """ A handler class which prints the field contents """
    def __init__(self):
        pass
        
    def handleField(self, field, depth):
        """handle Field"""
        buf = ""
        for _ in range(depth):
            buf += "  "
        buf += FieldNames[field.type_] + " "
        if len(field.readableStr()) > 0:
            buf += field.readableStr()
        print buf

class IADHandler:
    """ IAD handler class """
    def __init__(self):
        self.packageVersion = (0, 0, 0)
        self.packageUid = 0
        self.vendorName = ""
        self.packageNames = []
        self.packageNamesFields = []
        self.languages = []
        self.platformDependencies = []
        self.packageDependencies = []
        self.installType = 0
        self.installFlags = 0
        self.packageVersionField = None
        self.packageUidField = None
        self.vendorNameField = None
        
    def handleDependency(self, field):
        """handle dependancy"""
        dep = [0, - 1, - 1, - 1, - 1, - 1, - 1]
        dep[0] = field.subFields[0].uid
        if field.subFields[1] and field.subFields[1].type_ == VersionRangeField:
            res = field.subFields[1]
            if res.fromVersion != None:
                dep[1] = res.fromVersion.version[0]
                dep[2] = res.fromVersion.version[1]
                dep[3] = res.fromVersion.version[2]
            if res.toVersion != None:
                dep[4] = res.toVersion.version[0]
                dep[5] = res.toVersion.version[1]
                dep[6] = res.toVersion.version[2]
        return dep
        
    def handleField(self, field, _):
        """handle Field"""
        if field.type_ == InfoField:
            self.packageVersion = field.subFields[4].version
            self.packageVersionField = field.subFields[4]
            self.packageUid = field.subFields[0].uid
            self.packageUidField = field.subFields[0]
            self.vendorName = field.subFields[1].data
            self.vendorNameField = field.subFields[1]
            self.installType = field.installType
            self.installFlags = field.installFlags
            for name in field.subFields[2].subFields:
                self.packageNames.append(name.data)
        elif field.type_ == LanguageField:
            self.languages.append(field.language)
        elif field.type_ == PrerequisitiesField:
            for f_field in field.subFields[0].subFields:
                dependency = self.handleDependency(f_field)
                self.platformDependencies.append(dependency)
            for f_field in field.subFields[1].subFields:
                dependency = self.handleDependency(f_field)
                self.packageDependencies.append(dependency)
        
    def getInfo (self, fileName):
        """get Info"""
        sisInfo = SISInfo()
        sisInfo.parse(fileName)
        handler = IADHandler()
        sisInfo.traverse(handler)
        info = "<sisinfo>\n" \
             + "  <uid>" + hex(handler.packageUid) + "</uid>\n" \
             + "  <vendor>" + handler.vendorName + "</vendor>\n" \
             + "  <version>" \
             + "<major>" + repr(handler.packageVersion[0]) + "</major>" \
             + "<minor>" + repr(handler.packageVersion[1]) + "</minor>" \
             + "<build>" + repr(handler.packageVersion[2]) + "</build>" \
             + "</version>\n" \
             + "  <type>" + InstallTypes[self.installType] + "</type>\n"
        for num, name in enumerate(handler.packageNames):
            info += "  <name language='" + repr(handler.languages[num]) + "'>" + name + "</name>\n"
        for language in handler.languages:
            info += "  <language>" + repr(language) + "</language>\n"
        for platDep in handler.platformDependencies:
            info += "  <platform_dependency><uid>" + hex(platDep[0]) + "</uid>\n"
            info += "    <from>" \
                 + "<major>" + repr(platDep[1]) + "</major>" \
                 + "<minor>" + repr(platDep[2]) + "</minor>"
#           info += "<build>" + repr(platDep[3]) + "</build>"
            info += "</from>\n    <to>" \
                 + "<major>" + repr(platDep[4]) + "</major>" \
                 + "<minor>" + repr(platDep[5]) + "</minor>"
#           info += "<build>" + repr(platDep[6]) + "</build>"
            info += "</to>\n" \
             + "  </platform_dependency>\n"
        for packageDep in handler.packageDependencies:
            info += "  <package_dependency><uid>" + hex(packageDep[0]) + "</uid>\n"
            info += "    <from>" \
                 + "<major>" + repr(packageDep[1]) + "</major>" \
                 + "<minor>" + repr(packageDep[2]) + "</minor>"
#           info += "<build>" + repr(packageDep[3]) + "</build>"
            info += "</from>\n    <to>" \
                 + "<major>" + repr(packageDep[4]) + "</major>" \
                 + "<minor>" + repr(packageDep[5]) + "</minor>"
#           info += "<build>" + repr(packageDep[6]) + "</build>"
            info += "</to>\n" \
                 + "  </package_dependency>\n"
        info += "</sisinfo>\n"
        return info

if __name__ == "__main__":
    _handler = IADHandler()
    print (_handler.getInfo (sys.argv[1]))
