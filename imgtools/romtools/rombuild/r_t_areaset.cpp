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
* AreaSet Unit Tests
*
*/


#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
#include <iostream>
#else //!__MSVCDOTNET__
#include <iostream.h>
#endif //__MSVCDOTNET__

#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "r_areaset.h"
#include "r_rom.h"

////////////////////////////////////////////////////////////////////////

LOCAL_C void Test(TBool aExpr, const char* aMsg)
	{
	if (! aExpr)
		{
		cerr << "Test Failed: " << aMsg << '\n';
		exit(1);
		}
	}


LOCAL_C void CheckAreas(const AreaSet* aPAreaSet, ...)
	{
	va_list l;
	va_start(l, aPAreaSet);

	TInt areaCount;
	for (areaCount = 0;; ++areaCount)
		{
		const char* name = va_arg(l, const char*);
		if (name == 0)
			break;

		TLinAddr startAddr = va_arg(l, TLinAddr);
		TUint size = va_arg(l, TUint);

		const Area* pArea = aPAreaSet->FindByName(name);
		Test(pArea != 0, "unknown name");
		Test(pArea->DestBaseAddr() == startAddr, "incorrect area start address");
		Test(pArea->MaxSize() == size, "incorrect area size");
		}

	Test(areaCount == aPAreaSet->Count(), "incorrect number of areas");

	va_end(l);
	}

////////////////////////////////////////////////////////////////////////

LOCAL_C void TestAddAreaSuccess()
	{
	cout << "TestAddAreaSuccess...\n";

	AreaSet areaSet;

	const char KName1[] = "toto";
	const TLinAddr KStart1 = 0x666;
	const TUint KSize1 = 0x42;

	const char* overlappingArea;
	AreaSet::TAddResult r = areaSet.AddArea(KName1, KStart1, KSize1, overlappingArea);
	Test(r == AreaSet::EAdded, "adding area 1");
	Test(overlappingArea == 0, "incorrect overlapping area 1");
	CheckAreas(&areaSet, KName1, KStart1, KSize1, 0);

	const char KName2[] = "foobar";
	const TLinAddr KStart2 = 0x100000;
	const TUint KSize2 = 0x100;

	r = areaSet.AddArea(KName2, KStart2, KSize2, overlappingArea);
	Test(r == AreaSet::EAdded, "adding area 2");
	Test(overlappingArea == 0, "incorrect overlapping area 2");
	CheckAreas(&areaSet, KName1, KStart1, KSize1, KName2, KStart2, KSize2, 0);
	}


LOCAL_C void TestAddingTwoAreas(const char* aName1, TLinAddr aDestBaseAddr1, TUint aSize1,
								const char* aName2, TLinAddr aDestBaseAddr2, TUint aSize2,
								AreaSet::TAddResult aExpectedResult)
	{
	cout << "Testing overlap between " << aName1 << " and " << aName2 << "\n";

	AreaSet areaSet;

	const char* overlappingArea;
	AreaSet::TAddResult r = areaSet.AddArea(aName1, aDestBaseAddr1, aSize1, overlappingArea);
	Test(r == AreaSet::EAdded, "adding area 1");
	Test(overlappingArea == 0, "incorrect overlapping area 1");

	r = areaSet.AddArea(aName2, aDestBaseAddr2, aSize2, overlappingArea);
	Test(r == aExpectedResult, "adding area 2");

	Test(areaSet.Count() == ((aExpectedResult == AreaSet::EAdded) ? 2 : 1),
		 "incorrect area count");
	if (aExpectedResult == AreaSet::EAdded)
		{
		Test(areaSet.Count() == 2, "incorrect area count (should be 2)");
		Test(overlappingArea == 0, "incorrect overlapping area 2 (should be 0)");
		}
	else
		{
		Test(areaSet.Count() == 1, "incorrect area count (should be 1)");
		if (aExpectedResult == AreaSet::EOverlap)
			Test(strcmp(overlappingArea, aName1) == 0, "incorrect overlapping area 2 (bad name)");
		else
			Test(overlappingArea == 0, "incorrect overlapping area 2 (should be 0)");
		}
	}


