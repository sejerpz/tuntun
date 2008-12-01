/*
 *  tuntun-connections.vala is a part of Tuntun
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

namespace Tuntun 
{
	public class Connections : Object 
	{
		private string _config_file;
		private uint _timeout_id = 0;

		public List<Connection> items;

                public signal void connection_added (Connection connection);
                public signal void connection_removed (Connection connection);
		public signal void connection_status_changed (Connection connection);
		public signal void connection_activity (Connection connection);
		public signal void connection_fatal_error (Connection connection, string error);
		public signal void authentication_required (Connection connection, AuthenticationModes mode, string type);
		public signal void authentication_failed (Connection connection, AuthenticationModes mode, string type);

		construct 
		{
			items = new List<Connection> ();
			load ();
		}

		private void load ()
		{
			_config_file = Utils.gnome_util_home_file (Constants.CONNECTIONS_FILENAME);
			try {
				load_config (_config_file);
			}
			catch (Error err) {
				warning ("Error reading config file: %s, %s", _config_file, err.message);				
			}
		}

		private void load_config (string filename) throws FileError
		{
			try {
				MarkupParser parser = MarkupParser ();
				string content;
				long len;

				if (!FileUtils.test (filename, FileTest.EXISTS))
					return; //no file

				if (!(FileUtils.test (filename, FileTest.IS_REGULAR) ||
					FileUtils.test (filename, FileTest.IS_SYMLINK)))
					throw new FileError.BADF ("File exists, but not a regular file or link");

				// read config file
				FileUtils.get_contents (filename, out content, out len);

				parser.start_element = xmlconfig_start_element_handler;
				parser.end_element = this.xmlconfig_end_element_handler;
				parser.text = this.xmlconfig_text_handler;

				var context = new MarkupParseContext (parser, MarkupParseFlags.TREAT_CDATA_AS_TEXT, this, null);
				context.parse (content, len);
			} catch (Error err) {
				throw err;
			}
		}

                public void save () throws FileError
                {
                        this.save_config (_config_file);
                }

		private void save_config (string filename) throws FileError 
		{
                        string content;
	
                        content = "<?xml version='1.0'?>\n<connections>\n";

                        foreach (Connection connection in items) {
                                string tmp = Markup.printf_escaped ("\t<connection \n\t\tname=\"%s\" \n\t\thost=\"%s\" \n\t\tport=\"%d\" \n\t\tquick-connect=\"%s\" >\n\t</connection>\n",
                                    connection.info.name,
                                    connection.info.address,
                                    connection.info.port,
				    connection.info.quick_connect ? "1" : "0");
                                content += tmp;
                        }
                        content += "</connections>\n";

			try {
				FileUtils.set_contents(filename, content);
			} catch (FileError err) {
                                warning ("error saving config: %s", err.message);
			}
		}

		[NoArrayLength]
		private void xmlconfig_start_element_handler (MarkupParseContext context, 
		    string element_name, 
		    string[] attribute_names, 
		    string[] attribute_values) 
		{
			if (element_name != null && "connection".collate (element_name) == 0) {
				var info = new ConnectionInfo ();
				for(int i=0; attribute_names[i] != null; i++) {
					if (attribute_names[i] == null)
						continue;

					if ("name".collate (attribute_names[i]) == 0) {
						info.name = attribute_values[i];
					} else if ("host".collate (attribute_names[i]) == 0) {
						info.address = attribute_values[i];
					} else if ("port".collate (attribute_names[i]) == 0) {
						info.port = attribute_values[i].to_int ();
					} else if ("quick-connect".collate (attribute_names[i]) == 0) {
						info.quick_connect = (attribute_values[i].to_int () != 0 ? true : false);
					}

				}

				if (info.name != null && info.name != "") {
					var connection = new Connection (info);
					this.add (connection);
				}
			}
		}

		public void add (Connection connection)
		{
                        connection.initialize ();
			items.append (connection);
                        on_connection_added (connection);
			Signal.connect (connection, "notify::status", 
			    (Callback)this.connection_notify_property_changed, this);
			Signal.connect (connection, "notify::control-channel-status", 
			    (Callback)this.connection_notify_property_changed, this);
			connection.authentication_required += this.on_connection_authentication_required;
			connection.authentication_failed += this.on_connection_authentication_failed;
			connection.control_channel_fatal_error += this.on_connection_fatal_error;
			connection.control_channel_data_received += this.on_connection_data_received;
		}

		public void remove (Connection connection)
		{
			items.remove (connection);
			SignalHandler.disconnect_by_func (connection, 
			    (void *) this.connection_notify_property_changed, this);
			connection.authentication_required -= this.on_connection_authentication_required;
			connection.authentication_failed -= this.on_connection_authentication_failed;
			connection.control_channel_fatal_error -= this.on_connection_fatal_error;
			connection.control_channel_data_received -= this.on_connection_data_received;
                        on_connection_removed (connection);
		}


		private void on_connection_data_received (Connection connection, string data)
		{
			on_connection_activity (connection);
		}

		protected virtual void on_connection_activity (Connection connection)
		{
			connection_activity (connection);
		}

                protected virtual void on_connection_fatal_error (Connection connection, string error)
                {
                        connection_fatal_error (connection, error);
                }

		protected virtual void on_connection_authentication_required (Connection connection, 
		    AuthenticationModes mode, string type)
		{
			authentication_required (connection, mode, type);
		}

		protected virtual void on_connection_authentication_failed (Connection connection, 
		    AuthenticationModes mode, string type)
		{
			authentication_failed (connection, mode, type);
		}

                protected virtual void on_connection_removed (Connection connection)
                {
                        connection_removed (connection);
                }

                protected virtual void on_connection_added (Connection connection)
                {
                        connection_added (connection);
                }

		protected virtual void on_connection_status_changed (Connection connection)
                {
			connection_status_changed (connection);

			//see if I need to reinit the connection later
			if (_timeout_id == 0 && 
			    connection.control_channel_status == ConnectionStates.ERROR) {
				_timeout_id = Timeout.add_seconds (15, this.connection_recheck);
			}
                }

		private bool connection_recheck ()
		{
			bool result = false;
			foreach (Connection connection in items) {
				if (connection.control_channel_status == ConnectionStates.ERROR) {
					connection.reinitialize ();
					result = true; //ensure that
						       //we do this
						       //for 2 times since some bad concurrency could happen here
				}
			}
			if (!result)
				_timeout_id = 0;
			return result;
		}

		private static void connection_notify_property_changed  (Connection connection, 
		    ParamSpec param, Connections connections)
		{
			connections.on_connection_status_changed (connection);
		}

		private void xmlconfig_end_element_handler (MarkupParseContext context, string element_name) {
			
		}

		private void xmlconfig_text_handler (MarkupParseContext context, string text, ulong text_len) {
		
		}
	}
}
