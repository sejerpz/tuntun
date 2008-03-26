/*
 *  tuntun-applet.vala is a part of Tuntun
 *
 *  Tuntun: a simple applet to manage OpenVPN connections
 *
 *  Copyright (C) 2008  Andrea Del Signore
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 *  02111-1307, USA.
 *
 *  Author:
 *     Andrea Del Signore <sejerpz@tin.it>       
 */

using Panel;
using GLib;
using Gtk;
using Notify;

namespace Tuntun
{
        public class PanelApplet : Panel.Applet 
        {
                private string _right_click_menu_xml;

                private BonoboUI.Verb[] _verbs = null;
                private Tuntun _tuntun;

                private ConnectionsDialog _settings = null;
		private LogWindow _log = null;

                construct {
                        this._tuntun = new Tuntun ();
                        this._tuntun.connections.connection_status_changed += this.on_connection_status_changed;
                        this._tuntun.connections.connection_fatal_error += this.on_connection_fatal_error;
			this._tuntun.connections.authentication_required += this.on_connection_authentication_required;
			this._tuntun.connections.authentication_failed += this.on_connection_authentication_failed;
                       	Notify.init ("Tuntun");
                }

                public PanelApplet() {
                }

                private void create() {
                        _verbs = new BonoboUI.Verb[4];
                        var image = new Gtk.Image ();

                        var verb = new BonoboUI.Verb();
                        verb.cname = "Properties";
                        verb.cb = on_context_menu_item_clicked;
                        verb.user_data = this;
                        _verbs[0] = verb;

                        verb = new BonoboUI.Verb();
                        verb.cname = "Log";
                        verb.cb = on_context_menu_item_clicked;
                        verb.user_data = this;
                        _verbs[1] = verb;

                        verb = new BonoboUI.Verb();
                        verb.cname = "About";
                        verb.cb = on_context_menu_item_clicked;
                        verb.user_data = this;
                        _verbs[2] = verb;
		
                        verb = new BonoboUI.Verb();
                        verb.cname = null;
                        verb.cb = null;
                        verb.user_data = null;
                        _verbs[3] = verb;

                        image.set_from_file (Utils.get_image_path (Constants.Images.PANEL_ICON_NORMAL));
                        this.add (image);

                        _right_click_menu_xml = "<popup name=\"button3\">" +
                            "<menuitem name=\"Properties Item\" verb=\"Properties\" _label=\"%s\" pixtype=\"stock\" pixname=\"gtk-properties\"/>" +
                            "<menuitem name=\"Log Window\" verb=\"Log\" _label=\"%s\" pixtype=\"stock\" pixname=\"gtk-info\"/>" +
                            "<menuitem debuname=\"About Item\" verb=\"About\" _label=\"%s\" pixtype=\"stock\" pixname=\"gnome-stock-about\"/>" +
                            "</popup>";

                        this.setup_menu (_right_click_menu_xml.printf (_("_Preferences..."), _("_Show log..."), _("_About...")), _verbs, this);
                        this.button_press_event += this.on_button_press;
                        this.show_all ();
                }

                static bool factory (PanelApplet applet, string iid, pointer data) 
		{
                        applet.create ();
                        return true;
                }

                private bool on_button_press (Widget sender, Gdk.EventButton eventButton) 
		{
                        if (eventButton.type == Gdk.EventType.BUTTON_PRESS && 
                            eventButton.button == 1) {
                                select_connection ();
                                return true;
                        }
                        return false;
                }

		private void authenticate (Connection connection, AuthenticationModes mode, string type)
		{
			var auth = new AuthDialog (connection, mode, type);
			auth.authenticate ();
		}

		private void on_connection_authentication_required (Connections connections, Connection connection, AuthenticationModes mode, string type)
		{
			authenticate (connection, mode, type);
		}

		private void on_connection_authentication_failed (Connections connections, Connection connection, AuthenticationModes mode, string type)
		{
			//suppress dialog if keyring authentication
			var dialog = new MessageDialog (null,
			    DialogFlags.DESTROY_WITH_PARENT,
			    MessageType.ERROR,
			    ButtonsType.CLOSE,
			    connection.info.name);
			dialog.secondary_text = _("Authentication failed");
			dialog.run ();
			dialog.destroy ();
		}

		private void on_connection_fatal_error (Connections connections, Connection connection, string error)
		{
			var dialog = new MessageDialog (null,
                                  DialogFlags.DESTROY_WITH_PARENT,
                                  MessageType.ERROR,
                                  ButtonsType.CLOSE,
			          connection.info.name);
			dialog.secondary_text = error;
			dialog.run ();
			dialog.destroy ();
		}

                private void on_connection_status_changed (Connections connections, Connection connection)
                {
                        Notification notification = null;

			try {
				if (connection.status == ConnectionStates.CONNECTED) {
					notification = new Notification (connection.info.name, 
					    _("connection established"), 
					    Utils.get_image_path ("not_connected.png"), 
					    this );
				} else if (connection.status == ConnectionStates.DISCONNECTED) {
					notification = new Notification (connection.info.name, 
					    _("connection closed"), 
					    Utils.get_image_path ("connected.png"), 
					    this );
				}

				if (notification != null) {
					notification.set_urgency (Urgency.NORMAL);
					notification.set_timeout (EXPIRES_DEFAULT);
					notification.show ();
				}
			} catch (Error err) {
				warning ("error %d: %s", err.code, err.message);
			}
                }

