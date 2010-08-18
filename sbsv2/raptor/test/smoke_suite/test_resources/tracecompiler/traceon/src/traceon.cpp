// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "traceonTraces.h"
#endif

#include "e32def.h"

char test[] = "test traces keyword";

TInt E32Main()
{
	OstTrace0( TRACE_NORMAL, PLACE0, "Test TRACES mmpkeyword" );
	return 0;
}
