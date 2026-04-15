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

## License

MIT. See `LICENSE.txt` at the repository root.
