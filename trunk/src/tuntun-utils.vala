/*
 *  tuntun-utils.vala is a part of Tuntun
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

namespace Tuntun {
	public class Utils {
		private const string GNOME_DOT_GNOME = ".gnome2";

		private static Gtk.Builder ui = null;

		/*
		 * This function is the equivalent of
		 * gnome_util_home_file contained in
		 * libgnome-2.0/gnome-util.h
		 */
		public static string gnome_util_home_file (string afile) {
			return Path.build_filename ( Environment.get_home_dir (), GNOME_DOT_GNOME, afile);
		}

		public static string get_image_path (string id) {
			return Path.build_filename (Config.PACKAGE_DATA_DIR, "tuntun", "pixmaps", id);
		}

		public static string get_ui_path (string id) {
			return Path.build_filename (Config.PACKAGE_DATA_DIR, "tuntun", "ui", id);
		}

		public static unowned Gtk.Builder get_ui ()
		{
                        if (ui == null)
				initialize_gtk_builder ();

			return ui;
		}

		private static void initialize_gtk_builder ()
		{
			try {
				ui = new Gtk.Builder ();
				ui.set_translation_domain (Config.GETTEXT_PACKAGE);
				ui.add_from_file ( get_ui_path ("tuntun.ui") );
			} catch (Error err) {
				display_error ("initialize_gtk_builder", err.message);
			}
		}

		public static void display_error (string function, string message)
		{
			var dialog = new MessageDialog (null,
                                  DialogFlags.DESTROY_WITH_PARENT,
                                  MessageType.ERROR,
                                  ButtonsType.CLOSE,
			          message);
			dialog.secondary_text = function;
			dialog.run ();
			dialog.destroy ();

		}
	}
}
