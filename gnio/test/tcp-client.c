#include <gio/gio.h>
#include <gnio/gnio.h>

GMainLoop *loop;

typedef struct {
	gchar buffer[512];
	GInputStream *input;
	GOutputStream *output;
} Data;

static void
read_callback (GObject *source, GAsyncResult *result, gpointer data)
{
	GSocketInputStream *stream = G_SOCKET_INPUT_STREAM (source);
	GError *error = NULL;
	gssize count;

	if ((count = g_input_stream_read_finish (G_INPUT_STREAM (stream), result, &error)) < 0) {
		g_warning (error->message);
		return;
	}

	// strduping without freeing just for the kicks
	g_print ("read %" G_GSSIZE_FORMAT " bytes: %s\n", count, g_strndup (((Data *) data)->buffer, count));
}

static void
write_callback (GObject *source, GAsyncResult *result, gpointer data)
{
	GSocketOutputStream *stream = G_SOCKET_OUTPUT_STREAM (source);
	GError *error = NULL;
	gssize count;

	if ((count = g_output_stream_write_finish (G_OUTPUT_STREAM (stream), result, &error)) < 0) {
		g_warning (error->message);
		return;
	}

	g_print ("wrote %" G_GSSIZE_FORMAT " bytes\n", count);

	g_input_stream_read_async (G_INPUT_STREAM (((Data *) data)->input), ((Data *) data)->buffer, 512, G_PRIORITY_DEFAULT, NULL, read_callback, data);
}

static void
connect_callback (GObject *source, GAsyncResult *result, gpointer data)
{
	GSocketConnection *client = G_SOCKET_CONNECTION (source);
	GInputStream *input;
	GOutputStream *output;
	gssize count;
	GError *error = NULL;

	if (!g_socket_connection_connect_finish (client, result, &error)) {
		g_warning (error->message);
		return;
	}

	g_print ("successfully connected\n");

	((Data *) data)->output = G_OUTPUT_STREAM (g_socket_connection_get_output_stream (client));

	((Data *) data)->input = G_INPUT_STREAM (g_socket_connection_get_input_stream (client));

	g_print ("writing...\n");

	g_output_stream_write_async (G_OUTPUT_STREAM (((Data *) data)->output), "GET / HTTP/1.0\r\n\r\n", 19, G_PRIORITY_DEFAULT, NULL, write_callback, data);

/*	if ((count = g_input_stream_read (input, buffer, 512, NULL, &error)) < 0) {
		g_warning (error->message);
		return;
	}

	g_print ("read %" G_GSSIZE_FORMAT " bytes: %s\n", count, buffer);*/
}

int main (int argc, char *argv[])
{
	GSocketConnection *client;
	Data *data;

	g_thread_init (NULL);

	g_type_init ();

	data = g_new0 (Data, 1);

	loop = g_main_loop_new (NULL, FALSE);

/*
	client = g_socket_connection_new ("www.google.com", 80);

	g_print ("connecting to www.google.com:80\n");

	g_socket_connection_connect_async (client, NULL, connect_callback, data);
*/
	g_print ("connecting seems to have begun\n");
/*
	if (!g_tcp_client_connect (client, NULL, &error)) {
		g_warning (error->message);
		return 1;
	}

	g_print ("connected!\n");

	g_object_unref (G_OBJECT (client));

	g_main_loop_run (loop);
*/

	return 0;
}

