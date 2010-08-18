/**
 * @file cachegenerator.hpp
 */


#ifndef ROM_TOOLS_ROFSBUILD_CACHE_CACHEGENERATOR_H_
#define ROM_TOOLS_ROFSBUILD_CACHE_CACHEGENERATOR_H_


/**
 * @class CacheGenerator
 * @brief Cache Generator will be running in a separated thread, its job is to pick up an invalidated entry from the CacheableList and then write the content into the cache.
 */
class CacheGenerator : public boost::thread
{
public:
	/**
	 * @fn static CacheGenerator* CacheGenerator::GetInstance(void)
	 * @brief Get singleton instance.
	 * @return The singleton instance.
	 * @exception CacheException Catch resource allocation failures.
	 */
	static CacheGenerator* GetInstance(void) throw (CacheException);

	/**
	 * @fn void CacheGenerator::ProcessFiles(void)
	 * @brief Pick up an invalidated entry from the cacheable list and write the content into the cache (i.e. under cache root directory).
	 */
	static void ProcessFiles(void) throw (CacheException);
protected:
	static CacheGenerator* Only;
private:
	CacheGenerator(void);

	CacheGenerator(const CacheGenerator&);

	CacheGenerator& operator = (const CacheGenerator&);
};


#endif  /* defined ROM_TOOLS_ROFSBUILD_CACHE_CACHEGENERATOR_H_ */
