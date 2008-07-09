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
#ifndef G_OS_WIN32
# include <netinet/in.h>
# include <arpa/inet.h>
# include <netdb.h>
#else
# include <winsock2.h>
# include <winerror.h>
# include <ws2tcpip.h>
# undef HAVE_GETADDRINFO
# define HAVE_GETHOSTBYNAME_THREADSAFE 1
#endif
#include <errno.h>

#include "gresolver.h"
#include "ginetaddress.h"
#include "ginet4address.h"
#include "ginet6address.h"
#include "gnioerror.h"

G_DEFINE_TYPE (GResolver, g_resolver, G_TYPE_OBJECT);

#if defined(HAVE_GETHOSTBYNAME_R_GLIB_MUTEX) || defined(HAVE_GETADDRINFO_GLIB_MUTEX)
# ifndef G_THREADS_ENABLED
#  error Using GLib Mutex but thread are not enabled.
# endif
G_LOCK_DEFINE (dnslock);
#endif

#ifdef G_OS_WIN32
/* This is copied straight from giowin32.c, but its static there... */
/* TODO: is there another way to get this functionality? or maybe make this public? */
static char *
winsock_error_message (int number)
{
  static char unk[100];

  switch (number) {
  case WSAEINTR:
    return "Interrupted function call";
  case WSAEACCES:
    return "Permission denied";
  case WSAEFAULT:
    return "Bad address";
  case WSAEINVAL:
    return "Invalid argument";
  case WSAEMFILE:
    return "Too many open sockets";
  case WSAEWOULDBLOCK:
    return "Resource temporarily unavailable";
  case WSAEINPROGRESS:
    return "Operation now in progress";
  case WSAEALREADY:
    return "Operation already in progress";
  case WSAENOTSOCK:
    return "Socket operation on nonsocket";
  case WSAEDESTADDRREQ:
    return "Destination address required";
  case WSAEMSGSIZE:
    return "Message too long";
  case WSAEPROTOTYPE:
    return "Protocol wrong type for socket";
  case WSAENOPROTOOPT:
    return "Bad protocol option";
  case WSAEPROTONOSUPPORT:
    return "Protocol not supported";
  case WSAESOCKTNOSUPPORT:
    return "Socket type not supported";
  case WSAEOPNOTSUPP:
    return "Operation not supported on transport endpoint";
  case WSAEPFNOSUPPORT:
    return "Protocol family not supported";
  case WSAEAFNOSUPPORT:
    return "Address family not supported by protocol family";
  case WSAEADDRINUSE:
    return "Address already in use";
  case WSAEADDRNOTAVAIL:
    return "Address not available";
  case WSAENETDOWN:
    return "Network interface is not configured";
  case WSAENETUNREACH:
    return "Network is unreachable";
  case WSAENETRESET:
    return "Network dropped connection on reset";
  case WSAECONNABORTED:
    return "Software caused connection abort";
  case WSAECONNRESET:
    return "Connection reset by peer";
  case WSAENOBUFS:
    return "No buffer space available";
  case WSAEISCONN:
    return "Socket is already connected";
  case WSAENOTCONN:
    return "Socket is not connected";
  case WSAESHUTDOWN:
    return "Can't send after socket shutdown";
  case WSAETIMEDOUT:
    return "Connection timed out";
  case WSAECONNREFUSED:
    return "Connection refused";
  case WSAEHOSTDOWN:
    return "Host is down";
  case WSAEHOSTUNREACH:
    return "Host is unreachable";
  case WSAEPROCLIM:
    return "Too many processes";
  case WSASYSNOTREADY:
    return "Network subsystem is unavailable";
  case WSAVERNOTSUPPORTED:
    return "Winsock.dll version out of range";
  case WSANOTINITIALISED:
    return "Successful WSAStartup not yet performed";
  case WSAEDISCON:
    return "Graceful shutdown in progress";
  case WSATYPE_NOT_FOUND:
    return "Class type not found";
  case WSAHOST_NOT_FOUND:
    return "Host not found";
  case WSATRY_AGAIN:
    return "Nonauthoritative host not found";
  case WSANO_RECOVERY:
    return "This is a nonrecoverable error";
  case WSANO_DATA:
    return "Valid name, no data record of requested type";
  case WSA_INVALID_HANDLE:
    return "Specified event object handle is invalid";
  case WSA_INVALID_PARAMETER:
    return "One or more parameters are invalid";
  case WSA_IO_INCOMPLETE:
    return "Overlapped I/O event object not in signaled state";
  case WSA_NOT_ENOUGH_MEMORY:
    return "Insufficient memory available";
  case WSA_OPERATION_ABORTED:
    return "Overlapped operation aborted";
  case WSAEINVALIDPROCTABLE:
    return "Invalid procedure table from service provider";
  case WSAEINVALIDPROVIDER:
    return "Invalid service provider version number";
  case WSAEPROVIDERFAILEDINIT:
    return "Unable to initialize a service provider";
  case WSASYSCALLFAILURE:
    return "System call failure";
  default:
    sprintf (unk, "Unknown WinSock error %d", number);
    return unk;
  }
}
#endif

