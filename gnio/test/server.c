#include <gio/gio.h>
#include <gnio/gsocket.h>
#include <gnio/ginetsocketaddress.h>
#include <gnio/ginet4address.h>
#include <glib.h>
#include <sys/socket.h>
#include <errno.h>

GMainLoop *loop;

void accept_callback (GSocket *socket, GAsyncResult *result, gpointer data);

/*
gboolean
accept_source (gpointer data)
{
	GSocket *socket = G_SOCKET (data);

	g_print ("in source\n");

	g_socket_accept_async (socket, NULL, (GAsyncReadyCallback) accept_callback, NULL);

	return FALSE;	
}

void
accept_callback (GSocket *socket, GAsyncResult *result, gpointer data)
{
	GSocket *new_socket;
	GSocketAddress *address;
	GError *error = NULL;

	g_print ("in callback\n");

	new_socket = g_socket_accept_finish (socket, result, &error);

	if (!new_socket)
		g_error (error->message);

	address = g_socket_get_remote_address (new_socket, &error);

	if (!address)
		g_error (error->message);

	g_print ("got a new connection from %s:%d\n", g_inet_address_to_string (g_inet_socket_address_get_address (G_INET_SOCKET_ADDRESS (address))), g_inet_socket_address_get_port (G_INET_SOCKET_ADDRESS (address)));

	g_idle_add (accept_source, (gpointer) socket);
}
*/

int main (int argc, char *argv[])
{
	GSocket *socket, *new_socket;
	GSocketAddress *address;
	GError *error = NULL;

	g_thread_init (NULL);

	g_type_init ();

	loop = g_main_loop_new (NULL, FALSE);

	socket = g_socket_new (G_SOCKET_DOMAIN_INET, G_SOCKET_TYPE_STREAM, NULL, NULL);

	g_socket_set_reuse_address (socket, TRUE);

	if (!g_socket_bind (socket, G_SOCKET_ADDRESS (g_inet_socket_address_new (G_INET_ADDRESS (g_inet4_address_from_string ("127.0.0.1")), 31882)), &error)) {
		g_error (error->message);
		return 0;
	}

	if (!g_socket_listen (socket, &error)) {
		g_error (error->message);
		return 0;
	}

	g_print ("listening on port 31882...\n");

	new_socket = g_socket_accept (socket, &error);

	if (!new_socket) {
		g_error (error->message);
		return 0;
	}

	address = g_socket_get_remote_address (new_socket, &error);

	if (!address) {
		g_error (error->message);
		return 0;
	}

	g_print ("got a new connection from %s:%d\n", g_inet_address_to_string (g_inet_socket_address_get_address (G_INET_SOCKET_ADDRESS (address))), g_inet_socket_address_get_port (G_INET_SOCKET_ADDRESS (address)));

	while (TRUE) {
		gchar buffer[128] = { };
		gssize size;

		if ((size = g_socket_receive (new_socket, buffer, 128, &error)) < 0) {
			g_error (error->message);
			return 0;
		}

		if (size == 0)
			break;

		g_print ("received %" G_GSSIZE_FORMAT " bytes of data: %s\n", size, buffer);

		if ((size = g_socket_send (new_socket, buffer, size, &error)) < 0) {
			g_error (error->message);
			return 0;
		}

		if (size == 0)
			break;
	}

	g_print ("connection closed\n");

	g_object_unref (G_OBJECT (new_socket));

	g_socket_close (socket);

	g_object_unref (G_OBJECT (socket));

	return 0;
}
