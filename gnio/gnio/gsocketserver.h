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

#ifndef G_SOCKET_SERVER_H
#define G_SOCKET_SERVER_H

#include <glib-object.h>
#include <gio/gio.h>

G_BEGIN_DECLS

#define G_TYPE_SOCKET_SERVER         (g_socket_server_get_type ())
#define G_SOCKET_SERVER(o)           (G_TYPE_CHECK_INSTANCE_CAST ((o), G_TYPE_SOCKET_SERVER, GSocketServer))
#define G_SOCKET_SERVER_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), G_TYPE_SOCKET_SERVER, GSocketServerClass))
#define G_IS_SOCKET_SERVER(o)        (G_TYPE_CHECK_INSTANCE_TYPE ((o), G_TYPE_SOCKET_SERVER))
#define G_IS_SOCKET_SERVER_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE ((k), G_TYPE_SOCKET_SERVER))
#define G_SOCKET_SERVER_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o), G_TYPE_SOCKET_SERVER, GSocketServer))

typedef struct _GSocketServer          GSocketServer;
typedef struct _GSocketServerClass     GSocketServerClass;
typedef struct _GSocketServerPrivate   GSocketServerPrivate;

#include <gnio/gsocketconnection.h>

struct _GSocketServer
{
  GObject parent;

  GSocketServerPrivate *priv;
};

struct _GSocketServerClass
{
  GObjectClass parent_class;
};

GType               g_socket_server_get_type      (void) G_GNUC_CONST;

GSocketServer *     g_socket_server_new           (GSocketAddress  *address,
                                                   GError         **error);

GSocketConnection * g_socket_server_accept        (GSocketServer  *server,
                                                   GCancellable   *cancellable,
                                                   GError        **error);

void                g_socket_server_accept_async  (GSocketServer       *server,
                                                   GCancellable        *cancellable,
                                                   GAsyncReadyCallback  callback,
                                                   gpointer             user_data);

GSocketConnection * g_socket_server_accept_finish (GSocketServer  *server,
                                                   GAsyncResult   *result,
                                                   GError        **error);

void                g_socket_server_close         (GSocketServer *server);

G_END_DECLS

#endif /* G_SOCKET_SERVER_H */

