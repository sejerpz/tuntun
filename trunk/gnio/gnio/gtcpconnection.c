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

#include "gtcpconnection.h"

G_DEFINE_TYPE (GTCPConnection, g_tcp_connection, G_TYPE_SOCKET_CONNECTION);

enum
{
  PROP_0,
  PROP_ADDRESS,
  PROP_HOSTNAME,
  PROP_PORT,
  PROP_INPUT_STREAM,
  PROP_OUTPUT_STREAM
};

struct _GTCPConnectionPrivate
{
  gchar   *hostname;
  gushort  port;
};

static void
g_tcp_connection_constructed (GObject *object)
{
  GTCPConnection *connection = G_TCP_CONNECTION (object);

  GInetSocketAddress *address = G_INET_SOCKET_ADDRESS (g_socket_connection_get_address (G_SOCKET_CONNECTION (object)));

  if (address)
    {
      // we've been constructed with an address, extract hostname+port
      connection->priv->hostname = g_inet_address_to_string (g_inet_socket_address_get_address (address));
      connection->priv->port = g_inet_socket_address_get_port (address);
      return;
    }
}

static void
g_tcp_connection_get_property (GObject    *object,
                               guint       prop_id,
                               GValue     *value,
                               GParamSpec *pspec)
{
  GTCPConnection *connection = G_TCP_CONNECTION (object);

  switch (prop_id)
    {
      case PROP_HOSTNAME:
        g_value_set_string (value, connection->priv->hostname);
        break;

      case PROP_PORT:
        g_value_set_uint (value, connection->priv->port);
        break;

      default:
        G_OBJECT_CLASS (g_tcp_connection_parent_class)->get_property (object, prop_id, value, pspec);
//        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_tcp_connection_set_property (GObject      *object,
                           guint         prop_id,
                           const GValue *value,
                           GParamSpec   *pspec)
{
  GTCPConnection *connection = G_TCP_CONNECTION (object);

  switch (prop_id)
    {
      case PROP_HOSTNAME:
        connection->priv->hostname = g_value_dup_string (value);
        break;

      case PROP_PORT:
        connection->priv->port = g_value_get_uint (value);
        break;

      default:
        G_OBJECT_CLASS (g_tcp_connection_parent_class)->set_property (object, prop_id, value, pspec);
//        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_tcp_connection_finalize (GObject *object)
{
  GTCPConnection *connection = G_TCP_CONNECTION (object);

  if (G_OBJECT_CLASS (g_tcp_connection_parent_class)->finalize)
    (*G_OBJECT_CLASS (g_tcp_connection_parent_class)->finalize) (object);
}

static void
g_tcp_connection_dispose (GObject *object)
{
  GTCPConnection *connection = G_TCP_CONNECTION (object);

  g_free (connection->priv->hostname);

  if (G_OBJECT_CLASS (g_tcp_connection_parent_class)->dispose)
    (*G_OBJECT_CLASS (g_tcp_connection_parent_class)->dispose) (object);
}

static void
g_tcp_connection_class_init (GTCPConnectionClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (GTCPConnectionPrivate));

  gobject_class->finalize = g_tcp_connection_finalize;
  gobject_class->dispose = g_tcp_connection_dispose;
  gobject_class->constructed = g_tcp_connection_constructed;
  gobject_class->set_property = g_tcp_connection_set_property;
  gobject_class->get_property = g_tcp_connection_get_property;

  g_object_class_install_property (gobject_class, PROP_ADDRESS,
                                   g_param_spec_object ("address",
                                                        "address",
                                                        "the hostname of the remote address the tcp will connect to",
                                                        G_TYPE_INET_SOCKET_ADDRESS,
                                                        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_HOSTNAME,
                                   g_param_spec_string ("hostname",
                                                        "hostname",
                                                        "the hostname of the remote address the tcp will connect to",
                                                        NULL,
                                                        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_PORT,
                                   g_param_spec_uint ("port",
                                                      "port",
                                                      "the remote port the tcp will connect to",
                                                      0,
                                                      G_MAXUSHORT,
                                                      0,
                                                      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));
}

static void
g_tcp_connection_init (GTCPConnection *connection)
{
  connection->priv = G_TYPE_INSTANCE_GET_PRIVATE (connection, G_TYPE_TCP_CONNECTION, GTCPConnectionPrivate);

  connection->priv->hostname = NULL;
  connection->priv->port = 0;
}

GTCPConnection *
g_tcp_connection_new (const gchar *hostname,
                      gushort      port)
{
  return G_TCP_CONNECTION (g_object_new (G_TYPE_TCP_CONNECTION, "hostname", hostname, "port", port, NULL));
}

/*
gboolean
g_tcp_connection_connect (GTCPConnection    *connection,
                      GCancellable  *cancellable,
                      GError       **error)
{
  GInetAddress *address;

  g_return_val_if_fail (G_IS_TCP_CONNECTION (connection), FALSE);

  if (!connection->priv->address)
    {
      // we've been constructed with just hostname+port, resolve
      GResolver *resolver = g_resolver_new ();

      address = g_resolver_resolve (resolver, connection->priv->hostname, cancellable, error);

      if (!address)
        return FALSE;

      connection->priv->address = g_inet_socket_address_new (address, connection->priv->port);

      g_object_unref (resolver);

      g_object_ref_sink (connection->priv->address);
    }
  else
    {
      address = g_inet_socket_address_get_address (connection->priv->address);
    }

  if (G_IS_INET4_ADDRESS (address))
    connection->priv->tcp = g_tcp_new (G_TCP_DOMAIN_INET, G_TCP_TYPE_STREAM, NULL, error);
  else if (G_IS_INET6_ADDRESS (address))
    connection->priv->tcp = g_tcp_new (G_TCP_DOMAIN_INET6, G_TCP_TYPE_STREAM, NULL, error);
  else
    {
      g_set_error (error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED, "unsupported address domain");
      return FALSE;
    }

  if (!connection->priv->tcp)
    return FALSE;

  if (g_cancellable_set_error_if_cancelled (cancellable, error))
    return FALSE;

  if (!g_tcp_connect (connection->priv->tcp, G_TCP_ADDRESS (connection->priv->address), error))
    return FALSE;

  return TRUE;
}

typedef struct {
  GAsyncReadyCallback  callback;
  GCancellable        *cancellable;
  gpointer             user_data;
  GTCPConnection          *connection;
} ConnectData;

static gboolean
connect_callback (ConnectData *data,
                  GIOCondition condition,
                  gint fd)
{
  GTCPConnection *connection;
  GSimpleAsyncResult *result;
  GError *error = NULL;

  connection = data->connection;

  if (condition & G_IO_OUT)
    {
      result = g_simple_async_result_new (G_OBJECT (connection), data->callback, data->user_data, g_tcp_connection_connect_async);
    }
  else
    {
      if (!g_tcp_has_tcp_error (connection->priv->tcp, &error))
        g_warning ("got G_IO_ERR but tcp does not have error");

      result = g_simple_async_result_new_from_error (G_OBJECT (connection), data->callback, data->user_data, error);
    }

  g_simple_async_result_complete (result);

  g_object_unref (result);

  return FALSE;
}

static void
resolve_callback (GObject      *source,
                  GAsyncResult *result,
                  gpointer      user_data)
{
  ConnectData *data = (ConnectData *) user_data;
  GInetAddress *address;
  GSimpleAsyncResult *error_result;
  GError *error = NULL;

  address = g_resolver_resolve_finish (G_RESOLVER (source), result, &error);

  g_object_unref (G_RESOLVER (source));

  if (!address)
    {
      error_result = g_simple_async_result_new_from_error (G_OBJECT (data->connection), data->callback, data->user_data, error);

      g_simple_async_result_complete (error_result);

      g_object_unref (error_result);
    }
  else
    {
      data->connection->priv->address = g_inet_socket_address_new (address, data->connection->priv->port);

      g_object_ref_sink (data->connection->priv->address);

      // at this point, the address has been resolved, so connect_async again
      g_tcp_connection_connect_async (data->connection, data->cancellable, data->callback, data->user_data);
    }

  g_free (data);
}

void
g_tcp_connection_connect_async (GTCPConnection          *connection,
                            GCancellable        *cancellable,
                            GAsyncReadyCallback  callback,
                            gpointer             user_data)
{
  GInetAddress *address;
  GSimpleAsyncResult *result;
  GSource *source;
  ConnectData *data;
  GError *error = NULL;

  g_return_if_fail (G_IS_TCP_CONNECTION (connection));

  if (!connection->priv->address)
    {
      // we've been constructed with just hostname+port, resolve
      GResolver *resolver = g_resolver_new ();

      data = g_new (ConnectData, 1);

      data->connection = connection;
      data->callback = callback;
      data->cancellable = cancellable;
      data->user_data = user_data;

      g_resolver_resolve_async (resolver, connection->priv->hostname, cancellable, resolve_callback, data);

      return;
    }

  address = g_inet_socket_address_get_address (connection->priv->address);

  if (G_IS_INET4_ADDRESS (address))
    connection->priv->tcp = g_tcp_new (G_TCP_DOMAIN_INET, G_TCP_TYPE_STREAM, NULL, &error);
  else if (G_IS_INET6_ADDRESS (address))
    connection->priv->tcp = g_tcp_new (G_TCP_DOMAIN_INET6, G_TCP_TYPE_STREAM, NULL, &error);
  else
    {
      g_simple_async_report_error_in_idle (G_OBJECT (connection), callback, user_data, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED, "unsupported address domain");
      return;
    }

  if (!connection->priv->tcp)
    {
      g_simple_async_report_gerror_in_idle (G_OBJECT (connection), callback, user_data, error);
      return;
    }

  g_tcp_set_blocking (connection->priv->tcp, FALSE);

  if (!g_tcp_connect (connection->priv->tcp, G_TCP_ADDRESS (connection->priv->address), &error))
    {
      if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_PENDING))
        {
          // the connection is in progress
          source = g_tcp_create_source (connection->priv->tcp, G_IO_OUT | G_IO_ERR | G_IO_HUP, cancellable);

          data = g_new (ConnectData, 1);

          data->connection = connection;
          data->callback = callback;
          data->cancellable = cancellable;
          data->user_data = user_data;

          g_source_set_callback (source, (GSourceFunc) connect_callback, data, g_free);

          g_source_attach (source, NULL);
        }
      else
        {
          g_simple_async_report_gerror_in_idle (G_OBJECT (connection), callback, user_data, error);
        }
    }
  else
    {
      // the connection is already completed
      result = g_simple_async_result_new (G_OBJECT (connection), callback, user_data, g_tcp_connection_connect_async);

      g_simple_async_result_complete_in_idle (result);

      g_object_unref (result);
    }
}

gboolean
g_tcp_connection_connect_finish (GTCPConnection    *connection,
                             GAsyncResult  *result,
                             GError       **error)
{
  GSimpleAsyncResult *simple;

  g_return_val_if_fail (G_IS_TCP_CONNECTION (connection), FALSE);

  simple = G_SIMPLE_ASYNC_RESULT (result);

  if (g_simple_async_result_propagate_error (simple, error))
    return FALSE;

  g_warn_if_fail (g_simple_async_result_get_source_tag (simple) == g_tcp_connection_connect_async);

  return TRUE;
}
*/
