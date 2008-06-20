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

#ifndef G_TCP_SERVER_H
#define G_TCP_SERVER_H

#include <glib-object.h>
#include <gio/gio.h>

#include <gnio/gsocketserver.h>
#include <gnio/gtcpconnection.h>

G_BEGIN_DECLS

#define G_TYPE_TCP_SERVER         (g_tcp_server_get_type ())
#define G_TCP_SERVER(o)           (G_TYPE_CHECK_INSTANCE_CAST ((o), G_TYPE_TCP_SERVER, GTCPServer))
#define G_TCP_SERVER_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), G_TYPE_TCP_SERVER, GTCPServerClass))
#define G_IS_TCP_SERVER(o)        (G_TYPE_CHECK_INSTANCE_TYPE ((o), G_TYPE_TCP_SERVER))
#define G_IS_TCP_SERVER_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE ((k), G_TYPE_TCP_SERVER))
#define G_TCP_SERVER_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o), G_TYPE_TCP_SERVER, GTCPServer))

typedef struct _GTCPServer          GTCPServer;
typedef struct _GTCPServerClass     GTCPServerClass;
typedef struct _GTCPServerPrivate   GTCPServerPrivate;

#include <gnio/gsocketserver.h>

struct _GTCPServer
{
  GSocketServer parent;

  GTCPServerPrivate *priv;
};

struct _GTCPServerClass
{
  GSocketServerClass parent_class;
};

GType               g_tcp_server_get_type      (void) G_GNUC_CONST;

GTCPServer *        g_tcp_server_new           (GInetSocketAddress  *address,
                                                GError             **error);

GTCPConnection *    g_tcp_server_accept        (GTCPServer    *server,
                                                GCancellable  *cancellable,
                                                GError       **error);

void                g_tcp_server_accept_async  (GTCPServer          *server,
                                                GCancellable        *cancellable,
                                                GAsyncReadyCallback  callback,
                                                gpointer             user_data);

GTCPConnection *    g_tcp_server_accept_finish (GTCPServer    *server,
                                                GAsyncResult  *result,
                                                GError       **error);

void                g_tcp_server_close         (GTCPServer *server);

G_END_DECLS

#endif /* G_TCP_SERVER_H */

