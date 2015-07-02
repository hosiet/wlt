#!/usr/bin/make -f
#

prefix = /usr
bindir = $(prefix)/bin
man1dir = $(prefix)/share/man/man1
manzh1dir = $(prefix)/share/man/zh_CN/man1
etcdir = /etc

all:

install:
	install -m 0755 wlt $(DESTDIR)$(bindir)
	install -m 0644 wlt.1 $(DESTDIR)$(man1dir)
	if test ! -f $(DESTDIR)$(etcdir)/wlt.conf; then install -m 0644 wlt.conf $(DESTDIR)$(etcdir); fi
