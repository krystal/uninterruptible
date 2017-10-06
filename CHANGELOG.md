# Changelog

# 2.2.1
* Allow multiple certificates to be used in one build file

# 2.2.0
* Verify client TLS certificates
* Allow trusted client CA to be set

# 2.1.1
* Prevent bad SSL handshakes from crashing server

# 2.1.0
* Add TLS support for TCP connections

# 2.0.0
* Use an internal pipe for delivering signals to the main thread.
* `accept_connections` retired in favour of a select loop and `accept_client_connection` being called for each waiting connection
* Logging when shutting down or restarting
