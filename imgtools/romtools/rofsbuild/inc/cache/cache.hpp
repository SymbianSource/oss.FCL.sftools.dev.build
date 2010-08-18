/**
 * @file cache.hpp
 */


#ifndef ROM_TOOLS_ROFSBUILD_CACHE_CACHE_H_
#define ROM_TOOLS_ROFSBUILD_CACHE_CACHE_H_


#define BOOST_FILESYSTEM_NO_DEPRECATED


/**
 * @class Cache
 * @brief Cache
 */
class Cache
{
public:
	/**
	 * @fn static Cache* Cache::GetInstance(void)
	 * @brief Retrieve singleton instance of class Cache.
	 * @return The singleton instance.
	 */
	static Cache* GetInstance(void) throw (CacheException);

	/**
	 * @fn void Cache::Initialize(path* CacheRoot)
	 * @brief Load Cache meta data file and initialize inner structures.
	 * @exception CacheException I/O operation failures or resource allocation failures.
	 */
	void Initialize(void) throw (CacheException);

	/**
	 * @fn CacheEntry Cache::GetEntryList(const char* OriginalFilename)
	 * @param OriginalFilename The filename of original executable which is being cached.
	 * @return A list of cached items for the original executables or NULL if there's no entries match the original filename.
	 */
	CacheEntry* GetEntryList(const char* OriginalFilaname);

	/**
	 * @fn void Cache::SetEntry(const char* OriginalFilename, CacheEntry* EntryRef)
	 * @brief Add a new cache entry into cache or update an existing cache entry.
	 * @param OriginalFilename The filename of the original executable file.
	 * @param EntryRef The address pointing to an instance of class CacheEntry, must be valid, verified by the caller.
	 */
	void AddEntry(const char* OriginalFilename, CacheEntry* EntryRef);

	/**
	 * @fn void Cache::CloseCache(void)
	 * @brief Update cache with all cache entries.
	 * @exception CacheException Catch errors occurring when the Cache gets updated.
	 */
	void CloseCache(void) throw (CacheException);
protected:
	bool ValidateEntry(std::string& EntryRawText);

	static Cache* Only;

	std::string metafile;

	boost::mutex cachemutex;

	std::map<std::string, CacheEntry*> entrymap;
private:
	Cache(void);

	Cache(const Cache&);

	Cache& operator = (const Cache&);
};


#endif  /* defined ROM_TOOLS_ROFSBUILD_CACHE_CACHE_H_ */
