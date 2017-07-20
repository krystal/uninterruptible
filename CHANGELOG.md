# Changelog

# 2.0.0
* Use an internal pipe for delivering signals to the main thread.
* `accept_connections` retired in favour of a select loop and `accept_client_connection` being called for each waiting connection
* Logging when shutting down or restarting
