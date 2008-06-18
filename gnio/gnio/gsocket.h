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

#ifndef G_SOCKET_H
#define G_SOCKET_H

#include <glib-object.h>
#include <gio/gio.h>

#include <gnio/gsocketaddress.h>

G_BEGIN_DECLS

#define G_TYPE_SOCKET         (g_socket_get_type ())
#define G_SOCKET(o)           (G_TYPE_CHECK_INSTANCE_CAST ((o), G_TYPE_SOCKET, GSocket))
#define G_SOCKET_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), G_TYPE_SOCKET, GSocketClass))
#define G_IS_SOCKET(o)        (G_TYPE_CHECK_INSTANCE_TYPE ((o), G_TYPE_SOCKET))
#define G_IS_SOCKET_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE ((k), G_TYPE_SOCKET))
#define G_SOCKET_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o), G_TYPE_SOCKET, GSocket))

typedef struct _GSocket          GSocket;
typedef struct _GSocketClass     GSocketClass;
typedef struct _GSocketPrivate   GSocketPrivate;

struct _GSocket
{
  GObject parent;

  GSocketPrivate *priv;
};

struct _GSocketClass
{
  GObjectClass parent_class;
};

typedef enum
{
  G_SOCKET_DOMAIN_INET,
  G_SOCKET_DOMAIN_INET6,
  G_SOCKET_DOMAIN_LOCAL,
} GSocketDomain;

typedef enum
{
  G_SOCKET_TYPE_STREAM,
  G_SOCKET_TYPE_DATAGRAM,
  G_SOCKET_TYPE_SEQPACKET,
} GSocketType;

GType            g_socket_get_type           (void) G_GNUC_CONST;

GSocket *        g_socket_new                (GSocketDomain   domain,
                                              GSocketType     type,
                                              const gchar    *protocol);

GSocket *        g_socket_new_from_fd        (gint fd);

GSocketAddress * g_socket_get_local_address  (GSocket  *socket,
                                              GError  **error);

GSocketAddress * g_socket_get_remote_address (GSocket  *socket,
                                              GError  **error);

void             g_socket_set_blocking       (GSocket  *socket,
                                              gboolean  blocking);

gboolean         g_socket_get_blocking       (GSocket  *socket);

void             g_socket_set_reuse_address  (GSocket  *socket,
                                              gboolean  reuse);

gboolean         g_socket_get_reuse_address  (GSocket  *socket);

gboolean         g_socket_has_error          (GSocket  *socket,
                                              GError  **error);

gboolean         g_socket_bind               (GSocket         *socket,
                                              GSocketAddress  *address,
                                              GError         **error);

gboolean         g_socket_connect            (GSocket         *socket,
                                              GSocketAddress  *address,
                                              GError         **error);

GSocket *        g_socket_accept             (GSocket  *socket,
                                              GError  **error);

gboolean         g_socket_listen             (GSocket  *socket,
                                              GError  **error);

gssize           g_socket_receive            (GSocket  *socket,
                                              gchar    *buffer,
                                              gsize     size,
                                              GError  **error);

gssize           g_socket_send               (GSocket      *socket,
                                              const gchar  *buffer,
                                              gsize         size,
                                              GError      **error);

void             g_socket_close              (GSocket *socket);

GSource *        g_socket_create_source      (GSocket      *socket,
                                              GIOCondition  condition,
                                              GCancellable *cancellable);

G_END_DECLS

#endif /* G_SOCKET_H */

