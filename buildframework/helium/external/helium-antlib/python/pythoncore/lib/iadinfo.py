#============================================================================ 
#Name        : iadinfo.py 
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

import optparse
import sys, os
import struct
import zlib
import pdb
    
PyASN1Availabe = True

try :
    from pyasn1.codec.der import decoder
    from pyasn1.type import univ, base
except :
    PyASN1Availabe = False

def _findItem(item, itemParent, index, objectIdentifier) :
    if isinstance(item, base.AbstractSimpleAsn1Item) :
        if item == objectIdentifier :
            return itemParent[index + 1]
    else:
        for i in range(len(item)) :
            found = _findItem(item[i], item, i, objectIdentifier)
            if found: 
                return found

def findItem(decodedCert, objectIdentifier) :
    return _findItem(decodedCert, None, 0, objectIdentifier)


class CertificateOrganization :
    def __init__(self) :
        pass
    
    def parse(self, decodedCert) :
        self.commonName = findItem(decodedCert, (2, 5, 4, 3))
        self.countryCode = findItem(decodedCert, (2, 5, 4, 6))
        self.locality = findItem(decodedCert, (2, 5, 4, 7))
        self.state = findItem(decodedCert, (2, 5, 4, 8))
        self.street = findItem(decodedCert, (2, 5, 4, 9))
        self.organization = findItem(decodedCert, (2, 5, 4, 10))

    def readableStr(self) :
        buf = ""
        if self.commonName :
            buf += self.commonName.prettyPrint() + "\n"
        if self.countryCode :
            buf += self.countryCode.prettyPrint() + "\n"
        if self.locality :
            buf += self.locality.prettyPrint() + "\n"
        if self.state :
            buf += self.state.prettyPrint() + "\n"
        if self.street :
            buf += self.street.prettyPrint() + "\n"
        if self.organization :
            buf += self.organization.prettyPrint()
        return buf

class CertificateInfo :
    def __init__(self) :
        pass
        
    def parse(self, decodedCert) :
        self.issuer = CertificateOrganization()
        self.issuer.parse(decodedCert[0][3])
        
        self.signer = CertificateOrganization()
        self.signer.parse(decodedCert[0][5])
        
    def readableStr(self) :
        buf = "Signer:\n      " + "\n      ".join(self.signer.readableStr().split('\n')) + "\n"
        buf += "Issuer:\n      " + "\n      ".join(self.issuer.readableStr().split('\n')) + "\n"
        return buf
            

class SISFileHeader :
    def __init__(self) :
        self.uid1 = 0
        self.uid2 = 0
        self.uid3 = 0
        self.uidChecksum = 0

class SISField :
    def __init__(self) :
        self.type = 0
        self.length = None
        self.subFields = []
        
    def readFieldLength(self, fileReader) :
        length = fileReader.readBytesAsUint(4)
        if length & 0x80000000 > 0 :
            length = length << 32
            length |= fileReader.readBytesAsUint(4)
        return length
        
    def findField(self, fieldType, startIndex=0) :
        result = None
        index = startIndex
        
        for field in self.subFields[startIndex:] :
            if field.type == fieldType :
                result = field
                break
            ++ index
        return (result, index)
        
    def readableStr(self) :
        return ""
    
    def traverse(self, handler, depth=0) :
        handler.handleField(self, depth)
        for field in self.subFields :
            field.traverse(handler, depth + 1)
        
class SISUnsupportedField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fileReader.readPlainBytes(self.length)

class SISStringField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.data = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        buf = fileReader.readPlainBytes(self.length)
        self.data = u""
        while len(buf) > 0 :
            temp = buf[:2]
            buf = buf[2:]
            self.data += unichr(ord(temp[0]) | ord(temp[1]) << 8)
        
    def readableStr(self) :
        return self.data
        
class SISArrayField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        type = fileReader.readBytesAsInt(4)
        l = self.length - 4
        while l > 0 :
            field = SISFieldTypes[type]()
            field.type = type
            field.initFromFile(fileReader)
            self.subFields.append(field)
            
            l -= field.length + 4 # field length + the length field
            padding = fileReader.skipPadding()
            l -= padding

