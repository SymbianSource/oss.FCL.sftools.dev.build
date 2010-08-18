// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "child2Traces.h"
#endif

#include "e32def.h"

TInt E32Main()
{
	OstTrace0( TRACE_NORMAL, PLACE2, "Child 2" );
	return 0;
}
