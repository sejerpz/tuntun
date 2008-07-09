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

#ifndef G_SOCKET_CONNECTION_H
#define G_SOCKET_CONNECTION_H

#include <glib-object.h>
#include <gio/gio.h>

#include <gnio/gsocketaddress.h>
#include <gnio/gsocketinputstream.h>
#include <gnio/gsocketoutputstream.h>

G_BEGIN_DECLS

#define G_TYPE_SOCKET_CONNECTION         (g_socket_connection_get_type ())
#define G_SOCKET_CONNECTION(o)           (G_TYPE_CHECK_INSTANCE_CAST ((o), G_TYPE_SOCKET_CONNECTION, GSocketConnection))
#define G_SOCKET_CONNECTION_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), G_TYPE_SOCKET_CONNECTION, GSocketConnectionClass))
#define G_IS_SOCKET_CONNECTION(o)        (G_TYPE_CHECK_INSTANCE_TYPE ((o), G_TYPE_SOCKET_CONNECTION))
#define G_IS_SOCKET_CONNECTION_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE ((k), G_TYPE_SOCKET_CONNECTION))
#define G_SOCKET_CONNECTION_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o), G_TYPE_SOCKET_CONNECTION, GSocketConnection))

typedef struct _GSocketConnection          GSocketConnection;
typedef struct _GSocketConnectionClass     GSocketConnectionClass;
typedef struct _GSocketConnectionPrivate   GSocketConnectionPrivate;

struct _GSocketConnection
{
  GObject parent;

  GSocketConnectionPrivate *priv;
};

struct _GSocketConnectionClass
{
  GObjectClass parent_class;

  GSocketInputStream *  (*get_input_stream)  (GSocketConnection *connection);

  GSocketOutputStream * (*get_output_stream) (GSocketConnection *connection);

  gboolean              (*connect_fn)        (GSocketConnection  *connection,
                                              GCancellable       *cancellable,
                                              GError            **error);

  void                  (*connect_async)     (GSocketConnection   *connection,
                                              GCancellable        *cancellable,
                                              GAsyncReadyCallback  callback,
                                              gpointer             user_data);

  gboolean              (*connect_finish)    (GSocketConnection  *connection,
                                              GAsyncResult       *result,
                                              GError            **error);

};

GType                 g_socket_connection_get_type          (void) G_GNUC_CONST;

GSocketConnection *   g_socket_connection_new               (GSocketAddress *address);

GSocketConnection *   g_socket_connection_new_from_socket   (GSocket *socket);

GSocketInputStream *  g_socket_connection_get_input_stream  (GSocketConnection *connection);

GSocketOutputStream * g_socket_connection_get_output_stream (GSocketConnection *connection);

GSocketAddress *      g_socket_connection_get_address       (GSocketConnection *connection);

gboolean              g_socket_connection_is_connected      (GSocketConnection *connection);

gboolean              g_socket_connection_connect           (GSocketConnection  *connection,
                                                             GCancellable       *cancellable,
                                                             GError            **error);

void                  g_socket_connection_connect_async     (GSocketConnection   *connection,
                                                             GCancellable        *cancellable,
                                                             GAsyncReadyCallback  callback,
                                                             gpointer             user_data);

gboolean              g_socket_connection_connect_finish    (GSocketConnection  *connection,
                                                             GAsyncResult       *result,
                                                             GError            **error);

void                  g_socket_connection_close             (GSocketConnection *connection);

G_END_DECLS

#endif /* G_SOCKET_CONNECTION_H */
