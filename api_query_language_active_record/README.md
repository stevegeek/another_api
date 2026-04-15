# api_query_language-active_record

ActiveRecord backend for [`api_query_language`](../api_query_language).
Consumes the parsed AST and produces real AR/Arel queries via
`#apply_to(relation)`.

Part of the [another_api](https://github.com/stevegeek/another_api) family.

## Installation

```ruby
gem "api_query_language-active_record"
```

Installing this gem transitively installs `api_query_language` and requires
`activerecord >= 7.2`.

## Quickstart

```ruby
require "api_query_language/active_record"

relation = Post.all
filter = ApiQueryLanguage::ActiveRecord::Filtering::FilterExpression.new(
  "title:Hello*",
  { title: nil } # field name → DB column (nil = same name)
)
filter.apply_to(relation)
# Emits Arel `matches` — ILIKE on PostgreSQL, LIKE on MySQL/SQLite:
# => Post.where(Post.arel_table[:title].matches("Hello%"))

sort = ApiQueryLanguage::ActiveRecord::Sorting::SortExpression.new(
  "created_at:desc",
  { created_at: nil }
)
sort.apply_to(relation)
# => Post.order(created_at: :desc)
```

Consumers who only need the AST (e.g. for Elasticsearch queries, or for
validating filter expressions server-side before forwarding) should use the
base `api_query_language` gem directly and skip this one.

## Field mappings

The second constructor argument is a hash keyed by the field name exposed in
the query string. Each value can take several shapes:

```ruby
{
  # nil → use a column of the same name on the root model
  name: nil,

  # String or Symbol → rename to a different column on the root model
  email: :email_address,
  created: "created_at",

  # Single-element Array — same as Symbol, kept for readability
  state: [:status],

  # Dotted path → JOIN through associations, filter on the joined column.
  # "author.company.name" joins `author` then `company` and filters on
  # `companies.name`. Applied automatically; the resulting relation is
  # `.distinct`.
  "author.name": nil,
  "author.company.name": nil,

  # Rich mapping — any object responding to `.column` acts as a
  # QueryableMapping; `api_serializer`'s `QueryableConfig` is the canonical
  # example. Supports:
  #   .column          → column name (falls back to the field name)
  #   .transform       → lambda run on the raw value before casting/filtering
  #   .allowed_values  → array; values outside it raise DisallowedValueError
  role: UserSchema.filtering_mapped_attributes[:role]
}
```

`transform:` runs on the decoded value before it reaches the caster, letting
an API consumer pass opaque tokens (`"admin"`, `"me"`) that you rewrite into
real column values server-side.

## Collection columns (PostgreSQL)

For PG `array` columns the visitor dispatches to `attribute.contains(...)`
rather than `=`/`LIKE`, so `roles:admin` on a `roles text[]` column emits
`roles @> ARRAY['admin']`. Non-array collection types raise
`UnsupportedCollectionFieldTypeError`.

## Case sensitivity

The `{ieq}` comparison operator forces case-insensitive matching across
adapters: the column is wrapped in `LOWER()` and compared via Arel `matches`
against the lower-cased value. On PostgreSQL this ends up as
`LOWER(col) ILIKE <value>`; on MySQL/SQLite it is `LOWER(col) LIKE <value>`.
Either way the match is case-insensitive.

Wildcard matching (`*` / `+`) uses `Arel::Attribute#matches` directly, which
emits `ILIKE` on PostgreSQL and `LIKE` on MySQL/SQLite. Behaviour there is
adapter-dependent: PostgreSQL is always case-insensitive; SQLite's `LIKE` is
case-insensitive only for ASCII A–Z; MySQL depends on the column's
collation.

## Custom visitors

`QueryContext` carries the root relation and the field-mapping lookup as the
AST is walked; each visitor receives a `NodeWithContext` (current AST node,
current relation, optional field context). If you need to extend query
behaviour beyond what ships — e.g. a new comparison operator — subclass
`Visitor` and register it in `Filtering::Visitors::AstVisitor::VISITOR_MAP`.

## License

MIT. See `LICENSE.txt` at the repository root.
