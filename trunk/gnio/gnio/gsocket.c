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
#include "gasynchelper.h"
#include "gnioenums.h"

#include <string.h>
#ifndef G_OS_WIN32
# include <netinet/in.h>
# include <arpa/inet.h>
# include <netdb.h>
# include <fcntl.h>
# include <unistd.h>
# include <sys/types.h>
#else

#endif
#include <errno.h>

#include "ginetaddress.h"
#include "ginet4address.h"
#include "ginet6address.h"
#include "gsocket.h"
#include "gnioerror.h"
#include "ginetsocketaddress.h"

G_DEFINE_TYPE (GSocket, g_socket, G_TYPE_OBJECT);

enum
{
  PROP_0,
  PROP_DOMAIN,
  PROP_TYPE,
  PROP_PROTOCOL,
  PROP_FD,
  PROP_BLOCKING,
  PROP_BACKLOG,
  PROP_REUSE_ADDRESS,
  PROP_LOCAL_ADDRESS,
  PROP_REMOTE_ADDRESS
};

struct _GSocketPrivate
{
  GSocketDomain   domain;
  GSocketType     type;
  gchar          *protocol;
  gint            fd;
  gboolean        blocking;
  gint            backlog;
  gboolean        reuse_address;
  GError         *error;
  GSocketAddress *local_address;
  GSocketAddress *remote_address;
};

static void
g_socket_constructed (GObject *object)
{
  GSocket *sock = G_SOCKET (object);
  GError *error = NULL;
  static GStaticMutex getprotobyname_mutex = G_STATIC_MUTEX_INIT;
  gint fd, native_domain, native_type, native_protocol;

  if (sock->priv->fd >= 0)
    {
      // we've been constructed from an existing file descriptor
      glong arg;
      gboolean blocking;

      // TODO: set the socket type with getsockopt (SO_TYPE)
      // TODO: what should we do about domain and protocol?

      if ((arg = fcntl (sock->priv->fd, F_GETFL, NULL)) < 0)
        g_warning ("Error getting socket status flags: %s", g_strerror (errno));

      blocking = ((arg & O_NONBLOCK) == 0);

      return;
    }

  switch (sock->priv->domain)
    {
      case G_SOCKET_DOMAIN_INET:
        native_domain = PF_INET;
        break;

      case G_SOCKET_DOMAIN_INET6:
        native_domain = PF_INET6;
        break;

      case G_SOCKET_DOMAIN_LOCAL:
        native_domain = PF_LOCAL;
        break;

      default:
        g_set_error (&error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED, "unsupported socket domain");
        return;
    }

  switch (sock->priv->type)
    {
      case G_SOCKET_TYPE_STREAM:
        native_type = SOCK_STREAM;
        break;

      case G_SOCKET_TYPE_DATAGRAM:
        native_type = SOCK_DGRAM;
        break;

      case G_SOCKET_TYPE_SEQPACKET:
        native_type = SOCK_SEQPACKET;
        break;

      default:
        g_set_error (&error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED, "unsupported socket type");
        return;
    }

  if (sock->priv->protocol == NULL)
    native_protocol = 0;
  else
    {
      struct protoent *ent;
      g_static_mutex_lock (&getprotobyname_mutex);
      if (!(ent = getprotobyname (sock->priv->protocol)))
        {
          g_static_mutex_unlock (&getprotobyname_mutex);
          g_set_error (&error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED, "unsupported socket protocol");
          return;
        }
      native_protocol = ent->p_proto;
      g_static_mutex_unlock (&getprotobyname_mutex);
    }

  fd = socket (native_domain, native_type, native_protocol);

  if (fd < 0)
    {
      g_set_error (&error, G_IO_ERROR, g_io_error_from_errno (errno), "unable to create socket: %s", g_strerror (errno));
      return;
    }

  sock->priv->fd = fd;
}

