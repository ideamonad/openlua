
PLATS = windows freebsd linux

ifeq ($(OS),Windows_NT)
PLAT=windows
else
UNAME=$(shell uname -s)
ifeq ($(UNAME),FreeBSD)
PLAT=freebsd
else
ifeq ($(UNAME),Linux)
PLAT=linux
endif
endif
endif

ifeq (windows, $(PLAT))
PLAT_MAKEFILE=Makefile.win
MFLAGS+= PLAT=windows
endif

ifeq (freebsd, $(PLAT))
PLAT_MAKEFILE=Makefile.bsd
MFLAGS+= PLAT=freebsd
endif

ifeq (linux, $(PLAT))
PLAT_MAKEFILE=Makefile.bsd
MFLAGS+= PLAT=linux
endif
