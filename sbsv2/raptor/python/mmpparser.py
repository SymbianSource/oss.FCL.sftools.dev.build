#
# Copyright (c) 2007-2010 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description: 
# MMPParser module
# This module provides a parser for MMP files which can work
# with any supplied MMPBackend
#


# We have to define the grammar in the following order:
# Actions - because the rules reference them
# Terminals - because the rules use them
# Rules
# Root rule - e.g. "an MMP is a list of statements"
#
# This seems inverted but it's just the price of
# being able to use python to define the grammar.


from pyparsing import *
import sys

# For multiline matching we must exclude \n from the list of whitespace
# characters.  If we don't then Parse Elements like OneOrMore won't stop
# at line boundaries.
# \r doesn't matter as it is always followed by \n anyhow it is
# redundant and may be thrown away without any loss of information.
ParserElement.setDefaultWhitespaceChars('\t\r ')




## Useful Parse Elements #########################################
def String():
	return Regex('[^ \n]+')

def StringList():
	return Group(OneOrMore(Regex('[^ \n]+')))

def HexOrDecNumber():
	return Regex('(0[xX][0-9a-fA-Z]+)|([0-9]+)')

def Line(pattern):
	return pattern.copy() + LineEnd().suppress()



class MMPParser(object):
	# Tools for whom options may be specified
	tools = [ 'ARMCC', 'CW', 'GCC', 'MSVC', 'GCCXML', 'ARMASM', 'GCCE' ]


	def __init__(self,statemachine):
		self.backend = statemachine
		# Create Tokens for the tools we support
		self.toolName = CaselessKeyword(MMPParser.tools[0])
		for thisTool in MMPParser.tools[1:]:
			self.toolName ^= CaselessKeyword(thisTool)

		self.assignment = \
			( \
			Line(CaselessKeyword('ARMFPU') + String()) ^ \
			Line(CaselessKeyword('APPLY') + String()) ^ \
			Line(CaselessKeyword('ASSPLIBRARY') + StringList()) ^ \
			Line(CaselessKeyword('CAPABILITY') + StringList()) ^ \
			Line(CaselessKeyword('DOCUMENT') + StringList()) ^ \
			Line(CaselessKeyword('EPOCHEAPSIZE') + HexOrDecNumber() + HexOrDecNumber()) ^ \
			Line(CaselessKeyword('EPOCPROCESSPRIORITY') + String()) ^ \
			Line(CaselessKeyword('FIRSTLIB') + String()) ^ \
			Line(CaselessKeyword('TARGET') + String()) ^ \
			Line(CaselessKeyword('ROMTARGET') + Optional(StringList())) ^ \
			Line(CaselessKeyword('RAMTARGET') + String()) ^ \
			Line(CaselessKeyword('TARGETTYPE') + String()) ^ \
			Line(CaselessKeyword('TARGETPATH') + String()) ^ \
			Line(CaselessKeyword('SYSTEMINCLUDE') + StringList()) ^ \
			Line(CaselessKeyword('USERINCLUDE') + StringList()) ^ \
			Line(CaselessKeyword('DEFFILE') + String()) ^ \
			Line(CaselessKeyword('EXPORTLIBRARY') + String()) ^ \
			Line(CaselessKeyword('LINKAS') + String()) ^ \
			Line(CaselessKeyword('VENDORID') + HexOrDecNumber()) ^ \
			Line(CaselessKeyword('OPTION') + self.toolName + StringList()) ^ \
			Line(CaselessKeyword('LINKEROPTION') + self.toolName + StringList()) ^\
			Line(CaselessKeyword('OPTION_REPLACE') + self.toolName + StringList()) ^ \
			Line(CaselessKeyword('SECUREID') + HexOrDecNumber()) ^ \
			Line(CaselessKeyword('EPOCSTACKSIZE') + HexOrDecNumber()) ^ \
			Line(CaselessKeyword('VERSION') + String() + Optional(CaselessKeyword('EXPLICIT'))) ^ \
			Line(CaselessKeyword('EPOCPROCESSPRIORITY') + String()) ^ \
			Line(CaselessKeyword('NEWLIB') + String()) \
			).setParseAction(self.backend.doAssignment) ^ \
			( \
			Line(CaselessKeyword('SOURCE') + StringList()).setParseAction(self.backend.doSourceAssignment) \
			).setParseAction(self.backend.doSourceAssignment) ^ \
			( \
			Line(CaselessKeyword('RESOURCE') + StringList()).setParseAction(self.backend.doOldResourceAssignment) \
			).setParseAction(self.backend.doOldResourceAssignment) ^ \
			( \
			Line(CaselessKeyword('SYSTEMRESOURCE') + StringList()).setParseAction(self.backend.doResourceAssignment) \
			).setParseAction(self.backend.doOldResourceAssignment) ^ \
			( \
			Line(CaselessKeyword('SOURCEPATH') + String()).setParseAction(self.backend.doSourceAssignment) \
			).setParseAction(self.backend.doSourcePathAssignment) ^ \
			( \
			Line((CaselessKeyword('UID') + Group(HexOrDecNumber() + Optional(HexOrDecNumber())))).setParseAction(self.backend.doUIDAssignment) \
			).setParseAction(self.backend.doUIDAssignment)  ^ \
			( \
			Line(CaselessKeyword('LANG') + StringList()) \
			).setParseAction(self.backend.doAppend) ^ \
			( \
			Line(CaselessKeyword('LIBRARY') + StringList()) \
			).setParseAction(self.backend.doAppend) ^ \
			( \
			Line(CaselessKeyword('DEBUGLIBRARY') + StringList()) \
			).setParseAction(self.backend.doAppend) ^ \
			( \
			Line(CaselessKeyword('MACRO') + Optional(StringList())) \
			).setParseAction(self.backend.doAppend) ^ \
			( \
			Line(CaselessKeyword('AIF') + StringList()) \
			).setParseAction(self.backend.doDeprecated) ^ \
			( \
			Line(CaselessKeyword('STATICLIBRARY') + StringList()) \
			).setParseAction(self.backend.doAppend)

		self.switch = \
			(Line( \
			CaselessKeyword('ALWAYS_BUILD_AS_ARM') ^ \
			CaselessKeyword('ASSPEXPORTS') ^ \
			CaselessKeyword('ASSPABI') ^ \
			CaselessKeyword('ASSPEXPORTS') ^ \
			CaselessKeyword('DEBUGGABLE') ^ \
			CaselessKeyword('DEBUGGABLE_UDEBONLY') ^ \
			CaselessKeyword('EPOCALLOWDLLDATA') ^ \
			CaselessKeyword('EPOCCALLDLLENTRYPOINTS') ^ \
			CaselessKeyword('EPOCFIXEDPROCESS') ^ \
			CaselessKeyword('EPOCNESTEDEXCEPTIONS') ^ \
			CaselessKeyword('EXPORTUNFROZEN') ^ \
			CaselessKeyword('FEATUREVARIANT') ^ \
			CaselessKeyword('BYTEPAIRCOMPRESSTARGET') ^ \
			CaselessKeyword('INFLATECOMPRESSTARGET') ^ \
			CaselessKeyword('NOCOMPRESSTARGET') ^ \
			CaselessKeyword('NOLINKTIMECODEGENERATION') ^ \
			CaselessKeyword('NOMULTIFILECOMPILATION') ^ \
			CaselessKeyword('COMPRESSTARGET') ^ \
			CaselessKeyword('NOEXPORTLIBRARY') ^ \
			CaselessKeyword('NOSTRICTDEF') ^ \
			CaselessKeyword('SRCDBG') ^ \
			CaselessKeyword('STRICTDEPEND') ^ \
			CaselessKeyword('STDCPP') ^ \
			CaselessKeyword('NOSTDCPP') ^ \
			CaselessKeyword('SMPSAFE') ^ \
			CaselessKeyword('PAGED') ^ \
			CaselessKeyword('PAGEDCODE') ^ \
			CaselessKeyword('PAGEDDATA') ^ \
			CaselessKeyword('UNPAGED') ^ \
			CaselessKeyword('UNPAGEDCODE') ^ \
			CaselessKeyword('UNPAGEDDATA') ^ \
			CaselessKeyword('WCHARENTRYPOINT') \
			)).setParseAction(self.backend.doSetSwitch)

		# General

		self.blankline = (LineStart() + Regex('[\t\r ]*') + LineEnd().suppress() \
			).setParseAction(self.backend.doBlankLine)

		self.preProcessorComment = (LineStart() + Regex('# .*') + LineEnd().suppress() 
			).setParseAction(self.backend.doPreProcessorComment)

		self.unknownstatement = (LineStart() + Regex('.*\S+') + LineEnd().suppress() \
			).setParseAction(self.backend.doUnknownStatement)
			
		self.unknownBlockBody = (\
			(Regex("[^\n]+?\s*") + LineEnd().suppress()).setParseAction(self.backend.doStartUnknown) + \
			ZeroOrMore(self.unknownstatement) \
			).setParseAction(self.backend.doEndUnknown) 

		# Platform

		self.ARMCCBlockStatement = \
			self.blankline ^ self.preProcessorComment ^ \
			Line( \
			CaselessKeyword('ARMRT') ^ \
			CaselessKeyword('ARMINC') \
			).setParseAction(self.backend.doSetSwitch) ^ \
			Line( \
			(CaselessKeyword('ARMLIBS') + StringList()) \
			).setParseAction(self.backend.doAppend)

		self.WINSBlockStatement = \
			self.blankline ^ self.preProcessorComment ^ \
			Line( \
			(CaselessKeyword('BASEADDRESS') + HexOrDecNumber()) \
			).setParseAction(self.backend.doAssignment) ^ \
			Line( \
			(CaselessKeyword('WIN32_LIBRARY') + StringList()) \
			).setParseAction(self.backend.doAppend) ^ \
			Line( \
			(CaselessKeyword('WIN32_RESOURCE') + StringList()) \
			).setParseAction(self.backend.doAppend) ^ \
			Line( \
			CaselessKeyword('WIN32_HEADERS') ^ \
			CaselessKeyword('COPY_FOR_STATIC_LINKAGE')			
			).setParseAction(self.backend.doSetSwitch)

		self.TOOLSBlockStatement = \
			self.blankline ^ self.preProcessorComment ^ \
			Line( \
			(CaselessKeyword('WIN32_LIBRARY') + StringList()) \
			).setParseAction(self.backend.doAppend)

		self.platformBlock = ( \
			((CaselessKeyword('ARMCC') + LineEnd().suppress()).setParseAction(self.backend.doStartPlatform) + ZeroOrMore(self.ARMCCBlockStatement)) ^ \
			((CaselessKeyword('WINS') + LineEnd().suppress()).setParseAction(self.backend.doStartPlatform) + ZeroOrMore(self.WINSBlockStatement)) ^ \
			((CaselessKeyword('WINSCW') + LineEnd().suppress()).setParseAction(self.backend.doStartPlatform) + ZeroOrMore(self.WINSBlockStatement)) ^ \
			(CaselessKeyword('MARM') + LineEnd().suppress()).setParseAction(self.backend.doStartPlatform) ^ \
			((CaselessKeyword('TOOLS') + LineEnd().suppress()).setParseAction(self.backend.doStartPlatform) + ZeroOrMore(self.TOOLSBlockStatement)) ^ \
			(CaselessKeyword('WINC') + LineEnd().suppress()).setParseAction(self.backend.doStartPlatform) + ZeroOrMore(self.WINSBlockStatement) \
			).setParseAction(self.backend.doEndPlatform)

		# Resource
			
		self.resourceSetting= \
			self.blankline ^ self.preProcessorComment ^ \
			Line( \
			(CaselessKeyword('TARGET') + String()) ^ \
			(CaselessKeyword('TARGETPATH') + String()) ^ \
			(CaselessKeyword('UID') + HexOrDecNumber()) \
			).setParseAction(self.backend.doResourceAssignment) ^ \
			Line( \
			(CaselessKeyword('DEPENDS') + StringList()) ^ \
			(CaselessKeyword('LANG') + StringList()) \
			).setParseAction(self.backend.doResourceAppend) ^ \
			Line( \
			CaselessKeyword('HEADER') ^ \
			CaselessKeyword('HEADERONLY')
			).setParseAction(self.backend.doResourceSetSwitch)

		self.resourceBlockBody = (\
			(CaselessKeyword('RESOURCE') + String() + LineEnd().suppress()).setParseAction(self.backend.doStartResource) \
			 + ZeroOrMore(self.resourceSetting) \
			).setParseAction(self.backend.doEndResource)

		# Bitmap

		self.bitmapSetting = \
			self.blankline ^ self.preProcessorComment ^ \
			Line( \
			(CaselessKeyword('TARGETPATH') + String()) \
			).setParseAction(self.backend.doBitmapAssignment) ^\
			Line( \
			(CaselessKeyword('SOURCE') + StringList()) 
			).setParseAction(self.backend.doBitmapSourceAssignment) ^\
			Line( \
			(CaselessKeyword('SOURCEPATH') + String()) 
			).setParseAction(self.backend.doBitmapSourcePathAssignment) ^\
			Line( \
			CaselessKeyword('HEADER')
			).setParseAction(self.backend.doBitmapSetSwitch)
			
		self.bitmapBlockBody = (\
			(CaselessKeyword('BITMAP') + String() + LineEnd().suppress()).setParseAction(self.backend.doStartBitmap) + \
			ZeroOrMore(self.bitmapSetting) \
			).setParseAction(self.backend.doEndBitmap)
			
		# Stringtable
		
		self.stringTableSetting = \
			self.blankline ^ self.preProcessorComment ^ \
			Line( \
			(CaselessKeyword('EXPORTPATH') + String())		
			).setParseAction(self.backend.doStringTableAssignment) ^\
			Line( \
			CaselessKeyword('HEADERONLY') \
			).setParseAction(self.backend.doStringTableSetSwitch)
			
		self.stringTableBlockBody = (\
			(CaselessKeyword('STRINGTABLE') + String() + LineEnd().suppress()).setParseAction(self.backend.doStartStringTable) + \
			ZeroOrMore(self.stringTableSetting) \
			).setParseAction(self.backend.doEndStringTable)		

		# Top-level
		self.block = \
			LineStart() + CaselessLiteral("START") + White().suppress() + \
			(self.platformBlock ^ self.resourceBlockBody ^ self.bitmapBlockBody ^ self.stringTableBlockBody ^self.unknownBlockBody) +  \
			LineStart() + CaselessLiteral("END") + LineEnd().suppress()
					

		self.command = \
			 self.assignment ^ self.switch
	
		# Unknown blocks and statements are ordered i.e. if there's a failure to match something before,
		# then they're "caught" appropriately
		
		self.mmp = (ZeroOrMore(self.preProcessorComment ^ self.blankline ^ self.block ^ self.command ^ self.unknownstatement)).setParseAction(self.backend.doMMP) 


