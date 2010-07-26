// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "var_source1Traces.h"
#endif

#include "e32def.h"

char test[] = "variant source 1";

TInt E32Main()
{
	OstTrace0( TRACE_NORMAL, PLACE1, "Variant Source 1" );
	return 0;
}
