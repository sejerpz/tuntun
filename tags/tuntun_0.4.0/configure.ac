dnl Process this file with autoconf to produce a configure script.

AC_INIT(tuntun, 0.4.0)

AM_INIT_AUTOMAKE(AC_PACKAGE_NAME, AC_PACKAGE_VERSION)
AM_CONFIG_HEADER(config.h)
AM_MAINTAINER_MODE

AC_ISC_POSIX
AC_PROG_CC
AM_PROG_CC_STDC
AC_HEADER_STDC

GNOME_COMMON_INIT

VALA_PROG_VALAC([0.7.9])

IT_PROG_INTLTOOL([0.35.0])

dnl ***************************************************************************
dnl Internationalization
dnl ***************************************************************************
GETTEXT_PACKAGE=tuntun
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE", "definition of GETTEXT_PACKAGE")

ALL_LINGUAS=""
AM_GLIB_GNU_GETTEXT
AM_GLIB_DEFINE_LOCALEDIR([GNOMELOCALEDIR])

AM_PROG_LIBTOOL


PKG_CHECK_MODULES(TUNTUN, [gtk+-2.0 >= 2.8 libglade-2.0 >= 2.6.0 libpanelapplet-2.0 >= 2.6 libgnomeui-2.0 >= 2.22.0 libnotify >= 0.4.4 glib-2.0 >= 2.22.0 gio-2.0 >= 2.22.0])
AC_SUBST(TUNTUN_CFLAGS)
AC_SUBST(TUNTUN_LIBS)


AC_OUTPUT([
Makefile
src/Makefile
ui/Makefile
po/Makefile.in
pixmaps/Makefile
vapi/Makefile
])
