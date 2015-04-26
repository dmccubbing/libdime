# usage:
#	checks_SOURCES = ...
#	checks_CFLAGS = ...
#	checks_LDADD = ...
#	CLEANFILES = ...
#
#	include .../check.mk

# convenience definitions

OPENSSL_CFLAGS		= -I../../deps/sources/openssl/include
OPENSSL_LIBS		= ../../deps/sources/openssl/libssl.a ../../deps/sources/openssl/libcrypto.a -pthread -lrt -lresolv
DONNA_CFLAGS		= -I../../deps/sources/donna
DONNA_LIBS		= ../../deps/sources/donna/ed25519.o
LIBCOMMON_CFLAGS	=
LIBCOMMON_LIBS		= ../../libs/common/libcommon.a
LIBCORE_CFLAGS		=
LIBCORE_LIBS		= ../../libs/core/libcore.a
LIBSIGNET_CFLAGS	=
LIBSIGNET_LIBS		= ../../libs/signet/libsignet.a
LIBSIGNETRESOLVER_CFLAGS =
LIBSIGNETRESOLVER_LIBS	= ../../libs/signet-resolver/libsignet-resolver.a
LIBDMESSAGE_CFLAGS	=
LIBDMESSAGE_LIBS	= ../../libs/dmessage/libdmessage.a

# implementation

topdir = $(dir $(lastword $(MAKEFILE_LIST)))
include $(topdir)/common.mk

CHECK_CFLAGS	:= $(shell pkg-config --cflags check)
CHECK_LIBS	:= $(shell pkg-config --libs check)

check_PROGRAMS	= checks
CC		=  gcc
LIBS 		= $(checks_LDADD) $(CHECK_LIBS) -lz -lresolv
CFLAGS		= $(checks_CFLAGS) $(CHECK_CFLAGS) $(CWARNS) $(CDEBUG) -I../../include -std=gnu99
SRCFILES	= $(checks_SOURCES)
OBJDIRNAME	= .objs
DEPDIRNAME	= .deps
df = $(DEPDIRNAME)/$(*F)
DEPFILES	= $(patsubst %.c,$(DEPDIRNAME)/%.d,$(SRCFILES))
OBJFILES	= $(patsubst %.c,$(OBJDIRNAME)/%.o,$(SRCFILES))

.PHONY: all clean run-checks
all: $(check_PROGRAMS) run-checks

clean:
	@rm -rf $(OBJDIRNAME) $(DEPDIRNAME)
	@rm -f $(check_PROGRAMS)
	@rm -f $(CLEANFILES)

$(check_PROGRAMS): $(OBJFILES) $(filter %.a,$(LIBS))
	@echo "Linking $(GREEN)$@$(NORMAL)"
	$(RUN)$(CC) -o $@ $(OBJFILES) $(LIBS)

$(OBJDIRNAME) $(DEPDIRNAME):
	@test -d $@ || mkdir $@

$(OBJDIRNAME)/%.o : %.c | $(OBJDIRNAME) $(DEPDIRNAME)
	@echo Compiling $(YELLOW)$<$(NORMAL)
	$(RUN)$(CC) -M -MF $(df).d.tmp $(CFLAGS) $(ALL_INC_CCOPT) -fPIC -c $<
	@sed -e 's,^\($*\)\.o,$(OBJDIRNAME)/\1.o,' < $(df).d.tmp > $(df).d; \
	sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
		-e 's/$$/ :/' -e 's/^ *//' < $(df).d.tmp >> $(df).d ; \
		rm -f $(df).d.tmp
	$(RUN)$(CC) $(CFLAGS) $(ALL_INC_CCOPT) -fPIC -c $< -o $@

run-checks: $(check_PROGRAMS)
	./$(check_PROGRAMS)

run-checks-endlessly: $(check_PROGRAMS)
	$(RUN)ulimit -c unlimited; \
	rm -f core.*; \
	while ./checks; do :; done; \
	echo 'where' | gdb --quiet ./checks core.*

-include $(DEPFILES)
