# Changelog

## 2.5.0
* Rewrite restart code to avoid potentially nasty hangs.

## 2.4.1
* Handle an error raised (`Errno::EINVAL`) when a client would connect and immediately disconnect before any processing occurs.

## 2.4.0
* When restarting a server, the socket is passed to the new server via a UNIX socket instead of inheriting open file descriptors from the parent.

## 2.3.0
* Incoming connections can be restricted to certain networks by setting `allowed_networks` in the configuration.

## 2.2.1
* Allow multiple certificates to be used in one build file

## 2.2.0
* Verify client TLS certificates
* Allow trusted client CA to be set

## 2.1.1
* Prevent bad SSL handshakes from crashing server

## 2.1.0
* Add TLS support for TCP connections

## 2.0.0
* Use an internal pipe for delivering signals to the main thread.
* `accept_connections` retired in favour of a select loop and `accept_client_connection` being called for each waiting connection
* Logging when shutting down or restarting
