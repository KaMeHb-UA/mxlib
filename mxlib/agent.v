module mxlib

import net.http
import net.urllib

struct Null{}

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