LOCAL_C void TestAddAreaOverlap()
	{
	cout << "TestAddAreaOverlap...\n";

	const char KNameInitial[] = "initial";
	const TLinAddr KStartInitial = 0x1000;
	const TUint KSizeInitial = 0x101;

	// new area overlapping first byte of initial one
	TestAddingTwoAreas(KNameInitial, KStartInitial, KSizeInitial,
					   "overlap 1", 0x0F00, 0x101, AreaSet::EOverlap);

	// new area overlapping last byte of initial one
	TestAddingTwoAreas(KNameInitial, KStartInitial, KSizeInitial,
					   "overlap 2", 0x01100, 0x101, AreaSet::EOverlap);

	// new area embedded in the initial one
	TestAddingTwoAreas(KNameInitial, KStartInitial, KSizeInitial,
					   "overlap 3", 0x01010, 0x10, AreaSet::EOverlap);

	// existing area overlapping first byte of new one
	TestAddingTwoAreas(KNameInitial, 0x0F00, 0x101, "overlap 10",
					   KStartInitial, KSizeInitial, AreaSet::EOverlap);

	// existing area overlapping last byte of new one
	TestAddingTwoAreas(KNameInitial, 0x01100, 0x101, "overlap 11",
					   KStartInitial, KSizeInitial, AreaSet::EOverlap);

	// existing area embedded in the new one
	TestAddingTwoAreas(KNameInitial, 0x01010, 0x10, "overlap 12",
					   KStartInitial, KSizeInitial, AreaSet::EOverlap);

	// new area just before the initial one
	TestAddingTwoAreas(KNameInitial, KStartInitial, KSizeInitial,
					   "overlap 4", 0x0F00, 0x100, AreaSet::EAdded);
	
	// new area just after the initial one
	TestAddingTwoAreas(KNameInitial, KStartInitial, KSizeInitial,
					   "overlap 5", 0x01101, 0x100, AreaSet::EAdded);
	}


LOCAL_C void TestAddAreaDuplicateName()
	{
	cout << "TestAddAreaDuplicateName...\n";
	
	TestAddingTwoAreas("foobar", 0x10, 0x10,
					   "foobar", 0x100, 0x10,
					   AreaSet::EDuplicateName);
	}


LOCAL_C void TestAddAreaOverflow()
	{
	cout << "TestAddAreaOverflow...\n";
	
	AreaSet areaSet;

	const char KName1[] = "foobar";
	const char* overlappingArea;
	AreaSet::TAddResult r = areaSet.AddArea(KName1, 0xFFFFFFFF, 0x02, overlappingArea);
	Test(r == AreaSet::EOverflow, "adding area 1");
	Test(areaSet.Count() == 0, "incorrect count after trying to add area 1");
	Test(areaSet.FindByName(KName1) == 0, "Unexpected name found after trying to add area 1");
	Test(overlappingArea == 0, "incorrect overlapping area 1");

	const char KName2[] = "barfoo";
	r = areaSet.AddArea(KName2, 0xFFFFFFFF, 0xFFFFFFFF, overlappingArea);
	Test(r == AreaSet::EOverflow, "adding area 2");
	Test(areaSet.Count() == 0, "incorrect count after trying to add area 2");
	Test(areaSet.FindByName(KName2) == 0, "Unexpected name found after trying to add area 2");
	Test(overlappingArea == 0, "incorrect overlapping area 2");
	}



LOCAL_C void TestAddArea()
	{
	TestAddAreaSuccess();
	TestAddAreaOverlap();
	TestAddAreaDuplicateName();
	TestAddAreaOverflow();
	}

