/**
 * @file cacheentry.hpp
 */


#ifndef ROM_TOOLS_ROFSBUILD_CACHE_CACHEENTRY_H_
#define ROM_TOOLS_ROFSBUILD_CACHE_CACHEENTRY_H_


/**
 * @class CacheEntry
 * @brief CacheEntry holds both original executable data and cached executable data.
 */
class CacheEntry
{
public:
	CacheEntry(void);

	/**
	 * @fn void CacheEntry::SetOriginalFilename(const char* OriginalFilename)
	 * @brief Assign the original filename of the executable to be cached.
	 * @param OriginalFilename The original filename.
	 */
	void SetOriginalFilename(const char* OriginalFilename);

	/**
	 * @fn const char* CacheEntry::GetOriginalFilename(void)
	 * @return The original filename.
	 */
	const char* GetOriginalFilename(void) const;

	void SetCachedFilename(const char* CachedFilename);

	const char* GetCachedFilename(void) const;

	void SetOriginalFileCreateTime(time_t* CreateRawTime);

	void SetOriginalFileCreateTime(const char* CreateRawTime);

	const char* GetOriginalFileCreateTime(void) const;

	void SetOriginalFileCompression(const char* CompressionMethodID);

	void SetOriginalFileCompression(unsigned int CompressionMethodID);

	const char* GetOriginalFileCompressionID(void) const;

	void SetCachedFileCompression(const char* CompressionMethodID);

	void SetCachedFileCompression(unsigned int CompressionMethodID);

	const char* GetCachedFileCompressionID(void) const;

	void SetCachedFileBuffer(char* FileBuffer, int FileBufferLen);

	const char* GetCachedFileBuffer(void) const;

	int GetCachedFileBufferLen(void) const;

	void AppendEntry(CacheEntry* EntryRef);

	CacheEntry* GetNextEntry(void) const;

	void SetNextEntry(CacheEntry* EntryRef);

	bool Equals(CacheEntry* EntryRef);

	virtual ~CacheEntry(void);
protected:
	std::string originalfile;

	std::string cachedfile;

	std::string originalfilecreatetime;

	std::string originalfilecompression;

	std::string cachedfilecompression;

	std::string compressionenabled;

	std::string compressionindicator;

	CacheEntry* next;

	char* cachedfilebuffer;

	int cachedfilebuffersize;
private:
	CacheEntry(const CacheEntry&);

	CacheEntry& operator = (const CacheEntry&);
};


#endif  /* defined ROM_TOOLS_ROFSBUILD_CACHE_CACHEENTRY_H_ */
