/*
* Copyright (c) 1997-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#if !defined(SHUTDOWNSRV_H)
#define SHUTDOWNSRV_H

#include <e32base.h>
#include <savenotf.h>
#include <e32power.h>
#include <s32mem.h>

class CShutdownTimer;

/**
This class describes an interface, which is used by LaF Shutdown Manager to notify the Shutdown Server of 
device shutdown, so that the server can take appropriate power management steps. The concrete implementation 
of this interface is provided by CServShutdownServer class.
@publishedPartner
@released
*/
class MShutdownEventObserver
	{
public:
	/**
	This method has to be called, when the observed object requires the Shutdown Server to notify registered 
	clients about the shutdown event, such as MSaveObserver::ESaveData, MSaveObserver::ESaveAll, 
	MSaveObserver::EReleaseRAM,...
	@param aAction The type of the requested action
	@param aPowerOff If it is non-zero, this is the beginning of a powerdown sequence.
	@param aEvent The type of the powerdown event 
	@leave KErrNotSupported Leaves if aEvent is invalid  
	*/
	virtual void HandleShutdownEventL(MSaveObserver::TSaveType aAction,TBool aPowerOff, TPowerState aEvent = EPwStandby)=0;
	/**
	This method creates an array of CArrayFix<TThreadId> type and appends to it the	thread id-s of 
	all the registered clients. The created CArrayFix<TThreadId> instance will be pushed on the 
	cleanup stack. The caller becomes responsible for the memory allocated for this array.
	@return A pointer to a CArrayFix<TThreadId> array with the client thread id-s.
	@leave Some system-wide error codes including KErrNoMemory.
	*/
	virtual CArrayFix<TThreadId>* ClientArrayLC()=0;
	/**
	Checks if a particular client is hung in that the client has not re-registered with the 
	Shutdown Server indicating it is ready for the next stage of the shutdown.
	@param aId Client's thread id.
	@return Non-zero if the client with this thread id has no pending request.
	*/
	virtual TBool IsClientHung(TThreadId aId) const=0;
	/**
	This method returns information about the shutdown status.
	@param aPowerOff An output parameter, where power-off status will be stored. 
	                 It will be non-zero, if a powerdown sequence has been initiated.
	@param aAllSessionsHavePendingRequest An output parameter. It will be non-zero, if all clients 
	                 have pending requests to receive further events from the Shutdown Manager.
	*/
	virtual void GetShutdownState(TBool& aPowerOff, TBool& aAllSessionsHavePendingRequest) const=0;
	};

/**
This class describes an object, which handles requests, such as of MSaveObserver::TSaveType type.
When CServShutdownServer::HandleShutdownEventL() gets called, the CServShutdownServer implementation
will notify all registered clients, completing their asynchronous messages 
(CServShutdownSession::iPtr), then it will wait until all clients re-register itself and
if this is a beginning of a powerdown sequence, the method will store the locales and the HAL
properties subsequently switching off the power.
@internalTechnology
*/
class CServShutdownServer : public CServer2, public MShutdownEventObserver
	{
public:
	IMPORT_C static CServShutdownServer* NewL();
	IMPORT_C ~CServShutdownServer();
	IMPORT_C void HandlePowerNotifRequest(const RThread& aClient);
	IMPORT_C void NotifySave(MSaveObserver::TSaveType aSaveType);
	IMPORT_C TBool IsPowerOff() const;
	IMPORT_C void CancelPowerOff();
	void SwitchOff();
#ifdef SYMBIAN_SSM_GRACEFUL_SHUTDOWN
	TInt ClientArrayCount();
	void ClientArrayL(const RMessage2& aMessage);
#endif //SYMBIAN_SSM_GRACEFUL_SHUTDOWN	
public:
	IMPORT_C virtual void ConstructL();
public: // from MShutdownEventObserver
	IMPORT_C void HandleShutdownEventL(MSaveObserver::TSaveType aAction,TBool aPowerOff, TPowerState aEvent = EPwStandby);
	IMPORT_C CArrayFix<TThreadId>* ClientArrayLC();
	IMPORT_C TBool IsClientHung(TThreadId aId) const;
	IMPORT_C void GetShutdownState(TBool& aPowerOff, TBool& aAllSessionsHavePendingRequest) const;

protected:
	IMPORT_C CServShutdownServer(TInt aPriority);
private:
	TBool AllSessionsHavePendingRequest() const;
	void DoSwitchOff();
private: // from CServer
	CSession2* NewSessionL(const TVersion& aVersion,const RMessage2& aMessage) const;
private:
	TBool iPowerOff;
	TPowerState iPowerEvent;	
	CShutdownTimer* iShutdownTimer;	
	};

/**
This class describes a server side session object, which handles reqistration requests
of clients, which are interested in power down events.
@internalTechnology
*/
class CServShutdownSession : public CSession2
	{
public:
	IMPORT_C ~CServShutdownSession();
protected:
	IMPORT_C CServShutdownSession();
public:
	static CServShutdownSession* NewL();
	TBool HasPendingRequest() const;
	void NotifySave(MSaveObserver::TSaveType aSaveType);
protected: // from CSession
	IMPORT_C void ServiceL(const RMessage2& aMessage);
private:
	void RequestNotifyPowerDown(const RMessage2& aMessage);
	void RequestNotifyPowerDownCancel();
	void DoServiceL(const RMessage2& aMessage, TBool& aCompleteRequest);
	void PowerOffL(const RMessage2& aMessage);
	void PowerStateL(const RMessage2& aMessage) const;

#ifdef SYMBIAN_SSM_GRACEFUL_SHUTDOWN
	void HandleShutdownEventL(const RMessage2& aMessage);
	void ClientArrayL(const RMessage2& aMessage);
	void IsClientHung(const RMessage2& aMessage) const;
	void GetShutdownState(const RMessage2& aMessage) const;
	void ClientArrayCount(const RMessage2& aMessage) const;
#endif //SYMBIAN_SSM_GRACEFUL_SHUTDOWN

public:
	TThreadId ClientThreadId() const;

private:
	RMessagePtr2 iPtr;
	TInt iCurrentEvent;
	TInt iOutstandingEvent;
	};

#endif// SHUTDOWNSRV_H
