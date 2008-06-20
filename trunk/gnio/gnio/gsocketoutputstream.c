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

#include "gsocket.h"
#include "gsocketoutputstream.h"

static void
g_socket_output_stream_write_async (GOutputStream       *stream,
                                    const void          *buffer,
                                    gsize                count,
                                    gint                 io_priority,
                                    GCancellable        *cancellable,
                                    GAsyncReadyCallback  callback,
                                    gpointer             user_data);

G_DEFINE_TYPE (GSocketOutputStream, g_socket_output_stream, G_TYPE_OUTPUT_STREAM);

enum
{
  PROP_0,
  PROP_SOCKET
};

struct _GSocketOutputStreamPrivate
{
  GSocket *socket;
};

static void
g_socket_output_stream_get_property (GObject    *object,
                                     guint       prop_id,
                                     GValue     *value,
                                     GParamSpec *pspec)
{
  GSocketOutputStream *stream = G_SOCKET_OUTPUT_STREAM (object);

  switch (prop_id)
    {
      case PROP_SOCKET:
        g_value_set_object (value, stream->priv->socket);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_socket_output_stream_set_property (GObject      *object,
                                     guint         prop_id,
                                     const GValue *value,
                                     GParamSpec   *pspec)
{
  GSocketOutputStream *stream = G_SOCKET_OUTPUT_STREAM (object);

  switch (prop_id)
    {
      case PROP_SOCKET:
        stream->priv->socket = g_value_dup_object (value);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}

static void
g_socket_output_stream_finalize (GObject *object)
{
  if (G_OBJECT_CLASS (g_socket_output_stream_parent_class)->finalize)
    (*G_OBJECT_CLASS (g_socket_output_stream_parent_class)->finalize) (object);
}

static void
g_socket_output_stream_dispose (GObject *object)
{
  if (G_OBJECT_CLASS (g_socket_output_stream_parent_class)->dispose)
    (*G_OBJECT_CLASS (g_socket_output_stream_parent_class)->dispose) (object);
}

static gssize
g_socket_output_stream_write (GOutputStream  *stream,
                              const void     *buffer,
                              gsize           count,
                              GCancellable   *cancellable,
                              GError        **error)
{
  GSocketOutputStream *output_stream = G_SOCKET_OUTPUT_STREAM (stream);

  return g_socket_send (output_stream->priv->socket, (const gchar *) buffer, count, error);
}

typedef struct
{
  GSocketOutputStream *stream;
  GAsyncReadyCallback   callback;
  GCancellable         *cancellable;
  const void           *buffer;
  gsize                 count;
  gpointer              user_data;
} WriteData;

static gboolean
write_callback (WriteData    *data,
                GIOCondition  condition,
                gint          fd)
{
  GSocketOutputStream *stream = data->stream;
  GError *error = NULL;
  gssize res;
  GSimpleAsyncResult *result;

  if ((res = g_socket_send (stream->priv->socket, data->buffer, data->count, &error)) < 0)
    {
      result = g_simple_async_result_new_from_error (G_OBJECT (stream), data->callback, data->user_data, error);
    }
  else
    {
      result = g_simple_async_result_new (G_OBJECT (stream), data->callback, data->user_data, g_socket_output_stream_write_async);
      g_simple_async_result_set_op_res_gssize (result, res);
    }

  g_simple_async_result_complete (result);

  g_object_unref (G_OBJECT (result));

  return FALSE;
}

static void
g_socket_output_stream_write_async (GOutputStream       *stream,
                                    const void          *buffer,
                                    gsize                count,
                                    gint                 io_priority,
                                    GCancellable        *cancellable,
                                    GAsyncReadyCallback  callback,
                                    gpointer             user_data)
{
  GSocketOutputStream *output_stream = G_SOCKET_OUTPUT_STREAM (stream);
  GSimpleAsyncResult *result;
  gssize res;
  GError *error = NULL;

  if ((res = g_socket_send (output_stream->priv->socket, buffer, count, &error)) < 0)
    {
      if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_WOULD_BLOCK))
        {
          GSource *source = g_socket_create_source (output_stream->priv->socket, G_IO_OUT | G_IO_ERR, cancellable);
          WriteData *data = g_new0 (WriteData, 1);

          data->callback = callback;
          data->stream = output_stream;
          data->user_data = user_data;
          data->cancellable = cancellable;
          data->buffer = buffer;
          data->count = count;

          g_source_set_callback (source, (GSourceFunc) write_callback, data, g_free);

          g_source_attach (source, NULL);
        }
      else
        g_simple_async_report_gerror_in_idle (G_OBJECT (stream), callback, user_data, error);
    }
  else
    {
      result = g_simple_async_result_new (G_OBJECT (stream), callback, user_data, g_socket_output_stream_write_async);
      g_simple_async_result_set_op_res_gssize (result, res);
      g_simple_async_result_complete_in_idle (result);
    }
}

static gssize
g_socket_output_stream_write_finish (GOutputStream  *stream,
                                    GAsyncResult   *result,
                                    GError        **error)
{
  GSimpleAsyncResult *simple;
  gssize count;

  g_return_val_if_fail (G_IS_SOCKET_OUTPUT_STREAM (stream), -1);

  simple = G_SIMPLE_ASYNC_RESULT (result);

  g_warn_if_fail (g_simple_async_result_get_source_tag (simple) == g_socket_output_stream_write_async);

  count = g_simple_async_result_get_op_res_gssize (simple);

  return count;
}


static void
g_socket_output_stream_class_init (GSocketOutputStreamClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
  GOutputStreamClass *goutputstream_class = G_OUTPUT_STREAM_CLASS (klass);

  g_type_class_add_private (klass, sizeof (GSocketOutputStreamPrivate));

  gobject_class->finalize = g_socket_output_stream_finalize;
  gobject_class->dispose = g_socket_output_stream_dispose;
  gobject_class->get_property = g_socket_output_stream_get_property;
  gobject_class->set_property = g_socket_output_stream_set_property;

  goutputstream_class->write_fn = g_socket_output_stream_write;
  goutputstream_class->write_async = g_socket_output_stream_write_async;
  goutputstream_class->write_finish = g_socket_output_stream_write_finish;

  g_object_class_install_property (gobject_class, PROP_SOCKET,
                                   g_param_spec_object ("socket",
                                                        "socket",
                                                        "the socket that this stream wraps",
                                                        G_TYPE_SOCKET,
                                                        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_NAME | G_PARAM_STATIC_BLURB | G_PARAM_STATIC_NICK));
}

static void
g_socket_output_stream_init (GSocketOutputStream *stream)
{
  stream->priv = G_TYPE_INSTANCE_GET_PRIVATE (stream, G_TYPE_SOCKET_OUTPUT_STREAM, GSocketOutputStreamPrivate);

  stream->priv->socket = NULL;
}

GSocketOutputStream *
_g_socket_output_stream_new (GSocket *socket)
{
  return G_SOCKET_OUTPUT_STREAM (g_object_new (G_TYPE_SOCKET_OUTPUT_STREAM, "socket", socket, NULL));
}
