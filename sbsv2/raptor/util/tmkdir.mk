SOURCEDIR:=$(subst \,/,$(SBS_HOME))/util/tmkdir
TALONDIR:=$(subst \,/,$(SBS_HOME))/util/talon

TARGET:=tmkdir
CFLAGS:=$(CFLAGS) -g -I$(TALONDIR)
SOURCES:=$(addprefix $(SOURCEDIR)/,tmkdir.c) $(addprefix $(TALONDIR)/,log.c)
$(eval $(cprogram))

