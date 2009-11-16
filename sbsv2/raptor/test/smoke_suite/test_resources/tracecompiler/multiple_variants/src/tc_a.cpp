// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "tc_aTraces.h"
#endif

#include "e32def.h"

TInt tc_a()
{
	OstTrace0( TRACE_NORMAL, PLACE2, "source tc_a" );
	return 0;
}
