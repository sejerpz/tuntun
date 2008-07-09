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

#ifndef G_SOCKET_OUTPUT_STREAM_H
#define G_SOCKET_OUTPUT_STREAM_H

#include <glib-object.h>
#include <gio/gio.h>

G_BEGIN_DECLS

#define G_TYPE_SOCKET_OUTPUT_STREAM         (g_socket_output_stream_get_type ())
#define G_SOCKET_OUTPUT_STREAM(o)           (G_TYPE_CHECK_INSTANCE_CAST ((o), G_TYPE_SOCKET_OUTPUT_STREAM, GSocketOutputStream))
#define G_SOCKET_OUTPUT_STREAM_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), G_TYPE_SOCKET_OUTPUT_STREAM, GSocketOutputStreamClass))
#define G_IS_SOCKET_OUTPUT_STREAM(o)        (G_TYPE_CHECK_INSTANCE_TYPE ((o), G_TYPE_SOCKET_OUTPUT_STREAM))
#define G_IS_SOCKET_OUTPUT_STREAM_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE ((k), G_TYPE_SOCKET_OUTPUT_STREAM))
#define G_SOCKET_OUTPUT_STREAM_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o), G_TYPE_SOCKET_OUTPUT_STREAM, GSocketOutputStream))

typedef struct _GSocketOutputStream        GSocketOutputStream;
typedef struct _GSocketOutputStreamClass   GSocketOutputStreamClass;
typedef struct _GSocketOutputStreamPrivate GSocketOutputStreamPrivate;

struct _GSocketOutputStream
{
  GOutputStream parent;

  GSocketOutputStreamPrivate *priv;
};

struct _GSocketOutputStreamClass
{
  GOutputStreamClass parent_class;
};

GType                 g_socket_output_stream_get_type (void) G_GNUC_CONST;

GSocketOutputStream * _g_socket_output_stream_new     (GSocket *socket);

G_END_DECLS

#endif /* G_SOCKET_OUTPUT_STREAM_H */
