/**
 * @file cachemanager.hpp
 */


#ifndef ROM_TOOLS_ROFSBUILD_CACHE_CACHEMANAGER_H_
#define ROM_TOOLS_ROFSBUILD_CACHE_CACHEMANAGER_H_


#define BOOST_FILESYSTEM_NO_DEPRECATED


/**
 * @class CacheManager
 * @brief Managing cache content and the processing of generating/updating cache.
 * @note CacheManager will accept forward slashes as file separators and all input filenames will be normalized.
 */
class CacheManager
{
public:
	/**
	 * @fn static CacheManager* CacheManager::GetInstance(void)
	 * @brief This method is thread-safe as it's using double-check pattern for singleton creation.
	 * @exception CacheException Catch initialization failures.
	 * @return Retrieve the singleton instance of class CacheManager.
	 */
	static CacheManager* GetInstance(void) throw (CacheException);

	/**
	 * @fn E32ImageFile* CacheManager::GetE32ImageFile(char* Filename, int CurrentCompressionID)
	 * @brief Retrieve an instance of class E32ImageFile.
	 * @param OriginalFilename The filename of the original file.
	 * @param CurrentCompressionID The ID of compression method used over current image build.
	 * @return Instance of class E32ImageFile or NULL if the original file has not been cached yet.
	 */
	E32ImageFile* GetE32ImageFile(char* OriginalFilename, int CurrentCompressionID);

	/**
	 * @fn CacheEntry* CacheManager::GetE32ImageFileRepresentation(char* OriginalFilename, int CurrentCompressionID, int FileFlags)
	 * @param OriginalFilename The filename of the original executable file.
	 * @param CurrentCompressionID
	 * @return A valid cached entry or NULL if the original file has not been cached yet.
	 */
	CacheEntry* GetE32ImageFileRepresentation(char* OriginalFilename, int CurrentCompressionID);

	/**
	 * @fn void CacheManager::Invalidate(const char* Filename)
	 * @brief Add an invalidated cache entry into the cacheable list.
	 * @param Filename The filename of the original file.
	 * @param EntryRef The reference of newly created CacheEntry instance.
	 * @exception CacheException Catch resource allocation failures.
	 */
	void Invalidate(char* Filename, CacheEntry* EntryRef) throw (CacheException);

	/**
	 * @fn void CacheManager::CleanCache(void)
	 * @brief Remove all cache content from hard drive.
	 * @exception CacheException Catch I/O failures on deletion.
	 */
	void CleanCache(void) throw (CacheException);

	/**
	 * @fn const char* CacheManager::GetCacheRoot(void)
	 * @brief Retrieve the root directory of cache.
	 * @return The absolute path of root directory.
	 */
	const char* GetCacheRoot(void);

	/**
	 * @fn CacheManager::~CacheManager(void)
	 * @brief Clean up allocated resources and writes Cache class back in the cache.
	 * @note It's important to delete CacheManager instance if you created it with new operation.
	 */
	virtual ~CacheManager(void);

	/**
	 * @fn void CacheManager::NormalizeFilename(char* Filename)
	 * @brief Convert back slashes into forward slashes and remove redundant slashes.
	 * @param Filename The filename which will be normalized when this function gets returned.
	 */
	void NormalizeFilename(char* Filename);
protected:
	void InitializeCache(void) throw (CacheException);

	char* cacheroot;

	static boost::mutex creationlock;

	static CacheManager* Only;
private:
	CacheManager(void);

	CacheManager(const CacheManager&);

	CacheManager& operator = (const CacheManager&);
};


#endif  /* defined ROM_TOOLS_ROFSBUILD_CACHE_CACHEMANAGER_H_ */
