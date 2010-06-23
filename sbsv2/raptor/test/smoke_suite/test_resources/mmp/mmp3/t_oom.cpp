/*
* Copyright (c) 1998-2009 Nokia Corporation and/or its subsidiary(-ies).
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
*
*/


#include <s32file.h>
#include <e32test.h>

#define UNUSED_VAR(a) a = a

const TInt KTestCleanupStack=0x20;
const TPtrC KTestDir=_L("\\STOR-TST\\T_OOM\\");

#ifdef _DEBUG
const TPtrC desOriginalReverted2(_S("original/reverted A"),19);
const TPtrC desOriginalReverted3(_S("original/reverted B"),19);
const TPtrC desNewOverwritten2(_S("new/overwritten X"),17);
const TPtrC desNewOverwritten3(_S("new/overwritten Y"),17);
const TPtrC alphabet(_S("abcdefghijklmnopqrstuvwxyz"),26);
LOCAL_D CFileStore* store;
RStoreWriteStream out;
RStoreReadStream in;
TInt KMemoryAllocsInTestFunction=1;
#endif

LOCAL_D CTrapCleanup* TheTrapCleanup;
LOCAL_D RTest test(_L("T_OOM"));
LOCAL_D RFs TheFs;

LOCAL_C void setupTestDirectory()
    {// Prepare the test directory.
	TInt r=TheFs.Connect();
	test(r==KErrNone);
//
	r=TheFs.MkDirAll(KTestDir);
	test(r==KErrNone||r==KErrAlreadyExists);
	r=TheFs.SetSessionPath(KTestDir);
	test(r==KErrNone);
	}

LOCAL_C void setupCleanup()
    {// Initialise the cleanup stack
	TheTrapCleanup=CTrapCleanup::New();
	test(TheTrapCleanup!=NULL);
	TRAPD(r,\
		{\
		for (TInt i=KTestCleanupStack;i>0;i--)\
			CleanupStack::PushL((TAny*)0);\
		CleanupStack::Pop(KTestCleanupStack);\
		});
	test(r==KErrNone);
	}

#ifdef _DEBUG
LOCAL_D void CreateStoreSetRootAndDestroyStoreL()
	{
	TheFs.Delete(_L("pfs"));
	store=CPermanentFileStore::CreateLC(TheFs,_L("pfs"),EFileWrite|EFileRead);
	store->SetTypeL(KPermanentFileStoreLayoutUid);
	TStreamId rootId = store->ExtendL();
	store->SetRootL(rootId);
	store->CommitL();
	CleanupStack::PopAndDestroy();
	}

LOCAL_D void AlterStoreL()
	{
	RStoreWriteStream out2;
	RStoreWriteStream out3;
	RStoreWriteStream out4;
	RStoreReadStream in;

	TStreamId id2 = out.CreateLC(*store);
	out.CommitL();
	CleanupStack::PopAndDestroy();

	TStreamId id3 = out.CreateLC(*store);
	out.CommitL();
	CleanupStack::PopAndDestroy();

	TStreamId id4 = out.CreateLC(*store);
	out << _L("mum");
	out.CommitL();
	CleanupStack::PopAndDestroy();

	out.ReplaceLC(*store,store->Root());
	out << id2;
	out << id3;
	out << id4;
	out.CommitL();
	CleanupStack::PopAndDestroy();

	in.OpenLC(*store,store->Root());// use the root for in and out streams
	out.ReplaceLC(*store,store->Root());
	out.WriteL(in);
	out.CommitL();
	CleanupStack::PopAndDestroy(2);

	out.ReplaceLC(*store,store->Root());// swap the order
	in.OpenLC(*store,store->Root());
	out.WriteL(in);
	out << _L("fromage");
	out.CommitL();
	CleanupStack::PopAndDestroy(2);

	store->CommitL();

	in.OpenLC(*store,store->Root());
	TStreamId idX,idZ;
	in >> idX;
	in >> idX;
	in >> idZ;// id4 "mum"
	CleanupStack::PopAndDestroy();
	out.OpenLC(*store,idZ);
	in.OpenLC(*store,idZ);
	out2.OpenLC(*store,idZ);
	out3.OpenLC(*store,idZ);
	out4.OpenLC(*store,idZ);
	out4.WriteL(in);
	out.CommitL();
	CleanupStack::PopAndDestroy(5);
	}
