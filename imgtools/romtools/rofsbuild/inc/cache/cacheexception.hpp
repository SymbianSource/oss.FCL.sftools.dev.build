/**
 * @file cacheexception.hpp
 */


#ifndef ROM_TOOLS_ROFSBUILD_CACHE_CACHEEXCEPTION_H_
#define ROM_TOOLS_ROFSBUILD_CACHE_CACHEEXCEPTION_H_


/**
 * @class CacheException
 * @brief Encapsulates all possible failures happening inside cache.
 */
class CacheException
{
public:
	/**
	 * @fn CacheException::CacheException(int ErrorCode)
	 * @brief Constructor
	 * @param ErrorCode The error code, must be one of the static constants.
	 */
	CacheException(int ErrorCode);

	/**
	 * @fn int CacheException::GetErrorCode(void)
	 * @brief Retrieve integer error number.
	 * @reurn The error code.
	 */
	int GetErrorCode(void);

	/**
	 * @fn const char* CacheException::GetErrorMessage(void)
	 * @brief Retrieve text error message.
	 * @return The error message.
	 */
	const char* GetErrorMessage(void);

	virtual ~CacheException(void);

	static int EPOCROOT_NOT_FOUND         ;
	static int RESOURCE_ALLOCATION_FAILURE;
	static int CACHE_NOT_FOUND            ;
	static int CACHE_INVALID              ;
	static int CACHE_IS_EMPTY             ;
	static int HARDDRIVE_FAILURE          ;
protected:
	int errcode;
private:
	CacheException(void);

	CacheException& operator = (const CacheException&);
};


#endif  /* defined ROM_TOOLS_ROFSBUILD_CACHE_CACHEEXCEPTION_H_ */
