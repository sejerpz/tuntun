using GLib;

namespace Tuntun {
	public class Tuntun : Object {
		private Connections _connections = null;

		public Connections connections { 
			get {
				return _connections;
			}
		}

		construct {
			this._connections = new Connections ();
		}
	}
}