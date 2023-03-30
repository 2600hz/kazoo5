# Architectural decision-making

## Crossbar endpoints for external services or licensed apps

When creating a Crossbar endpoint to manage settings for an external service, or for a 2600Hz licensed application (like Qubicle), the expectation is that all the code for managing this config will live in the endpoint module and not make its way into kazoo-core.

A JSON schema should be created for the expected request data to be received.

Once validated, if the data is to be stored on a typical KAZOO document, like a user or device, the endpiont should store/retrieve it as a `pvt_` field.

This way, the data can only be accessed via the specific endpoint. If the data was stored on a "public" key in the user doc (for instance), there wouldn't be a way to prevent a client request to the users endpoint to set it directly, bypassing the validation (JSON schema plus extra steps) of the service's endpoint.

When GET-ing the data from the endpoint, the response envelope should reflect:
  - if the field is writable by the client put it in "data"
  - if the field is read-only, put it in "metadata"

Any accessors for managing getting/setting the pvt fields should be in the endpoint module as well.
