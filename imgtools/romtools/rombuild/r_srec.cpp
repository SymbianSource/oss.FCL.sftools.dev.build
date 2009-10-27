/*
* Copyright (c) 1996-2009 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of the License "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description: 
*
*/


#include "r_rom.h"
#include "r_obey.h"

#include <e32std.h>
#include <e32std_private.h>

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
#include <iostream>
#include <fstream>
#else //!__MSVCDOTNET__
#include <iostream.h>
#include <fstream.h>
#endif //__MSVCDOTNET__

#include <string.h>

const TInt KSRecBytesPerLine=32;		// max line = 1+1+2+8 + (32*2) + 2 = 78

LOCAL_C TInt enchex(TUint nibble)
//
// Return ascii hex character corresponding to nibble
//
    {

    nibble&=0xf;
    return(nibble<=9 ? '0'+nibble : 'A'-10+nibble);
    }

GLDEF_C TUint putbhx(TUint8 *buf,TUint byte)
//
// Write byte to buffer as two hex digits
//
    {

    *buf++ = (TUint8)enchex(byte>>4);
    *buf++ = (TUint8)enchex(byte);
	return byte&0xff;
    }

GLDEF_C TInt putmot(TUint8 *mcode, TUint8 *mdata,TUint mlen,TUint addr)
//
// Write SREC or S19 format to buffer at mcode from mlen bytes of binary data
// stored in buffer mdata. The code is given address addr.
// Returns the number of bytes written to mcode.
//
    {
    TUint8 *p,*q,*qend;
    TUint  sum,byte;

    p=mcode;
    *p='S';
#ifdef ALLOW_S_RECORD_THREE_BYTE_ADDRESSES
	// This is an optimisation which is useful for S-Record downloads over serial cable
	// but some S-Record tools don't support it, so it's off by default.
	if ((TUint)((addr>>24)&0xff) == 0)
		{
		*(p+1)='2';		// 3-byte address field
		sum=putbhx(p+=2,3+mlen+1);
 		}
	else
#endif
		{
		*(p+1)='3';		// 4-byte address field
		sum=putbhx(p+=2,4+mlen+1);
		sum+=putbhx(p+=2,(TUint)((addr>>24)&0xff));
		}
    sum+=putbhx(p+=2,(TUint)((addr>>16)&0xff));
    sum+=putbhx(p+=2,(TUint)((addr>>8)&0xff));
    sum+=putbhx(p+=2,(TUint)addr);
    q=mdata;
    qend=mdata+mlen;
    for (q=mdata;q<qend;q++)
		{
		byte=(*q);
		sum+=putbhx(p+=2,byte);
		}
	putbhx(p+=2,~sum);
    return((TUint)(p-mcode+2));
    }

void E32Rom::WriteSRecord(ofstream &of)
//
// Write the rom to a file in S record format and return its check sum.
//
	{

	TInt i;
	TUint8 sBuf[256];
	of << "S00600004844521B\n";
	TInt size=iObey->iRomSize;
	TUint8 *ptr=(TUint8 *)iHeader;
	for (i=0; i<size; i+=KSRecBytesPerLine)
		{
		TInt len;
		if ((i+KSRecBytesPerLine)>size)
			len=size-i;
		else
			len=KSRecBytesPerLine;
		TUint8 *pS=ptr+i;
		TInt l=putmot(sBuf,pS,len,i+iObey->iSRecordBase);
		of.write(reinterpret_cast<char *>(sBuf), l);
		of<<endl;
		}
	of << "S70500000000FA\n";		// Fixed address! - would need to compute the checksum
	}

