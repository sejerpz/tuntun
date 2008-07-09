#include <gio/gio.h>
#include <gnio/gnio.h>

GMainLoop *loop;

static void print_address (GInetAddress *address, gpointer data);

static void
print_address (GInetAddress *address, gpointer data)
{
	gchar *string = g_inet_address_to_string (G_INET_ADDRESS (address));

	g_printf ("%s\n", string);

	g_free (string);
}

static void
resolve_callback (GObject *source, GAsyncResult *result, gpointer data)
{
	GError *error = NULL;

	GResolver *resolver = G_RESOLVER (source);

	GList *list;

	list = g_resolver_resolve_list_finish (resolver, result, &error);

	if (error) {
		g_error (error->message);
		return;
	}

	g_printf ("\nwww.google.com (list, async):\n");

	g_list_foreach (list, (GFunc) print_address, NULL);

	g_list_foreach (list, (GFunc) g_object_unref, NULL);

	g_list_free (list);

	g_main_loop_quit (loop);
}

int main (int argc, char *argv[])
{
	GInetAddress *address;
	GResolver *resolver;
	GError *error = NULL;

	g_thread_init (NULL);

	g_type_init ();

	loop = g_main_loop_new (NULL, FALSE);

	address = (GInetAddress *) g_inet4_address_from_string ("127.0.0.1");

	g_printf ("is floating: %d\n", g_object_is_floating (address));

	g_printf ("%s:\n", g_inet_address_to_string (address));

	g_printf ("is_any: %d, is_link_local: %d, is_loopback: %d\n", g_inet_address_is_any (address), g_inet_address_is_link_local (address), g_inet_address_is_loopback (address));

	g_object_unref (address);

	address = (GInetAddress *) g_inet4_address_from_string ("0.0.0.0");

	g_printf ("\n%s:\n", g_inet_address_to_string (address));

	g_printf ("is_any: %d, is_link_local: %d, is_loopback: %d\n", g_inet_address_is_any (address), g_inet_address_is_link_local (address), g_inet_address_is_loopback (address));

	g_object_unref (address);

	address = (GInetAddress *) g_inet4_address_from_string ("169.254.0.0");

	g_printf ("\n%s:\n", g_inet_address_to_string (address));

	g_printf ("is_any: %d, is_link_local: %d, is_loopback: %d\n", g_inet_address_is_any (address), g_inet_address_is_link_local (address), g_inet_address_is_loopback (address));

	g_object_unref (address);

	resolver = G_RESOLVER (g_object_new (G_TYPE_RESOLVER, NULL));

	address = g_resolver_resolve (resolver, "www.yahoo.com", NULL, &error);

	if (!address) {
		g_error (error->message);
		return 0;
	}

	g_printf ("\nwww.yahoo.com: %s\n", g_inet_address_to_string (address));

	g_printf ("is_any: %d, is_link_local: %d, is_loopback: %d\n", g_inet_address_is_any (address), g_inet_address_is_link_local (address), g_inet_address_is_loopback (address));

	g_object_unref (address);

	g_resolver_resolve_list_async (resolver, "www.google.com", NULL, resolve_callback, NULL);

	g_main_loop_run (loop);

	return 0;
}
