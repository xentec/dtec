
import
	std.algorithm,
	std.array,
	std.bitmanip,
	std.conv,
	std.getopt,
	std.net.curl,
	std.regex,
	std.stdio,
	std.string,
	std.system;

import
	ircbod.client,
	ircbod.message;

import dtec.utils;

enum url_match = regex(r"(?:https?://|[\S]+\.[\S]+/?)[\S]+", "ig");

bool muted;
string nick = "Dtec";

int main(string[] args) {
	string host = "fr.quakenet.org";
	ushort port = 6666;

	string passwd = null;
	string[] channels = [ "#DerpsInAction" ];

	getopt(args,
		   "h|host", &host,
		   "p|port", &port,
		   "n|nick|nickname", &nick,
		   "pass|password", &passwd,
		   "c|channel|channels", &channels,
		   "m|muted", &muted);

	writeln("Initialising... ");

	IRCClient dtec = new IRCClient(host, port, nick, passwd, channels);

	dtec.on(IRCMessage.Type.CHAN_MESSAGE, &onChannelMessage);

	writeln("Connecting... ", nick, passwd.length > 0 ? ":" : "", passwd, "@", host, ":", port, "/", channels);
	dtec.connect();
	writeln("Processing...");
	dtec.run();
	return 0;
}

void onChannelMessage(IRCMessage msg) {
	string atMe = nick ~ " ";
	if(msg.text == atMe ~ "stfu") {
		msg.client.name = "zz_" ~ nick;
		muted = true;
	}
	if(msg.text == atMe ~ "k") {
		msg.client.name = nick;
		muted = false;
	}
	if(muted) return;

	printURLs(msg);
}

void printURLs(ref IRCMessage msg) {

	string[] urls;
	foreach(ref cap; match(msg.text, url_match)) {
		string url = cap.hit;
		try {
			string info;
			MetaInfo mi;
			auto ap = appender!string();

			try {
				writeln("Loading ", url);
				mi = getInfo(url, info);
				if(mi.status.code >= 400) {
					ap ~= "! ";
					ap ~= text(mi.status.code);
					if(mi.status.code == 403 && mi.cloudflare)
						ap ~= " +Cloudflare";
					//	ap ~= " - ";
					//	ap ~= status.reason;
				}

				if(!info.empty()) {
					if(ap.data.length != 0)
						ap ~= " ";
					ap ~= "» [";
					ap ~= info;
					ap ~= "]";
				}
			} catch(CurlTimeoutException ex) {
				ap.put("! Timed out");
			}


			if(ap.data.length > 0) {
				writeln(ap.data);
				msg.reply(ap.data);
			}
		} catch (Exception e) {
			writeln("Failed to load: ", url);
			writeln(e.file,":", e.line, "::", e.classinfo.name, ": ", e.msg);
		}
	}
}

struct MetaInfo {
	HTTP.StatusLine status;
	ulong size;
	string contentType;
	bool cloudflare;
}

MetaInfo getInfo(in string url, ref string info) {
	auto aInfo = appender!(string);

	HTTP client = HTTP(url);
	client.method = HTTP.Method.get;

	MetaInfo mi;

	debug client.verbose = true;

	{	// Some websites need an user agent
		import etc.c.curl;
		client.addRequestHeader("User-Agent", "curl/" ~ (text((*curl_version_info(0)).version_)));
	}

	string encoding = "ISO-8859-1";

	alias size_t delegate(ubyte[]) request;
	enum request[string] handler = [
		"text/html": (ubyte[] data){
			static auto content = appender!(string);
			static ulong size = 0;
			static long ts=-1, te=-1;

			if(!size)
				size = mi.size;

			string chunk = decodeString(encoding, data);
			content ~= chunk;

			if(ts == -1) {
				ts = content.data.indexOf("<title", CaseSensitive.no);
				if(ts > -1) {
					ts += "<title".length;
					long tse = content.data[ts..$].indexOf(">", CaseSensitive.yes);
					ts += (tse > -1) ? tse+1 : -1;
				}
			}
			if(ts > -1 && te == -1) {
				te = content.data[ts .. $].indexOf("</title>", CaseSensitive.no);
				if(te == -1) {
					aInfo ~= content.data[ts .. $];
				} else {
					aInfo ~= content.data[ts .. ts+te];
					content.clear();
					size=0,ts=-1,te=-1;
					return HTTP.requestAbort;

				}
			}
			if(size <= data.length) {
				content.clear();
				size=0,ts=-1,te=-1;
			} else
				size-=data.length;

			return data.length;
		},
		"image/png": (ubyte[] data){
			if(data.length < 36 || data[0..16] != [0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, /*|*/ 0x00, 0x00, 0x00, 0x0D, 'I', 'H', 'D', 'R'])
				return HTTP.requestAbort;

			uint w = data.peek!uint(16);
			uint h = data.peek!uint(20);
			aInfo.put(text(w,"x",h, " ", humanBytes(mi.size)));
			return 0x10000000UL; // workaround
		},
		"image/gif": (ubyte[] data){
			if(data.length < 10 || data[0..3] != ['G', 'I', 'F'])
				return HTTP.requestAbort;

			ushort w = data.peek!(ushort, Endian.littleEndian)(6);
			ushort h = data.peek!(ushort, Endian.littleEndian)(8);
			aInfo.put(text(w,"x",h, " ", humanBytes(mi.size)));
			return 0x10000000UL; // workaround
		},
		"image/jpeg": (ubyte[] data){
			if(data.length < 10 || data[0..2] != [0xFF, 0xD8])
				return HTTP.requestAbort;
/*
			static auto content = appender!(ubyte[]);
			static ulong s = 0;
			if(!s)
				s = mi.size;
			content ~= data;
*/
			ubyte[] SOF = data.find([0xFF, 0xC0]);
			if(SOF.length) {
				SOF = SOF[2..$];
				ushort w = SOF.peek!ushort(3);
				ushort h = SOF.peek!ushort(5);
				aInfo.put(text(w,"x",h, " ", humanBytes(mi.size)));
				return HTTP.requestAbort;
			}
/*
			if(s <= data.length) {
				content.clear();
				s=0;
			} else
				s-=data.length;
*/
			return data.length;
		}
	];

	client.onReceiveStatusLine = (HTTP.StatusLine sl) { mi.status = sl; };
	client.onReceiveHeader = (in char[] key, in char[] value) {
		debug writeln(key,"=", value);
		switch(key.toLower) {
			case "content-length":
				mi.size = to!ulong(value);
				break;
			case "content-type":
				const(char)[][] v = value.split(";");

				mi.contentType = v[0].idup.toLower();

				if(v.length > 1) {
					auto m = match(v[1], regex("charset=([^;,]*)", "i"));
					if (!m.empty && m.captures.length > 1)
						encoding = m.captures[1].idup.toUpper();
				}
				break;
			case "server":
				if(std.string.indexOf(value.toLower(),"cloudflare") > -1)
					mi.cloudflare = true;
				break;
			default:
		}

		client.onReceive = handler.get(mi.contentType, (ubyte[]){return 0x10000000UL; /* workaround */});
	};

	try
		client.perform();
	catch(CurlTimeoutException ex)
		throw ex;
	catch(CurlException ex) {
		if(!ex.msg.startsWith("Failed writing received data to disk/application on handle"))
			throw ex;
	}
	debug writeln(mi);
	info = aInfo.data.decodeHTML().strip().replace("\n","");
	return mi;
}