class SISCompressedField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.algorithm = None
        self.uncompressedDataSize = None
        self.data = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.algorithm = fileReader.readBytesAsUint(4)
        self.uncompressedDataSize = fileReader.readBytesAsUint(8)
        data = fileReader.readPlainBytes(self.length - 4 - 8)
        if self.algorithm == 0 :
            self.data = data
        elif self.algorithm == 1 :
            self.data = zlib.decompress(data)
            
class SISVersionField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.version = (- 1, - 1, - 1)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        major = fileReader.readBytesAsInt(4)
        minor = fileReader.readBytesAsInt(4)
        build = fileReader.readBytesAsInt(4)
        self.version = (major, minor, build)
        
    def readableStr(self) :
        return str(self.version)
    
class SISVersionRangeField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.fromVersion = None
        self.toVersion = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.fromVersion = fieldParser.parseField(fileReader)
        if self.length - fieldParser.lastReadBytes > 0  :
            self.toVersion = fieldParser.parseField(fileReader)
    
class SISDateField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.year = None
        self.month = None
        self.day = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.year = fileReader.readBytesAsUint(2)
        self.month = fileReader.readBytesAsUint(1)
        self.day = fileReader.readBytesAsUint(1)
    
    def readableStr(self) :
        return str(self.year) + "." + str(self.month) + "." + str(self.day)
    
class SISTimeField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.hours = None
        self.minutes = None
        self.seconds = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.hours = fileReader.readBytesAsUint(1)
        self.minutes = fileReader.readBytesAsUint(1)
        self.seconds = fileReader.readBytesAsUint(1)
    
    def readableStr(self) :
        return str(self.hours) + ":" + str(self.minutes) + ":" + str(self.seconds)
    
class SISDateTimeField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.date = None
        self.time = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.date = fieldParser.parseField(fileReader)
        self.time = fieldParser.parseField(fileReader)
    
class SISUidField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.uid = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.uid = fileReader.readBytesAsUint(4)
        
    def readableStr(self) :
        return hex(self.uid)
    
class SISLanguageField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.language = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.language = fileReader.readBytesAsUint(4)
        
    def readableStr(self) :
        return str(self.language)
    
class SISContentsField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        field = fieldParser.parseField(fileReader)
        while field :
            if field.type == 3 : # compressed<conroller>
                bufferReader = SISBufferReader(field.data)
                field = fieldParser.parseField(bufferReader)
            self.subFields.append(field)
            field = fieldParser.parseField(fileReader)

class SISControllerField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        bufferReader = SISBufferReader(fileReader.readPlainBytes(self.length))
        field = fieldParser.parseField(bufferReader)
        while field :
            self.subFields.append(field)
            field = fieldParser.parseField(bufferReader)

class SISInfoField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.installType = None
        self.installFlags = None
        
    def initFromFile(self, fileReader) :
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
            
class SISSupportedLanguagesField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # languages
        
class SISSupportedOptionsField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # options
            
class SISPrerequisitiesField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # target devices
        self.subFields.append(fieldParser.parseField(fileReader)) # dependencies
        
        
class SISDependencyField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # UID
        field = fieldParser.parseField(fileReader)
        # Version range field is optional
        if field.type == VersionRangeField :
            self.subFields.append(field) # version range
            self.subFields.append(fieldParser.parseField(fileReader)) # dependency names
        else :
            self.subFields.append(field) # dependency names
    
class SISPropertiesField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # properties
    
class SISPropertyField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.key = None
        self.value = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.key = fileReader.readBytesAsInt(4)
        self.value = fileReader.readBytesAsInt(4)
    
# There is a type for this field, but there is no definition of the field contents
class SISSignaturesField(SISUnsupportedField) :
    pass
    
class SISCertificateChainField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # certificate data
    
class SISLogoField(SISField) :
    def __init__(self) :
        SISField.__init__(self)

    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # logo file
    
