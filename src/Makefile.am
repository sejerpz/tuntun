## Process this file with automake to produce Makefile.in

INCLUDES = \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\" \
	-DGETTEXT_PACKAGE=\""$(tuntunlocaledir)"\" \
	$(TUNTUN_CFLAGS)

AM_CFLAGS =\
	 -Wall\
	 -g

libexec_PROGRAMS = tuntun

tuntun_SOURCES = \
	tuntun.vala \
	tuntun-applet.vala \
	tuntun-constants.vala \
	tuntun-connection.vala \
	tuntun-connection-info.vala \
	tuntun-connections.vala \
	tuntun-utils.vala \
	tuntun-connections-dialog.vala \
	tuntun-connection-dialog.vala \
	tuntun-log-window.vala \
	tuntun-auth-dialog.vala \
	tuntun-tooltip.vala \
	snul.vala

tuntun_VALAFLAGS = -C --save-temps --vapidir ../vapi --pkg libnotify --pkg config --pkg extensions --pkg unix-socket --pkg libpanelapplet-2.0 --pkg libbonoboui-2.0 --pkg vte --pkg gnome-keyring-1

tuntun-connection.$(OBJEXT): libgnio.a

tuntun_LDFLAGS = $(PACKAGE_LIBS) \
	-export-dynamic

tuntun_LDADD = libgnio.a $(TUNTUN_LIBS)

serverdir       = $(libdir)/bonobo/servers
server_in_files = tuntun.server.in
server_DATA     = $(server_in_files:.server.in=.server)

@INTLTOOL_SCHEMAS_RULE@
@INTLTOOL_SERVER_RULE@

$(server_in_files): $(server_files:.server.in=.server.in.in)
	sed -e "s|\@LIBEXECDIR\@|$(libexecdir)|" < tuntun.server.in.in > $@

EXTRA_DIST = $(server_in_files) \
	tuntun.server.in.in

CLEANFILES = $(server_in_files) $(server_DATA) libgnio.a

include Makefile.vm

BUILT_SOURCES += libgnio.a

libgnio.a:
	cd ../gnio; ./waf configure;
	cd ../gnio; ./waf build --target=gnio; 
	cp ../gnio/build/default/gnio/libgnio.a  .