## MMP Parsing Backends #########################################
class MMPBackend(object):
	"""A "backend" for the MMP language
	This may be used to implement a build system,
	source analysis tool or anything else"""
	def __init__(self):
		super(MMPBackend,self).__init__()
	def doPreProcessorComment(self,s,loc,toks):
		return "OK"
	
	def doStartPlatform(self,s,loc,toks):
		return "OK"
	def doEndPlatform(self,s,loc,toks):
		return "OK"

	def doStartResource(self,s,loc,toks):
		return "OK"
	def doResourceAssignment(self,s,loc,toks):
		return "OK"
	def doResourceAppend(self,s,loc,toks):
		return "OK"
	def doResourceSetSwitch(self,s,loc,toks):
		return "OK"	
	def doEndResource(self,s,loc,toks):
		return "OK"

	def doStartBitmap(self,s,loc,toks):
		return "OK" 
	def doBitmapAssignment(self,s,loc,toks):
		return "OK" 
	def doBitmapSourceAssignment(self,s,loc,toks):
		return "OK" 
	def doBitmapSourcePathAssignment(self,s,loc,toks):
		return "OK" 
	def doBitmapSetSwitch(self,s,loc,toks):
		return "OK" 
	def doEndBitmap(self,s,loc,toks):
		return "OK"

	def doStartStringtable(self,s,loc,toks):
		return "OK" 
	def doStringTableAssignment(self,s,loc,toks):
		return "OK" 
	def doStringTableSetSwitch(self,s,loc,toks):
		return "OK" 	
	def doEndStringtable(self,s,loc,toks):
		return "OK"

	def doSetSwitch(self,s,loc,toks):
		return "OK"
	def doAppend(self,s,loc,toks):
		return "OK"
	def doAssignment(self,s,loc,toks):
		return "OK"
	def doUIDAssignment(self,s,loc,toks):
		return "OK"
	def doSourcePathAssignment(self,s,loc,toks):
		return "OK"
	def doSourceAssignment(self,s,loc,toks):
		return "OK"
	
	def doOldResourceAssignment(self,s,loc,toks):
		return "OK"
	
	def doUnknownStatement(self,s,loc,toks):
		return "OK"
	def doStartUnknown(self,s,loc,toks):
		return "OK"
	def doEndUnknown(self,s,loc,toks):
		return "OK"
	
	def doBlankLine(self,s,loc,toks):
		return "OK"
	
	def doDeprecated(self,s,loc,toks):
		return "OK"
		
	def doNothing(self):
		return "OK"
	
	def doMMP(self,s,loc,toks):
		return "MMP"


