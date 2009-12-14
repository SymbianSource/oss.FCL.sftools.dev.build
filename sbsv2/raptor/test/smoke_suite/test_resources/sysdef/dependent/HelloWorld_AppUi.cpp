/*
* Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* HelloWorld_CExampleAppUi.cpp
*
*/


#include "HelloWorld.h"

//             The second phase constructor of the application UI class.
//             The application UI creates and owns the one and only view.
// 
void CExampleAppUi::ConstructL()
    {
	           // BaseConstructL() completes the UI framework's
	           // construction of the App UI.
    BaseConstructL();
	           // Create the single application view in which to
	           // draw the text "Hello World!", passing into it
	           // the rectangle available to it.
	iAppView = CExampleAppView::NewL(ClientRect());
	}


//             The app Ui owns the two views and is. 
//             therefore, responsible for destroying them
//
CExampleAppUi::~CExampleAppUi()
	{
	delete iAppView;
	}


//             Called by the UI framework when a command has been issued.
//             In this example, a command can originate through a 
//             hot-key press or by selection of a menu item.
//             The command Ids are defined in the .hrh file
//             and are 'connected' to the hot-key and menu item in the
//             resource file.
//             Note that the EEikCmdExit is defined by the UI
//             framework and is pulled in by including eikon.hrh
//
void CExampleAppUi::HandleCommandL(TInt aCommand)
	{
	switch (aCommand)
		{
		      // Just issue simple info messages to show that
		      // the menu items have been selected
	case EExampleItem0:
		iEikonEnv->InfoMsg(R_EXAMPLE_TEXT_ITEM0);
		break;

	
	case EExampleItem1:
		iEikonEnv->InfoMsg(R_EXAMPLE_TEXT_ITEM1);
		break;
	
	case EExampleItem2:
		iEikonEnv->InfoMsg(R_EXAMPLE_TEXT_ITEM2);
		break;
               // Exit the application. The call is
		       // implemented by the UI framework.

	case EEikCmdExit: 
		Exit();
		break;
		}
	}

