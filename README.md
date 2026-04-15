# another_api

A set of Ruby gems for building opinionated JSON APIs on Rails. Extracted
from the Confinus monorepo.

This repository is a monorepo containing four gems whose versions stay in
lockstep:

| Gem | What it is | Depends on |
|---|---|---|
| **[api_serializer](api_serializer)** | Declarative DSL for serializing Ruby objects to JSON with typed, versioned schemas. | `literal` |
| **[api_query_language](api_query_language)** | Filter / sort query-language parser. Produces a backend-agnostic AST. | `literal`, `racc` |
| **[api_query_language-active_record](api_query_language_active_record)** | ActiveRecord backend for the above — adds `apply_to(relation)`. | `api_query_language`, `activerecord` |
| **[another_api](another_api)** | Rails engine wiring the three above together with ActionPolicy and Dry::Monads into a JSON API base controller. | all three + `rails`, `action_policy`, `dry-monads` |


`api_serializer` and `api_query_language` are useable outside Rails.

## Installing

Pick the level you need:

```ruby
# Just the serializer — any Ruby app
gem "api_serializer"

# Just the query-language parser — any Ruby app
gem "api_query_language"

# Query language + ActiveRecord application
gem "api_query_language-active_record"

# Full Rails engine (brings in all of the above)
gem "another_api"
```

Per-gem quickstart is in each gem's README.

## Development

```bash
bundle install      # installs all four gemspecs as path gems
bundle exec rake    # runs tests + standardrb across all four gems
```

Individual gem test suites:

```bash
cd api_serializer                    && bundle exec rake test
cd api_query_language                && bundle exec rake test
cd api_query_language_active_record  && bundle exec rake test
cd another_api                       && bundle exec rake test
```

The `api_query_language-active_record` suite uses in-memory SQLite by default.
To run the full suite including PG-only tests (array/jsonb columns), set
`DATABASE_URL`:

```bash
DATABASE_URL=postgres://user:pass@host/test_db bundle exec rake test
```

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for more.

## License

MIT. See [`LICENSE.txt`](LICENSE.txt).
