/*
 + WARNING: this vapi file is provided only to support devlopment of gnome-panel applets
 * since libbonoboui is deprecated (http://library.gnome.org/devel/references.html.en_GB)
 */

[CCode (cheader_filename = "libbonoboui.h")]
namespace BonoboUI {
	public struct Verb {
		public string cname;
		public VerbFn cb;
		public pointer user_data;
		public pointer dummy;
	}

	public class Component
	{
	}

	public static delegate void VerbFn (Component component, pointer user_data, string cname);
}