namespace Extensions
{
	/* api additions to glib */
 	[CCode (cname="g_object_notify")]
	public static void notify_property_changed (GLib.Object sender, string property_name);

 	[CCode (cname="g_source_set_callback")]
	public static void source_set_callback (GLib.Source source, void* func, void* data, GLib.DestroyNotify? notify);

}