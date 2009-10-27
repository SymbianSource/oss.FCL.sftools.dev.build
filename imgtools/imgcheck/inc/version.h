// Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
// All rights reserved.
// This component and the accompanying materials are made available
// under the terms of the License "Eclipse Public License v1.0"
// which accompanies this distribution, and is available
// at the URL "http://www.eclipse.org/legal/epl-v10.html".
//
// Initial Contributors:
// Nokia Corporation - initial contribution.
// 
// Contributors:
//
// Description:
// @internalComponent
// @released
//

#ifndef VERSION_H
#define VERSION_H
/** 
Constant values needs to be updated for every release of imgcheck tool

@internalComponent
@released
*/
/**
The versions should be in three parts as 
<major>.<minor>.<maintenance>
For any architectural change the major version should be incremented
For any change in the input or output format or enhancements or feature support the minor version should be incremented
For any patch or maintenance(defect fixes) changes the maintenance version should be incremented.
The maintenance version should be reset to 0 if the minor version is incremented.
*/
const String gMajorVersion("V1");
const String gMinorVersion(".3");
const String gMaintenanceVersion(".5 \n");

/** 
Copyright to be displayed

@internalComponent
@released
*/
const String gCopyright("Copyright (c) 2007-2009 Nokia Corporation.\n");

/** 
Tool description

@internalComponent
@released
*/
const String gToolDesc("\nIMGCHECK - Tool for ROM/ROFS partition check ");

#endif //VERSION_H
