/*
* Copyright (c) 2001-2009 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of the License "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description: 
* Area-related classes implementation
*
*/


#include "r_areaset.h"
#include "r_global.h"
#include "r_rom.h"

extern TBool gGenDepGraph;
extern char* gDepInfoFile;

using namespace std;

////////////////////////////////////////////////////////////////////////

Area::Area(const char* aName, TLinAddr aDestBaseAddr, TUint aMaxSize, Area* aNext)
	: iFirstPagedCode(0),
	  iName(strdup(aName)),
	  iDestBaseAddr(aDestBaseAddr),
	  iSrcBaseAddr(0),
	  iSrcLimitAddr(0),
	  iMaxSize(aMaxSize),
	  iIsDefault(strcmp(aName, AreaSet::KDefaultAreaName) == 0),
	  iFiles(0),
	  iNextFilePtrPtr(&iFiles),
	  iNextArea(aNext)
	  
	{
	}


Area::~Area()
	{
	ReleaseAllFiles();
	free(const_cast<char*>(iName));	// allocated with strdup()
	}


/**
 Increase the size of the area.

 The reallocation must not exceed the area maximum size.

 @param aSrcLimitAddr New source top address

 @param aOverflow Number of overflow bytes if failure.

 @return success indication
*/

TBool Area::ExtendSrcLimitAddr(TLinAddr aSrcLimitAddr, TUint& aOverflow)
	{
	// must have been set before
	assert(iSrcBaseAddr != 0);
	// can only allocate more
	assert(aSrcLimitAddr > iSrcBaseAddr);

	if (aSrcLimitAddr-iSrcBaseAddr > iMaxSize)
		{
		aOverflow = aSrcLimitAddr-iSrcBaseAddr-iMaxSize;
		return EFalse;
		}

	iSrcLimitAddr = aSrcLimitAddr;
	return ETrue;
	}


/**
 Add a file at end of the list of files contained in this area.

 @param aFile File to add.  Must be allocated on the heap.  Ownership
 is transfered from the caller to the callee.
*/

void Area::AddFile(TRomBuilderEntry* aFile)
	{
	assert(aFile != 0);

	*iNextFilePtrPtr = aFile;
	iNextFilePtrPtr = &(aFile->iNextInArea);
	}


void Area::ReleaseAllFiles()
	{
	for (TRomBuilderEntry *next = 0, *current = iFiles;
		 current != 0;
		 current = next)
		{
		next = current->iNextInArea;
		delete current;
		}

	iFiles = 0;
	iNextFilePtrPtr = &iFiles;
	}

////////////////////////////////////////////////////////////////////////

void FilesInAreaIterator::GoToNext()
	{
	assert(iCurrentFile!=0);
	iCurrentFile = iCurrentFile->iNextInArea;
	}

////////////////////////////////////////////////////////////////////////

const char AreaSet::KDefaultAreaName[] = "DEFAULT AREA";

AreaSet::AreaSet()
	: iNonDefaultAreas(0),
	  iDefaultArea(0),
	  iAreaCount(0)
	{
	}


AreaSet::~AreaSet()
	{
	ReleaseAllAreas();
	}


inline TBool IsInRange(TLinAddr aAddr, TLinAddr aDestBaseAddr, TLinAddr aEndAddr)
	{
	return aDestBaseAddr <= aAddr && aAddr <= aEndAddr;
	}


/**
 Add a new area.

 Areas must have unique name, not overlap one another and not overflow
 the 32-bit address range.  

 @param aOverlappingArea On return ptr to name of overlapping area if
 any, 0 otherwise.

 @return EAdded if success, an error code otherwise.  
*/