/**
@SYMTestCaseID          SYSLIB-STORE-CT-1170
@SYMTestCaseDesc	    Allocation failure in store test
@SYMTestPriority 	    High
@SYMTestActions  	    Tests for any memory errors during allocation of store
@SYMTestExpectedResults Test must not fail
@SYMREQ                 REQ0000
*/
LOCAL_D void AllocFailInSampleStoreCodeL()
	{
	test.Next(_L(" @SYMTestCaseID:SYSLIB-STORE-CT-1170 "));
	test.Console()->Printf(_L("AllocFailInSampleStoreCodeL()\n"));
	TRAPD(r,CreateStoreSetRootAndDestroyStoreL())
    UNUSED_VAR(r);
	const TInt KAllocFail=15;
	for (TInt ii=1;ii<=20;++ii)
		{
		store=CPermanentFileStore::OpenLC(TheFs,_L("pfs"),EFileWrite|EFileRead);
		__UHEAP_FAILNEXT(ii);
		TRAPD(r,AlterStoreL());
		if (ii<KAllocFail)
			test(r==KErrNoMemory);
		if (ii>=KAllocFail)
			test(r==KErrNone);
		__UHEAP_RESET;
		CleanupStack::PopAndDestroy();
		}
	TheFs.Delete(_L("pfs"));
	}

LOCAL_D void InitialseStoreWithDataL()
	{
	TheFs.Delete(_L("pope"));
	store=CPermanentFileStore::CreateLC(TheFs,_L("pope"),EFileWrite|EFileRead);
	store->SetTypeL(KPermanentFileStoreLayoutUid);
	TStreamId rootId = store->ExtendL();
	store->SetRootL(rootId);
	store->CommitL();
	CleanupStack::PopAndDestroy();

	store=CPermanentFileStore::OpenLC(TheFs,_L("pope"),EFileWrite|EFileRead);
	TStreamId id2 = out.CreateLC(*store);
	out << desOriginalReverted2;
	out.CommitL();
	CleanupStack::PopAndDestroy();

	TStreamId id3 = out.CreateLC(*store);
	out << desOriginalReverted3;
	out.CommitL();
	CleanupStack::PopAndDestroy();

	out.ReplaceLC(*store,store->Root());
	out << id2;
	out << id3;
	out.CommitL();
	CleanupStack::PopAndDestroy();// out

	store->CommitL();
	CleanupStack::PopAndDestroy();// store
	}

LOCAL_D void AlterStoreDuringOutOfMemoryL(TInt aFail)
	{
	store=CPermanentFileStore::OpenLC(TheFs,_L("pope"),EFileWrite|EFileRead);
	in.OpenLC(*store,store->Root());
	TStreamId id2;
	TStreamId id3;
	in >> id2;
	in >> id3;
	CleanupStack::PopAndDestroy();// in

	out.ReplaceLC(*store,id2);
	out << desNewOverwritten2;
	out.CommitL();
	CleanupStack::PopAndDestroy();// out

	store->CommitL();
	__UHEAP_FAILNEXT(aFail);// Out of memory

	out.ReplaceLC(*store,id3);
	out << desNewOverwritten3;
	out.CommitL();
	CleanupStack::PopAndDestroy();// out

	store->CommitL();
	CleanupStack::PopAndDestroy();// store

	__UHEAP_RESET;
	}

/**
@SYMTestCaseID          SYSLIB-STORE-CT-1346
@SYMTestCaseDesc	    Streaming of data test
@SYMTestPriority 	    High
@SYMTestActions  	    Tests for RStoreReadStream::>> operator
@SYMTestExpectedResults Test must not fail
@SYMREQ                 REQ0000
*/
LOCAL_D void TestStreamDataL(TInt aFail)
	{
	test.Next(_L(" @SYMTestCaseID:SYSLIB-STORE-CT-1346 "));
	store=CPermanentFileStore::OpenLC(TheFs,_L("pope"),EFileWrite|EFileRead);
	in.OpenLC(*store,store->Root());
	TStreamId id2;
	TStreamId id3;
	in >> id2;
	in >> id3;
	CleanupStack::PopAndDestroy();// in

	TBuf<32> buf;

	in.OpenLC(*store,id2);
	in >> buf;
	test(buf==desNewOverwritten2);

	CleanupStack::PopAndDestroy();// in

	in.OpenLC(*store,id3);
	in >> buf;
	if (aFail > KMemoryAllocsInTestFunction)
		test(buf==desNewOverwritten3);
	else if (aFail<=KMemoryAllocsInTestFunction)
		test(buf==desOriginalReverted3);

	CleanupStack::PopAndDestroy();// in

	CleanupStack::PopAndDestroy();// store
	}