LOCAL_C void TestSrcAddrManipulations()
	{
	cout << "TestSrcAddrManipulations...\n";

	//
	// Creating an AreaSet instance containing one area
	//

	AreaSet areaSet;
	const char* overlappingArea;
	const char KAreaName[] = "foobar";
	const TUint KMaxSize = 10;
	AreaSet::TAddResult r = areaSet.AddArea(KAreaName, 0x100, KMaxSize, overlappingArea);
	Test(r == AreaSet::EAdded, "Failed to add area");

	Area* area = areaSet.FindByName(KAreaName);
	Test(area != 0, "Failed to find area");

	Test(area->UsedSize() == 0, "used size before allocation");

	const TUint KSrcBaseAddr = 0x100;
	area->SetSrcBaseAddr(KSrcBaseAddr);

	Test(area->SrcBaseAddr() == KSrcBaseAddr, "destination base address before allocation");
	Test(area->SrcBaseAddr() == area->SrcLimitAddr(), "destination limit address before allocation");

	//
	// Allocating some space in the area
	//

	const TUint KAlloc1 = KMaxSize-1;
	TUint overflow;
	TBool allocated = area->ExtendSrcLimitAddr(KSrcBaseAddr+KAlloc1, overflow);
	Test(allocated, "allocation 1 failed");
	Test(area->UsedSize() == KAlloc1, "used size after allocation 1");
	Test(area->SrcBaseAddr()+KAlloc1 == area->SrcLimitAddr(), "destination limit address after allocation 1");

	//
	// Allocating more than available
	//

	const TUint KAlloc2 = KMaxSize*2;
	allocated = area->ExtendSrcLimitAddr(KSrcBaseAddr+KAlloc1+KAlloc2, overflow);
	Test(! allocated, "allocation 2 should have failed");
	Test(overflow == KAlloc2+KAlloc1 - KMaxSize, "overflow after allocation 2");
	Test(area->UsedSize() == KAlloc1, "used size after allocation 2");
	Test(area->SrcBaseAddr()+KAlloc1 == area->SrcLimitAddr(), "destination limit address after allocation 2");

	//
	// Allocating just enough to fill the area completely  
	//

	const TUint KAlloc3 = KMaxSize-KAlloc1;
	allocated = area->ExtendSrcLimitAddr(KSrcBaseAddr+KAlloc1+KAlloc3, overflow);
	Test(allocated, "allocation 3 failed");
	Test(area->UsedSize() == KAlloc1+KAlloc3, "used size after allocation 3");
	Test(area->UsedSize() == area->MaxSize(), "used size and max size should be equal");
	Test(area->SrcBaseAddr()+KAlloc1+KAlloc3 == area->SrcLimitAddr(), "destination limit address after allocation 3");

	//
	// Overflowing the area by one byte
	//

	const TUint KAlloc4 = 1;
	allocated = area->ExtendSrcLimitAddr(KSrcBaseAddr+KAlloc1+KAlloc3+KAlloc4, overflow);
	Test(! allocated, "allocation 4 should have failed");
	Test(overflow == 1, "overflow after allocation 4");
	Test(area->UsedSize() == KAlloc1+KAlloc3, "used size after allocation 4");
	Test(area->SrcBaseAddr()+KAlloc1+KAlloc3 == area->SrcLimitAddr(), "destination limit address after allocation 4");
	}