AreaSet::TAddResult AreaSet::AddArea(const char* aNewName,
									 TLinAddr aNewDestBaseAddr,
									 TUint aNewMaxSize,
									 const char*& aOverlappingArea)
	{
	assert(aNewName != 0 && strlen(aNewName) > 0);
	assert(aNewMaxSize > 0);

	aOverlappingArea = 0;

	//
	// Checking new area validity
	//

	if (aNewDestBaseAddr+aNewMaxSize <= aNewDestBaseAddr)
		return EOverflow;

	TLinAddr newEndAddr = aNewDestBaseAddr+aNewMaxSize-1;

	// iterate non default areas first, then the default one if any
	Area* area=iNonDefaultAreas; 
	while (area != 0)
		{
		if (strcmp(area->Name(), aNewName) == 0)
			return EDuplicateName;

		TLinAddr curDestBaseAddr = area->DestBaseAddr();
		TLinAddr curEndAddr = area->DestBaseAddr()+area->MaxSize()-1;

		if (IsInRange(newEndAddr, curDestBaseAddr, curEndAddr) ||
			IsInRange(aNewDestBaseAddr, curDestBaseAddr, curEndAddr) ||
			IsInRange(curDestBaseAddr, aNewDestBaseAddr, newEndAddr))
			{
			aOverlappingArea = area->Name();
			return EOverlap;
			}

		if (area->iNextArea == 0 && area != iDefaultArea)
			area = iDefaultArea;
		else
			area = area->iNextArea;
		}
	
	//
	// Adding new area
	//

	if (strcmp(KDefaultAreaName, aNewName) == 0)
		iDefaultArea = new Area(aNewName, aNewDestBaseAddr, aNewMaxSize);
	else
		iNonDefaultAreas = new Area(aNewName, aNewDestBaseAddr, aNewMaxSize, iNonDefaultAreas);
	++iAreaCount;

	return EAdded;
	}


/**
 Remove every area added to the set.

 As a side-effect every file added to the areas is deleted.
*/

void AreaSet::ReleaseAllAreas()
	{
	for (Area *next = 0, *current = iNonDefaultAreas; current != 0; current = next)
		{
		next = current->iNextArea;
		delete current;
		}

	iNonDefaultAreas = 0;

	delete iDefaultArea;
	iDefaultArea = 0;
	}


/**
 Find an area from its name.

 @return A pointer to the area or 0 if the name is unknown.  The
 returned pointer becomes invalid when "this" is destructed.
*/

Area* AreaSet::FindByName(const char* aName) const
	{
	assert(aName != 0 && strlen(aName) > 0);

	if (iDefaultArea && strcmp(iDefaultArea->Name(), aName) == 0)
		return iDefaultArea;

	for (Area* area=iNonDefaultAreas; area != 0; area = area->iNextArea)
		{
		if (strcmp(area->Name(), aName) == 0)
			return area;
		}

	return 0;
	}


////////////////////////////////////////////////////////////////////////

void NonDefaultAreasIterator::GoToNext()
	{
	assert(iCurrentArea!=0);
	iCurrentArea = iCurrentArea->iNextArea;
	}

TInt Area::SortFilesForPagedRom()
	{
	Print(ELog,"Sorting files to paged/unpaged.\n");
	TRomBuilderEntry* extention[2] = {0,0};
	TRomBuilderEntry* unpaged[2] = {0,0};
	TRomBuilderEntry* normal[2] = {0,0};
	TRomBuilderEntry* current = iFiles;
	while(current)
		{
		TRomBuilderEntry** list;
		if((current->iRomImageFlags & (KRomImageFlagPrimary|KRomImageFlagVariant|KRomImageFlagExtension|KRomImageFlagDevice)) ||
			current->HCRDataFile())
			list = extention;
		else if(current->iRomImageFlags&(KRomImageFlagCodeUnpaged))
			list = unpaged;
		else if(current->iResource && (current->iOverrideFlags&KOverrideCodeUnpaged) && gPagedRom)
			list = unpaged;
		else
			list = normal;

		if(list!=normal)
			{
			Print(ELog, "Unpaged file %s\n",current->iRomNode->BareName());
			}

		if(!list[0])
			list[0] = current;
		else
			list[1]->iNextInArea = current;
		list[1] = current;

		current = current->iNext;
		}

	if(extention[1])
		{
		if(unpaged[0])
			{
			extention[1]->iNextInArea = unpaged[0];
			unpaged[1]->iNextInArea = normal[0];
			}
		else
			extention[1]->iNextInArea = normal[0];

		if (normal[1])
			normal[1]->iNextInArea = 0;

		iFiles = extention[0];
		}
	else{
		Print(EError,"No primary files.\n");
		return KErrGeneral;
	}

	iFirstPagedCode = normal[0];
	Print(ELog,"\n");
	if(gGenDepGraph)
		WriteDependenceGraph();
	return KErrNone;
	}


