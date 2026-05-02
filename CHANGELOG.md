# Changelog

All four gems in this repository — `api_serializer`, `api_query_language`,
`api_query_language-active_record`, `another_api` — share a single VERSION
file and release together. Entries here apply to all four unless called out.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **another_api** — opt-in OpenAPI 3.1 spec generator under
  `AnotherApi::OpenAPI` (`require "another_api/openapi"`). Walks
  `api_serializer` schemas and emits `components/schemas` for each
  serializer/deserializer variant; reads endpoint metadata from
  controllers via the `AnotherApi::OpenAPI::EndpointMetadata` DSL
  (`api_resource` / `api_action`). Includes:
  - `Configuration` with title/version/description, path_prefix,
    schema_namespace_prefix, controllers_glob, watched_dirs, info_extra,
    servers, security/security_schemes, common_parameters, error and
    pagination overrides, and an extensible `concern_map` (default
    entries cover `AnotherApi::Paginated`, `FilteredAndSorted`,
    `SchemaConfigurable`).
  - `Generator`, `SchemaBuilder`, `PathBuilder`, `TypeMapper`,
    `EndpointRegistry`, `EndpointMetadata`, `CommonSchemas`,
    `SpecRenderer` (mtime-cached in dev, lifetime-cached in prod).
  - `PathBuilder` advertises common index parameters based on which
    controller concerns are present in the registered entry: `page` /
    `page_size` only when `:paginated` is detected, `filter` / `sort`
    only when `:filtered_and_sorted` is detected, `variant` only when
    `:schema_configurable` is detected. (Previously these were emitted
    on every index action regardless.) `:filter_on_deleted` and
    `:filter_on_active` continue to gate their respective parameters.

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
