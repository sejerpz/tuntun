/*
 *  tuntun-log-window.vala is a part of Tuntun
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
using Pango;

namespace Tuntun
{
        private enum ComboColumns
        {
                NAME,
                CONNECTION,
                COUNT
        }

	public class LogWindow : GLib.Object
	{
                public signal void closed ();

		private weak Window _window = null;
		private weak TextView _text_view = null;
		private weak Entry _entry_send = null;
		private weak Button _button_send = null;
		private weak ComboBox _combo = null;
		private ListStore _store = null;
                private TextTagTable _tag_table = null;
		private Tuntun _tuntun;

		construct
		{
			initialize ();
		}

		public LogWindow (Tuntun tuntun) 
		{ 
			GLib.Object(tuntun: tuntun);
		}

		public Tuntun tuntun { construct { _tuntun = value; } }

		private void initialize ()
		{
                        var builder = Utils.get_ui ();
                        _window = (Gtk.Window) builder.get_object ("window_log");
                        assert (_window != null);
                        /* one time initialization */
                        _window.delete_event += this.on_window_delete;

                        _text_view = (Gtk.TextView) builder.get_object ("textview_buffer");
                        assert (_text_view != null);
                 
                        _button_send = (Gtk.Button) builder.get_object ("button_send");
                        assert (_button_send != null);
                        _button_send.clicked += this.on_button_send_clicked;

                        _entry_send = (Gtk.Entry) builder.get_object ("entry_send");
                        assert (_entry_send != null);

                        /* intialize text view formatting */
                        _tag_table = new TextTagTable ();
                        var tag = new TextTag ("information");

			tag.set ("foreground", "DimGray", 
                            "style", Pango.Style.ITALIC, 
                            "weight", Pango.Weight.BOLD,
			    "family", "Monospace");

			_tag_table.add (tag);
	
                        tag = new TextTag ("received");
                        tag.set ("style", Pango.Style.NORMAL, "family", "Monospace");
                        _tag_table.add (tag);

                        tag = new TextTag ("sent");
			tag.set ("foreground", "DimGray",
			    "style", Pango.Style.NORMAL,
			    "family", "Monospace");
                        _tag_table.add (tag);
	
                        tag = new TextTag ("connection-name");
                        tag.set ("weight", Pango.Weight.BOLD, "family", "Monospace");
                        _tag_table.add (tag);
	
                        TextBuffer text_buffer =  new TextBuffer (_tag_table);
                        _text_view.set_buffer (text_buffer);

                        /* initialize connection list view */
                        _store = new ListStore (ComboColumns.COUNT, 
                            typeof(string), 
                            typeof(Connection));

			TreeIter iter;
			_store.append (out iter);
			_store.set (iter, 
			    ComboColumns.NAME, _("All"),
			    ComboColumns.CONNECTION, null);
                        foreach (Connection connection in _tuntun.connections.items) {
				_store.append (out iter);
				_store.set (iter, 
				    ComboColumns.NAME, connection.info.name,
				    ComboColumns.CONNECTION, connection);
				connection.control_channel_data_received += this.on_connection_data_received;
				connection.control_channel_data_sent += this.on_connection_data_sent;
                        }

			_combo = (Gtk.ComboBox) builder.get_object ("combobox_connection");
			assert (_combo != null);

			Gtk.CellRenderer renderer = new Gtk.CellRendererText ();
			_combo.pack_start (renderer, true);
			_combo.set_attributes(renderer, "text", 0);
			_combo.set_model (_store);
			_combo.changed += this.on_combo_active_connection_changed;
			_store.get_iter_first (out iter);
			_combo.set_active_iter (iter);
		}

                private void cleanup_and_close ()
                {
                        _window.delete_event -= this.on_window_delete;
                        _window.hide ();
                        _button_send.clicked -= this.on_button_send_clicked;
                        TreeIter iter;
			bool valid = _store.get_iter_first (out iter);
			while (valid) {
				Connection connection = null;
				_store.get (iter, ComboColumns.CONNECTION, out connection);
				if (connection != null) {
					connection.control_channel_data_received -= this.on_connection_data_received;
					connection.control_channel_data_sent -= this.on_connection_data_sent;
				}
				valid = _store.iter_next (ref iter);
                        }

			_combo.set_model (null);
			_combo.changed -= this.on_combo_active_connection_changed;
			_combo.clear ();
			_store = null;
			_tag_table = null;
			_tuntun = null;

			this.closed ();
                }

		private void on_combo_active_connection_changed (ComboBox sender)
		{
			if (active_connection == null) {
				_entry_send.set_sensitive (false);
				_button_send.set_sensitive (false);
				_entry_send.set_text (_("select a connection first..."));
			} else {
				_entry_send.set_sensitive (true);
				_button_send.set_sensitive (true);
				_entry_send.set_text ("");
			}
		}

		private void on_connection_data_sent (Connection connection, string data)
		{
			Gtk.TextTag tag = null;
			tag = _tag_table.lookup ("sent");
			append_text (tag, connection, data);
		}

		private void on_connection_data_received (Connection connection, string data)
		{
			Gtk.TextTag tag = null;
			tag = _tag_table.lookup ("received");
			append_text (tag, connection, data);
		}

		private void append_text (TextTag tag, Connection connection, string data)
		{
			TextIter iter, end_iter;
	
			Gtk.TextBuffer text_buffer = _text_view.get_buffer ();
			return_if_fail (text_buffer != null);

			Gtk.TextTag tag_connection = null;
			tag_connection = _tag_table.lookup ("connection-name");
			text_buffer.get_end_iter (out iter);
	
			string[] lines = data.split ("\n");
			string tmp;
			int line_count = text_buffer.get_line_count ();
	
			foreach (string line in lines) {
				if (line == null)
					break;
				if (line == "")
					continue;

				if (!line.has_suffix ("\n"))
					line += "\n";

				if (line_count > 500)
				{
					text_buffer.get_start_iter (out iter);
					text_buffer.get_iter_at_line (out end_iter, 1);
					text_buffer.delete (iter, end_iter);
					text_buffer.get_end_iter (out iter);
					line_count--;
				}
		
				tmp = "%s: ".printf (connection.info.name);
				text_buffer.insert_with_tags (iter, tmp, -1, tag_connection);


				tmp = "%s".printf (line);
				text_buffer.insert_with_tags (iter, tmp, -1, tag);	
				line_count++;
			} 

			Gtk.TextMark mark = text_buffer.create_mark (null, iter, false);
			_text_view.scroll_to_iter (iter, 0, false, 0,0);
			_text_view.scroll_to_mark (mark, 0, false, 0,0);
			text_buffer.delete_mark (mark);
		}

                private bool on_window_delete (Gtk.Window sender, Gdk.Event event)
                {
                        cleanup_and_close ();
                        return true;
                }

		private void on_button_send_clicked (Widget sender)
		{
			string command_text = _entry_send.get_text ();
			send_command (active_connection, command_text);
			_entry_send.set_text ("");
		}

		private void send_command (Connection connection, string command_text)
		{
			return_if_fail (connection != null);
			return_if_fail (command_text != null);

			connection.send ("%s\n".printf (command_text));
		}

		private weak Connection active_connection
		{
			get {
				Gtk.TreeIter iter;
				weak Connection connection = null;
				if (_combo.get_active_iter (out iter))
				{
					Gtk.TreeModel store = _combo.get_model ();
		
					store.get (iter, ComboColumns.CONNECTION, out connection);
				}
				return connection;
			}
		}

		public void show ()
		{
			_window.show_all ();
		}
	}
}
