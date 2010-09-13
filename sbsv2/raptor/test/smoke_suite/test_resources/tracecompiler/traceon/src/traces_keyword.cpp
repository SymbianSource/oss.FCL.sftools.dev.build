// Trace compile macro and header
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "traces_keywordTraces.h"
#endif

#include "e32def.h"

char test[] = "test traces keyword with a parameter";

TInt E32Main()
{
	OstTrace0( TRACE_NORMAL, PLACE0, "Test TRACES mmpkeyword" );
	return 0;
}
