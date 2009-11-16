// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "tc_bTraces.h"
#endif

#include "e32def.h"

TInt tc_b()
{
	OstTrace0( TRACE_NORMAL, PLACE3, "source tc_b" );
	return 0;
}