#if !defined(HAVE_GETADDRINFO)
static void
g_set_error_from_last_error (GError **error)
{
  int code;

#ifdef G_OS_WIN32
  int err = WSAGetLastError ();
#else
  int err = h_errno;
#endif

  switch (err)
    {
      case HOST_NOT_FOUND:
        code = G_IO_ERROR_RESOLVER_NOT_FOUND;
        break;
      case NO_DATA:
        code = G_IO_ERROR_RESOLVER_NO_DATA;
        break;
      default:
        g_warning ("unknown h_errno code encountered");
    }

#ifdef G_OS_WIN32
  g_set_error (error, G_IO_ERROR, code, winsock_error_message (err));
#else
  g_set_error (error, G_IO_ERROR, code, hstrerror (err));
#endif
}
#endif

typedef struct
{
  GInetAddress *address;
  gchar        *canonical_name;
} HostInfo;

#if !defined(HAVE_GETADDRINFO)
static GList *
hostent2list (const struct hostent *he)
{
  GList *list = NULL;
  int i;

  g_return_val_if_fail (he != NULL, NULL);

  for (i = 0; he->h_addr_list[i]; i++)
    {
      GInetAddress *address = NULL;

      if (he->h_addrtype == AF_INET)
        address = G_INET_ADDRESS (g_inet4_address_from_bytes ((guint8 *) he->h_addr_list[i]));
      else if (he->h_addrtype == AF_INET6)
        address = G_INET_ADDRESS (g_inet6_address_from_bytes ((guint8 *) he->h_addr_list[i]));

      list = g_list_prepend (list, address);
    }

  return list;
}
#endif

#if defined(HAVE_GETADDRINFO)
static void
g_io_error_from_addrinfo (GError** error, int err)
{
  GIOErrorEnum code = G_IO_ERROR_FAILED;
  const gchar *message = NULL;

  if (error == NULL)
    return;

  switch (err)
    {
      case EAI_NONAME:
        code = G_IO_ERROR_RESOLVER_NOT_FOUND;
        break;
      case EAI_NODATA:
        code = G_IO_ERROR_RESOLVER_NO_DATA;
        break;
      default:
        g_warning ("unknown getaddrinfo() error code encountered");
    }

  if (message == NULL)
    {
#ifndef G_OS_WIN32
      /* FIXME: is gai_strerror() thread-safe? */
      message = gai_strerror (err);
#else
      message = winsock_error_message (WSAGetLastError ());
#endif
    }

  *error = g_error_new_literal (G_IO_ERROR, code, message);
}
#endif

