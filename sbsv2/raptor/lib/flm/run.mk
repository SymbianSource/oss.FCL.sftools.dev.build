.PHONY:: ALL
ALL:: # Default target

HOSTPLATFORM:=win 32
HOSTPLATFORM_DIR:=win32
OSTYPE:=cygwin
FLMHOME:=E:/wip2/lib/flm
SHELL:=E:/wip2/win32/cygwin/bin/sh.exe


USE_TALON:=



include E:/wip2/lib/flm/globals.mk

# dynamic default targets

# call E:/wip2/lib/flm/config/default.flm
SBS_SPECIFICATION:=Symbian.config.default
SBS_CONFIGURATION:=armv5_urel

EPOCROOT:=E:/wip2/test/epocroot
ELF2E32:=E:/wip2/test/epocroot/epoc32/tools/elf2e32.exe
WHATLOG:=
include E:/wip2/lib/flm/config/default.flm


component_paths:=$(SBS_HOME)/test/smoke_suite/test_resources/simple/bld.inf|c:/make_test/a.mk \
$(SBS_HOME)/test/smoke_suite/test_resources/simple_dll/bld.inf|c:/make_test/b.mk \
$(SBS_HOME)/test/smoke_suite/test_resources/simple/always_build_as_arm_bld.inf|c:/make_test/c.mk \
$(SBS_HOME)/test/smoke_suite/test_resources/simple/debuggable_bld.inf|c:/make_test/d.mk \
$(SBS_HOME)/test/smoke_suite/test_resources/simple_export/bld.inf|c:/make_test/e.mk

configs:=armv5 armv7

cli_options:=-d

include build.flm
