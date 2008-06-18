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

#include <string.h>
#include <errno.h>

#include "gsocketserver.h"

G_DEFINE_TYPE (GSocketServer, g_socket_server, G_TYPE_OBJECT);

enum
{
  PROP_0,
  PROP_ADDRESS,
};

struct _GSocketServerPrivate
{
  GSocketAddress  *address;
  GSocket         *socket;
  GError          *error;
  GStaticMutex     mutex;
};

static void
g_socket_server_get_property (GObject *object, guint prop_id, GValue *value, GParamSpec *pspec)
{
  GSocketServer *server = G_SOCKET_SERVER (object);

  switch (prop_id)
    {
      case PROP_ADDRESS:
        g_value_set_object (value, server->priv->address);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_socket_server_set_property (GObject *object, guint prop_id, const GValue *value, GParamSpec *pspec)
{
  GSocketServer *server = G_SOCKET_SERVER (object);

  switch (prop_id)
    {
      case PROP_ADDRESS:
        server->priv->address = G_SOCKET_ADDRESS (g_object_ref_sink (g_value_get_object (value)));
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_socket_server_finalize (GObject *object)
{
  GSocketServer *server = G_SOCKET_SERVER (object);

  g_object_unref (G_OBJECT (server->priv->address));

  if (G_OBJECT_CLASS (g_socket_server_parent_class)->finalize)
    (*G_OBJECT_CLASS (g_socket_server_parent_class)->finalize) (object);
}

static void
g_socket_server_dispose (GObject *object)
{
  GSocketServer *server G_GNUC_UNUSED = G_SOCKET_SERVER (object);

  if (G_OBJECT_CLASS (g_socket_server_parent_class)->dispose)
    (*G_OBJECT_CLASS (g_socket_server_parent_class)->dispose) (object);
}

static void
g_socket_server_class_init (GSocketServerClass *klass)
{
  GObjectClass *gobject_class G_GNUC_UNUSED = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (GSocketServerPrivate));

  gobject_class->finalize = g_socket_server_finalize;
  gobject_class->dispose = g_socket_server_dispose;
  gobject_class->set_property = g_socket_server_set_property;
  gobject_class->get_property = g_socket_server_get_property;

  g_object_class_install_property (gobject_class, PROP_ADDRESS,
                                   g_param_spec_object ("address",
                                                        "address",
                                                        "the local address the server will listen on",
                                                        G_TYPE_SOCKET_ADDRESS,
                                                        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));
}

static void
g_socket_server_init (GSocketServer *server)
{
  server->priv = G_TYPE_INSTANCE_GET_PRIVATE (server, G_TYPE_SOCKET_SERVER, GSocketServerPrivate);

  server->priv->address = NULL;
  server->priv->socket = NULL;
  server->priv->error = NULL;
  g_static_mutex_init (&(server->priv->mutex));
}

GSocketServer *
g_socket_server_new (GSocketAddress  *address,
                     GError         **error)
{
  return g_object_new (G_TYPE_SOCKET_SERVER, "address", address, NULL);
}

static void
g_socket_server_initialize_socket (GSocketServer *server)
{
  g_static_mutex_lock (&(server->priv->mutex));

  if (server->priv->socket)
    {
      g_static_mutex_unlock (&(server->priv->mutex));
      return;
    }

  /* TODO: get the domain from the address */
  server->priv->socket = g_socket_new (G_SOCKET_DOMAIN_INET, G_SOCKET_TYPE_STREAM, NULL);

  if (!server->priv->socket)
    {
      g_static_mutex_unlock (&(server->priv->mutex));
      return;
    }

  if (g_socket_has_error (server->priv->socket, &(server->priv->error)))
    {
      g_static_mutex_unlock (&(server->priv->mutex));
      return;
    }

  if (!g_socket_bind (server->priv->socket, server->priv->address, &(server->priv->error)))
    {
      g_static_mutex_unlock (&(server->priv->mutex));
      return;
    }

  if (!g_socket_listen (server->priv->socket, &(server->priv->error)))
    {
      g_static_mutex_unlock (&(server->priv->mutex));
      return;
    }

  g_static_mutex_unlock (&(server->priv->mutex));
}

GSocketConnection *
g_socket_server_accept (GSocketServer  *server,
                        GCancellable   *cancellable,
                        GError        **error)
{
  GSocket *socket;

  g_return_val_if_fail (G_IS_SOCKET_SERVER (server), NULL);

  g_socket_server_initialize_socket (server);

  if (server->priv->error)
    {
      g_propagate_error (error, server->priv->error);
      return NULL;
    }

  if (!(socket = g_socket_accept (server->priv->socket, error)))
    return NULL;

  return g_socket_connection_new_from_socket (socket);
}

typedef struct {
  GAsyncReadyCallback  callback;
  GCancellable        *cancellable;
  gpointer             user_data;
  GSocketServer       *server;
} AcceptData;

static gboolean
accept_callback (AcceptData   *data,
                 GIOCondition  condition,
                 gint          fd)
{
  GSocketServer *server;
  GSimpleAsyncResult *result;
  GError *error = NULL;
  GSocketConnection *connection;
  GSocket *socket;

  server = data->server;

  if (condition & G_IO_IN)
    {
      if (!(socket = g_socket_accept (server->priv->socket, &error)))
        {
          result = g_simple_async_result_new_from_error (G_OBJECT (connection), data->callback, data->user_data, error);
        }
      else
        {
          result = g_simple_async_result_new (G_OBJECT (server), data->callback, data->user_data, g_socket_server_accept_async);

          connection = g_socket_connection_new_from_socket (socket);

          g_simple_async_result_set_op_res_gpointer (result, connection, NULL);
        }
    }
  else
    {
      if (!g_socket_has_error (server->priv->socket, &error))
        g_warning ("got G_IO_ERR but socket does not have error");

      result = g_simple_async_result_new_from_error (G_OBJECT (connection), data->callback, data->user_data, error);
    }

  g_simple_async_result_complete (result);

  g_object_unref (result);

  return FALSE;
}

void
g_socket_server_accept_async (GSocketServer       *server,
                              GCancellable        *cancellable,
                              GAsyncReadyCallback  callback,
                              gpointer             user_data)
{
  GSource *source;
  GSocket *socket;
  GError *error = NULL;
  AcceptData *data;

  g_socket_server_initialize_socket (server);

  if (server->priv->error) {
    g_simple_async_report_gerror_in_idle (G_OBJECT (server), callback, user_data, server->priv->error);
    return;
  }

  g_socket_set_blocking (server->priv->socket, FALSE);

  if (!(socket = g_socket_accept (server->priv->socket, &error)))
    {
      if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_WOULD_BLOCK))
        {
          source = g_socket_create_source (server->priv->socket, G_IO_IN | G_IO_ERR | G_IO_HUP, cancellable);

          data = g_new (AcceptData, 1);

          data->server = server;
          data->callback = callback;
          data->cancellable = cancellable;
          data->user_data = user_data;

          g_source_set_callback (source, (GSourceFunc) accept_callback, data, g_free);

          g_source_attach (source, NULL);

          g_error_free (error);
        }
      else
        {
          g_simple_async_report_gerror_in_idle (G_OBJECT (server), callback, user_data, error);
        }
    }
  else
    {
      GSocketConnection *connection;
      GSimpleAsyncResult *result;

      connection = g_socket_connection_new_from_socket (socket);

      result = g_simple_async_result_new (G_OBJECT (server), callback, user_data, g_socket_server_accept_async);

      g_simple_async_result_set_op_res_gpointer (result, connection, NULL);

      g_simple_async_result_complete_in_idle (result);

      g_object_unref (result);
    }
}

GSocketConnection *
g_socket_server_accept_finish (GSocketServer  *server,
                               GAsyncResult   *result,
                               GError        **error)
{
  GSocketConnection *connection;
  GSimpleAsyncResult *simple;

  g_return_val_if_fail (G_IS_SOCKET_SERVER (server), FALSE);

  simple = G_SIMPLE_ASYNC_RESULT (result);

  if (g_simple_async_result_propagate_error (simple, error))
    return NULL;

  g_warn_if_fail (g_simple_async_result_get_source_tag (simple) == g_socket_server_accept_async);

  connection = g_simple_async_result_get_op_res_gpointer (simple);

  return connection;
}

void
g_socket_server_close (GSocketServer *server)
{
  g_return_if_fail (G_IS_SOCKET_SERVER (server));
}
