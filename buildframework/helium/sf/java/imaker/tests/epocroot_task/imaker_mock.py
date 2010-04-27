#============================================================================ 
#Name        : imaler_mock.py 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description:
#===============================================================================

import sys
print "iMaker 09.24.01, 10-Jun-2009."

if sys.argv.count("version"):
    print ""
    sys.exit(0)

# two product supported by the mock
if sys.argv.count("help-config"):
    print "Finding available configuration file(s):"
    print "/epoc32/rom/config/platform/product/image_conf_product.mk"
    print "/epoc32/rom/config/platform/product/image_conf_product_ui.mk"
    print ""
    sys.exit(0)

# List of targets
if sys.argv.count("help-target-*-list"):
    # start with some kind of warnings...
    print "all"
    print "core"
    print "core-dir"
    print "help-%-list"
    print "langpack_01"
    print ""
    sys.exit(0)




def print_log(log):
    for line in log:
        print line


core_log = ["iMaker 09.42.01, 13-Oct-2009.", 
"Generating content with ConE",
"* Writing tmp2.oby - result of substitution phase",
"* Writing tmp3.oby - result of reorganisation phase",
"* Writing tmp4.oby - result of Plugin stage",
"* Writing tmp5.oby - result of choosing language-specific files",
"* Writing tmp7.oby - result of problem-suppression phase",
"* Writing tmp8.oby - result of bitmap conversion phase",
"* Removing previous image and logs...",
"* Writing tmp9.oby - result of cleaning phase",
"* Writing NAME_VERSION04_rnd.oby - final OBY file",
"* Writing NAME_VERSION04_rnd.rom.oby - final OBY file",
"* Writing NAME_VERSION04_rnd.dir - ROM directory listing",
"-------------------------------------------------------------------------------",
"Total duration: 01:42  Status: OK",
"===============================================================================",
]

if sys.argv.count("core"):
    print_log(core_log)
    print ""
    sys.exit(0)

