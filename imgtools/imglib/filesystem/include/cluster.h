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
* Cluster class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef CLUSTER_H
#define CLUSTER_H

#include "errorhandler.h"
#include "directory.h"

typedef std::multimap <unsigned int,unsigned int> TClustersPerEntryMap;

/*
 * This class is used by classes CDirRegion and CLongName. This class describes 
 * the basic Data members and Member functions related to cluster number 
 * allocation and FAT input map creation.
 *
 * @internalComponent
 * @released
 */

class CCluster
{
	public:
		static CCluster* Instance (unsigned int aClusterSize, 
								   unsigned int aTotalNumberOfClusters);

		unsigned int GetCurrentClusterNumber() const;
		void DecrementCurrentClusterNumber();
		unsigned short int GetHighWordClusterNumber() const;
		unsigned short int GetLowWordClusterNumber() const;
		void CreateMap(unsigned int aStartingClusterNumber,unsigned int aPairClusterNumber);
		TClustersPerEntryMap* GetClustersPerEntryMap();
		void UpdateNextAvailableClusterNumber();
		unsigned int GetClusterSize() const;
		~CCluster ();

	private:
		CCluster(unsigned int aClusterSize,
				 unsigned int aTotalNumberOfClusters);
		static CCluster* iClusterInstance;

		unsigned long int iClusterSize;
		unsigned int iRootClusterNumber;
		unsigned int iCurrentClusterNumber;
		unsigned int iTotalNumberOfClusters;

		
		/* used to store the mapping of Starting cluster and Number's of
		 * clusters occupied by the specific entry
		 */
		TClustersPerEntryMap iClustersPerEntry;
};

#endif //CLUSTER_H
