_Need help: I've made my best to translate this page from italian to english but I'm not a so good english speaker and writer. So if you find some mistakes or you feel that you can do something to correct my "engrish", drop me an email at: sejerpz at tin dot it. Your help will be appreciated. Andrea._

### Preface ###

_**Tuntun**_ is a GNOME applet written in Vala useful to manage Vpn connections. It's a GUI that can show the state of a VPN connection and open or close it through the **OpenVpn Management Interface**.

### Usage ###

After adding it to the GNOME panel, you can configure the predefined Open VPN connections by clicking with the right mouse button on the Tuntun icon and then selecting the item Properties from the popup menu:
|![http://tuntun.googlecode.com/svn/wiki/images/docs/conn_manager.png](http://tuntun.googlecode.com/svn/wiki/images/docs/conn_manager.png)|
|:----------------------------------------------------------------------------------------------------------------------------------------|
You can _add_, _remove_ a connection or modify its _properties_, you can also see its status in a window like the following:|![http://tuntun.googlecode.com/svn/wiki/images/docs/conn_prop.png](http://tuntun.googlecode.com/svn/wiki/images/docs/conn_prop.png)      |


  * _Name_: connection's name
  * _Address_: ip address or server name where OpenVPN is running (usually localhost)
  * _Port_: port number where the server is listening, written in the connection config option '_management_'.
  * _Status_: the tunnel status (see below for an explanation of the icons meanings)
  * _Quick connect_: check this if you want to quickly activate this tunnel with a shit+click in the main tuntun panel icon

You can simply open or close a connection by selecting it on the menu that will popup with a left clck on the Tuntun icon. A boubble window will appear whenever the connection state change.
|![http://tuntun.googlecode.com/svn/wiki/images/docs/connecting.png](http://tuntun.googlecode.com/svn/wiki/images/docs/connecting.png)|
|:------------------------------------------------------------------------------------------------------------------------------------|
|![http://tuntun.googlecode.com/svn/wiki/images/docs/connection_established.png](http://tuntun.googlecode.com/svn/wiki/images/docs/connection_established.png)|

Legend of the icons shown on the popup menu and in the connections manager dialog:
  * ![http://tuntun.googlecode.com/svn/wiki/images/docs/connected.png](http://tuntun.googlecode.com/svn/wiki/images/docs/connected.png) connection currently established, click to disconnect
  * ![http://tuntun.googlecode.com/svn/wiki/images/docs/not_connected.png](http://tuntun.googlecode.com/svn/wiki/images/docs/not_connected.png) connection closed, click to connect
  * ![http://tuntun.googlecode.com/svn/wiki/images/docs/unknown.png](http://tuntun.googlecode.com/svn/wiki/images/docs/unknown.png) connection status unknown (the server running the Management Interface is unreachable, the corresponding menu item will be disabled).

### Links ###

  * _kovpn_: it's a project like ovpnClient, but more advanced and for KDE Desktop (http://www.enlighter.de/)
  * _Network Manager_: it's a GNOME application and it has a module to control OpenVPN connection (http://www.gnome.org/projects/NetworkManager/)
  * _Tango Project_: where I've taken the icons for Tuntun (http://tango.freedesktop.org/)

### Old Documentation ###
  * _tuntun_ version 0.1.0 (http://code.google.com/p/tuntun/wiki/Old_Documentation_0_1_0)