static void
g_socket_get_property (GObject    *object,
                       guint       prop_id,
                       GValue     *value,
                       GParamSpec *pspec)
{
  GSocket *socket = G_SOCKET (object);

  switch (prop_id)
    {
      case PROP_DOMAIN:
        g_value_set_enum (value, socket->priv->domain);
        break;

      case PROP_TYPE:
        g_value_set_enum (value, socket->priv->type);
        break;

      case PROP_PROTOCOL:
        g_value_set_string (value, socket->priv->protocol);
        break;

      case PROP_FD:
        g_value_set_int (value, socket->priv->fd);
        break;

      case PROP_BLOCKING:
        g_value_set_boolean (value, socket->priv->blocking);
        break;

      case PROP_BACKLOG:
        g_value_set_int (value, socket->priv->backlog);
        break;

      case PROP_REUSE_ADDRESS:
        g_value_set_boolean (value, socket->priv->reuse_address);
        break;

      case PROP_LOCAL_ADDRESS:
        g_value_set_object (value, socket->priv->local_address);
        break;

      case PROP_REMOTE_ADDRESS:
        g_value_set_object (value, socket->priv->remote_address);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_socket_set_property (GObject      *object,
                       guint         prop_id,
                       const GValue *value,
                       GParamSpec   *pspec)
{
  GSocket *socket = G_SOCKET (object);

  switch (prop_id)
    {
      case PROP_DOMAIN:
        socket->priv->domain = g_value_get_enum (value);
        break;

      case PROP_TYPE:
        socket->priv->type = g_value_get_enum (value);
        break;

      case PROP_PROTOCOL:
        socket->priv->protocol = g_value_dup_string (value);
        break;

      case PROP_FD:
        socket->priv->fd = g_value_get_int (value);
        break;

      case PROP_BLOCKING:
        g_socket_set_blocking (socket, g_value_get_boolean (value));
        break;

      case PROP_BACKLOG:
        socket->priv->backlog = g_value_get_int (value);
        break;

      case PROP_REUSE_ADDRESS:
        g_socket_set_reuse_address (socket, g_value_get_boolean (value));
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_socket_finalize (GObject *object)
{
  GSocket *socket = G_SOCKET (object);

  if (socket->priv->local_address)
    g_object_unref (socket->priv->local_address);

  if (socket->priv->remote_address)
    g_object_unref (socket->priv->remote_address);

  if (G_OBJECT_CLASS (g_socket_parent_class)->finalize)
    (*G_OBJECT_CLASS (g_socket_parent_class)->finalize) (object);
}

static void
g_socket_dispose (GObject *object)
{
  GSocket *socket = G_SOCKET (object);

  g_free (socket->priv->protocol);

  g_clear_error (&socket->priv->error);

  g_socket_close (socket);

  if (G_OBJECT_CLASS (g_socket_parent_class)->dispose)
    (*G_OBJECT_CLASS (g_socket_parent_class)->dispose) (object);
}

static void
g_socket_class_init (GSocketClass *klass)
{
  GObjectClass *gobject_class G_GNUC_UNUSED = G_OBJECT_CLASS (klass);

  // TODO: WSAStartup

  g_type_class_add_private (klass, sizeof (GSocketPrivate));

  gobject_class->finalize = g_socket_finalize;
  gobject_class->dispose = g_socket_dispose;
  gobject_class->constructed = g_socket_constructed;
  gobject_class->set_property = g_socket_set_property;
  gobject_class->get_property = g_socket_get_property;

  g_object_class_install_property (gobject_class, PROP_DOMAIN,
                                   g_param_spec_enum ("domain",
                                                      "socket domain",
                                                      "the socket's domain",
                                                      G_TYPE_SOCKET_DOMAIN,
                                                      G_SOCKET_DOMAIN_INET,
                                                      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_TYPE,
                                   g_param_spec_enum ("type",
                                                      "socket type",
                                                      "the socket's type",
                                                      G_TYPE_SOCKET_TYPE,
                                                      G_SOCKET_TYPE_STREAM,
                                                      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_PROTOCOL,
                                   g_param_spec_string ("protocol",
                                                        "socket protocol",
                                                        "the socket's protocol",
                                                        NULL,
                                                        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_FD,
                                   g_param_spec_int ("fd",
                                                     "file descriptor",
                                                     "the socket's file descriptor",
                                                     G_MININT,
                                                     G_MAXINT,
                                                     -1,
                                                     G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_BLOCKING,
                                   g_param_spec_boolean ("blocking",
                                                         "blocking",
                                                         "whether or not this socket is blocking",
                                                         TRUE,
                                                         G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_BACKLOG,
                                   g_param_spec_int ("backlog",
                                                     "listen backlog",
                                                     "outstanding connections in the listen queue",
                                                     0,
                                                     SOMAXCONN,
                                                     10,
                                                     G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_REUSE_ADDRESS,
                                   g_param_spec_boolean ("reuse-address",
                                                         "reuse address",
                                                         "allow reuse of local addresses when binding",
                                                         FALSE,
                                                         G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_LOCAL_ADDRESS,
                                   g_param_spec_object ("local-address",
                                                        "local address",
                                                        "the local address the socket is bound to",
                                                        G_TYPE_SOCKET_ADDRESS,
                                                        G_PARAM_READABLE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));

  g_object_class_install_property (gobject_class, PROP_REMOTE_ADDRESS,
                                   g_param_spec_object ("remote-address",
                                                        "remote address",
                                                        "the remote address the socket is connected to",
                                                        G_TYPE_SOCKET_ADDRESS,
                                                        G_PARAM_READABLE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));
}

static void
g_socket_init (GSocket *socket)
{
  socket->priv = G_TYPE_INSTANCE_GET_PRIVATE (socket, G_TYPE_SOCKET, GSocketPrivate);

  socket->priv->fd = -1;
  socket->priv->blocking = TRUE;
  socket->priv->backlog = 10;
  socket->priv->reuse_address = FALSE;
  socket->priv->error = NULL;
  socket->priv->remote_address = NULL;
  socket->priv->local_address = NULL;
}

GSocket *
g_socket_new (GSocketDomain domain, GSocketType type, const gchar *protocol)
{
  return G_SOCKET (g_object_new (G_TYPE_SOCKET, "domain", domain, "type", type, "protocol", protocol, NULL));
}

GSocket *
g_socket_new_from_fd (gint fd)
{
  return G_SOCKET (g_object_new (G_TYPE_SOCKET, "fd", fd, NULL));
}

void
g_socket_set_blocking (GSocket  *socket,
                       gboolean  blocking)
{
  glong arg;

  g_return_if_fail (G_IS_SOCKET (socket));

  if ((arg = fcntl (socket->priv->fd, F_GETFL, NULL)) < 0)
    g_warning ("Error getting socket status flags: %s", g_strerror (errno));

  arg = blocking ? arg & ~O_NONBLOCK : arg | O_NONBLOCK;

  if (fcntl (socket->priv->fd, F_SETFL, arg) < 0)
    g_warning ("Error setting socket status flags: %s", g_strerror (errno));

  socket->priv->blocking = blocking;
}

gboolean
g_socket_get_blocking (GSocket *socket)
{
  g_return_val_if_fail (G_IS_SOCKET (socket), FALSE);

  return socket->priv->blocking;
}

void
g_socket_set_reuse_address (GSocket  *socket,
                            gboolean  reuse)
{
  gint value = (gint) reuse;

  g_return_if_fail (G_IS_SOCKET (socket));

  if (setsockopt (socket->priv->fd, SOL_SOCKET, SO_REUSEADDR, (gpointer) &value, sizeof (value)) < 0)
    g_warning ("error setting reuse address: %s", g_strerror (errno));

  socket->priv->reuse_address = reuse;
}

gboolean
g_socket_get_reuse_address (GSocket *socket)
{
  g_return_val_if_fail (G_IS_SOCKET (socket), FALSE);

  return socket->priv->reuse_address;
}

GSocketAddress *
g_socket_get_local_address (GSocket  *socket,
                            GError  **error)
{
  gchar buffer[256];
  gsize len = 256;

  g_return_val_if_fail (G_IS_SOCKET (socket), NULL);

  if (socket->priv->local_address)
    return socket->priv->local_address;

  if (getsockname (socket->priv->fd, (struct sockaddr *) buffer, &len) < 0)
    {
      g_set_error (error, G_IO_ERROR, g_io_error_from_errno (errno), "could not get local address: %s", g_strerror (errno));
      return NULL;
    }

  return (socket->priv->local_address = g_object_ref_sink (g_socket_address_from_native (buffer, len)));
}

GSocketAddress *
g_socket_get_remote_address (GSocket  *socket,
                             GError  **error)
{
  gchar buffer[256];
  gsize len = 256;

  g_return_val_if_fail (G_IS_SOCKET (socket), NULL);

  if (socket->priv->remote_address)
    return socket->priv->remote_address;

  if (getpeername (socket->priv->fd, (struct sockaddr *) buffer, &len) < 0)
    {
      g_set_error (error, G_IO_ERROR, g_io_error_from_errno (errno), "could not get remote address: %s", g_strerror (errno));
      return NULL;
    }

  return (socket->priv->remote_address = g_object_ref_sink (g_socket_address_from_native (buffer, len)));
}

gboolean
g_socket_has_error (GSocket  *socket,
                    GError  **error)
{
  g_return_val_if_fail (G_IS_SOCKET (socket), FALSE);

  if (!socket->priv->error)
    return FALSE;

  g_propagate_error (error, socket->priv->error);

  return TRUE;
}

gboolean
g_socket_is_connected (GSocket *socket)
{
  g_return_val_if_fail (G_IS_SOCKET (socket), FALSE);

  return socket->priv->remote_address != NULL;
}

gboolean
g_socket_listen (GSocket  *socket,
                 GError  **error)
{
  g_return_val_if_fail (G_IS_SOCKET (socket), FALSE);

  if (g_socket_has_error (socket, error))
    return FALSE;

  if (listen (socket->priv->fd, socket->priv->backlog) < 0)
    {
      g_set_error (error, G_IO_ERROR, g_io_error_from_errno (errno), "could not listen: %s", g_strerror (errno));
      return FALSE;
    }

  return TRUE;
}

gboolean
g_socket_bind (GSocket         *socket,
               GSocketAddress  *address,
               GError         **error)
{
  g_return_val_if_fail (G_IS_SOCKET (socket) && G_IS_SOCKET_ADDRESS (address), FALSE);

  if (g_socket_has_error (socket, error))
    return FALSE;

  {
    gchar addr[256];

    if (!g_socket_address_to_native (address, addr))
      return FALSE;

    if (bind (socket->priv->fd, (struct sockaddr *) addr, g_socket_address_native_size (address)) < 0)
      {
        socket->priv->error = g_error_new (G_IO_ERROR, g_io_error_from_errno (errno), "error binding to address: %s", g_strerror (errno));
        g_propagate_error (error, socket->priv->error);
        return FALSE;
      }

    g_object_ref_sink (address);

    socket->priv->local_address = address;

    return TRUE;
  }
}

GSocket *
g_socket_accept (GSocket       *socket,
                 GError       **error)
{
  gint ret;

  g_return_val_if_fail (G_IS_SOCKET (socket), NULL);

  if (g_socket_has_error (socket, error))
    return NULL;

  if ((ret = accept (socket->priv->fd, NULL, 0)) < 0)
    {
      if (errno == EAGAIN)
        g_set_error (error, G_IO_ERROR, G_IO_ERROR_WOULD_BLOCK, "operation would block");
      else
        {
          socket->priv->error = g_error_new (G_IO_ERROR, g_io_error_from_errno (errno), "error accepting connection: %s", g_strerror (errno));
          g_propagate_error (error, socket->priv->error);
        }
      return FALSE;
    }

  return g_socket_new_from_fd (ret);
}

gboolean
g_socket_connect (GSocket         *socket,
                  GSocketAddress  *address,
                  GError         **error)
{
  gchar buffer[256];

  g_return_val_if_fail (G_IS_SOCKET (socket) && G_IS_SOCKET_ADDRESS (address), FALSE);

  if (g_socket_has_error (socket, error))
    return FALSE;

  g_socket_address_to_native (address, buffer);

  if (connect (socket->priv->fd, (struct sockaddr *) buffer, g_socket_address_native_size (address)) < 0)
    {
      if (errno == EINPROGRESS)
        g_set_error (error, G_IO_ERROR, G_IO_ERROR_PENDING, "connection in progress");
      else
        {
          socket->priv->error = g_error_new (G_IO_ERROR, g_io_error_from_errno (errno), "error connecting: %s", g_strerror (errno));
          g_propagate_error (error, socket->priv->error);
        }

      return FALSE;
    }

  socket->priv->remote_address = g_object_ref_sink (address);

  return TRUE;
}

gssize
g_socket_receive (GSocket       *socket,
                  gchar         *buffer,
                  gsize          size,
                  GError       **error)
{
  gssize ret;

  g_return_val_if_fail (G_IS_SOCKET (socket) && buffer != NULL, FALSE);

  if ((ret = recv (socket->priv->fd, buffer, size, 0)) < 0)
    {
      if (errno == EAGAIN)
        g_set_error (error, G_IO_ERROR, G_IO_ERROR_WOULD_BLOCK, "operation would block");
      else
        {
          socket->priv->error = g_error_new (G_IO_ERROR, g_io_error_from_errno (errno), "error receiving data: %s", g_strerror (errno));
          g_propagate_error (error, socket->priv->error);
        }
      return -1;
    }

  return ret;
}

gssize
g_socket_send (GSocket      *socket,
               const gchar  *buffer,
               gsize         size,
               GError      **error)
{
  gssize ret;

  g_return_val_if_fail (G_IS_SOCKET (socket) && buffer != NULL, FALSE);

  if ((ret = send (socket->priv->fd, buffer, size, 0)) < 0)
    {
      if (errno == EAGAIN)
        g_set_error (error, G_IO_ERROR, G_IO_ERROR_WOULD_BLOCK, "operation would block");
      else
        {
          socket->priv->error = g_error_new (G_IO_ERROR, g_io_error_from_errno (errno), "error sending data: %s", g_strerror (errno));
          g_propagate_error (error, socket->priv->error);
        }
      return -1;
    }

  return ret;
}

void
g_socket_close (GSocket *socket)
{
  g_return_if_fail (G_IS_SOCKET (socket));

#ifdef G_OS_WIN32
  closesocket (socket->priv->fd);
#else
  close (socket->priv->fd);
#endif
}

GSource *
g_socket_create_source (GSocket      *socket,
                        GIOCondition  condition,
                        GCancellable *cancellable)
{
  g_return_val_if_fail (G_IS_SOCKET (socket) && (cancellable == NULL || G_IS_CANCELLABLE (cancellable)), NULL);

  return _g_fd_source_new (socket->priv->fd, condition, cancellable);
}
