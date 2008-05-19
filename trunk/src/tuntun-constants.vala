/*
 *  tuntun-constants.vala is a part of Tuntun
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

namespace Tuntun {
	public static class Constants {
		public const string CONNECTIONS_FILENAME = "tuntun.xml";

		public static class Images {
			public const string APPLICATION = "tuntun.png";
			public const string PANEL_ICON_NORMAL = "tuntun.png";
			public const string PANEL_ICON_ACTIVITY_1 = "tuntun_act_1.png";
			public const string PANEL_ICON_ACTIVITY_2 = "tuntun_act_2.png";

			public const string CONNECTION_STATUS_UNKNOWN = "unknown.png";
 			public const string CONNECTION_STATUS_CONNECT = "disconnect.png";
			public const string CONNECTION_STATUS_DISCONNECT = "connect.png";

 			public const string CONNECTION_STATUS_CONNECTED = "connected.png";
			public const string CONNECTION_STATUS_DISCONNECTED = "not_connected.png";
		}
	}
}