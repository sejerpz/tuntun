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

#ifndef G_RESOLVER_H
#define G_RESOLVER_H

#include <glib-object.h>
#include <gio/gio.h>

#include <gnio/ginetaddress.h>

G_BEGIN_DECLS

#define G_TYPE_RESOLVER         (g_resolver_get_type ())
#define G_RESOLVER(o)           (G_TYPE_CHECK_INSTANCE_CAST ((o), G_TYPE_RESOLVER, GResolver))
#define G_RESOLVER_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), G_TYPE_RESOLVER, GResolverClass))
#define G_IS_RESOLVER(o)        (G_TYPE_CHECK_INSTANCE_TYPE ((o), G_TYPE_RESOLVER))
#define G_IS_RESOLVER_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE ((k), G_TYPE_RESOLVER))
#define G_RESOLVER_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o), G_TYPE_RESOLVER, GResolver))

typedef struct _GResolver        GResolver;
typedef struct _GResolverClass   GResolverClass;

struct _GResolver
{
  GObject parent;
};

struct _GResolverClass
{
  GObjectClass parent_class;
};

GType          g_resolver_get_type                  (void) G_GNUC_CONST;

GResolver *    g_resolver_new                       (void);

GInetAddress * g_resolver_resolve                   (GResolver     *resolver,
                                                     const char    *host,
                                                     GCancellable  *cancellable,
                                                     GError       **error);

void           g_resolver_resolve_async             (GResolver           *resolver,
                                                     const char          *host,
                                                     GCancellable        *cancellable,
                                                     GAsyncReadyCallback  callback,
                                                     gpointer             user_data);

GInetAddress * g_resolver_resolve_finish            (GResolver     *resolver,
                                                     GAsyncResult  *result,
                                                     GError       **error);

GList *        g_resolver_resolve_list              (GResolver     *resolver,
                                                     const char    *host,
                                                     GCancellable  *cancellable,
                                                     GError       **error);

void           g_resolver_resolve_list_async        (GResolver           *resolver,
                                                     const char          *host,
                                                     GCancellable        *cancellable,
                                                     GAsyncReadyCallback  callback,
                                                     gpointer             user_data);

GList *        g_resolver_resolve_list_finish       (GResolver     *resolver,
                                                     GAsyncResult  *result,
                                                     GError       **error);

G_END_DECLS

#endif /* G_RESOLVER_H */