LOCAL_D void ResetStreamDataL()
	{
	store=CPermanentFileStore::OpenLC(TheFs,_L("pope"),EFileWrite|EFileRead);
	in.OpenLC(*store,store->Root());
	TStreamId id2;
	TStreamId id3;
	in >> id2;
	in >> id3;
	CleanupStack::PopAndDestroy();// in

	out.ReplaceLC(*store,id2);
	out << desOriginalReverted2;
	out.CommitL();
	CleanupStack::PopAndDestroy();// out

	out.ReplaceLC(*store,id3);
	out << desOriginalReverted3;
	out.CommitL();
	CleanupStack::PopAndDestroy();// out

	store->CommitL();
	CleanupStack::PopAndDestroy();// store
	}
/**
@SYMTestCaseID          SYSLIB-STORE-CT-1171
@SYMTestCaseDesc	    Out of memory errors test
@SYMTestPriority 	    High
@SYMTestActions  	    Tests for out of memory conditions before commiting to the store
@SYMTestExpectedResults Test must not fail
@SYMREQ                 REQ0000
*/
LOCAL_D void OutOfMemoryBeforeStoreCommitL()
	{
	test.Next(_L(" @SYMTestCaseID:SYSLIB-STORE-CT-1171 "));
	test.Console()->Printf(_L("OutOfMemoryBeforeStoreCommitL()\n"));
	InitialseStoreWithDataL();
	for (TInt fail=1; fail<=5; ++ fail)
		{
		TRAPD(r,AlterStoreDuringOutOfMemoryL(fail));
		if (fail<=KMemoryAllocsInTestFunction)
			test(r==KErrNoMemory);// store saved when r!=KErrNone
		else
			test(r==KErrNone);
		TestStreamDataL(fail);
		ResetStreamDataL();
		}
	TheFs.Delete(_L("pope"));
	}


LOCAL_D void OpenCloseStoreL(TInt aFail)
	{
	__UHEAP_FAILNEXT(aFail);
	TheFs.Delete(_L("pope"));
	store=CPermanentFileStore::CreateLC(TheFs,_L("pope"),EFileWrite|EFileRead);
	store->SetTypeL(KPermanentFileStoreLayoutUid);
	TStreamId rootId = store->ExtendL();
	store->SetRootL(rootId);
	store->CommitL();
	CleanupStack::PopAndDestroy();

	store=CPermanentFileStore::OpenLC(TheFs,_L("pope"),EFileWrite|EFileRead);
	TStreamId id2 = out.CreateLC(*store);
	out << desOriginalReverted2;
	out << id2;
	out.CommitL();
	CleanupStack::PopAndDestroy(2);
	}
/**
@SYMTestCaseID          SYSLIB-STORE-CT-1172
@SYMTestCaseDesc	    Out of memory test
@SYMTestPriority 	    High
@SYMTestActions  	    Test for memory errors during opening and closing of store operation.
@SYMTestExpectedResults Test must not fail
@SYMREQ                 REQ0000
*/

LOCAL_D void OutOfMemoryWhenOpeningClosingStoreL()
	{
	test.Next(_L(" @SYMTestCaseID:SYSLIB-STORE-CT-1172 "));
	test.Console()->Printf(_L("OutOfMemoryWhenOpeningClosingStoreL()\n"));
	const TInt KAllocs=12;
	for (TInt fail=1; fail<=20; ++ fail)
		{
		TRAPD(r,OpenCloseStoreL(fail))
		if (fail<KAllocs)
			test(r==KErrNoMemory);
		else
			test(r==KErrNone);
		}
	TheFs.Delete(_L("pope"));
	__UHEAP_RESET;
	}
#endif

GLDEF_C TInt E32Main()
    {// Test permanent file store
	test.Title();
	setupTestDirectory();
	setupCleanup();
#ifdef _DEBUG
	__UHEAP_MARK;
//
	test.Start(_L("Begin tests"));
	TRAPD(r,AllocFailInSampleStoreCodeL());
	test(r==KErrNone);
	TRAP(r,OutOfMemoryBeforeStoreCommitL());
	test(r==KErrNone);
	TRAP(r,OutOfMemoryWhenOpeningClosingStoreL());
	test(r==KErrNone);
	test.End();

	TheFs.Delete(_L("pope"));
	TheFs.Delete(_L("pfs"));
//
	__UHEAP_MARKEND;
#endif

#ifndef _DEBUG
	test.Start(_L("The tests are not valid in release mode"));
	test.End();
#endif
	delete TheTrapCleanup;
	TheFs.Close();
	test.Close();
	return 0;
    }

