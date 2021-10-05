module mxlib

import net.http
import net.urllib

[noinit]
pub struct Server {
	homeserver &urllib.URL
	identity_server &urllib.URL
	versions map[string]map[string][]string
	unstable_features map[string]bool
	mut:
	login_flows []LoginFlow
}

fn (s &Server) get_suitable_version(versions []string) ?string {
	for version in versions {
		if s.supports_version(version) {
			return version
		}
	}
	return error('Server does not run support suitable API version')
}

fn (s &Server) raw_call<R, A>(http_method http.Method, versions []string, method string, headers map[string]string, args A) ?R {
	return call_method<R, A>(s.homeserver, http_method, s.get_suitable_version(versions)?, method, headers, args)
}

/**
 * -----------------------------------------------------------------------------------------------------------------------------
 *                                                   PUBLIC METHODS
 * -----------------------------------------------------------------------------------------------------------------------------
 */

pub fn (s &Server) supports_unstable_feature(unstable_feature string) bool {
	return unstable_feature in s.unstable_features && s.unstable_features[unstable_feature]
}

pub fn (s &Server) supports_version(version string) bool {
	version_parts := version.split('.')
	if version_parts.len == 1 {
		if version_parts[0] in s.versions {
			return true
		}
	} else if version_parts.len == 2 {
		if version_parts[0] in s.versions && version_parts[1] in s.versions[version_parts[0]] {
			return true
		}
	} else if version_parts.len == 3 {
		if version_parts[0] in s.versions && version_parts[1] in s.versions[version_parts[0]] && version_parts[2] in s.versions[version_parts[0]][version_parts[1]] {
			return true
		}
	}
	return false
}

pub fn (mut s Server) get_login_flows() ? {
	resp := s.raw_call<RespLogin, Null>(http.Method.get, ['r0'], 'login', map[string]string{}, Null{})?
	s.login_flows = resp.flows
}
