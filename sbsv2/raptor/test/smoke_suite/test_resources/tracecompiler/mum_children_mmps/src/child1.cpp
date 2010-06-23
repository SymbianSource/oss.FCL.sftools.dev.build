// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "child1Traces.h"
#endif

#include "e32def.h"

char test[] = "Child 1";

TInt E32Main()
{
	OstTrace0( TRACE_NORMAL, PLACE1, "Child 1" );
	return 0;
}
