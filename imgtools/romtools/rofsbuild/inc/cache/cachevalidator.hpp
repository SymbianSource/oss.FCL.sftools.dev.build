/**
 * @file cachevalidator.hpp
 */


#ifndef ROM_TOOLS_ROFSBUILD_CACHE_CACHEVALIDATOR_H_
#define ROM_TOOLS_ROFSBUILD_CACHE_CACHEVALIDATOR_H_


/**
 * @class CacheValidator
 * @brief Validate an existing cache entry.
 */
class CacheValidator
{
public:
	/**
	 * @fn CacheValidator* CacheValidator::GetInstance(void)
	 * @brief Get singleton instance of class CacheValidator.
	 * @return The singleton instance.
	 * @exception CacheException Catch allocation failures.
	 */
	static CacheValidator* GetInstance(void) throw (CacheException);

	/**
	 * @fn CacheEntry* CacheValidator::Validate(const char* OriginalFilename, int CurrentCompressionID)
	 * @brief Validate cached executable with original version.
	 * @param OriginalFilename The filename of original executable.
	 * @param CurrentCompressionID The ID of compression method used over current image build.
	 * @return The entry for cached file or zero if the given executable file is invalidated.
	 */
	CacheEntry* Validate(const char* OriginalFilename, int CurrentCompressionID);
protected:
	static CacheValidator* Only;
private:
	CacheValidator(void);

	CacheValidator(const CacheValidator&);

	CacheValidator& operator = (const CacheValidator&);
};


#endif  /* defined ROM_TOOLS_ROFSBUILD_CACHE_CACHEVALIDATOR_H_ */
