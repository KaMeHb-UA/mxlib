module mxlib

import net.http
import net.urllib

struct Null{}

[noinit]
pub struct Server {
	homeserver &urllib.URL
	identity_server &urllib.URL
	versions []string
	unstable_features map[string]bool
}

fn non_discovered(url &urllib.URL) (&urllib.URL, &urllib.URL) {
	base_url := url.parse('/') or { *url }
	hsurl := urllib.parse(base_url.str()) or { *url }
	isurl := urllib.parse(base_url.str()) or { *url }
	return &hsurl, &isurl
}

fn discover(url &urllib.URL) (&urllib.URL, &urllib.URL) {
	def_hsurl, def_isurl := non_discovered(url)
	well_known := raw_call<RespWellKnown, Null>(url, http.Method.get, '/.well-known/matrix/client', map[string]string{}, Null{}) or {
		return def_hsurl, def_isurl
	}
	hsurl := urllib.parse(well_known.homeserver.base_url) or { *def_hsurl }
	isurl := urllib.parse(well_known.identity_server.base_url) or { *def_isurl }
	return &hsurl, &isurl
}

pub fn new(proto string, host string, port int) ?&Server {
	homeserver, identity_server := discover(urllib.parse('$proto://$host:$port/')?)
	r := call_method_wo_version<RespVersions, Null>(homeserver, http.Method.get, 'versions', map[string]string{}, Null{})?
	return &Server{homeserver, identity_server, r.versions, r.unstable_features}
}

// just a shorthand
fn (s &Server) raw_call<R, A>(http_method http.Method, method string, headers map[string]string, args A) ?R {
	return call_method<R, A>(s.homeserver, http_method, 'r0', method, headers, args)
}
