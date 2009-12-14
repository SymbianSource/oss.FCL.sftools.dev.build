// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "var_source2Traces.h"
#endif

#include "e32def.h"

TInt var_source2()
{
	OstTrace0( TRACE_NORMAL, PLACE2, "Variant Source 2" );
	return 0;
}
