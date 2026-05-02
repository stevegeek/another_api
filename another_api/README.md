# another_api

A Rails engine for building opinionated JSON APIs. Wires together
[`api_serializer`](../api_serializer),
[`api_query_language`](../api_query_language),
[`api_query_language-active_record`](../api_query_language_active_record),
[ActionPolicy](https://actionpolicy.evilmartians.io/), and
[Dry::Monads](https://dry-rb.org/gems/dry-monads/) behind a batteries-included
API base controller: bearer-token auth, scoped policies, typed responses,
structured errors, pagination, and filter/sort query-string parsing.

Part of the [another_api](https://github.com/stevegeek/another_api) family.

## Installation

```ruby
gem "another_api"
```

## Configuration

```ruby
# config/initializers/another_api.rb
AnotherApi.configure do |c|
  c.token_model       = "ApiToken"                               # your AR model
  c.token_secret      = Rails.application.credentials.api_token_secret
  c.token_prefix      = "my_app"                                 # default: "aa"
  c.scope_prefix      = "api.v1."                                # default: "api.v2."
  c.default_page_size = 20                                       # same as default
  c.max_page_size     = 200                                      # same as default

  # Map application exception classes to HTTP error types:
  c.rescue_from "MyApp::NotAllowedError", as: :forbidden
end

AnotherApi.configuration.validate!   # fail fast at boot if required
                                     # settings (token_secret, token_model)
                                     # are missing. Otherwise you get a 500
                                     # on the first request instead.

AnotherApi::Scopes.define do
  scope :"account.users"
  scope :"selling.products", only: [:list, :show]
end
```

## Token model

Your `ApiToken` model includes the contract module:

```ruby
class ApiToken < ApplicationRecord
  include AnotherApi::ApiTokenContract

  serialize :scopes, coder: JSON, type: Array
end
```

The contract requires columns: `token_digest`, `token_prefix`, `token_suffix`,
`scopes`, polymorphic `bearer_id`/`bearer_type`, plus optional `revoked_at` and
`expires_at`. See
[`api_token_contract.rb`](lib/another_api/api_token_contract.rb) for the full
contract.

`ApiTokenContract` adds these instance methods:

- `allows?(scope)` — true if the token's parsed scopes cover `scope`.
- `parsed_scopes` — memoised array of `AnotherApi::Scope` structs.
- `active?` / `revoked?` / `expired?` — lifecycle predicates.
  `BaseController`'s authentication already checks `active?`; you do not
  need to re-check in controllers.
- `token_preview` — `"aa****…****1234"` for safe display in admin UIs.
- `ApiToken.find_by_token(raw_token)` — HMAC-digest lookup.

## Building a controller

```ruby
class Api::V1::WidgetsController < AnotherApi::BaseController
  include Dry::Monads[:result]

  def index
    api_respond_to_json do
      authorize! with: Api::V1::WidgetsPolicy
      Success(data: Widget.all.map { |w| w.attributes.slice("id", "name") })
    end
  end
end
```

with a matching policy:

```ruby
class Api::V1::WidgetsPolicy < AnotherApi::ApiTokenScopedPolicy
  private

  def scope_group_name = :widgets
end
```

`scope_group_name` is **required** on every `ApiTokenScopedPolicy`
subclass — omitting it raises `NoMethodError` at authorization time (not
a policy denial). Return the Symbol that matches your
`AnotherApi::Scopes.define` entry.

For resource-ownership checks (as opposed to scope checks), inherit
`AnotherApi::ApiTokenOwnershipPolicy` instead and override `owned?`.

That gets you bearer-token auth, scope checks, standardised error responses,
and Dry::Monads result handling out of the box. See
[`test/dummy/`](test/dummy/) for a full example app used by the test suite.

## Result handling

Controller blocks return a `Dry::Monads::Result`. On `Failure`, return an
`AnotherApi::OperationFailure` value with a mapped error type:

```ruby
Failure(AnotherApi::OperationFailure.new(type: :not_found, message: "…"))
```

`type:` must be a key in `configuration.error_status_map` (or match a
`rescue_from` entry); `ResponseHandler` converts it to the matching HTTP
status and a standardised JSON error body.

## Utilities

- `AnotherApi::ParamSanitizer#sanitise_query_param(str, max_length:, strip_out:)`
  — length-caps a param and optionally strips characters. `strip_out:`
  takes a regex; only pass **trusted, non-user-supplied** patterns
  (it reaches `gsub` directly, so catastrophic backtracking is on you).
- `AnotherApi::Paginated` — reads `?page=` / `?page_size=`, clamps to
  `configuration.default_page_size` / `.max_page_size`.
- `AnotherApi::ResponseHasMetadata` — builds the envelope's `meta:` block
  (offset, count, total, poll-interval hint).

## OpenAPI 3.1 generation

Opt-in. Add `require "another_api/openapi"` (typically in an initialiser)
and you get a generator that walks your `api_serializer` schemas and the
controllers that include the `EndpointMetadata` DSL, and emits an OpenAPI
3.1 spec. The output assumes another_api's response envelope (`{success:,
data:, metadata:}`) and pagination shape; if your API ships something
different, subclass `PathBuilder` or override `error_response_content` /
`pagination_metadata_schema` in configuration.

```ruby
# config/initializers/another_api_openapi.rb
require "another_api/openapi"

AnotherApi::OpenAPI.configure do |c|
  c.title                   = "My API"
  c.version                 = "1.0"
  c.description             = "Public REST API"
  c.path_prefix             = "/api/v1"            # stripped from route paths
  c.controllers_glob        = "app/controllers/api/v1/**/*_controller.rb"
  c.schema_namespace_prefix = "MyApp::Schemas::V1::" # auto-discovers nested schemas
  c.default_variant_name    = :default              # which api_serializer variant
                                                    # maps to "<Schema>Full" output

  # If your app has its own filtering concerns:
  c.register_concern "MyApp::FilterOnDeleted", :filter_on_deleted
  c.register_concern "MyApp::FilterOnActive",  :filter_on_active
end
```

Declare endpoint metadata on each controller:

```ruby
class Api::V1::UsersController < AnotherApi::BaseController
  include AnotherApi::OpenAPI::EndpointMetadata

  api_resource "Users",
    schema:      -> { MyApp::Schemas::V1::User },
    description: "Manage users in your account"

  api_action :index,  summary: "List users"
  api_action :show,   summary: "Get a single user"
  api_action :create, summary: "Create a user"
  api_action :update, summary: "Update a user"
end
```

Generate the spec:

```ruby
spec      = AnotherApi::OpenAPI::Generator.generate
spec_json = AnotherApi::OpenAPI::SpecRenderer.render_json   # cached, mtime-checked in dev
```

`SpecRenderer` caches the result for the lifetime of the process in
production and recomputes it when files under `configuration.watched_dirs`
change in development. Call `SpecRenderer.reset!` from a Rails reloader
hook if you need finer control.

### Index parameter advertising

`PathBuilder` advertises these query-string parameters on `:index`
operations only when the controller's ancestors include the
corresponding `another_api` concern:

| Parameter | Required concern |
|---|---|
| `page`, `page_size` | `AnotherApi::Paginated` |
| `filter`, `sort` | `AnotherApi::FilteredAndSorted` |
| `variant` | `AnotherApi::SchemaConfigurable` |
| `deleted` | concern key `:filter_on_deleted` (register via `c.register_concern`) |
| `active` | concern key `:filter_on_active` |

Because `AnotherApi::BaseController` already includes `Paginated` and
`SchemaConfigurable`, every controller that inherits from it advertises
`page` / `page_size` / `variant` by default. `filter` / `sort` only
appear if the controller explicitly `include`s `FilteredAndSorted`.

### Reference example

A working end-to-end example lives in this gem's dummy app — see
`test/dummy/app/controllers/test/posts_controller.rb` and
`test/dummy/app/controllers/test/widgets_controller.rb` for the DSL,
`test/dummy/config/initializers/another_api_openapi.rb` for the
configuration block, and `test/openapi/integration_test.rb` for an
end-to-end assertion suite that generates and inspects the resulting
spec.

### Schema-name conventions

OpenAPI component names are derived from the schema's class name. With
`schema_namespace_prefix` set, the prefix is stripped and remaining
sub-namespaces are concatenated (e.g.
`MyApp::Schemas::V1::Seller::Cart` → `SellerCart`); without a prefix,
`demodulize` is used. Variant suffixes:

- the configured `default_variant_name` → `"Full"` (e.g. `UserFull`)
- `:id_only` → `IdOnly`
- any other variant → `CamelCase` of the variant symbol
- deserializer variants → `<Name><VariantCamel>Input`

## License

MIT. See `LICENSE.txt` at the repository root.
