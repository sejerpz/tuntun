/* GNIO - GLib Network Layer of GIO
 *
 * Copyright (C) 2008 Christian Kellner, Samuel Cormier-Iijima
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authors: Christian Kellner <gicmo@gnome.org>
 *          Samuel Cormier-Iijima <sciyoshi@gmail.com>
 */

#include <config.h>
#include <glib.h>
#include <gio/gio.h>
#include <gnio/gnio.h>

#include <string.h>
#include <errno.h>

G_DEFINE_TYPE (GSocketConnection, g_socket_connection, G_TYPE_OBJECT);

enum
{
  PROP_0,
  PROP_ADDRESS,
  PROP_SOCKET,
  PROP_INPUT_STREAM,
  PROP_OUTPUT_STREAM
};

struct _GSocketConnectionPrivate
{
  GSocketAddress      *address;
  GSocket             *socket;
  GSocketInputStream  *input_stream;
  GSocketOutputStream *output_stream;
};

static void
g_socket_connection_get_property (GObject    *object,
                                  guint       prop_id,
                                  GValue     *value,
                                  GParamSpec *pspec)
{
  GSocketConnection *connection = G_SOCKET_CONNECTION (object);

  switch (prop_id)
    {
      case PROP_ADDRESS:
        g_value_set_object (value, connection->priv->address);
        break;

      case PROP_SOCKET:
        g_value_set_object (value, connection->priv->socket);
        break;

      case PROP_INPUT_STREAM:
        g_value_set_object (value, g_socket_connection_get_input_stream (connection));
        break;

      case PROP_OUTPUT_STREAM:
        g_value_set_object (value, g_socket_connection_get_output_stream (connection));
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_socket_connection_set_property (GObject      *object,
                                  guint         prop_id,
                                  const GValue *value,
                                  GParamSpec   *pspec)
{
  GSocketConnection *connection = G_SOCKET_CONNECTION (object);

  switch (prop_id)
    {
      case PROP_ADDRESS:
        // sink the address' floating reference
        connection->priv->address = G_SOCKET_ADDRESS (g_value_get_object (value));
        if (connection->priv->address)
          g_object_ref_sink (connection->priv->address);
        break;

      case PROP_SOCKET:
        connection->priv->socket = G_SOCKET (g_value_get_object (value));
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_socket_connection_finalize (GObject *object)
{
  GSocketConnection *connection = G_SOCKET_CONNECTION (object);

  g_object_unref (connection->priv->address);

  if (connection->priv->input_stream)
    g_object_unref (connection->priv->input_stream);

  if (connection->priv->output_stream)
    g_object_unref (connection->priv->output_stream);

  if (G_OBJECT_CLASS (g_socket_connection_parent_class)->finalize)
    (*G_OBJECT_CLASS (g_socket_connection_parent_class)->finalize) (object);
}

static void
g_socket_connection_dispose (GObject *object)
{
  GSocketConnection *connection = G_SOCKET_CONNECTION (object);

  g_socket_connection_close (connection);

  if (G_OBJECT_CLASS (g_socket_connection_parent_class)->dispose)
    (*G_OBJECT_CLASS (g_socket_connection_parent_class)->dispose) (object);
}

static void
g_socket_connection_class_init (GSocketConnectionClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (GSocketConnectionPrivate));

  gobject_class->finalize = g_socket_connection_finalize;
  gobject_class->dispose = g_socket_connection_dispose;
  gobject_class->set_property = g_socket_connection_set_property;
  gobject_class->get_property = g_socket_connection_get_property;

  g_object_class_install_property (gobject_class, PROP_ADDRESS,
                                   g_param_spec_object ("address",
                                                        "address",
                                                        "the remote address the socket will connect to",
                                                        G_TYPE_SOCKET_ADDRESS,
                                                        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_SOCKET,
                                   g_param_spec_object ("socket",
                                                        "socket",
                                                        "the underlying GSocket",
                                                        G_TYPE_SOCKET,
                                                        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_INPUT_STREAM,
                                   g_param_spec_object ("input-stream",
                                                        "input stream",
                                                        "the GSocketInputStream for reading from this socket",
                                                        G_TYPE_SOCKET_INPUT_STREAM,
                                                        G_PARAM_READABLE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_OUTPUT_STREAM,
                                   g_param_spec_object ("output-stream",
                                                        "output stream",
                                                        "the GSocketOutputStream for writing to this socket",
                                                        G_TYPE_SOCKET_OUTPUT_STREAM,
                                                        G_PARAM_READABLE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));
}

static void
g_socket_connection_init (GSocketConnection *connection)
{
  connection->priv = G_TYPE_INSTANCE_GET_PRIVATE (connection, G_TYPE_SOCKET_CONNECTION, GSocketConnectionPrivate);

  connection->priv->address = NULL;
  connection->priv->socket = NULL;
  connection->priv->input_stream = NULL;
  connection->priv->output_stream = NULL;
}

GSocketConnection *
g_socket_connection_new (GSocketAddress *address)
{
  return G_SOCKET_CONNECTION (g_object_new (G_TYPE_SOCKET_CONNECTION, "address", address, NULL));
}

GSocketConnection *
g_socket_connection_new_from_socket (GSocket *socket)
{
  return G_SOCKET_CONNECTION (g_object_new (G_TYPE_SOCKET_CONNECTION, "socket", socket, NULL));
}

GSocketInputStream *
g_socket_connection_get_input_stream (GSocketConnection *connection)
{
  g_return_val_if_fail (G_IS_SOCKET_CONNECTION (connection), NULL);

  if (!connection->priv->socket)
    return NULL;

  if (connection->priv->input_stream)
    return connection->priv->input_stream;

  // TODO: should we set g_object_notify here, or just create both these streams earlier?

  return (connection->priv->input_stream = _g_socket_input_stream_new (connection->priv->socket));
}

GSocketOutputStream *
g_socket_connection_get_output_stream (GSocketConnection *connection)
{
  g_return_val_if_fail (G_IS_SOCKET_CONNECTION (connection), NULL);

  if (!connection->priv->socket)
    return NULL;

  if (connection->priv->output_stream)
    return connection->priv->output_stream;

  // TODO: should we set g_object_notify here, or just create both these streams earlier?

  return (connection->priv->output_stream = _g_socket_output_stream_new (connection->priv->socket));
}

GSocketAddress *
g_socket_connection_get_address (GSocketConnection *connection)
{
  g_return_val_if_fail (G_IS_SOCKET_CONNECTION (connection), NULL);

  return connection->priv->address;
}

gboolean
g_socket_connection_is_connected (GSocketConnection *connection)
{
  g_return_val_if_fail (G_IS_SOCKET_CONNECTION (connection), FALSE);

  if (!connection->priv->socket)
    return FALSE;

  return g_socket_is_connected (connection->priv->socket);
}

gboolean
g_socket_connection_connect (GSocketConnection  *connection,
                             GCancellable       *cancellable,
                             GError            **error)
{
  g_return_val_if_fail (G_IS_SOCKET_CONNECTION (connection), FALSE);

  if (G_IS_INET_SOCKET_ADDRESS (connection->priv->address))
    {
      GInetAddress *address = g_inet_socket_address_get_address (G_INET_SOCKET_ADDRESS (connection->priv->address));

      if (G_IS_INET4_ADDRESS (address))
        connection->priv->socket = g_socket_new (G_SOCKET_DOMAIN_INET, G_SOCKET_TYPE_STREAM, NULL);
      else if (G_IS_INET6_ADDRESS (address))
        connection->priv->socket = g_socket_new (G_SOCKET_DOMAIN_INET6, G_SOCKET_TYPE_STREAM, NULL);
    }
  // TODO: do unix domain sockets here

  if (!connection->priv->socket)
    {
      g_set_error (error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED, "unsupported address domain");
      return FALSE;
    }

  if (g_socket_has_error (connection->priv->socket, error))
    return FALSE;

  if (g_cancellable_set_error_if_cancelled (cancellable, error))
    return FALSE;

  if (!g_socket_connect (connection->priv->socket, connection->priv->address, error))
    return FALSE;

  return TRUE;
}

typedef struct {
  GAsyncReadyCallback  callback;
  GCancellable        *cancellable;
  gpointer             user_data;
  GSocketConnection   *connection;
} ConnectData;

static gboolean
connect_callback (ConnectData *data,
                  GIOCondition condition,
                  gint fd)
{
  GSocketConnection *connection;
  GSimpleAsyncResult *result;
  GError *error = NULL;

  connection = data->connection;

  if (condition & G_IO_OUT)
    {
      result = g_simple_async_result_new (G_OBJECT (connection), data->callback, data->user_data, g_socket_connection_connect_async);
    }
  else
    {
      if (!g_socket_has_error (connection->priv->socket, &error))
        g_warning ("got G_IO_ERR but socket does not have error");

      result = g_simple_async_result_new_from_error (G_OBJECT (connection), data->callback, data->user_data, error);
    }

  g_simple_async_result_complete (result);

  g_object_unref (result);

  return FALSE;
}

void
g_socket_connection_connect_async (GSocketConnection   *connection,
                                   GCancellable        *cancellable,
                                   GAsyncReadyCallback  callback,
                                   gpointer             user_data)
{
  GSimpleAsyncResult *result;
  GSource *source;
  ConnectData *data;
  GError *error = NULL;

  g_return_if_fail (G_IS_SOCKET_CONNECTION (connection));

  if (!connection->priv->socket && G_IS_INET_SOCKET_ADDRESS (connection->priv->address))
    {
      GInetAddress *address = g_inet_socket_address_get_address (G_INET_SOCKET_ADDRESS (connection->priv->address));
      if (G_IS_INET4_ADDRESS (address))
        connection->priv->socket = g_socket_new (G_SOCKET_DOMAIN_INET, G_SOCKET_TYPE_STREAM, NULL);
      else if (G_IS_INET6_ADDRESS (address))
        connection->priv->socket = g_socket_new (G_SOCKET_DOMAIN_INET6, G_SOCKET_TYPE_STREAM, NULL);
    }
  // TODO: unix domain sockets

  if (!connection->priv->socket)
    {
      g_simple_async_report_error_in_idle (G_OBJECT (connection), callback, user_data, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED, "unsupported address domain");
      return;
    }

  if (g_socket_has_error (connection->priv->socket, &error))
    {
      g_simple_async_report_gerror_in_idle (G_OBJECT (connection), callback, user_data, error);
      return;
    }

  // TODO: is it ok to set the socket to nonblocking each time?
  g_socket_set_blocking (connection->priv->socket, FALSE);

  if (!g_socket_connect (connection->priv->socket, connection->priv->address, &error))
    {
      if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_PENDING))
        {
          // the connection is in progress
          source = g_socket_create_source (connection->priv->socket, G_IO_OUT | G_IO_ERR | G_IO_HUP, cancellable);

          data = g_new (ConnectData, 1);

          data->connection = connection;
          data->callback = callback;
          data->cancellable = cancellable;
          data->user_data = user_data;

          g_source_set_callback (source, (GSourceFunc) connect_callback, data, g_free);

          g_source_attach (source, NULL);

          g_clear_error (&error);
        }
      else
        {
          g_simple_async_report_gerror_in_idle (G_OBJECT (connection), callback, user_data, error);
        }
    }
  else
    {
      // the connection is already completed
      result = g_simple_async_result_new (G_OBJECT (connection), callback, user_data, g_socket_connection_connect_async);

      g_simple_async_result_complete_in_idle (result);

      g_object_unref (result);
    }
}

gboolean
g_socket_connection_connect_finish (GSocketConnection  *connection,
                                    GAsyncResult       *result,
                                    GError            **error)
{
  GSimpleAsyncResult *simple;

  g_return_val_if_fail (G_IS_SOCKET_CONNECTION (connection), FALSE);

  simple = G_SIMPLE_ASYNC_RESULT (result);

  if (g_simple_async_result_propagate_error (simple, error))
    return FALSE;

  g_warn_if_fail (g_simple_async_result_get_source_tag (simple) == g_socket_connection_connect_async);

  return TRUE;
}

void
g_socket_connection_close (GSocketConnection *connection)
{
  g_return_if_fail (G_IS_SOCKET_CONNECTION (connection));

  g_socket_close (connection->priv->socket);
}
