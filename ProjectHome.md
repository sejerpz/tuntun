![http://tuntun.googlecode.com/svn/wiki/images/Header.png](http://tuntun.googlecode.com/svn/wiki/images/Header.png)

Tuntun is an applet for Gnome panel written in [Vala](http://live.gnome.org/Vala) and it can manage a list of vpn connections through the OpenVPN Management Interface.
It's a rewrite and a replacement of my [ovpnClient](http://persbaglio.no-ip.org/?page_id=85) and it implements some items that were on ovpnClient todo list.

## Main features ##
  * Simple & lightweight just a client GUI to start/stop your OpenVPN tunnels and nothing more
  * Integrated with the Gnome Desktop (support for the Keyring and notification daemon)
  * Support for Auth and Private-Key OpenVPN authentication methods

Although _Tuntun_ was written in Vala you will need the _valac_ compiler only if you want to contribute to the project or compile it _from svn_. Since _valac_ compiler just translate vala code to straight C code + GObject,  to build every Tuntun release only _**gcc**_ is required.

Beside that I advise you to try [Vala](http://live.gnome.org/Vala) because it's just a more fun and productive way to write programs that integrate well in the Gtk+ and Gnome technologies.

## Download ##

Releases: http://code.google.com/p/tuntun/downloads/list

Source code repository: http://gitorious.org/tuntun/tuntun

## Compile & Install ##

Just do:

> _./configure --prefix=/usr --libexec=/usr/lib/gnome-applets_

> _./make_

> _./make install_


## NEWS ##
_Mon Jan 11 2009:_
> Tuntun version 0.4.0 "back to life" released!

> Main changes from 0.3.1 are:
    * Dropped GNIO and used GLib for networking (requires GLib >= 2.22)
    * Support for .config XDG directory specification
    * Fully compatible with valac 0.7.9

_Tue Aug 26  2008:_
> Back from vacation :(

> New AMD64 Debian package uploaded for _tuntun_ version 0.3.1
> (thanks to Ivars Strazdiņš)

_Mon Jul 28  2008:_
> Tuntun version 0.3.1 released!

> This is a bugfix release, main changes from 0.3.0 are:
    * Fixed internationalization support
    * Added Latvian translation (thanks to Ivars Strazdiņš)

_Sat Jul 19 2008:_
> New Ubuntu 8.04 package uploaded for _tuntun_ version 0.3.0

_Wed Jul 16 2008:_
> Tuntun version 0.3.0 released!

> Main changes from 0.2.0 are:
    * S.n.u.l. adapted to use GIO/GNIO library
    * New summary tooltip with the current connection status
    * Automatically reconnect to the openvpn daemon management interface on connection lost
    * Fully compatible with valac 0.3.4

_Sat Jun 7 2008:_
> Tuntun version 0.2.0 released!

> Main changes from 0.1.0 are:
    * Animated panel icon on activity
    * Assigned ip shown in the notification
    * More consistent status icons in the menu / notification / connections dialog
    * A connection may be selected for a quick (shift + click) connect action
    * Fully compatible with valac 0.3.3

_Fri Mar 14 2008:_
> Tuntun version 0.1.0 released!