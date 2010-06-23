/*
* Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Cluster class used to allocate cluster numbers for directory entries 
* and while writing file contents. And it is responsible to create the 
* MAP of content starting cluster to ending cluster which can be used 
* to generate FAT table. Since the cluster number is unique all over the
* filesystem component, this class is designed as singleton class.
* @internalComponent
* @released
*
*/


#include "cluster.h"


//Initialize the Static CCluster instance pointer
CCluster* CCluster::iClusterInstance = NULL;

/**
Static function which is used to instantiate and return the address of CCluster class.

@internalComponent
@released

@param aClusterSize - single cluster size in Bytes
@param aTotalNumberOfClusters - Maximum number of clusters
@return - returns the instance of CCluster class
*/

CCluster* CCluster::Instance(unsigned int aClusterSize,unsigned int aTotalNumberOfClusters) 
{
	if (iClusterInstance == NULL)  // is it the first call?
    {  
		// create sole instance
		iClusterInstance = new CCluster(aClusterSize, aTotalNumberOfClusters);
    }
    return iClusterInstance; // address of sole instance
}

/**
Destructor: Clears the clusters per entry map

@internalComponent
@released
*/
CCluster::~CCluster ()
{
	iClustersPerEntry.clear();
	iClusterInstance = NULL;
}


/**
Constructor Receives inputs from dirregion Class and initializes the class variables

@internalComponent
@released

@param aClusterSize - Size of every Cluster
@param aTotalNumberOfClusters - maximum number of clusters allowed for current FAT image
*/
CCluster::CCluster(unsigned int aClusterSize, unsigned int aTotalNumberOfClusters)
				   :iClusterSize(aClusterSize),iTotalNumberOfClusters(aTotalNumberOfClusters)
{
	iRootClusterNumber = KRootClusterNumber;
	iCurrentClusterNumber = iRootClusterNumber;
}

/**
Function to return the current cluster number

@internalComponent
@released

@return - returns the current cluster number
*/
unsigned int CCluster::GetCurrentClusterNumber() const
{
	return iCurrentClusterNumber;
}

/** 
Function to decrement the current cluster number

@internalComponent
@released
*/
void CCluster::DecrementCurrentClusterNumber()
{
	--iCurrentClusterNumber;
}

/**
Function to get the High word of Current cluster number

@internalComponent
@released

@return - returns the 16 bit HIGH word
*/
unsigned short int CCluster::GetHighWordClusterNumber() const
{
	return (unsigned short)(iCurrentClusterNumber >> KBitShift16);
}

/**
Function to get the Low word of Current cluster number

@internalComponent
@released

@return - returns the 16 bit LOW word
*/
unsigned short int CCluster::GetLowWordClusterNumber() const
{
	return (unsigned short)(iCurrentClusterNumber & KHighWordMask);
}


/**
Function responsible to 
1. Increment the current Cluster Number 
2. Throw the error "image size too big" if the allocated clusters count exceeds total
number of available clusters.

@internalComponent
@released
*/
void CCluster::UpdateNextAvailableClusterNumber()
{
	if(iCurrentClusterNumber >= iTotalNumberOfClusters)
	{
    	throw ErrorHandler(IMAGESIZETOOBIG,"Occupied number of clusters count exceeded than available clusters",__FILE__,__LINE__);
	}
	++iCurrentClusterNumber;
}

/**
Function to Return the cluster size

@internalComponent
@released

@return the cluster size
*/
unsigned int CCluster::GetClusterSize() const
{
	return iClusterSize;
}

/**
Function Creates mapping between starting cluster number (where data starts) and 
the sub sequent cluster numbers (where the data extends).

@internalComponent
@released

@param aStartingClusterNumber - Cluster number where the data starts
@param aPairClusterNumber - Cluster number where the data extends
*/
void CCluster::CreateMap(unsigned int aStartingClusterNumber,unsigned int aPairClusterNumber)
{
	iClustersPerEntry.insert(make_pair(aStartingClusterNumber,aPairClusterNumber));
}

/**
Function to get Clusters per Entry MAP container.

@internalComponent
@released

@return - returns the CLusters per entry container
*/

TClustersPerEntryMap* CCluster::GetClustersPerEntryMap()
{
	return &iClustersPerEntry;
}
