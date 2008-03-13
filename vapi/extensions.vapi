namespace Extensions
{
	/* api additions to glib */
	[CCode (cname="g_object_notify")]
	public static void notify_property_changed (GLib.Object sender, string property_name);
}