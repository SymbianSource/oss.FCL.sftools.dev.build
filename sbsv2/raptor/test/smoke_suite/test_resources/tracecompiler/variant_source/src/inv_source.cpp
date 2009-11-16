// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "inv_sourceTraces.h"
#endif

#include "e32def.h"

char test[] = "invariant source";

TInt E32Main()
{
	OstTrace0( TRACE_NORMAL, PLACE0, "Invariant Source" );
	return 0;
}