class SISFileDescriptionField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.operation = None
        self.operationOptions = None
        self.compressedLength = None
        self.uncompressedLength = None
        self.fileIndex = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        
        self.subFields.append(fieldParser.parseField(fileReader))
        self.subFields.append(fieldParser.parseField(fileReader))
        field = fieldParser.parseField(fileReader)
        self.subFields.append(field)
        if field.type == 41 : # read field was capabilities ==> there is one more field left
            self.subFields.append(fieldParser.parseField(fileReader))
        
        self.operation = fileReader.readBytesAsUint(4)
        self.operationOptions = fileReader.readBytesAsUint(4)
        self.compressedLength = fileReader.readBytesAsUint(8)
        self.uncompressedLength = fileReader.readBytesAsUint(8)
        self.fileIndex = fileReader.readBytesAsUint(4)
        
    def readableStr(self) :
        return "index: " + str(self.fileIndex)
    
class SISHashField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.algorithm = None

    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.algorithm = fileReader.readBytesAsUint(4)
        self.subFields.append(fieldParser.parseField(fileReader)) # logo file
    
class SISIfField(SISField) :
    def __init__(self) :
        SISField.__init__(self)

    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # expression
        self.subFields.append(fieldParser.parseField(fileReader)) # install block
        self.subFields.append(fieldParser.parseField(fileReader)) # else ifs

class SISElseIfField(SISField) :
    def __init__(self) :
        SISField.__init__(self)

    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # expression
        self.subFields.append(fieldParser.parseField(fileReader)) # install block
    
class SISInstallBlockField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.files = None
        self.embeddedSISFiles = None
        self.ifBlocks = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader))
        self.subFields.append(fieldParser.parseField(fileReader))
        self.subFields.append(fieldParser.parseField(fileReader))

class SISExpressionField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.operator = None
        self.integerValue = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.operator = fileReader.readBytesAsUint(4)
        self.integerValue = fileReader.readBytesAsInt(4)
        
        if self.operator == 10 or self.operator == 13 :
            self.subFields.append(fieldParser.parseField(fileReader))
        if self.operator == 1 or self.operator == 2 or self.operator == 3 or self.operator == 4 or self.operator == 5 or self.operator == 6 or self.operator == 7 or self.operator == 8 or self.operator == 11 or self.operator == 12 :
            self.subFields.append(fieldParser.parseField(fileReader))
        if not (self.operator == 13 or self.operator == 14 or self.operator == 15 or self.operator == 16 or self.operator == 10) :
            self.subFields.append(fieldParser.parseField(fileReader))
        
class SISDataField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # data units
    
class SISDataUnitField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # file data
    
class SISFileDataField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # raw file data
    
class SISSupportedOptionField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # names
    
class SISControllerChecksumField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.checksum = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.checksum = fileReader.readBytesAsUint(2)
    
class SISDataChecksumField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.checksum = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.checksum = fileReader.readBytesAsUint(2)
    
class SISSignatureField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # signature algorithm
        self.subFields.append(fieldParser.parseField(fileReader)) # signature data
    
class SISBlobField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.data = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.data = fileReader.readPlainBytes(self.length)
    
class SISSignatureAlgorithmField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # algorithm identifier
    
class SISSignatureCertificateChainField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        fieldParser = SISFieldParser()
        self.subFields.append(fieldParser.parseField(fileReader)) # signatures
        self.subFields.append(fieldParser.parseField(fileReader)) # certificate chain
    
class SISDataIndexField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.dataIndex = None
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.dataIndex = fileReader.readBytesAsUint(4)

