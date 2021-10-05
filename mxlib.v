module mxlib

import server

pub fn init(proto string, host string, port int) ?&server.Server {
	return server.new(proto, host, port)
}