                private void select_connection () {
                        Menu popup_menu = new Menu ();

                        foreach (weak Connection connection in _tuntun.connections.items) {
                                var item = new ImageMenuItem.with_label (connection.info.name);
			
                                item.set("user-data", connection);
                                item.sensitive = (connection.control_channel_status == ConnectionStates.CONNECTED &&
						  connection.status != ConnectionStates.CONNECTING &&
						  connection.status != ConnectionStates.DISCONNECTING);

                                popup_menu.append (item);

                                string menu_image;

                                switch (connection.status) {
                                        case ConnectionStates.UNKNOWN:
                                                menu_image = Utils.get_image_path (Constants.Images.CONNECTION_STATUS_UNKNOWN);
                                                break;
                                        case ConnectionStates.ERROR:
                                                menu_image = Utils.get_image_path (Constants.Images.CONNECTION_STATUS_UNKNOWN);
                                                break;
                                        case ConnectionStates.DISCONNECTED:
                                                menu_image = Utils.get_image_path (Constants.Images.CONNECTION_STATUS_NOT_CONNECTED);
                                                break;
                                        case ConnectionStates.CONNECTED:
                                                menu_image = Utils.get_image_path (Constants.Images.CONNECTION_STATUS_CONNECTED);
                                                break;
                                        case ConnectionStates.CONNECTING:
                                        case ConnectionStates.DISCONNECTING:
                                                menu_image = Utils.get_image_path (Constants.Images.CONNECTION_STATUS_UNKNOWN);
                                                break;
                                        default:
                                                menu_image = Utils.get_image_path (Constants.Images.CONNECTION_STATUS_UNKNOWN);
                                                break;
                                }

                                item.image = new Image.from_file (menu_image);
                                item.activate += this.on_connection_menu_item_activated;
                        }

                        popup_menu.show_all ();
                        popup_menu.popup (null, null, null, 0, Gtk.get_current_event_time ());
                }

                private void on_connection_menu_item_activated (Gtk.ImageMenuItem sender)
                {
                        weak Connection connection = null;


                        sender.get("user-data", out connection);

                        return_if_fail (connection != null);
                        if (connection.status == ConnectionStates.CONNECTED)
                                connection.disconnect ();
                        else if (connection.status == ConnectionStates.DISCONNECTED)
                                connection.connect ();
                        
                }

                private static void on_context_menu_item_clicked (BonoboUI.Component component, void* user_data, string cname) 
		{
                        PanelApplet instance = (PanelApplet) user_data;

                        if (cname == "About") {
                                instance.about ();
                        } else if (cname == "Properties") {
                                instance.show_properties ();
			} else if (cname == "Log") {
				instance.show_log ();
                        }
                }

		private void show_log ()
		{
			if (_log == null) {
				_log = new LogWindow (_tuntun);
				_log.closed += this.on_log_window_closed;
			}
			_log.show ();
		}

                private void show_properties ()
                {
                        if (_settings == null) {
                                _settings = new ConnectionsDialog (_tuntun);
                                _settings.closed += this.on_settings_dialog_closed;
                        }
                        _settings.show ();
                }

                private void on_log_window_closed (LogWindow sender)
                {
                        _log.closed -= this.on_log_window_closed;
                        _log = null;
                }

                private void on_settings_dialog_closed (ConnectionsDialog sender)
                {
                        _settings.closed -= this.on_settings_dialog_closed;
                        _settings = null;
                }

                private void about ()
                {
                        var dialog = new Gtk.AboutDialog();
                        string[] authors = new string[] { "Andrea Del Signore", null };
                        string translator_credits = _("translator_credits");
  
                        if ("translator_credits".has_prefix(translator_credits) == false)
                                dialog.set_translator_credits(translator_credits);
  
  
                        dialog.set_name (Config.PACKAGE_STRING);
                        dialog.set_comments (_("TunTun VPN Connection manager"));
                        dialog.set_version (Config.PACKAGE_VERSION);
                        dialog.set_website ("http://code.google.com/p/tuntun");
                        dialog.set_website_label (_("Homepage"));
                        dialog.set_license (_("(c) 2008 Andrea Del Signore (sejerpz@tin.it).\n\n This program is licensed under the terms of the GNU\n\n General Public License and is provided with absolutely\n\n NO WARRANTY; see the file COPYING for details."));

                        dialog.set_authors (authors);
                        dialog.run ();	

                        dialog.hide ();
                }

                public static int main(string[] args) {
                        var program = Gnome.Program.init ("GNOME_Tuntun", "0", Gnome.libgnomeui_module, args, "sm-connect", false);
                        var ret = Panel.Applet.factory_main ("OAFIID:GNOME_Tuntun_Factory", typeof(PanelApplet), (Panel.AppletFactoryCallback) factory);
                        return ret;
                }
        }
}