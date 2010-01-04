using GLib;
using Gtk;

namespace Tuntun
{
	public class Tooltip : Gtk.VBox
	{
		construct 
		{
			bool title_added = false;

			foreach (Connection connection in _connections.items) {
				if (connection.status == ConnectionStates.CONNECTED) {
					if (!title_added) {
						add_title ();
						title_added = true;
					}
					add_connection (connection, Constants.Images.CONNECTION_STATUS_CONNECT);
				}
			}
			foreach (Connection connection in _connections.items) {
				if (connection.status == ConnectionStates.DISCONNECTED) {
					if (!title_added) {
						add_title ();
						title_added = true;
					}
					add_connection (connection, Constants.Images.CONNECTION_STATUS_DISCONNECT);
				}
			}

			this.show_all ();
		}

		private void add_title ()
		{
			var title = new Label (null);
			title.set_markup ("<b>%s</b>".printf(_("Tuntun connections status")));
			this.pack_start (title, false, true, 8);
		}

		private void add_connection (Connection connection, string status_image)
		{
			var widget = new Image.from_file (Utils.get_image_path (status_image));
			var hbox = new HBox (false, 8);
			Label label;
			
			hbox.pack_start (widget, false, false, 4);
			hbox.pack_start (new Label.with_mnemonic (connection.info.name), false, false, 12);
			if (connection.status == ConnectionStates.CONNECTED) {
				label = new Label (null);
				label.set_markup ("<i>%s</i>".printf(_("ip address: %s").printf(connection.info.assigned_ip)));
				hbox.pack_end (label, false, false, 12);
			} else {
				label = new Label (null);
				label.set_markup ("<i>%s</i>".printf(_("disconnected")));
				hbox.pack_end (label, false, false, 12);
			}
			this.pack_start (hbox, true, true, 4);
		}

		public Connections connections { private get; construct; }

		public Tooltip (Connections connections)
		{
			GLib.Object(connections: connections);
		}
	}
}
