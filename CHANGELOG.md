# Changelog

All four gems in this repository — `api_serializer`, `api_query_language`,
`api_query_language-active_record`, `another_api` — share a single VERSION
file and release together. Entries here apply to all four unless called out.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] — 2026-04-15

### Added

- **api_serializer** — initial release. Schema/variant DSL (`serializer`,
  `deserializer`, templates, inheritance, composition), `attribute`,
  `compose`, `decompose`, `virtual`, `has_one`, `has_many`, `_Nilable`
  resolvers, `queryable:` mappings, `TargetDataStructure#as_json`.
- **api_query_language** — initial release. Filter and sort expression
  parsers (racc + oedipus_lex generated), AST node types, `FilterExpression`
  and `SortExpression` value objects, `FilterValueCaster`, field mappings.
- **api_query_language-active_record** — initial release. ActiveRecord
  visitors, `MappingToColumn`, subclass `FilterExpression`/`SortExpression`
  adding `#apply_to(relation)`.
- **another_api** — initial release. Rails engine with:
  - `BaseController` (inherits `ActionController::API`) with HTTP bearer-
    token authentication
  - `ApiTokenContract` and `TokenGeneration` (HMAC-SHA256)
  - `ApiTokenScopedPolicy` and `ApiTokenOwnershipPolicy` for ActionPolicy
  - `Scope` and `Scopes` DSL
  - `ErrorHandling`, `ResponseHandler`, `Paginated`, `ResponseHasMetadata`,
    `SchemaConfigurable`, `FilteredAndSorted`, `ParamDeserializer`,
    `Serializes` concerns
  - `OperationFailure` value class for Dry::Monads result pattern matching

### Notes

APIs are expected to evolve before `1.0.0`.

[Unreleased]: https://github.com/stevegeek/another_api/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/stevegeek/another_api/releases/tag/v0.1.0
