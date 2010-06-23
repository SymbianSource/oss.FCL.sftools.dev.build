// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "tc_mainTraces.h"
#endif

#include "e32def.h"

char test[] = "source tc_main";

TInt E32Main()
{
	OstTrace0( TRACE_NORMAL, PLACE1, "source tc_main" );
	return 0;
}
