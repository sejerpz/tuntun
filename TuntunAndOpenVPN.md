# The OpenVPN Management Interface #
### What is it and why it's useful? ###

The [OpenVPN](http://openvpn.net) management interface allows to control a
running instance of openvpn daemon by issue simple
commands in a telnel like tcp connection.

It's partculary useful because it allow to start or stop
a vpn tunnel, to grab its current status and to provide login credentials interactively.

Because it was written just to allow GUI application to control the daemon instance, it's by no means a secure connection to openvpn,
so it should be explicitly enabled in the config file,
and it should be used just in a single user environment
binded to localhost.

Follow this link for futher details: http://openvpn.net/index.php/documentation/miscellaneous/management-interface.html



### How to configure a vpn tunnel for using with Tuntun ###

Configuring a vpn tunnel so it can be controlled from
**Tuntun** applet is quite easy.

Just add some OpenVPN directive at the end of you config file
and restart the daemon.

The relevants config options are:

_management <ip address>_

&lt;port&gt;

_> This_enable_the managment interface, so that OpenVpn daemon
> can listen for commands on the specified local address and port._**(required)**

_management-hold_
> This directive tell openvpn to now open the connection
> on startup. (optional)

_management-query-passwords_
> Ask for passwords if required. (optional)

_auth-user-pass_
> Enable pam-unix username and password authentication
> (optional)

_auth-retry interact_
> Reask the username and/or password in case of failure.
> (required if password prompt is enabled)