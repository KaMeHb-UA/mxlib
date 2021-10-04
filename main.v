module main

import mxlib

fn main(){
	server := mxlib.new('https', 'matrix.org', 443)?
	println(server)
}
