## Process this file with automake to produce Makefile.in

uidir = $(datadir)/tuntun/ui

ui_DATA = tuntun.ui tuntun-auth-dialog.ui

#BUILT_SOURCES = tuntun.ui.stamp

GLADE_FILES = tuntun.glade

$(ui_DATA): $(GLADE_FILES)
	gtk-builder-convert $^ `basename $^ .glade`.ui
	gtk-builder-convert -r vbox_authentication $^ tuntun-auth-dialog.ui
#	touch $@

EXTRA_DIST = $(ui_DATA) \
	tuntun.glade

CLEANFILES = $(ui_DATA) 
#tuntun.ui.stamp
