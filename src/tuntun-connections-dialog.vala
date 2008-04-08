/*
 *  tuntun-connections-dialog.vala is a part of Tuntun
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
        private enum Columns
        {
		DOUBLE_CLICK_CONNECT,
                NAME,
                ADDRESS,
                PORT,
                CONNECTION,
                COUNT
        }

	public class ConnectionsDialog : GLib.Object
	{
                public signal void closed ();

		private weak Window _window = null;
                private weak TreeView _treeview = null;
		private weak Button button_conn_remove = null;
		private weak Button button_conn_modify = null;
                private ListStore _store;
                private Tuntun _tuntun = null;

		private bool is_dirty = false;

                construct
                {
                        initialize ();
                }

		private void initialize ()
		{
                        var builder = Utils.get_ui ();
                        _treeview = (TreeView) builder.get_object ("treeview_connections");
			assert (_treeview != null);
                        _window = (Gtk.Window) builder.get_object ("window_connections");
			assert (_window != null);

                        /* one time initialization */
                        _window.delete_event += this.on_window_delete;

			_treeview.get_selection().changed += this.on_treeview_selection_changed;


                        Gtk.CellRenderer renderer;
                        Gtk.TreeViewColumn column;
                        var selection = _treeview.get_selection ();

                        selection.set_mode (SelectionMode.SINGLE);
                        /* list view columns */
                        renderer = new CellRendererToggle ();
                        ((CellRendererToggle)renderer).toggled += this.on_double_click_connect_toggled;

                        column = new TreeViewColumn.with_attributes (_("Quick connect"), 
			    renderer, "active", Columns.DOUBLE_CLICK_CONNECT);
			column.alignment = 0.50;
                        _treeview.append_column (column);

                        renderer = new CellRendererText ();
			renderer.mode = CellRendererMode.EDITABLE;
                        column = new TreeViewColumn.with_attributes (_("Name"), 
			    renderer, "text", Columns.NAME);
                        _treeview.append_column (column);

                        renderer = new CellRendererText ();
                        column = new TreeViewColumn.with_attributes (_("Host"), 
			    renderer, "text", Columns.ADDRESS);
                        _treeview.append_column (column);

                        renderer = new CellRendererText ();
                        column = new TreeViewColumn.with_attributes (_("Port"), 
			    renderer, "text", Columns.PORT);
			column.expand = false;
                        _treeview.append_column (column);

                        /* buttons events */
                        var button = (Gtk.Button) builder.get_object ("button_connection_add");
			assert (button != null);
                        button.clicked += this.on_button_connection_add_clicked;

                        button_conn_remove = (Gtk.Button) builder.get_object ("button_connection_remove");
			assert (button_conn_remove != null);
                        button_conn_remove.clicked += this.on_button_connection_remove_clicked;

                        button_conn_modify = (Gtk.Button) builder.get_object ("button_connection_modify");
			assert (button_conn_modify != null);
                        button_conn_modify.clicked += this.on_button_connection_modify_clicked;

                        button = (Gtk.Button) builder.get_object ("button_close");
			assert (button != null);
                        button.clicked += this.on_button_close_clicked;

                        /* initialize connection list view */
                        _store = new ListStore (Columns.COUNT, 
			    typeof(bool),
                            typeof(string), 
                            typeof(string), 
                            typeof(int),
                            typeof(Connection));
                        _treeview.set_model (_store);
                        foreach (Connection connection in _tuntun.connections.items) {
                                store_add_item (connection);
                        }

                        _tuntun.connections.connection_added += this.on_connection_added;
                        _tuntun.connections.connection_removed += this.on_connection_removed;
		}

                private void on_double_click_connect_toggled (Gtk.CellRendererToggle cell_renderer, string path)
                {
			TreeIter iter;
			if (_store.get_iter_from_string (out iter, path))
			{
				weak Connection conn;
                                _store.get (iter, Columns.CONNECTION, out conn,-1);
				conn.info.quick_connect = !conn.info.quick_connect;
				store_modify_item (iter, conn);
				is_dirty = true;
			}
                }

                private void cleanup_and_close ()
                {
                        _window.delete_event -= this.on_window_delete;
                        _window.hide ();

                        var builder = Utils.get_ui ();
                        var button = (Gtk.Button) builder.get_object ("button_connection_add");
                        button.clicked -= this.on_button_connection_add_clicked;


                        button_conn_remove.clicked -= this.on_button_connection_remove_clicked;
                        button_conn_modify.clicked -= this.on_button_connection_modify_clicked;

                        button = (Gtk.Button) builder.get_object ("button_close");
                        button.clicked -= this.on_button_close_clicked;

                        if (_treeview != null) {
				_treeview.get_selection().changed -= this.on_treeview_selection_changed;
                                var column = _treeview.get_column (0);
                                while (column != null) {
                                        _treeview.remove_column (column);
                                        column = _treeview.get_column (0);
                                }
                        }
                        this.closed ();

                        _tuntun.connections.connection_added -= this.on_connection_added;
                        _tuntun.connections.connection_removed -= this.on_connection_removed;
                }

                public ConnectionsDialog (construct Tuntun tuntun) { }

                public Tuntun tuntun { construct { _tuntun = value; } }

		public void show ()
		{
			_window.show_all ();
		}

                private void on_connection_added (Connections connections, Connection connection)
                {
                        store_add_item (connection);
                }

                private void on_connection_removed (Connections connections, Connection connection)
                {
                        store_remove_item (connection);
                }

		private void on_treeview_selection_changed (TreeSelection sender)
		{
			bool sensitive = (this.selected_connection != null);

			button_conn_modify.set_sensitive (sensitive);
			button_conn_remove.set_sensitive (sensitive);
		}

                private bool on_window_delete (Gtk.Window sender, Gdk.Event event)
                {
                        cleanup_and_close ();
                        return true;
                }

                private void on_button_connection_add_clicked (Gtk.Button sender)
                {
			var connection_info = new ConnectionInfo ();
			var dialog = new ConnectionDialog (connection_info);
			
			if (dialog.show (_window) == ResponseType.OK) {
				var connection = new Connection (connection_info);
				_tuntun.connections.add (connection);
				is_dirty = true;
			}
                }

                private void on_button_connection_remove_clicked (Gtk.Button sender)
                {
                        var connection = this.selected_connection;

                        return_if_fail (connection != null);

                        var builder = Utils.get_ui ();                        
                        var confirm = (Gtk.Dialog) builder.get_object ("dialog_connection_remove");
		
                        if (confirm.run () == ResponseType.OK) {
                                _tuntun.connections.remove (connection);
				is_dirty = true;
                        }
                        confirm.hide ();
                }

                private void on_button_connection_modify_clicked (Gtk.Button sender)
                {
                        var connection = this.selected_connection;

                        if (connection == null)
                                return;

			var dialog = new ConnectionDialog (connection.info);
                        if (dialog.show (_window) == ResponseType.OK) {
				TreeIter iter;
				if (store_find (connection, out iter)) {
					store_modify_item (iter, connection);
				}
				is_dirty = true;
			}
                }

                private void on_button_close_clicked (Gtk.Button sender)
                {
			if (is_dirty) {
                                try {
                                        _tuntun.connections.save ();
                                } catch (Error err) {
					Utils.display_error (_("Error while saving config"), err.message);
                                }
			}
                        cleanup_and_close ();
                }

                private void store_add_item (Connection connection)
                {
                        TreeIter iter;
                        _store.append (out iter);
                        store_modify_item (iter, connection);
                }

                private void store_modify_item (TreeIter iter, Connection connection)
                {
                        _store.set (iter, 
                            Columns.NAME, connection.info.name,
                            Columns.ADDRESS, connection.info.address,
                            Columns.PORT, connection.info.port,
			    Columns.DOUBLE_CLICK_CONNECT, connection.info.quick_connect,
                            Columns.CONNECTION, connection);
                }

                private void store_remove_item (Connection connection)
                {
			TreeIter iter;
			if (store_find (connection, out iter))
                                _store.remove (iter);
                }

                private bool store_find (Connection connection, out TreeIter iter)
                {
                        bool valid;
                        bool result = false;

                        /* Get the first iter in the list */
                        valid = _store.get_iter_first (out iter);

                        while (valid)
                        {
                                weak Connection conn;
		
                                _store.get (iter, Columns.CONNECTION, out conn,-1);
                                if (conn == connection)
                                {
                                        result = true;
                                        break;
                                }
                                valid = _store.iter_next (ref iter);
                        }

                        return result;
                }

                private weak Connection selected_connection
                {
                        get {
                                TreeSelection selection = _treeview.get_selection ();
                                TreeIter iter;
                                if (selection.get_selected (null, out iter))
                                {
                                        weak Connection connection;
                                        _store.get (iter, Columns.CONNECTION, out connection,-1);
                                        return connection;
                                }
                                else
                                        return null;
                        }
                }
	}
}