LOCAL_C void TestFileIterator()
	{
	cout << "TestFileIterator...\n";

	//
	// Creating an area set containing one area
	//

	AreaSet areaSet;
	const char* overlappingArea;
	const char KAreaName[] = "foobar";
	const TUint KMaxSize = 10;
	AreaSet::TAddResult r = areaSet.AddArea(KAreaName, 0x100, KMaxSize, overlappingArea);
	Test(r == AreaSet::EAdded, "Failed to add area");

	Area* area = areaSet.FindByName(KAreaName);
	Test(area != 0, "Failed to find area");

	FilesInAreaIterator it1(*area);
	Test(it1.IsDone(), "it1.IsDone()");

	//
	// Adding one file to that area
	//
	
	TRomBuilderEntry* pfile1 = new TRomBuilderEntry("file1", (TText*) "file1");
	area->AddFile(pfile1);

	FilesInAreaIterator it2(*area);
	Test(! it2.IsDone(), "! it2.IsDone() 1");
	Test(it2.Current() == pfile1, "it2.Current() == pfile1");

	it2.GoToNext();
	Test(it2.IsDone(), "it2.IsDone()");

	//
	// Adding a second file to that area
	//

	TRomBuilderEntry* pFile2 = new TRomBuilderEntry("file2", (TText*) "file2");
	area->AddFile(pFile2);

	FilesInAreaIterator it3(*area);
	Test(! it3.IsDone(), "! it3.IsDone() 1");
	Test(it3.Current() == pfile1, "it3.Current() == pfile1");

	it3.GoToNext();
	Test(! it3.IsDone(), "it3.IsDone() 2");
	Test(it3.Current() == pFile2, "it3.Current() == pFile2");

	it3.GoToNext();
	Test(it3.IsDone(), "it3.IsDone()");
	}


LOCAL_C void TestNonDefaultAreaIterator() 
	{
	cout << "TestNonDefaultAreaIterator...\n";

	//
	// Creating an area set
	//

	AreaSet areaSet;

	NonDefaultAreasIterator it1(areaSet);
	Test(it1.IsDone(), "it1.IsDone()");
	
	//
	// Adding a first non default area
	//

	const char* overlappingArea;
	const char KAreaName1[] = "area 1";
	AreaSet::TAddResult r = areaSet.AddArea(KAreaName1, 0x100, 0x10, overlappingArea);
	Test(r == AreaSet::EAdded, "Failed to add area 1");

	Area* pArea1 = areaSet.FindByName(KAreaName1);
	Test(pArea1 != 0, "Failed to find area 1");

	NonDefaultAreasIterator it2(areaSet);
	Test(! it2.IsDone(), "! it2.IsDone()");

	Test(&it2.Current() == pArea1, "&it2.Current() == pArea1");

	it2.GoToNext();
	Test(it2.IsDone(), "it2.IsDone()");

	//
	// Adding a default area
	//

	r = areaSet.AddArea(AreaSet::KDefaultAreaName, 0x50000000, 0x00200000, overlappingArea);
	Test(r == AreaSet::EAdded, "failed to add default area");

	NonDefaultAreasIterator it3(areaSet);
	Test(! it3.IsDone(), "! it3.IsDone()");

	Test(&it3.Current() == pArea1, "&it3.Current() == pArea1");

	it3.GoToNext();
	Test(it3.IsDone(), "it3.IsDone()");

	//
	// Adding a second non default area
	//

	const char KAreaName2[] = "area 2";
	r = areaSet.AddArea(KAreaName2, 0x1000, 0x10, overlappingArea);
	Test(r == AreaSet::EAdded, "Failed to add area 2");

	Area* pArea2 = areaSet.FindByName(KAreaName2);
	Test(pArea2 != 0, "Failed to find area 2");

	NonDefaultAreasIterator it4(areaSet);
	Test(! it4.IsDone(), "! it4.IsDone()");

	Test(&it4.Current() == pArea2, "&it4.Current() == pArea2");

	it4.GoToNext();
	Test(! it4.IsDone(), "it4.IsDone()");
	Test(&it4.Current() == pArea1, "&it4.Current() == pArea1");

	it4.GoToNext();
	Test(it4.IsDone(), "it4.IsDone()");
	}

////////////////////////////////////////////////////////////////////////

GLDEF_C int main() 
	{
	TestAddArea();
	TestSrcAddrManipulations();
	TestFileIterator();
	TestNonDefaultAreaIterator();

	cout << "\nTests OK\n";
	return 0;
	}
