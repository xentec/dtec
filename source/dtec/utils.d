module dtec.utils;

import std.conv;
import std.array: appender;
import std.encoding;
import std.string: format;

string decodeString(string encoding, const(ubyte)[] data) {
	if(encoding == "UTF-8")
		return cast(string)(data);

	EncodingScheme scheme = EncodingScheme.create(encoding);
	auto decoded = appender!(string);
	while(data.length)
	{
		dchar dc = scheme.safeDecode(data);
		if (dc == INVALID_SEQUENCE)
			decoded ~= "?";
		else
			decoded ~= dc;
	}
	return decoded.data;
}

string humanBytes(ulong bytes) {
	enum prefix = ["","Ki","Mi","Gi","Ti","Pi"];
	float simplify(float bytes, ref byte level) {
		return (++level == prefix.length || bytes < 750f) ? bytes : simplify(bytes/1024f, level);
	}
	byte l = -1;
	float hb = simplify(to!float(bytes), l);
	return format("%.1f %sB", hb, prefix[l]);
}
