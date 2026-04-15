# api_query_language

A filter and sort query-language parser for JSON APIs. Parses URL query
expressions like `?filter=status:active&sort=created_at:desc` into a structured
AST. Zero ActiveSupport, zero ActiveRecord.

Part of the [another_api](https://github.com/stevegeek/another_api) family.
For the ActiveRecord-aware variant that produces real AR/Arel queries, see
[`api_query_language-active_record`](../api_query_language_active_record).

## Installation

```ruby
gem "api_query_language"
```

Runtime dependencies: [literal](https://github.com/joeldrapper/literal) and
[racc](https://github.com/ruby/racc). `racc` ships a C extension when
available and falls back to a pure-Ruby implementation otherwise.

Development-only: [oedipus_lex](https://github.com/seattlerb/oedipus_lex)
and `racc` itself are used to generate the checked-in `.rex.rb` / `.y.rb`
artefacts. Runtime does not require `oedipus_lex`; you only need it if you
change a `.rex` or `.y` grammar and run `bundle exec rake generate` from
this directory.

## Quickstart

```ruby
expr = ApiQueryLanguage::Filtering::FilterExpression.new(
  "status:active [and] created_at{gte}:2024-01-01",
  { status: nil, created_at: nil }
)

expr.ast_root
# => Parsed AST — walk it with your own visitor to produce queries for any
#    backend (ActiveRecord, Sequel, Elasticsearch, etc.).

sort = ApiQueryLanguage::Sorting::SortExpression.new(
  "created_at:desc;name:asc",
  { created_at: nil, name: nil }
)

sort.parsed
# => Parsed sort AST — SortExpression exposes `#parsed` rather than
#    `#ast_root` because the AST shape is flatter.
```

Input is hard-capped at 1000 characters; longer expressions raise
`Errors::InvalidExpressionError` before they reach the lexer.

## Filter syntax

```
field:value                     equality (parses to a plain Field node)
field{eq}:value                 equality (parses to a FieldComparison node —
                                same result, different AST shape, useful if
                                your visitor handles comparisons uniformly)
field{gte}:value                comparison (eq, neq, gt, gte, lt, lte, ieq)
field:a|b|c                     OR across values
field:a&b                       AND across values
name:a* / name:*a / name:*a*    wildcards — `*` matches any, `+` matches one
                                or more (e.g. `name:a+` = at least one char
                                after `a`)
null(field) / NULL(field)       matches rows where `field IS NULL`
[not] field:value               negation (also wraps groups: `[not] (…)`)
field:a [and] field:b           logical composition
(field:a [or] field:b) [and] …  grouping
```

Values are URL-decoded before the lexer sees them: `field:testy%40example.com`
resolves to `field:testy@example.com`. Use `%25` for a literal `%`.

## Sort syntax

```
field:asc                       ascending
field:desc                      descending
field1:asc;field2:desc          multiple fields (separator is `;`)
```

## License

MIT. See `LICENSE.txt` at the repository root.
