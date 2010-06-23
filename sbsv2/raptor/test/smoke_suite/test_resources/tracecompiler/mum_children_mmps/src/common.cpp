// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "commonTraces.h"
#endif

#include "e32def.h"


TInt common()
{
	OstTrace0( TRACE_NORMAL, PLACE0, "Common file shared by all mmp files" );
	return 0;
}