rof2_log = ["iMaker 09.42.01, 13-Oct-2009.", 
"Generating content with ConE",
"Variant target             USE_VARIANTBLD = `2'",
"Variant directory          VARIANT_DIR    = `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/temp/cone'",
"Variant config makefile    VARIANT_MK     = `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/temp/cone/language_variant.mk'",
"Variant include directory  VARIANT_INCDIR = `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/temp/cone/include'",
"Variant SIS directory      VARIANT_SISDIR = -",
"Variant operator cache dir VARIANT_OPCDIR = -",
"Variant widget preinst dir VARIANT_WGZDIR = -",
"Variant zip content dir    VARIANT_ZIPDIR = -",
"Variant copy content dir   VARIANT_CPDIR  = `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/temp/cone/content'",
"Variant output directory   VARIANT_OUTDIR = `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/variant'",
"Generating oby(s) for Variant image creation",
"Copying copy content directory",
"Generating Feature manager file(s)",
"Generating file(s) for ROFS2 image creation",
"Generating language files for Language Package image creation",
"Creating ROFS2 SOS image",
"",
"ROM_IMAGE[0] non-xip size=0x00000000 xip=0 compress=0 extension=0 composite=none uncompress=0", 
"ROM_IMAGE[1] dummy1 size=0x10000000 xip=0 compress=0 extension=0 composite=none uncompress=0 ",
"ROM_IMAGE[2] rofs2 size=0x10000000 xip=0 compress=0 extension=0 composite=none uncompress=0 ",
"ROM_IMAGE[3] dummy3 size=0x10000000 xip=0 compress=0 extension=0 composite=none uncompress=0 ",
"* Writing tmp2.oby - result of substitution phase",
"* Writing tmp3.oby - result of reorganisation phase",
"* Writing tmp4.oby - result of Plugin stage",
"* Writing tmp5.oby - result of choosing language-specific files",
"Created ecom-2-0.spi",
"Created ecom-2-1.s06",
"Created ecom-2-2.s15",
"Created ecom-2-3.s07",
"Created ecom-2-4.s08",
"Created ecom-2-5.s09",
"Created ecom-2-6.s01",
"* Writing tmp6.oby - result of SPI stage",
"override.pm: ------------------------------------------------------------------",
"Handling overrides...Replace ROM_IMAGE[2] `data=\epoc32\data\Z\Resource\bootdata\languages.txt   resource\Bootdata\languages.txt' with `data=I:/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/NAME_VERSION04_rnd_rofs2_languages.txt  resource\Bootdata\languages.txt'",
"Replace ROM_IMAGE[2] `data=\epoc32\data\Z\Resource\versions\lang.txt        resource\versions\lang.txt' with `data=I:/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/NAME_VERSION04_rnd_rofs2_lang.txt  resource\versions\lang.txt'",
"Replace ROM_IMAGE[2] `data=\epoc32\data\Z\Resource\versions\langsw.txt        resource\versions\langsw.txt' with `data=I:/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/NAME_VERSION04_rnd_rofs2_langsw.txt  resource\versions\langsw.txt'",
"override.pm: Duration: 1 seconds ----------------------------------------------",
"obyparse.pm: ------------------------------------------------------------------",
"Finding include hierarchy from tmp1.oby",
"Found 730 different include files",
"Finding SPI input files from tmp5.oby",
"Found 103 SPI input files",
"Reading UDEB files from /epoc32/rombuild/mytraces.txt",
"Found 0 entries",
"Finding ROM-patched components",
"Found 0 ROM-patched components",
"obyparse.pm: Duration: 2 seconds ----------------------------------------------",
"* Writing tmp7.oby - result of problem-suppression phase",
"* Writing tmp8.oby - result of bitmap conversion phase",
"* Removing previous image and logs...",
"* Writing tmp9.oby - result of cleaning phase",
"* Writing NAME_VERSION04_rnd.oby - final OBY file",
"* Writing NAME_VERSION04_rnd.rofs2.oby - final OBY file",
"* Writing NAME_VERSION04_rnd.dir - ROM directory listing",
"* Executing rofsbuild -slog -loglevel1     NAME_VERSION04_rnd.rofs2.oby",
"The number of processors (4) is used as the number of concurrent jobs.",
"",
"ROFSBUILD - Rofs/Datadrive image builder V2.6.3",
"Copyright (c) 1996-2009 Nokia Corporation.",
"",
"WARNING: Unknown keyword 'OM_IMAGE[0]'.  Line 31 ignored",
"WARNING: Unknown keyword '-----------------------------------------------------------'.  Line 2464 ignored",
"WARNING: Unknown keyword 'OM_IMAGE[0]'.  Line 31 ignored",
"WARNING: Unknown keyword '-----------------------------------------------------------'.  Line 2464 ignored",
"* rofsbuild failed",
"",
"*** Error: (S:ROFS2,C:1,B:1,K:0,V:1): Command `buildrom -loglevel1 -v -nosymbols -DFEATUREVARIANT=product -fm=/epoc32/include/s60regionalfeatures.xml -es60ibymacros -elocalise -oNAME_VERSION04_rnd.img I:/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/NAME_VERSION04_rnd_rofs2_master.oby' failed (1) in `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2'.",
"===============================================================================",
"Target: langpack_01  Duration: 01:40  Status: FAILED",
"ConE output dir = `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/temp/cone'",
"ConE log file   = `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/NAME_VERSION04_rnd_cone_langpack_01.log'",
"ROFS2 dir       = `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2'",
"ROFS2 symbols   = `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/NAME_VERSION04_rnd.rofs2.symbol'",
"ROFS2 flash     = `/output/release_flash_images/product/rnd/langpack/langpack_01/NAME_VERSION04_rnd.rofs2.fpsx'",
"-------------------------------------------------------------------------------",
"Total duration: 01:42  Status: FAILED",
"===============================================================================",
]

if sys.argv.count("langpack_01"):
    print_log(rof2_log)
    sys.stderr.write("*** Error: (S:ROFS2,C:1,B:1,K:0,V:1): Command `buildrom -loglevel1 -v -nosymbols -DFEATUREVARIANT=product -fm=/epoc32/include/s60regionalfeatures.xml -es60ibymacros -elocalise -oNAME_VERSION04_rnd.img /output/release_flash_images/product/rnd/langpack/langpack_01/rofs2/NAME_VERSION04_rnd_rofs2_master.oby' failed (1) in `/output/release_flash_images/product/rnd/langpack/langpack_01/rofs2'.\n")
    print ""
    sys.exit(1)


print ""
sys.exit(0)
