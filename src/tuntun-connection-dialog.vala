/*
 *  tuntun-connection-dialog.vala is a part of Tuntun
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

using GLib;
using Gtk;

namespace Tuntun
{
	public class ConnectionDialog : GLib.Object
	{
                public signal void closed ();

		private weak Dialog _window = null;
                private weak Gtk.Entry _name = null;
                private weak Gtk.Entry _address = null;
                private weak Gtk.Entry _port = null;

                private ConnectionInfo _connection_info = null;

                construct
                {
                        initialize ();
                }

		private void initialize ()
		{
                        var builder = Utils.get_ui ();
                        _window = (Gtk.Dialog) builder.get_object ("dialog_connection_properties");
                        assert (_window != null);

                        var button = (Gtk.Button) builder.get_object ("button_connection_dialog_ok");
                        assert (button != null);
                        button.clicked.connect (this.on_button_connection_ok_clicked);
                        button = (Gtk.Button) builder.get_object ("button_connection_dialog_cancel");
                        assert (button != null);
                        button.clicked.connect (this.on_button_connection_cancel_clicked);

                        _name = (Gtk.Entry) builder.get_object ("entry_connection_name");
                        assert (_name != null);
                        _address = (Gtk.Entry) builder.get_object ("entry_connection_host");
                        assert (_address != null);
                        _port = (Gtk.Entry) builder.get_object ("entry_connection_port");
                        assert (_port != null);

                        update_text_entries ();
		}

                private void cleanup ()
                {
                        var builder = Utils.get_ui ();

                        var button = (Gtk.Button) builder.get_object ("button_connection_dialog_ok");
                        button.clicked.disconnect (this.on_button_connection_ok_clicked);
                        button = (Gtk.Button) builder.get_object ("button_connection_dialog_cancel");
                        button.clicked.disconnect (this.on_button_connection_cancel_clicked);
                }

                public ConnectionDialog (ConnectionInfo connection_info) 
		{ 
			GLib.Object(connection_info: connection_info);
		}

                public ConnectionInfo connection_info { construct { _connection_info = value; } }

		public ResponseType show (Gtk.Widget parent)
		{
			var response = (ResponseType) _window.run ();                       
			cleanup ();
			_window.hide ();
			return response;
		}

                private void on_button_connection_ok_clicked (Gtk.Button sender)
                {
                        update_connection_info_object ();
                        _window.response (ResponseType.OK);
                }


                private void on_button_connection_cancel_clicked (Gtk.Button sender)
                {
                        _window.response (ResponseType.CANCEL);
                }

		private void update_text_entries ()
                {
                        set_text_if_null (_name, _connection_info.name);
                        set_text_if_null (_address, _connection_info.address);
                        set_text_if_null (_port, _connection_info.port.to_string());
                }

		private void update_connection_info_object ()
		{
                        _connection_info.name = _name.get_text ();
                        _connection_info.address = _address.get_text ();
                        _connection_info.port = _port.get_text ().to_int ();
		}

                private void set_text_if_null(Gtk.Entry entry, string text)
                {
                        if (text != null)
                                entry.set_text(text);
                        else
                                entry.set_text("");
                }
	}
}
