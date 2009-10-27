// Copyright (c) 2004-2009 Nokia Corporation and/or its subsidiary(-ies).
// All rights reserved.
// This component and the accompanying materials are made available
// under the terms of "Eclipse Public License v1.0"
// which accompanies this distribution, and is available
// at the URL "http://www.eclipse.org/legal/epl-v10.html".
//
// Initial Contributors:
// Nokia Corporation - initial contribution.
//
// Contributors:
//
// Description:
// Implementation of the Class ElfLocalRelocation for the elf2e32 tool
// @internalComponent
// @released
// 
//

#if !defined(_PL_ELFLOCALRELOCATION_H)
#define _PL_ELFLOCALRELOCATION_H

#include "pl_elfrelocation.h"

/**
This class represents relocations generated by the linker that need to be interpreted into
the E32 image.
@internalComponent
@released
*/
class ElfLocalRelocation : public ElfRelocation
{

public:
	ElfLocalRelocation(ElfExecutable *aElfExec,PLMemAddr32 aAddr, \
			PLUINT32 aAddend, PLUINT32 aIndex, PLUCHAR aRelType, \
			Elf32_Rel* aRel, bool aVeneerSymbol=false);
	ElfLocalRelocation(ElfExecutable *aElfExec,PLMemAddr32 aAddr, \
			PLUINT32 aAddend, PLUINT32 aIndex, PLUCHAR aRelType, \
			Elf32_Rel* aRel, ESegmentType aSegmentType, Elf32_Sym* aSym, bool aDelSym, bool aVeneerSymbol=false);
	~ElfLocalRelocation();
	bool IsImportRelocation();
	void Add();

	bool ExportTableReloc();
	PLUINT16 Fixup();
	bool iDelSym;
	bool iVeneerSymbol;
};




#endif // !defined(_PL_ELFLOCALRELOCATION_H)