static GList *
g_resolver_get_host_by_name (GResolver *resolver, const gchar *hostname, GError **error)
{
  GList *list = NULL;

#if defined(HAVE_GETADDRINFO)
  {
    struct addrinfo hints;
    struct addrinfo *res = NULL, *i;
    int rv;

    memset (&hints, 0, sizeof (hints));
    hints.ai_socktype = SOCK_STREAM;

#ifdef HAVE_GETADDRINFO_GLIB_MUTEX
    G_LOCK (dnslock);
#endif

    if ((rv = getaddrinfo (hostname, NULL, &hints, &res)))
      g_io_error_from_addrinfo (error, rv);
    else
      for (i = res; i != NULL; i = i->ai_next)
        {
          if (i->ai_family == PF_INET)
            list = g_list_prepend (list, g_inet4_address_from_bytes ((guint8 *) &(((struct sockaddr_in *) i->ai_addr)->sin_addr.s_addr)));
          else if (i->ai_family == PF_INET6)
            list = g_list_prepend (list, g_inet6_address_from_bytes ((guint8 *) &(((struct sockaddr_in *) i->ai_addr)->sin_addr.s_addr)));
        }

    if (res)
      freeaddrinfo (res);

#ifdef HAVE_GETADDRINFO_GLIB_MUTEX
    G_UNLOCK (dnslock);
#endif
  }
#elif defined(HAVE_GETHOSTBYNAME_THREADSAFE)
  {
    struct hostent *he = gethostbyname (hostname);

    if (!he)
      g_set_error_from_last_error (error);
    else
      list = hostent2list (he);
  }
#elif defined(HAVE_GETHOSTBYNAME_R_GLIBC)
  {
    struct hostent result, *he;
    gsize len = 1024;
    gchar *buf = g_new (gchar, len);
    gint rv, herr;

    while ((rv = gethostbyname_r (hostname, &result, buf, len, &he, &herr)) == ERANGE)
      {
        len *= 2;
        buf = g_renew (gchar, buf, len);
      }

    if (!rv)
      list = hostent2list (he);
    else
      g_set_error_from_last_error (error);

    g_free (buf);
  }
#elif defined(HAVE_GETHOSTBYNAME_R_SOLARIS)
  {
    struct hostent result, *he;
    gsize len = 8192;
    char *buf = NULL;

    do
      {
        buf = g_renew (gchar, buf, len);
        errno = 0;
        he = gethostbyname_r (hostname, &result, buf, len, &h_errno);
        len += 1024;
      }
    while (errno == ERANGE);

    if (he)
      list = hostent2list (&result);
    else
      g_set_error_from_last_error (error);

    g_free (buf);
  }
#elif defined(HAVE_GETHOSTBYNAME_R_HPUX)
  {
    struct hostent he;
    struct hostent_data buf;
    int rv;

    rv = gethostbyname_r (hostname, &he, &buf);

    if (!rv)
      list = hostent2list (&he);
    else
      g_set_error_from_last_error (error);
  }
#else
  {
    struct hostent *he;

#ifdef HAVE_GETHOSTBYNAME_R_GLIB_MUTEX
    G_LOCK (dnslock);
#endif

    he = gethostbyname (hostname);
    if (he)
      list = hostent2list (he);
    else
      g_set_error_from_last_error (error);

#ifdef HAVE_GETHOSTBYNAME_R_GLIB_MUTEX
    G_UNLOCK (dnslock);
#endif
  }
#endif

  if (list)
    list = g_list_reverse (list);

  return list;
}

static void
g_resolver_class_init (GResolverClass *klass)
{
  GObjectClass *gobject_class G_GNUC_UNUSED = G_OBJECT_CLASS (klass);
}

static void
g_resolver_init (GResolver *address)
{

}

GResolver *
g_resolver_new ()
{
  return G_RESOLVER (g_object_new (G_TYPE_RESOLVER, NULL));
}

typedef struct {
  GList       *list;
  const gchar *host;
} ResolveListData;