void Area::WriteDependenceGraph()
{
	TDepInfoList::iterator infoIt;
	TStringList::iterator strIt;
	TDepInfoList myDepInfoList;
	TRomBuilderEntry* e = iFirstPagedCode;
	char buffer[255];
	TInt count = 0;
	TStringList nameList;
	while(e)
	{
		DepInfo tmpDepInfo;
		TRomNode* rn = e->iRomNode;
		TInt ll = rn->FullNameLength();
		char* mm = (char*) malloc(ll+1);
		rn->GetFullName(mm);
		sprintf(buffer, "f%d", count);
		tmpDepInfo.portName = buffer;
		tmpDepInfo.index = count;
		myDepInfoList[mm] = tmpDepInfo;
		nameList.push_back(mm);
		free(mm);
		e = e->iNextInArea;
		count++;
	}
	e = iFirstPagedCode;
	count = 0;
	while(e)
	{
		TRomNode* rn = e->iRomNode;
		TRomFile* rf = rn->iRomFile;
		TInt j;
		TStringList depFiles;
		for(j=0; j < rf->iNumDeps; ++j)
		{
			TRomFile* f=rf->iDeps[j];
			TRomBuilderEntry* start = iFiles;
			while(start && start->iRomNode->iRomFile != f)
				start = start->iNextInArea;
			if(start && (start->iRomNode->iRomFile == f))
			{
				TRomNode* target = start->iRomNode;
				TInt l = target->FullNameLength();
				char* fname = (char *) malloc(l+1);
				target->GetFullName(fname);
				if(myDepInfoList.find(fname) != myDepInfoList.end())
				{
					depFiles.push_back(fname);
					myDepInfoList[fname].beenDepended = ETrue;
				}
				free(fname);
			}
		}
		if(depFiles.size() > 0)
		{
			myDepInfoList[nameList[count]].depFilesList=depFiles;
			myDepInfoList[nameList[count]].dependOthers = ETrue;
		}
		count++;
		e=e->iNextInArea;
	}
	ofstream os;
	string filename(gDepInfoFile, strlen(gDepInfoFile) - 3);
	filename = filename + "dot";
	os.open(filename.c_str());
	os << "digraph ROM {\n";
	os << "rankdir = LR;\n";
	os << "fontsize = 10;\n";
	os << "fontname = \"Courier New\";\n";
	os << "label = \"ROM DEPENDENCE GRAPH DOT FILE\";\n";
	os << "node[shape = plaintext];\n";
	os << "dependence[label=<<FONT FACE=\"Courier new\" POINT-SIZE=\"10pt\">\n";
	os << "<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\">\n";
	//for(infoIt = myDepInfoList.begin(); infoIt != myDepInfoList.end(); infoIt++)
	for(strIt = nameList.begin(); strIt != nameList.end(); strIt++)
	{
		string tmp = *strIt;
		string::iterator charIt;
		for(charIt=tmp.begin(); charIt != tmp.end(); charIt++)
		{
			if(*charIt == '\\')
				*charIt = '/';
		}
		if(myDepInfoList[*strIt].beenDepended && myDepInfoList[*strIt].dependOthers)
		{
			os << "\t<TR><TD PORT=\"" << myDepInfoList[*strIt].portName << "\" ALIGN=\"LEFT\" BGCOLOR=\"yellow\">\n";
			os << "\t<FONT COLOR=\"red\">" << tmp << "</FONT>\n";
			os << "\t</TD></TR>\n";
		}
		else if(myDepInfoList[*strIt].beenDepended)
		{
			os << "\t<TR><TD PORT=\"" << myDepInfoList[*strIt].portName << "\" ALIGN=\"LEFT\" BGCOLOR=\"gray\">\n";
			os << "\t<FONT COLOR=\"red\">" << tmp << "</FONT>\n";
			os << "\t</TD></TR>\n";
		}
		else if(myDepInfoList[*strIt].dependOthers)
		{
			os << "\t<TR><TD PORT=\"" << myDepInfoList[*strIt].portName << "\" ALIGN=\"LEFT\" BGCOLOR=\"cyan\">\n";
			os << "\t<FONT COLOR=\"blue\">" << tmp << "</FONT>\n";
			os << "\t</TD></TR>\n";
		}
		else
		{
			os << "\t<TR><TD PORT=\"" << myDepInfoList[*strIt].portName << "\" ALIGN=\"LEFT\">";
			os << tmp;
			os << "</TD></TR>\n";
		}
	}
	os << "</TABLE>\n";
	os << "</FONT>>]\n";
	TBool lastEdge = ETrue;
	TBool first = ETrue;
	for(infoIt = myDepInfoList.begin(); infoIt != myDepInfoList.end(); infoIt++)
	{
		if(!infoIt->second.dependOthers)
		{
			continue;
		}
		for(strIt = infoIt->second.depFilesList.begin(); strIt != infoIt->second.depFilesList.end(); strIt++)
		{
			TBool tmpEdge = ETrue;
			if(infoIt->second.index < myDepInfoList[*strIt].index)
			{	
				tmpEdge = EFalse;
			}
			if(first)
			{
				lastEdge = tmpEdge;
				first = EFalse;
				if(lastEdge)
				{
					os << "edge[color=forestgreen];\n";
				}
				else
				{
					os << "edge[color=red];\n";
				}
			}
			else
			{
				if(lastEdge != tmpEdge)
				{
					lastEdge = tmpEdge;
					if(lastEdge)
					{
						os << "edge[color=forestgreen];\n";
					}
					else
					{
						os << "edge[color=red];\n";
					}
				}
			}
			os << "dependence: " << infoIt->second.portName << " -> dependence: " << myDepInfoList[*strIt].portName << ";\n";
		}
	}
	os << "}\n";
	os.close();
	filename = filename.substr(0, filename.size()-4);
	filename = filename + ".backwarddep.dot";
	os.open(filename.c_str());
	os << "digraph ROM {\n";
	os << "rankdir = LR;\n";
	os << "fontsize = 10;\n";
	os << "fontname = \"Courier New\";\n";
	os << "label = \"ROM FORWARD DEPENDENCE GRAPH DOT FILE\";\n";
	os << "node[shape = plaintext];\n";
	os << "dependence[label=<<FONT FACE=\"Courier new\" POINT-SIZE=\"10pt\">\n";
	os << "<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\">\n";
	//for(infoIt = myDepInfoList.begin(); infoIt != myDepInfoList.end(); infoIt++)
	for(strIt = nameList.begin(); strIt != nameList.end(); strIt++)
	{
		string tmp = *strIt;
		string::iterator charIt;
		for(charIt=tmp.begin(); charIt != tmp.end(); charIt++)
		{
			if(*charIt == '\\')
				*charIt = '/';
		}
		if(myDepInfoList[*strIt].beenDepended && myDepInfoList[*strIt].dependOthers)
		{
			os << "\t<TR><TD PORT=\"" << myDepInfoList[*strIt].portName << "\" ALIGN=\"LEFT\" BGCOLOR=\"yellow\">\n";
			os << "\t<FONT COLOR=\"red\">" << tmp << "</FONT>\n";
			os << "\t</TD></TR>\n";
		}
		else if(myDepInfoList[*strIt].beenDepended)
		{
			os << "\t<TR><TD PORT=\"" << myDepInfoList[*strIt].portName << "\" ALIGN=\"LEFT\" BGCOLOR=\"gray\">\n";
			os << "\t<FONT COLOR=\"red\">" << tmp << "</FONT>\n";
			os << "\t</TD></TR>\n";
		}
		else if(myDepInfoList[*strIt].dependOthers)
		{
			os << "\t<TR><TD PORT=\"" << myDepInfoList[*strIt].portName << "\" ALIGN=\"LEFT\" BGCOLOR=\"cyan\">\n";
			os << "\t<FONT COLOR=\"blue\">" << tmp << "</FONT>\n";
			os << "\t</TD></TR>\n";
		}
		else
		{
			os << "\t<TR><TD PORT=\"" << myDepInfoList[*strIt].portName << "\" ALIGN=\"LEFT\">";
			os << tmp;
			os << "</TD></TR>\n";
		}
	}
	os << "</TABLE>\n";
	os << "</FONT>>]\n";
	os << "edge[color=red];\n";
	for(infoIt = myDepInfoList.begin(); infoIt != myDepInfoList.end(); infoIt++)
	{
		if(!infoIt->second.dependOthers)
		{
			continue;
		}
		for(strIt = infoIt->second.depFilesList.begin(); strIt != infoIt->second.depFilesList.end(); strIt++)
		{
			if(infoIt->second.index < myDepInfoList[*strIt].index)
			{	
				os << "dependence: " << infoIt->second.portName << " -> dependence: " << myDepInfoList[*strIt].portName << ";\n";
			}
		}
	}
	os << "}\n";
	os.close();
}

