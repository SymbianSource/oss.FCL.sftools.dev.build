// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "child3Traces.h"
#endif

#include "e32def.h"


TInt E32Main()
{
	OstTrace0( TRACE_NORMAL, PLACE3, "Child 3" );
	return 0;
}