static void
resolve_list_thread (GSimpleAsyncResult *res,
                     GObject            *object,
                     GCancellable       *cancellable)
{
  ResolveListData *op;
  GError *error = NULL;

  op = g_simple_async_result_get_op_res_gpointer (res);

  op->list = g_resolver_resolve_list (G_RESOLVER (object), op->host, cancellable, &error);

  if (op->list == NULL)
    {
      g_simple_async_result_set_from_error (res, error);
      g_error_free (error);
    }
}

GInetAddress *
g_resolver_resolve (GResolver     *resolver,
                    const char    *host,
                    GCancellable  *cancellable,
                    GError       **error)
{
  GList *list;
  GInetAddress *address;

  list = g_resolver_get_host_by_name (resolver, host, error);

  if (!list)
    return NULL;

  address = G_INET_ADDRESS (g_object_ref (g_list_first (list)->data));

  g_list_foreach (list, (GFunc) g_object_unref, NULL);

  g_list_free (list);

  return address;
}

void
g_resolver_resolve_async (GResolver           *resolver,
                          const char          *host,
                          GCancellable        *cancellable,
                          GAsyncReadyCallback  callback,
                          gpointer             user_data)
{
  GSimpleAsyncResult *res;
  ResolveListData *op;

  op = g_new (ResolveListData, 1);

  res = g_simple_async_result_new (G_OBJECT (resolver), callback, user_data, g_resolver_resolve_list_async);

  g_simple_async_result_set_op_res_gpointer (res, op, g_free);

  op->host = host;

  g_simple_async_result_run_in_thread (res, resolve_list_thread, G_PRIORITY_DEFAULT, cancellable);

  g_object_unref (res);
}

GInetAddress *
g_resolver_resolve_finish (GResolver     *resolver,
                           GAsyncResult  *result,
                           GError       **error)
{
  GSimpleAsyncResult *res = G_SIMPLE_ASYNC_RESULT (result);
  ResolveListData *op;
  GInetAddress *address;

  g_warn_if_fail (g_simple_async_result_get_source_tag (res) == g_resolver_resolve_list_async);

  op = g_simple_async_result_get_op_res_gpointer (res);

  g_simple_async_result_propagate_error (res, error);

  if (op->list == NULL)
    return NULL;

  address = G_INET_ADDRESS (g_object_ref (g_list_first (op->list)->data));

  g_list_foreach (op->list, (GFunc) g_object_unref, NULL);

  g_list_free (op->list);

  return address;
}

GList *
g_resolver_resolve_list (GResolver     *resolver,
                         const char    *host,
                         GCancellable  *cancellable,
                         GError       **error)
{
  return g_resolver_get_host_by_name (resolver, host, error);
}

void
g_resolver_resolve_list_async (GResolver           *resolver,
                               const char          *host,
                               GCancellable        *cancellable,
                               GAsyncReadyCallback  callback,
                               gpointer             user_data)
{
  GSimpleAsyncResult *res;
  ResolveListData *op;

  op = g_new (ResolveListData, 1);

  res = g_simple_async_result_new (G_OBJECT (resolver), callback, user_data, g_resolver_resolve_list_async);

  g_simple_async_result_set_op_res_gpointer (res, op, g_free);

  op->host = host;

  g_simple_async_result_run_in_thread (res, resolve_list_thread, G_PRIORITY_DEFAULT, cancellable);

  g_object_unref (res);
}

GList *
g_resolver_resolve_list_finish (GResolver     *resolver,
                                GAsyncResult  *result,
                                GError       **error)
{
  GSimpleAsyncResult *res = G_SIMPLE_ASYNC_RESULT (result);
  ResolveListData *op;

  g_warn_if_fail (g_simple_async_result_get_source_tag (res) == g_resolver_resolve_list_async);

  op = g_simple_async_result_get_op_res_gpointer (res);

  g_simple_async_result_propagate_error (res, error);

  return op->list;
}

