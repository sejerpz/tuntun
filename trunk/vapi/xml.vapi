[CCode (cprefix = "G", lower_case_cprefix = "g_", cheader_filename = "glib.h")]
namespace XmlUtils
{
	/* Simple XML Subset Parser */
	public errordomain MarkupError {
		BAD_UTF8,
		EMPTY,
		PARSE,
		UNKNOWN_ELEMENT,
		UNKNOWN_ATTRIBUTE,
		INVALID_CONTENT,
		MISSING_ATTRIBUTE
	}

	[CCode (cprefix = "G_MARKUP_", has_type_id = false)]
	public enum MarkupParseFlags {
		TREAT_CDATA_AS_TEXT
	}

	[Compact]
	[CCode (free_function = "g_markup_parse_context_free")]
	public class MarkupParseContext {
		public MarkupParseContext (MarkupParser parser, MarkupParseFlags _flags, void* user_data, GLib.DestroyNotify? user_data_dnotify);
		public bool parse (string text, ssize_t text_len) throws MarkupError;
		public bool end_parse () throws MarkupError;
		public unowned string get_element ();
		public unowned GLib.SList<string> get_element_stack ();
		public void get_position (out int line_number, out int char_number);
		public void push (MarkupParser parser, void* user_data);
		public void* pop ();
	}
	
	[CCode (cname = "GCallback", has_target = false)]
	public delegate void MarkupParserStartElementFunc (MarkupParseContext context, string element_name, [CCode (array_length = false, array_null_terminated = true)] string[] attribute_names, [CCode (array_length = false, array_null_terminated = true)] string[] attribute_values, void* user_data) throws MarkupError;
       
	[CCode (cname = "GCallback", has_target = false)]
	public delegate void MarkupParserEndElementFunc (MarkupParseContext context, string element_name, void* user_data) throws MarkupError;
	
	[CCode (cname = "GCallback", has_target = false)]
	public delegate void MarkupParserTextFunc (MarkupParseContext context, string text, size_t text_len, void* user_data) throws MarkupError;
	
	[CCode (cname = "GCallback", has_target = false)]
	public delegate void MarkupParserPassthroughFunc (MarkupParseContext context, string passthrough_text, size_t text_len, void* user_data) throws MarkupError;
	
	[CCode (cname = "GCallback", has_target = false)]
	public delegate void MarkupParserErrorFunc (MarkupParseContext context, GLib.Error error, void* user_data);
	
	public struct MarkupParser {
		public unowned MarkupParserStartElementFunc start_element;
		public unowned MarkupParserEndElementFunc end_element;
		public unowned MarkupParserTextFunc text;
		public unowned MarkupParserPassthroughFunc passthrough;
		public unowned MarkupParserErrorFunc error;
	}
}
