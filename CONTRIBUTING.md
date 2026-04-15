# Contributing

Thanks for considering a contribution.

## Dev setup

```bash
git clone https://github.com/stevegeek/another_api.git
cd another_api
bundle install
bundle exec rake          # runs tests + standardrb across all four gems
```

## Running a single gem's test suite

```bash
cd api_serializer                    && bundle exec rake test
cd api_query_language                && bundle exec rake test
cd api_query_language_active_record  && bundle exec rake test
cd another_api                       && bundle exec rake test
```

The `api_query_language-active_record` suite uses in-memory SQLite by default;
some tests are skipped because they need Postgres-specific features (array,
jsonb). To run the full suite:

```bash
createdb aql_test
DATABASE_URL=postgres://localhost/aql_test \
  bundle exec rake test
```

## Linting

```bash
bundle exec standardrb         # check
bundle exec standardrb --fix   # auto-fix
```

## Regenerating parsers

`api_query_language` ships the racc/oedipus_lex-generated `.y.rb` and
`.rex.rb` files. If you change a `.y` or `.rex` grammar, regenerate:

```bash
cd api_query_language && bundle exec rake generate
```

## Releasing

Versions are locked — all four gems release together. Each gem has its own
`lib/.../version.rb` with a literal `VERSION` constant; `bin/release` fails
fast if they disagree. Bump every file at once with:

```bash
bin/bump 0.2.0
```

Then preview and ship:

```bash
bin/release --dry-run   # builds gems into pkg/, prints what would push
bin/release             # builds, tags, pushes to rubygems.org
```

## License

By contributing you agree your contributions are licensed under MIT.
