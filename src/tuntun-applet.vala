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

		private Gtk.Image _image;
		private Gdk.Pixbuf[] _images;
		private int _image_idx = 1;
		private int _animation_status = 0;

                construct {
                        this._tuntun = new Tuntun ();
                        this._tuntun.connections.connection_status_changed += this.on_connection_status_changed;
                        this._tuntun.connections.connection_fatal_error += this.on_connection_fatal_error;
			this._tuntun.connections.authentication_required += this.on_connection_authentication_required;
			this._tuntun.connections.authentication_failed += this.on_connection_authentication_failed;
			this._tuntun.connections.connection_activity += this.on_connection_activity;
                       	Notify.init ("Tuntun");
                }

                public PanelApplet() {
                }

                private void create() {
			try {
				_verbs = new BonoboUI.Verb[4];
				_images = new Gdk.Pixbuf[3];

				string file = Utils.get_image_path (Constants.Images.PANEL_ICON_ACTIVITY_1);
				_images[0] = new Gdk.Pixbuf.from_file (file);

				file = Utils.get_image_path (Constants.Images.PANEL_ICON_NORMAL);
				_images[1] = new Gdk.Pixbuf.from_file (file);

				file = Utils.get_image_path (Constants.Images.PANEL_ICON_ACTIVITY_2);
				_images[2] = new Gdk.Pixbuf.from_file (file);

				_verbs[0].cname = "Properties";
				_verbs[0].cb = on_context_menu_item_clicked;
				_verbs[0].user_data = this;

				_verbs[1].cname = "Log";
				_verbs[1].cb = on_context_menu_item_clicked;
				_verbs[1].user_data = this;

				_verbs[2].cname = "About";
				_verbs[2].cb = on_context_menu_item_clicked;
				_verbs[2].user_data = this;
		
				_verbs[3].cname = null;
				_verbs[3].cb = null;
				_verbs[3].user_data = null;

				_image = new Gtk.Image.from_pixbuf (_images[1]);
				this.add (_image);

				_right_click_menu_xml = "<popup name=\"button3\">" +
				    "<menuitem name=\"Properties Item\" verb=\"Properties\" _label=\"%s\" pixtype=\"stock\" pixname=\"gtk-properties\"/>" +
				    "<menuitem name=\"Log Window\" verb=\"Log\" _label=\"%s\" pixtype=\"stock\" pixname=\"gtk-info\"/>" +
				    "<menuitem name=\"About Item\" verb=\"About\" _label=\"%s\" pixtype=\"stock\" pixname=\"gnome-stock-about\"/>" +
				    "</popup>";

				this.setup_menu (_right_click_menu_xml.printf (_("_Preferences..."), _("_Show log..."), _("_About...")), _verbs, this);

				this.button_press_event += this.on_button_press_release;
				this.has_tooltip = true;
				this.query_tooltip += this.on_query_tooltip;
				this.show_all ();
			} catch (Error err) {
				Utils.display_error ("PanelApplet.create", err.message);
			}
                }

                static bool factory (PanelApplet applet, string iid, void *data) 
		{
                        applet.create ();
                        return true;
                }

		private bool on_query_tooltip (PanelApplet applet, int x, int y, bool keyboard_tooltip, Gtk.Tooltip tooltip)
		{
			tooltip.set_custom (new Tooltip (_tuntun.connections));
			return true;
		}

		private bool on_animation_timeout ()
		{
			if (_animation_status == 1) {
				_animation_status = 0;
				return false;
			} else {
				_image_idx++;
				if (_image_idx >= _images.length)
					_image_idx = 0;
				else if (_image_idx == 1)
					_animation_status--;

				_image.set_from_pixbuf (_images[_image_idx]);
				return true;
			}
		}

		private void animate_icon ()
		{
			if (_animation_status == 0) {
				Timeout.add (250, this.on_animation_timeout);
				_image_idx = 1;
			} 
			_animation_status = 4;
		}

                private bool on_button_press_release (PanelApplet sender, Gdk.Event event) 
		{
                        if (event.button.type == Gdk.EventType.BUTTON_PRESS && 
                            event.button.button == 1) {
				if ((event.button.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
					quick_connect ();
				} else {
					select_connection ();
				}
				return true;
                        }
                        return false;
                }

		private void quick_connect ()
		{
			foreach (Connection conn in _tuntun.connections.items) {
				if (conn.info.quick_connect == true) {
                                        if (conn.status == ConnectionStates.DISCONNECTED)
                                                conn.connect ();
                                        else
                                                conn.disconnect ();
				}
			}
		}

		private void on_connection_activity (Connections connections, Connection connection)
		{
			animate_icon ();
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
					    _("connection established\nassigned ip: %s").printf (connection.info.assigned_ip), 
					    Utils.get_image_path (Constants.Images.CONNECTION_STATUS_CONNECTED), 
					    this );
				} else if (connection.status == ConnectionStates.DISCONNECTED) {
					notification = new Notification (connection.info.name, 
					    _("connection closed"), 
					    Utils.get_image_path (Constants.Images.CONNECTION_STATUS_DISCONNECTED),
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
                                                menu_image = Utils.get_image_path (Constants.Images.CONNECTION_STATUS_DISCONNECT);
                                                break;
                                        case ConnectionStates.CONNECTED:
                                                menu_image = Utils.get_image_path (Constants.Images.CONNECTION_STATUS_CONNECT);
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