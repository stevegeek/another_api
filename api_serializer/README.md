# api_serializer

A declarative DSL for serializing Ruby objects to JSON with typed, versioned
schemas. Works anywhere Ruby 3.3+ runs — no ActiveSupport, no Rails required.

Part of the [another_api](https://github.com/stevegeek/another_api) family
of gems; most useful when paired with the full
[another_api](../another_api) Rails engine, but usable standalone.

---

- [Installation](#installation)
- [Quickstart](#quickstart)
- [Core concepts](#core-concepts)
- [Attributes](#attributes)
  - [attribute](#attribute)
  - [virtual](#virtual)
  - [compose](#compose)
  - [decompose](#decompose)
- [Variants](#variants)
  - [serializer and deserializer](#serializer-and-deserializer)
  - [Templates and inheritance](#templates-and-inheritance)
  - [Composing templates](#composing-templates)
  - [Looking up variants at runtime](#looking-up-variants-at-runtime)
- [Associations](#associations)
  - [has_one and has_many](#has_one-and-has_many)
  - [Nilable resolvers](#nilable-resolvers)
  - [Variant fallback](#variant-fallback)
- [Serializing](#serializing)
  - [From the schema](#from-the-schema)
  - [From the instance](#from-the-instance)
  - [Rendering JSON](#rendering-json)
  - [Context](#context)
- [Queryable attributes](#queryable-attributes)
- [Error handling](#error-handling)
- [License](#license)

---

## Installation

```ruby
gem "api_serializer"
```

Ruby ≥ 3.3. Runtime dependency:
[literal](https://github.com/joeldrapper/literal).

## Quickstart

```ruby
class UserSchema < ApiSerializer::Schema
  serializer :default do
    attribute :id,   Integer
    attribute :name, String
    attribute :role, String, default: "member"
    virtual   :slug, String do |user|
      user.name.downcase.tr(" ", "-")
    end
  end

  deserializer :create do
    attribute :name, String
    attribute :role, _Nilable(String)
  end
end

user = User.new(id: 1, name: "Ada Lovelace", role: "admin")

UserSchema.serializer_for(:default).transform(user).as_json
# => { id: 1, name: "Ada Lovelace", role: "admin", slug: "ada-lovelace" }

UserSchema.deserializer_for(:create).transform(name: "Grace", role: nil).to_h
# => { name: "Grace", role: nil }
```

## Core concepts

- **Schema** — a class that inherits from `ApiSerializer::Schema` and groups
  every way a single resource can be read from or written to the API.
- **Variant** — a named, typed projection defined with `serializer :foo` or
  `deserializer :foo`. One schema can have many.
- **Attribute** — an entry in a variant declared with `attribute`, `virtual`,
  `compose`, `decompose`, `has_one`, or `has_many`.
- **Transformer** — the object that takes input (a model, a hash, anything
  that responds to the declared attribute names or keys) and produces a
  typed output struct matching the variant.

Everything else in the gem — templates, fallback resolvers, queryable
mappings, nested schemas — builds on those four.

## Attributes

### `attribute`

```ruby
attribute :name, type, from: nil, to: nil, default: nil, transform: nil, queryable: nil, &coercer
```

The workhorse. Declares a typed attribute that the transformer will pluck
from the input.

```ruby
attribute :id, Integer
```

Types come from [literal](https://github.com/joeldrapper/literal) — use
`String`, `Integer`, `Float`, `Time`, `Symbol`, etc., plus literal
combinators (`_Nilable(type)`, `_Union(a, b)`, `_Array(type)`, `_Boolean`,
`_Any`). A non-nil `default:` implicitly wraps the type in `_Nilable`.

**`from:` / `to:`** — source/target path on the input object. Supports
`.`-separated nested paths:

```ruby
attribute :email, String, from: "contact.email"
# reads input.contact.email, input[:contact][:email], or a mix.
```

**`default:`** — fallback value when the source path is missing. Automatically
makes the attribute nilable.

**`transform:`** — a proc called with `(value)` or `(value, context)` to
transform the raw value:

```ruby
attribute :created_at, Time, transform: ->(v) { Time.parse(v) }
attribute :tz_aware,   Time, transform: ->(v, ctx) { v.in_time_zone(ctx[:tz]) }
```

**block** — the trailing block is a Literal coercer, run by the type
system to convert / validate the final value:

```ruby
attribute :status, Symbol do |value|
  value.to_sym
end
```

**`queryable:`** — marks the attribute as filterable/sortable. See
[Queryable attributes](#queryable-attributes).

### `virtual`

A computed value with no direct source on the input. Not filterable or
sortable. Block receives the whole input object plus optional context.

```ruby
virtual :full_name, String do |user|
  "#{user.first_name} #{user.last_name}"
end

virtual :local_time, Time do |user, context|
  user.created_at.in_time_zone(context[:tz])
end
```

### `compose`

Combine several source paths into one output attribute via a block.

```ruby
compose :name, String, from: %i[first_name last_name] do |first, last|
  "#{first} #{last}"
end

compose :greeting, String, from: %i[name] do |name, context|
  "#{(context[:locale] == :fr) ? "Bonjour" : "Hi"} #{name}"
end
```

The block arity determines how context is passed: arity `from.size` gets
just the values; arity `from.size + 1` gets the values plus the context
hash.

### `decompose`

The inverse of `compose` — one source, many target attributes. The block
returns an array matching the target names.

```ruby
decompose %i[first_name last_name], String, from: :full_name do |full|
  full.split(" ", 2)
end
```

Path values (with `.`) are not supported as decomposition targets.

## Variants

### `serializer` and `deserializer`

Variants are defined inside a `Schema` subclass. `serializer` and
`deserializer` are identical under the hood — the names are a convention
so that your "model → API" and "API → model" shapes are declared
separately.

```ruby
class ArticleSchema < ApiSerializer::Schema
  serializer :default do
    attribute :id, Integer
    attribute :title, String
    attribute :body, String
  end

  serializer :minimal do
    attribute :id, Integer
    attribute :title, String
  end

  deserializer :create do
    attribute :title, String
    attribute :body, String
  end

  deserializer :update do
    attribute :title, _Nilable(String)
    attribute :body, _Nilable(String)
  end
end

ArticleSchema.serializer_for(:default).transform(article).as_json
ArticleSchema.deserializer_for(:update).transform(params).to_h
```

### Templates and inheritance

`serializer_template` and `deserializer_template` define abstract
variants that can't be used directly but can be inherited from.
`base_template` defines a template usable by both.

```ruby
class PostSchema < ApiSerializer::Schema
  base_template :id_base do
    attribute :id, Integer
  end

  serializer_template :admin_base, inherits: :id_base do
    attribute :created_at, Time
    attribute :updated_at, Time
  end

  serializer :default, inherits: :id_base do
    attribute :title, String
  end

  serializer :admin, inherits: :admin_base do
    attribute :title, String
    attribute :author_id, Integer
  end
end
```

Abstract variants are only inheritable —
`PostSchema.serializer_for(:admin_base)` raises
`VariantNotFoundError`.

### Composing templates

A variant can compose in one or more templates via `composes:`:

```ruby
serializer_template :timestamps do
  attribute :created_at, Time
  attribute :updated_at, Time
end

serializer_template :audit do
  attribute :created_by_id, Integer
  attribute :updated_by_id, Integer
end

serializer :admin, composes: %i[timestamps audit] do
  attribute :id, Integer
  attribute :title, String
end
```

### Looking up variants at runtime

Called without a variant name, `serializer` / `deserializer` return a
`VariantResolver` — a late-binding handle that fetches the variant on
first use. Use this when referring to another schema whose variants may
not be defined yet at class-body evaluation:

```ruby
class CommentSchema < ApiSerializer::Schema
  serializer :default do
    attribute :id, Integer
    # UserSchema may be loaded after us — the resolver defers lookup.
    has_one :author, UserSchema.serializer
  end
end
```

Resolvers optionally take a mapping so the nested schema uses a
different variant than the parent:

```ruby
has_one :author, UserSchema.serializer(full: :minimal, admin: :full)
#                                        ↑ when the parent is rendered
#                                          as :full, render :author as
#                                          :minimal.
```

To ask (without raising) whether a schema has a given variant, use
`Schema.variant?(name, type:)`:

```ruby
UserSchema.variant?(:admin)                    # => true / false
UserSchema.variant?(:create, type: :deserializer)
```

## Associations

### `has_one` and `has_many`

```ruby
serializer :default do
  attribute :id, Integer
  has_one  :author, UserSchema.serializer
  has_many :comments, CommentSchema.serializer
end
```

Both accept `from:`, `to:`, `default:`, `virtual:`, `queryable:` and a
`&coercer` block, plus the serializer/resolver as the second positional
argument. (They do **not** accept `attribute`'s `transform:` option —
associations transform via their own schema's pipeline.)

### Nilable resolvers

Wrap the resolver in `_Nilable(...)` to allow `nil`:

```ruby
has_one :author, _Nilable(UserSchema.serializer)
```

The parent will accept `nil` for the association and produce `nil` in
the output.

### Variant fallback

When the parent is rendered as variant `X`, nested schemas are asked for
variant `X` too. If they don't define it, they fall back through:

```
:nested  →  :minimal  →  :id_only
```

Consumers commonly define `:nested` on every schema as a safe
light-payload fallback. When the resolver can't find any match
(including fallbacks) and the association is `_Nilable`, the field
renders as `nil`. Otherwise it raises `VariantNotFoundError`.

## Serializing

### From the schema

```ruby
transformer = UserSchema.serializer_for(:default)
# => DataTransformer bound to the :default variant
transformer.transform(user)
# => a typed TargetDataStructure instance
```

`serializer_for` returns a `DataTransformer` — a stable, cacheable handle;
`#transform(input)` walks the schema and returns the target struct. If you
already hold a raw `Variant` (e.g. from `Schema.fetch_variant`), its
`#serialize(input, context = {})` / `#deserialize(input, context = {})`
convenience methods wrap the same pipeline.

`transform` accepts an input and an optional context hash:

```ruby
UserSchema.serializer_for(:default).transform(user, { locale: :fr })
```

The input can be any object whose attributes can be accessed by
symbolised name, or any `Hash`-like value indexed by symbol keys. Nested
paths (via `from: "contact.email"`) are walked through the same
interface.

### From the instance

For an object-oriented "serialise this instance" flow, wrap the input in
`ApiSerializer::SerializationContextWrapper`:

```ruby
wrapper = ApiSerializer::SerializationContextWrapper.new(user, UserSchema, { locale: :fr })
wrapper.serialize(:default)
wrapper.deserialize(:create)
```

The [`another_api`](../another_api) Rails engine ships a convenience
`AnotherApi::Serializes` mixin that looks up the schema class by
convention, e.g. `user.serialization.serialize(:default)` — see that
gem's README for details.

### Rendering JSON

The transformer produces a typed struct
(`ApiSerializer::TargetDataStructure`). Call `as_json` (recursive, pure
Ruby, no ActiveSupport) to get a plain Hash of primitives suitable for
any JSON encoder:

```ruby
output = UserSchema.serializer_for(:default).transform(user)
JSON.generate(output.as_json)
# or in a Rails controller:
render json: output.as_json
```

`to_h` gives you a shallow hash — use `as_json` when you have nested
schemas to avoid struct instances leaking into the output.

### Context

Context is an arbitrary hash threaded through the whole transformation.
Used by:

- attribute `transform:` procs with arity 2
- `virtual` blocks with arity 2
- `compose` blocks with arity `from.size + 1`
- nested association serialization (so nested schemas see the same
  context as the parent)

`current_variant_name` is added automatically before nested schemas run,
so downstream resolvers know which variant was requested.

## Queryable attributes

Mark an attribute `queryable:` to expose it to filter/sort mappings
consumed by
[`api_query_language`](https://github.com/stevegeek/another_api/tree/main/api_query_language):

```ruby
attribute :email,      String, queryable: true
attribute :name,       String, queryable: {filter: true, sort: false}
attribute :status,     String, queryable: {filter: true, allowed_values: %w[draft published]}
attribute :created_at, Time,   queryable: {sort: true, filter: false, column: "articles.created_at"}
```

Options (see `ApiSerializer::QueryableConfig`):

| Key | Default | Meaning |
|---|---|---|
| `filter` | `true` | Attribute can be filtered on |
| `sort` | `true` | Attribute can be sorted on |
| `column` | `nil` | Explicit DB column if different from the attribute name |
| `transform` | `nil` | Proc applied to the filter value before it reaches the backend |
| `allowed_values` | `nil` | If set, filter values must be one of these |

Retrieve the mappings with:

```ruby
UserSchema.serializer_for(:default).filtering_mapped_attributes
# => { email: nil, name: nil, status: <QueryableConfig …>, … }

UserSchema.serializer_for(:default).sorting_mapped_attributes
```

Nested associations are expanded into dotted paths (`author.name`,
`comments.created_at`, etc.) up to five levels deep.

## Error handling

All raised errors live in `ApiSerializer::Errors`:

| Error | Raised when |
|---|---|
| `VariantNotFoundError` | `serializer_for(:unknown)` or nested variant fallback exhausted |
| `VariantDefinitionError` | empty variant, invalid `inherits:`, or missing mixin template |
| `AttributeDefinitionError` | `transform:` / `compose` block arity doesn't match the sources |
| `DataTransformError` | input doesn't match the declared attribute types at transform time |

`DataTransformError` wraps Literal's `TypeError` / `ArgumentError` and
includes the offending schema class name in the message — pattern-match
on `e.message` only if you must; otherwise just rescue the class and
render a 400.

## License

MIT. See [`LICENSE.txt`](../LICENSE.txt) at the repository root.
