puts "Running Test Provider"
run -> (env) { [200, {"Content-Type" => "text/plain"}, ["Hello world"]] }
