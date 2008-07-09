#include <gio/gio.h>
#include <gnio/gsocket.h>
#include <gnio/ginetsocketaddress.h>
#include <gnio/ginet4address.h>
#include <glib.h>
#include <glib/gprintf.h>
#include <sys/socket.h>

GMainLoop *loop;

/*
void
accept_callback (GSocket *socket, GAsyncResult *result, gpointer data)
{
	GError *error = NULL;

	if (!g_socket_connect_finish (socket, result, &error)) {
		g_warning (error->message);
		return;
	}

	g_print ("successfully connected\n");
}
*/

int main (int argc, char *argv[])
{
	GSocket *socket;
	GSocketAddress *address;

	g_thread_init (NULL);

	g_type_init ();

	loop = g_main_loop_new (NULL, FALSE);

	socket = g_socket_new (G_SOCKET_DOMAIN_INET, G_SOCKET_TYPE_STREAM, NULL, NULL);

	g_printf ("connecting to 127.0.0.1:31882...\n");

	g_socket_connect (socket, G_SOCKET_ADDRESS (g_inet_socket_address_new (G_INET_ADDRESS (g_inet4_address_from_string ("127.0.0.1")), 31882)), NULL);

	address = g_socket_get_local_address (socket, NULL);

	g_printf ("connected, local socket is %s:%d\n", g_inet_address_to_string (g_inet_socket_address_get_address (G_INET_SOCKET_ADDRESS (address))), g_inet_socket_address_get_port (G_INET_SOCKET_ADDRESS (address)));

	g_object_unref (G_OBJECT (socket));

//	g_main_loop_run (loop);

	return 0;
}
