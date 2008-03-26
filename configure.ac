dnl Process this file with autoconf to produce a configure script.

AC_INIT(tuntun, 0.2.0)

AM_INIT_AUTOMAKE(AC_PACKAGE_NAME, AC_PACKAGE_VERSION)
AM_CONFIG_HEADER(config.h)
AM_MAINTAINER_MODE

AC_ISC_POSIX
AC_PROG_CC
AM_PROG_CC_STDC
AC_HEADER_STDC

GNOME_COMMON_INIT

VALA_PROG_VALAC([0.1.7])

dnl ***************************************************************************
dnl Internatinalization
dnl ***************************************************************************
GETTEXT_PACKAGE=tuntun
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [GETTEXT package name])
AM_GLIB_GNU_GETTEXT
IT_PROG_INTLTOOL([0.35.0])



AM_PROG_LIBTOOL



PKG_CHECK_MODULES(TUNTUN, [gtk+-2.0 >= 2.8 libglade-2.0 >= 2.6.0 libpanelapplet-2.0 >= 2.6 libnotify >= 0.4.4])
AC_SUBST(TUNTUN_CFLAGS)
AC_SUBST(TUNTUN_LIBS)




AC_OUTPUT([
Makefile
src/Makefile
ui/Makefile
po/Makefile.in
pixmaps/Makefile
])