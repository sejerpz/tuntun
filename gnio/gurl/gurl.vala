using GLib;

namespace Gurl {
	/* a couple of helpers not defined in glib's vapi */
	[CCode(cname="strcasecmp", cheader_filename="string.h")]
	public static int strcasecmp(string s1, string s2);

	[CCode(cname="strncasecmp", cheader_filename="string.h")]
	public static int strncasecmp(string s1, string s2, size_t n);

	[CCode(cname="strchr", cheader_filename="string.h")]
	public static char* strchr(string s, int c);

	public errordomain UriError {
		FAILED,
	}
}
