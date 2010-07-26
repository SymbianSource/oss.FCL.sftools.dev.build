/**
 * @file cacheablelist.hpp
 */


#ifndef ROM_TOOLS_ROFSBUILD_CACHE_CACHEABLELIST_H_
#define ROM_TOOLS_ROFSBUILD_CACHE_CACHEABLELIST_H_


/**
 * @class CacheableList
 * @brief CacheableList is used to hold buffers for executable files to be written into the cache.
 */
class CacheableList
{
public:
	/**
	 * @fn CacheableList* CacheableList::GetInstance(void)
	 * @return The singleton instance of class CacheableList.
	 * @exception CacheException Not enough system resource to create an instance at the first this method gets called.
	 */
	static CacheableList* GetInstance(void) throw (CacheException);

	/**
	 * @fn void CacheableList::AddCacheable(CacheEntry* EntryRef)
	 * @brief Add a file which needs to be cached into the list, cache generator will process this list.
	 * @param EntryRef The instance of CacheEntry, it represents the file which is going to be cached.
	 */
	void AddCacheable(CacheEntry* EntryRef);

	/**
	 * @fn CacheEntry* CacheableList::GetCacheable(void)
	 * @brief Retrieve a file from this list and write it into cache, the write operation is performed by cache generator.
	 * @return The instance of CacheEntry, used by cache generator.
	 */
	CacheEntry* GetCacheable(void);

	virtual ~CacheableList(void);
protected:
	static CacheableList* Only;

	std::queue<CacheEntry*> filelist;

	boost::condition_variable queuecond;

	boost::mutex queuemutex;
private:
	CacheableList(void);

	CacheableList(const CacheableList&);

	CacheableList& operator = (const CacheableList&);
};


#endif  /* defined ROM_TOOLS_ROFSBUILD_CACHE_CACHEABLELIST_H_ */
