// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "tc_cTraces.h"
#endif

#include "e32def.h"

TInt tc_c()
{
	OstTrace0( TRACE_NORMAL, PLACE4, "source tc_c" );
	return 0;
}