class SISCapabilitiesField(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.capabilities = 0
        self.readableCaps = []
        
    def initFromFile(self, fileReader) :
        self.length = self.readFieldLength(fileReader)
        self.capabilities = fileReader.readBytesAsUint(self.length)
        
        for i in range(20) :
            if (self.capabilities >> i) & 0x01 :
                self.readableCaps.append(CapabilityNames[i])
                
    def readableStr(self) :
        return " ".join(self.readableCaps)
    
SISFieldTypes = { 
    1 : SISStringField,
    2 : SISArrayField,
    3 : SISCompressedField,
    4 : SISVersionField,
    5 : SISVersionRangeField,
    6 : SISDateField,
    7 : SISTimeField,
    8 : SISDateTimeField,
    9 : SISUidField,
    10 : SISUnsupportedField,
    11 : SISLanguageField,
    12 : SISContentsField,
    13 : SISControllerField,
    14 : SISInfoField,
    15 : SISSupportedLanguagesField,
    16 : SISSupportedOptionsField,
    17 : SISPrerequisitiesField,
    18 : SISDependencyField,
    19 : SISPropertiesField,
    20 : SISPropertyField,
    21 : SISSignaturesField,
    22 : SISCertificateChainField,
    23 : SISLogoField,
    24 : SISFileDescriptionField,
    25 : SISHashField,
    26 : SISIfField,
    27 : SISElseIfField,
    28 : SISInstallBlockField,
    29 : SISExpressionField,
    30 : SISDataField,
    31 : SISDataUnitField,
    32 : SISFileDataField,
    33 : SISSupportedOptionField,
    34 : SISControllerChecksumField,
    35 : SISDataChecksumField,
    36 : SISSignatureField,
    37 : SISBlobField,
    38 : SISSignatureAlgorithmField,
    39 : SISSignatureCertificateChainField,
    40 : SISDataIndexField,
    41 : SISCapabilitiesField
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
 0 : "ROOT",
 StringField : "StringField",
 ArrayField : "ArrayField",
 CompressedField : "CompressedField",
 VersionField : "VersionField",
 VersionRangeField : "VersionRangeField",
 DateField : "DateField",
 TimeField : "TimeField",
 DateTimeField : "DateTimeField",
 UidField : "UidField",
 UnusedField : "UnusedField",
 LanguageField : "LanguageField",
 ContentsField : "ContentsField",
 ControllerField : "ControllerField",
 InfoField : "InfoField",
 SupportedLanguagesField : "SupportedLanguagesField",
 SupportedOptionsField : "SupportedOptionsField",
 PrerequisitiesField : "PrerequisitiesField",
 DependencyField : "DependencyField",
 PropertiesField : "PropertiesField",
 PropertyField : "PropertyField",
 SignaturesField : "SignaturesField",
 CertificateChainField : "CertificateChainField",
 LogoField : "LogoField",
 FileDescriptionField : "FileDescriptionField",
 HashField : "HashField",
 IfField : "IfField",
 ElseIfField : "ElseIfField",
 InstallBlockField : "InstallBlockField",
 ExpressionField : "ExpressionField",
 DataField : "DataField",
 DataUnitField : "DataUnitField",
 FileDataField : "FileDataField",
 SupportedOptionField : "SupportedOptionField",
 ControllerChecksumField : "ControllerChecksumField",
 DataChecksumField : "DataChecksumField",
 SignatureField : "SignatureField",
 BlobField : "BlobField",
 SignatureAlgorithmField : "SignatureAlgorithmField",
 SignatureCertificateChainField : "SignatureCertificateChainField",
 DataIndexField : "DataIndexField",
 CapabilitiesField : "CapabilitiesField"
}
     
CapabilityNames = {
    0 : "TCB",
    1 : "CommDD",
    2 : "PowerMgmt",
    3 : "MultimediaDD",
    4 : "ReadDeviceData",
    5 : "WriteDeviceData",
    6 : "DRM",
    7 : "TrustedUI",
    8 : "ProtServ",
    9 : "DiskAdmin",
    10 : "NetworkControl",
    11 : "AllFiles",
    12 : "SwEvent",
    13 : "NetworkServices",
    14 : "LocalServices",
    15 : "ReadUserData",
    16 : "WriteUserData",
    17 : "Location",
    18 : "SurroundingsDD",
    19 : "UserEnvironment"
    }

InstallTypes = {
    0: "SA",
    1: "SP",
    2: "PU",
    3: "PA",
    4: "PP"
    }
    
class SISReader :
    def __init__(self) :
        self.bytesRead = 0
        
    def readUnsignedBytes(self, numBytes) :
        buf = self.readPlainBytes(numBytes)
        if len(buf) < numBytes :
            return []
            
        format = ""
        for i in range(numBytes) :
            format += "B"
        return struct.unpack(format, buf)
    
    def readSignedBytes(self, numBytes) :
        buf = self.readPlainBytes(numBytes)
        if len(buf) < numBytes :
            return []
            
        format = ""
        for i in range(numBytes) :
            format += "b"
        return struct.unpack(format, buf)
        
    def readBytesAsUint(self, numBytes) :
        result = 0
        bytes = self.readUnsignedBytes(numBytes)
        if len(bytes) == numBytes :
            for i in range(numBytes) :
                result |= bytes[i] << (i * 8)
        
        return result
        
    def readBytesAsInt(self, numBytes) :
        result = 0
        bytes = self.readSignedBytes(numBytes)
        if len(bytes) == numBytes :
            for i in range(numBytes) :
                result |= bytes[i] << (i * 8)
        
        return result
        
    def skipPadding(self) :
        result = 0
        if self.bytesRead % 4 != 0 :
            paddingLength = 4 - self.bytesRead % 4
            self.readPlainBytes(paddingLength)
            result = paddingLength
            
        return result

    def readPlainBytes(self, numBytes) :
        pass

class SISFileReader(SISReader) : 
    def __init__(self, inStream) :
        SISReader.__init__(self)
        self.inStream = inStream
        self.eof = False
        self.bytesRead = 0

    def readPlainBytes(self, numBytes) :
        if self.eof :
            return ""
            
        if numBytes == 0 :
            return ""
            
        buf = ""
        buf = self.inStream.read(numBytes)
        if len(buf) < numBytes :
            self.eof = True
            return ""
            
        self.bytesRead += numBytes
        
        return buf

    def isEof(self) :
        return self.eof
        
class SISBufferReader(SISReader) :
    def __init__(self, buffer) :
        self.buffer = buffer
        self.bytesRead = 0
        
    def readPlainBytes(self, numBytes) :
        if self.isEof() :
            return ""
            
        if numBytes == 0 :
            return ""
            
        result = self.buffer[self.bytesRead:self.bytesRead + numBytes]
            
        self.bytesRead += numBytes
        
        return result
            
    def isEof(self) :
        return self.bytesRead >= len(self.buffer)
        
class SISFieldParser :
    def __init__(self) :
        self.lastReadBytes = 0
        
    def parseField(self, fileReader) :
        """Reads the next field from the fileReader stream and returns it"""
        field = None
        self.lastReadBytes = 0
        type = fileReader.readBytesAsUint(4)
        self.lastReadBytes += 4
        if type != 0 :
            field = SISFieldTypes[type]()
            field.type = type
            field.initFromFile(fileReader)
            self.lastReadBytes += field.length + 4 # Field length + length field
            self.lastReadBytes += fileReader.skipPadding()
        return field

class SISInfo(SISField) :
    def __init__(self) :
        SISField.__init__(self)
        self.fin = None
        self.fileHeader = SISFileHeader()
        
    def parse(self, filename) :
        fin = open(filename, 'rb')
        fileReader = SISFileReader(fin)
        self.parseHeader(fileReader)
        self.parseSISFields(fileReader)
        
    def parseHeader(self, fileReader) :
        self.fileHeader.uid1 = fileReader.readBytesAsUint(4)
        self.fileHeader.uid2 = fileReader.readBytesAsUint(4)
        self.fileHeader.uid3 = fileReader.readBytesAsUint(4)
        self.fileHeader.uidChecksum = fileReader.readBytesAsUint(4)
        
    def parseSISFields(self, fileReader) :
        parser = SISFieldParser()
        while not fileReader.isEof() :
            self.subFields.append(parser.parseField(fileReader))

class Handler :
    def __init__(self) :
        self.files = []
        self.fileDatas = []
        self.signatureCertificateChains = []
        
    def handleField(self, field, depth) :
        if field.type == FileDescriptionField :
            self.files.append(field)
        elif field.type == FileDataField :
            self.fileDatas.append(field)
        elif field.type == SignatureCertificateChainField  :
            self.signatureCertificateChains.append(field)

    def execute(self, options) :
        for f in self.files :
            if options.info :
                buf = "   " + f.findField(StringField)[0].readableStr()
                caps = f.findField(CapabilitiesField)[0]
                if caps :
                    buf += " [" + " ".join(f.findField(CapabilitiesField)[0].readableCaps) + "]"
                print buf
            if options.extract :
                parts = f.findField(StringField)[0].readableStr().split("\\")
                if len(parts[len(parts) - 1]) > 0 :
                    path = os.path.abspath(options.extract)
                    path += os.sep + os.sep.join(parts[1: - 1])
                    if not os.path.exists(path) :
                        os.makedirs(path)
                    newFile = file(path + os.sep + parts[len(parts) - 1], "wb")
                    newFile.write(self.fileDatas[f.fileIndex].findField(CompressedField)[0].data)
                    newFile.close()
        for s in self.signatureCertificateChains :
            if options.certificate:
                buf = s.findField(CertificateChainField)[0].subFields[0].data
                print "Certificate chain:"
                i = 1
                while len(buf) > 0 :
                    print "   Certificate " + str(i) + ":"
                    i += 1
                    decoded = decoder.decode(buf)
                    cer = CertificateInfo()
                    cer.parse(decoded[0])
                    readableStr = cer.readableStr()
                    print "      " + "\n      ".join(readableStr.split('\n'))
                    buf = decoded[1]
            
class ContentPrinter :
    def __init__(self) :
        pass
        
    def handleField(self, field, depth) :
        buf = ""
        for i in range(depth) :
            buf += "  "
        buf += FieldNames[field.type] + " "
        if len(field.readableStr()) > 0 :
            buf += field.readableStr()
        print buf

class IADHandler :
    def __init__(self) :
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
        
    def handleDependency(self, field) :
        dep = [0, - 1, - 1, - 1, - 1, - 1, - 1]
        dep[0] = field.subFields[0].uid
        if field.subFields[1] and field.subFields[1].type == VersionRangeField :
            r = field.subFields[1]
            if r.fromVersion != None :
                dep[1] = r.fromVersion.version[0]
                dep[2] = r.fromVersion.version[1]
                dep[3] = r.fromVersion.version[2]
            if r.toVersion != None :
                dep[4] = r.toVersion.version[0]
                dep[5] = r.toVersion.version[1]
                dep[6] = r.toVersion.version[2]
        return dep
        
    def handleField(self, field, depth) :
        if field.type == InfoField :
            self.packageVersion = field.subFields[4].version
            self.packageVersionField = field.subFields[4]
            self.packageUid = field.subFields[0].uid
            self.packageUidField = field.subFields[0]
            self.vendorName = field.subFields[1].data
            self.vendorNameField = field.subFields[1]
            self.installType = field.installType
            self.installFlags = field.installFlags
            for name in field.subFields[2].subFields :
                self.packageNames.append(name.data)
        elif field.type == LanguageField :
            self.languages.append(field.language)
        elif field.type == PrerequisitiesField :
            for f in field.subFields[0].subFields :
                dependency = self.handleDependency(f)
                self.platformDependencies.append(dependency)
            for f in field.subFields[1].subFields :
                dependency = self.handleDependency(f)
                self.packageDependencies.append(dependency)
        
    def getInfo (self, fileName) :
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
        for num, name in enumerate(handler.packageNames) :
            info += "  <name language='" + repr(handler.languages[num]) + "'>" + name + "</name>\n"
        for language in handler.languages :
            info += "  <language>" + repr(language) + "</language>\n"
        for platDep in handler.platformDependencies :
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
        for packageDep in handler.packageDependencies :
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

if __name__ == "__main__" :
    handler = IADHandler()
    print (handler.getInfo (sys.argv[1]))
