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

#ifndef G_INET_ADDRESS_H
#define G_INET_ADDRESS_H

#include <glib-object.h>

G_BEGIN_DECLS

#define G_TYPE_INET_ADDRESS         (g_inet_address_get_type ())
#define G_INET_ADDRESS(o)           (G_TYPE_CHECK_INSTANCE_CAST ((o), G_TYPE_INET_ADDRESS, GInetAddress))
#define G_INET_ADDRESS_CLASS(k)     (G_TYPE_CHECK_CLASS_CAST((k), G_TYPE_INET_ADDRESS, GInetAddressClass))
#define G_IS_INET_ADDRESS(o)        (G_TYPE_CHECK_INSTANCE_TYPE ((o), G_TYPE_INET_ADDRESS))
#define G_IS_INET_ADDRESS_CLASS(k)  (G_TYPE_CHECK_CLASS_TYPE ((k), G_TYPE_INET_ADDRESS))
#define G_INET_ADDRESS_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o), G_TYPE_INET_ADDRESS, GInetAddressClass))

typedef struct _GInetAddress        GInetAddress;
typedef struct _GInetAddressClass   GInetAddressClass;

struct _GInetAddress
{
  GInitiallyUnowned parent;
};

struct _GInetAddressClass
{
  GInitiallyUnownedClass parent_class;

  gchar * (*to_string) (GInetAddress *address);
};

GType           g_inet_address_get_type         (void) G_GNUC_CONST;

gchar *         g_inet_address_to_string        (GInetAddress *address);

gboolean        g_inet_address_is_any           (GInetAddress *address);

gboolean        g_inet_address_is_loopback      (GInetAddress *address);

gboolean        g_inet_address_is_link_local    (GInetAddress *address);

gboolean        g_inet_address_is_site_local    (GInetAddress *address);

gboolean        g_inet_address_is_multicast     (GInetAddress *address);

gboolean        g_inet_address_is_mc_global     (GInetAddress *address);

gboolean        g_inet_address_is_mc_link_local (GInetAddress *address);

gboolean        g_inet_address_is_mc_node_local (GInetAddress *address);

gboolean        g_inet_address_is_mc_org_local  (GInetAddress *address);

gboolean        g_inet_address_is_mc_site_local (GInetAddress *address);

G_END_DECLS

#endif /* G_INET_ADDRESS_H */
