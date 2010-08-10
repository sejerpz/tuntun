/*
 *  tuntun-auth-dialog.vala is a part of Tuntun
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
using GnomeKeyring;

namespace Tuntun
{
	public enum AuthSteps
	{
			KEYRING,
			DIALOG
	}

	public class AuthDialog : Gtk.Window
	{
		private Connection _connection = null;
		private AuthenticationModes _mode = AuthenticationModes.USERNAME_PASSWORD;
		private string _auth_type = null;
		private weak Gtk.Entry _entry_user;
		private weak Gtk.Entry _entry_pass;
		private weak CheckButton _checkbutton_save_in_keyring;
		private uint _keyring_item_id = 0;
		private AuthSteps _current = AuthSteps.KEYRING;

		construct
		{
			_connection.authentication_failed.connect (this.on_connection_authentication_failed);
		}

		public AuthDialog (Connection connection, AuthenticationModes mode, string auth_type) 
		{ 
			GLib.Object(connection: connection, mode: mode, auth_type: auth_type);
		}

		public Connection connection { construct { _connection = value; } }
		public AuthenticationModes mode { construct { _mode = value; } }
		public new string auth_type { construct { _auth_type = value; } }

		private void initialize_ui ()
		{
			var builder = new Builder();
			builder.set_translation_domain (Config.GETTEXT_PACKAGE);
			try {
				builder.add_from_file (Utils.get_ui_path ("tuntun-auth-dialog.ui"));
			} catch (Error err) {
				Utils.display_error ("initialize_ui", err.message);
			}
			var childs = (Gtk.VBox) builder.get_object ("vbox_authentication");
			assert (childs != null);
			this.add (childs);
			this.set ("border-width", 12);
			this.set_resizable (false);
			var button = (Gtk.Button) builder.get_object ("button_auth_ok");
			assert (button != null);
			button.clicked.connect (this.on_button_ok_clicked);
			button = (Gtk.Button) builder.get_object ("button_auth_cancel");
			assert (button != null);
			button.clicked.connect (this.on_button_cancel_clicked);

			_entry_user = (Gtk.Entry)  builder.get_object ("entry_username");
			assert (_entry_user != null);
			_entry_pass = (Gtk.Entry)  builder.get_object ("entry_password");
			assert (_entry_pass != null);

			_checkbutton_save_in_keyring = (Gtk.CheckButton)  builder.get_object ("checkbutton_save_in_keyring");
			assert (_checkbutton_save_in_keyring != null);

			var label = (Gtk.Label)  builder.get_object ("label_username");
			var label_message = (Gtk.Label)  builder.get_object ("label_message");
			string label_text;
			assert (label != null);
			assert (label_message != null);
			switch (_mode) {
				case AuthenticationModes.USERNAME_PASSWORD:
					label_text = _("Username and password for %s");
					label_message.set_text (label_text.printf (_connection.info.name));
					_entry_user.show ();
					label.show ();
					break;
				case AuthenticationModes.PASSWORD_ONLY:
					label_text = _("Private key password for %s");
					label_message.set_text (label_text.printf (_connection.info.name));
					_entry_user.hide ();
					label.hide ();
					break;
			}

			this.set_position (WindowPosition.CENTER);
		}


		private void on_button_ok_clicked (Gtk.Button sender)
		{
			authenticate_dialog_finish (false);
		}

		private void on_button_cancel_clicked (Gtk.Button sender)
		{
			authenticate_dialog_finish (true);
			this.destroy ();
		}

		private void on_connection_authentication_failed (Connection connection, AuthenticationModes mode, string type)
		{
			//delete bogus keyring item
			if (_keyring_item_id != 0)
				item_delete (null, _keyring_item_id, on_item_delete_done);
		}

		public void authenticate ()
		{
			_current = AuthSteps.KEYRING;
			authenticate_keyring ();
		}

		private void authenticate_keyring ()
		{
			switch (_mode) {
				case AuthenticationModes.USERNAME_PASSWORD:
					authenticate_keyring_auth ();
					break;
				case AuthenticationModes.PASSWORD_ONLY:
					authenticate_keyring_private_key ();
					break;
			}
		}

		private void authenticate_dialog ()
		{
			initialize_ui ();
			_current = AuthSteps.DIALOG;
			this.show_all ();
		}

		private void authenticate_dialog_finish (bool cancel)
		{
			string username = null;
			string password = null;

			switch (_mode) {
				case AuthenticationModes.USERNAME_PASSWORD:
					username = _entry_user.get_text ();
					password = _entry_pass.get_text ();
					break;
				case AuthenticationModes.PASSWORD_ONLY:
					password = _entry_pass.get_text ();
					break;
			}

			if (!cancel) {
				_connection.authenticate (_auth_type, username, password);
				if (_checkbutton_save_in_keyring.get_active ()) {
					if (username != null)
						save (username, password);
					else
						save_private_key_password (password);
				} else {
					this.destroy ();
				}
			} else {
				_connection.cancel_authentication (_auth_type, username);
			}
		}


		private void authenticate_keyring_auth ()
		{
			find_network_password (null, null, _connection.info.address, null, "vpn", "auth", 0, this.on_find_password_done);
		}

		private void authenticate_keyring_private_key ()
		{
			find_network_password (null, null, _connection.info.address, null, "vpn", "private-key", 0, this.on_find_password_done);
		}

		private void on_find_password_done (Result result, GLib.List? list)
		{
			string username = null;
			string password = null;

			if (result == Result.OK && list.length () > 0) {
				weak NetworkPasswordData npd = (NetworkPasswordData) list.first().data;
				this._keyring_item_id = npd.item_id;
				if (npd.authtype == "auth") {
					username = npd.user;
					password = npd.password;
				} else if (npd.authtype == "private-key") {
					username = null;
					password = npd.password;
				}
				this._connection.authenticate (this._auth_type, username, password);
			} else {
				this.authenticate_dialog ();
			}
		}

		private void on_item_delete_done (Result result)
		{
			if (result != Result.OK)
				Utils.display_error (_("Keyring"), _("Error deleting credentials for '%s'"));
		}

		private void on_set_password_done (Result result, uint32 val)
		{
			if (result != Result.OK)
				Utils.display_error (_("Keyring"), _("Error saving credentials for '%s'"));

			this.destroy ();
		}

		private void save (string username, string? password)
		{
			return_if_fail (username != "");

			set_network_password (null, 
			    username, 
			    null, 
			    _connection.info.address, 
			    null, 
			    "vpn", 
			    "auth",
			    0,
			    password,
			    on_set_password_done);
		}

		private void save_private_key_password (string private_key_password)
		{
			set_network_password (null, 
			    null, 
			    null, 
			    _connection.info.address, 
			    null, 
			    "vpn", 
			    "private-key",
			    0,
			    private_key_password,
			    this.on_set_password_done);
		}
	}
}
