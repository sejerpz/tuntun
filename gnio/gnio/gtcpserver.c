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

#include "gtcpserver.h"
#include "gtcpconnection.h"

G_DEFINE_TYPE (GTCPServer, g_tcp_server, G_TYPE_SOCKET_SERVER);

enum
{
  PROP_0
};

struct _GTCPServerPrivate
{

};

static void
g_tcp_server_get_property (GObject *object, guint prop_id, GValue *value, GParamSpec *pspec)
{
  GTCPServer *server G_GNUC_UNUSED = G_TCP_SERVER (object);

  switch (prop_id)
    {
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_tcp_server_set_property (GObject *object, guint prop_id, const GValue *value, GParamSpec *pspec)
{
  GTCPServer *server G_GNUC_UNUSED = G_TCP_SERVER (object);

  switch (prop_id)
    {
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_tcp_server_finalize (GObject *object)
{
  GTCPServer *server G_GNUC_UNUSED = G_TCP_SERVER (object);

  if (G_OBJECT_CLASS (g_tcp_server_parent_class)->finalize)
    (*G_OBJECT_CLASS (g_tcp_server_parent_class)->finalize) (object);
}

static void
g_tcp_server_dispose (GObject *object)
{
  GTCPServer *server G_GNUC_UNUSED = G_TCP_SERVER (object);

  if (G_OBJECT_CLASS (g_tcp_server_parent_class)->dispose)
    (*G_OBJECT_CLASS (g_tcp_server_parent_class)->dispose) (object);
}

static void
g_tcp_server_class_init (GTCPServerClass *klass)
{
  GObjectClass *gobject_class G_GNUC_UNUSED = G_OBJECT_CLASS (klass);

//  g_type_class_add_private (klass, sizeof (GTCPServerPrivate));

  gobject_class->finalize = g_tcp_server_finalize;
  gobject_class->dispose = g_tcp_server_dispose;
  gobject_class->set_property = g_tcp_server_set_property;
  gobject_class->get_property = g_tcp_server_get_property;
}

static void
g_tcp_server_init (GTCPServer *server)
{
//  server->priv = G_TYPE_INSTANCE_GET_PRIVATE (server, G_TYPE_TCP_SERVER, GTCPServerPrivate);
}

GTCPServer *
g_tcp_server_new (GInetSocketAddress  *address,
                  GError             **error)
{
  return NULL;
}

GTCPConnection *
g_tcp_server_accept (GTCPServer  *server,
                     GCancellable   *cancellable,
                     GError        **error)
{
  return NULL;
}

void
g_tcp_server_close (GTCPServer *server)
{
  g_return_if_fail (G_IS_TCP_SERVER (server));
}
