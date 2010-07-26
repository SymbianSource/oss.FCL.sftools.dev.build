// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "var_source3Traces.h"
#endif

#include "e32def.h"


TInt var_source3()
{
	OstTrace0( TRACE_NORMAL, PLACE3, "Variant Source 3" );
	return 0;
}
