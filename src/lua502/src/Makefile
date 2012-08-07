
PLAT= none

TOP=../..
include $(TOP)/platform.mk

.PHONY : all $(PLATS) main dirs clean

all:
ifeq (none, $(PLAT))
	@echo "Please do"
	@echo "   gmake PLAT=PLATFORM ..."
	@echo "where PLATFORM is one of these:"
	@echo "   $(PLATS)"
	exit 1
else
	$(MAKE) -f $(PLAT_MAKEFILE) $(MFLAGS)
endif

main dirs clean .DEFAULT :
ifeq (none, $(PLAT))
	@echo "Please do"
	@echo "   gmake PLAT=PLATFORM ..."
	@echo "where PLATFORM is one of these:"
	@echo "   $(PLATS)"
	exit 1
else
	$(MAKE) -f $(PLAT_MAKEFILE) $(MFLAGS) $@
endif

none: 
	@echo "Please do"
	@echo "   gmake PLAT=PLATFORM ..."
	@echo "where PLATFORM is one of these:"
	@echo "   $(PLATS)"
	exit 1
