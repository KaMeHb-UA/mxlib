module server

import net.http
import net.urllib

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
	mut versions := map[string]map[string][]string{}
	for version in r.versions {
		version_parts := version.split('.')
		if version_parts[0] !in versions {
			versions[version_parts[0]] = map[string][]string{}
		}
		if version_parts[1] !in versions[version_parts[0]] {
			versions[version_parts[0]][version_parts[1]] = [version_parts[2]]
		}
		if version_parts[2] !in versions[version_parts[0]][version_parts[1]] {
			versions[version_parts[0]][version_parts[1]] << version_parts[2]
		}
	}
	mut server := &Server{homeserver, identity_server, versions, r.unstable_features, []LoginFlow{}}
	server.get_login_flows()?
	return server
}
