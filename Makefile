################################
### FreeSwitch headers files found in libfreeswitch-dev ###
FS_INCLUDES=/usr/local/freeswitch/include/freeswitch
FS_MODULES=/usr/local/freeswitch/mod
################################

DESC="FreeSWITCH G.729A module using the opensource bcg729 implementation by Belledonne Communications"
DEBNAME=freeswitch-mod-bcg729
VERSION=1.0.0
SUB_VERSION=$(shell git rev-list --count HEAD)
AUTHOR="Roberto Paradinha"
VENDOR="Broadvoice"
URL="https://www.broadvoice.com"
FPM=/usr/local/bin/fpm
FS_VERSION=freeswitch

MODNAME = mod_bcg729.so

### END OF CUSTOMIZATION ###
SHELL := /bin/bash
PROC?=$(shell uname -m)
CMAKE := cmake

CFLAGS=-fPIC -O3 -fomit-frame-pointer -fno-exceptions -Wall -std=c99 -pedantic

INCLUDES=-I/usr/include -Ibcg729/include -I$(FS_INCLUDES)
LDFLAGS=-lm -Wl,-static -Lbcg729/src -lbcg729 -Wl,-Bdynamic

all : mod_bcg729.o mod_bcg729.so deb
	$(CC) $(CFLAGS) $(INCLUDES) -shared -Xlinker -x -o mod_bcg729.so mod_bcg729.o $(LDFLAGS)

mod_bcg729.o: bcg729 mod_bcg729.c
	$(CC) $(CFLAGS) $(INCLUDES) -c mod_bcg729.c

clone_bcg729:
	if [ ! -d bcg729 ]; then \
		git clone https://github.com/BelledonneCommunications/bcg729.git; \
	fi
	pushd bcg729; git fetch; git checkout 1.1.1; popd;

bcg729: clone_bcg729
	cd bcg729 && $(CMAKE) . -DENABLE_SHARED=NO -DENABLE_STATIC=YES -DCMAKE_POSITION_INDEPENDENT_CODE=YES && make && cd ..

clean:
	rm -f *.o *.so *.a *.la; cd bcg729 && make clean; cd ..

distclean: clean
	rm -fR bcg729

install: all
	/usr/bin/install -c mod_bcg729.so $(INSTALL_PREFIX)/$(FS_MODULES)/mod_bcg729.so

deb: all
        rm -f *.deb
        $(FPM) --provides $(DEBNAME) \
        --deb-no-default-config-files -s dir -t deb \
        --deb-build-depends debhelper \
        --deb-build-depends libbcg729-dev \
        --description $(DESC) \
        -v $(VERSION) \
        --iteration $(SUB_VERSION) \
        --deb-priority optional \
        --url $(URL) \
        --maintainer $(AUTHOR) \
        --vendor $(VENDOR) \
        --license MPL 1.1 \
        --depends $(FS_VERSION) \
        --depends libbcg729-0 \
        --after-install post-install.sh \
        -n $(DEBNAME) $(MODNAME)=$(DESTDIR)/usr/lib/freeswitch/mod/$(MODNAME)
