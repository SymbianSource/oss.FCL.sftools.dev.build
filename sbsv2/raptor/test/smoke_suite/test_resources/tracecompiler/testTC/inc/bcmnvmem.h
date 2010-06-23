/*
 * Broadcom implementation of Nokia WLAN Hardware Abstraction layer
 *
 * Copyright (C) 2008, Broadcom Corporation
 * All Rights Reserved.
 * 
 * This is UNPUBLISHED PROPRIETARY SOURCE CODE of Broadcom Corporation;
 * the contents of this file may not be disclosed to third parties, copied
 * or duplicated in any form, in whole or in part, without the prior
 * written permission of Broadcom Corporation.
 *
 * $Id: bcmnvmem.h,v 1.2.2.4.4.1 2008/09/08 22:53:16 Exp $
 */

#ifndef BCMNVMEM_H
#define BCMNVMEM_H

#include <wlanwhanamespace.h>

// Values larger than 8 bits are stored in little-endian format
// Total size: 320 bytes

NAMESPACE_BEGIN_WHA

#define BCM_NVMEM_MAGIC1                (TUint8)'N'     // 78
#define BCM_NVMEM_MAGIC2                (TUint8)'V'     // 86
#define BCM_NVMEM_MAGIC3                (TUint8)'M'     // 77
#define BCM_NVMEM_VERSION               3

#define BCM_NVMEM_FLAG_VERIFY           0x00000001

#ifndef BCM_NVMEM_PACKED
#define BCM_NVMEM_PACKED                // For packed-ness testing only
#endif

struct SNvMem {
    TUint8      magic1;
    TUint8      magic2;
    TUint8      magic3;
    TUint8      version;

    // Broadcom WHA section
    TUint32     whaflags;
    TUint8      whaspiclklo;
    TUint8      whaspiclkhi;
    TUint8      whamac[6];

    // Broadcom device section
    TUint16     xtalfreq;
    TUint16     manfid;
    TUint16     prodid;
    TUint16     sromrev;
    TUint16     vendid;
    TUint16     devid;
    TUint16     boardtype;
    TUint16     boardrev;
    TUint32     boardflags;
    TUint32     boardflags2;
    TUint16     opo;
    TUint16     pa0b0;
    TUint16     pa0b1;
    TUint16     pa0b2;
    TUint16     pa0b3;
    TUint16     pa0b4;
    TUint16     pa0b5;
    TUint16     pa0b6;
    TUint16     pa0b7;
    TUint16     pa0b8;
    TUint8      rssismf2g;
    TUint8      rssismc2g;
    TUint8      rssisav2g;
    TUint8      rssismf2g_low0;
    TUint8      rssismc2g_low1;
    TUint8      rssisav2g_low2;
    TUint8      rssismf2g_hi1;
    TUint8      rssismc2g_hi2;
    TUint8      rssisav2g_hi3;
    TUint8      pa0itssit;
    TUint8      tri2g;
    TUint8      rxpo2g;
    TUint16     pa0maxpwr;
    TUint16     aa2g;
    TUint16     ag0;
    TUint16     cctl;
    TUint32     boardnum;
    TUint8      bxa2g;
    TUint8      _pad2[43];

    // Bob WLAN NW Memory device section (based on Draft 0.3)
    TUint8      PL_2G_hdb;              /* Table 1 */
    TUint8      PL_5G_hdb;
    TUint16     rfq_2G;
    TUint16     rfq_4G;
    TUint16     rfq_5G_l;
    TUint16     rfq_5G_m;
    TUint16     rfq_5G_h;
    TUint16     pd_2G;
    TUint16     pd_4G;
    TUint16     pd_5G_l;
    TUint16     pd_5G_m;
    TUint16     pd_5G_h;
    TUint8      txg_2G;
    TUint8      txg_4G;
    TUint8      txg_5G_l;
    TUint8      txg_5G_m;
    TUint8      txg_5G_h;
    TUint8      P2G_PL1_hdb[9];         /* Table 2a (bumped to 9 entries for 11n) */
    TUint8      P2G_PL2_hdb[9];
    TUint8      P2G_PL3_hdb[9];
    TUint8      P2G_PL4_hdb[9];
    TUint8      P5G_PL1_hdb[8];         /* Table 2b */
    TUint8      P5G_PL2_hdb[8];
    TUint8      P5G_PL3_hdb[8];
    TUint8      P5G_PL4_hdb[8];
    TUint8      cga_cck_2G[14];         /* Table 4 */
    TUint8      cga_ofdm_2G[13];
    TUint8      cga_j_4G[4];
    TUint8      cga_j_5G[3];
    TUint8      cga_5G_l[8];
    TUint8      cga_5G_m[4];
    TUint8      cga_5G_u1[11];
    TUint8      cga_5G_u11[4];
    TUint8      pab_2G[6];              /* Table 5 */
    TUint8      pab_5G[6];
    TUint8      rssi_adj_2G;            /* Table 6 */
    TUint8      rssi_adj_j_5G;
    TUint8      rssi_adj_5G_l;
    TUint8      rssi_adj_5G_m;
    TUint8      rssi_adj_5G_h;
    TUint8      _pad3[19];
} BCM_NVMEM_PACKED;

NAMESPACE_END_WHA

#endif  // BCMNVMEM_H
