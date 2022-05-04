Notes
=====

Types in CoffeeScript Projects
----

TypeScript is a pretty good documentation tool (not a great type system). It has
strong support in VSCode. The goal of adding types is to get the Intellisense
support for functions when programming in VSCode. A secondary goal would be to
have a nice documentation reference/website.

TypeDoc can publish an ok website from `.ts` files including `.d.ts` files.

`types/types.d.ts` is the "source of truth" for all the documentation. It makes
it easy to publish to npm (no extra build step!) but the downside is that the
types need to be imported in the CoffeeScript files where they are implemented.

TypeScript Classes vs. Constructor Functions
----

JSDoc style type hints don't work well with classes and would need to be
duplicated between the types and the implementations in `.coffee` files.

Using explicit constructor functions works pretty well but is slightly wonky in
the types since they need both a `new (...): ...` and `(...): ...` signature.
The non-new signature works when setting `AdHocEntity = ->` and the `new`
signature is when the constructor is called with new.

Debug Node.js using Chrome Dev Tools with `--inspect-brk`
----

https://nodejs.org/en/docs/guides/debugging-getting-started/

```bash
node --inspect-brk
```


Add arguments to shebang line
----

https://unix.stackexchange.com/questions/399690/multiple-arguments-in-shebang

```
#!/usr/bin/env -S node --inspect-brk
```

CoffeeScript Source Maps in Node.js
----

### How do they work?

CoffeeScript compiles files with source maps, Node.js ignores them generally
but CoffeeScript monkey patches `Error.prepareStackTrace` to get them into Node.

https://coffeescript.org/annotated-source/coffeescript.html#section-38

### Visualize Source Maps

https://sokra.github.io/source-map-visualization/

https://evanw.github.io/source-map-visualization/


### How to add them to CoffeeCoverage

Essentially copy exactly how CoffeeScript does it down to using their same
helpers.

```coffee
# this isn't exposed publicly
SourceMap = require('coffeescript/lib/coffeescript/sourcemap')

map = new SourceMap

ast.compileToFragments

for fragment in fragments
  map.add
  js += fragment.code

# This is critical to hook into CoffeeScript's `Error.prepareStackTrace` hack
CoffeeScript.registerCompiled fileName, source, map
```

Adding the inline source map isn't necessary and doesn't have any effect in
Node.js but may become necessary at some point in the future if
`Error.prepareStackTrace` gets phased out in favor of the `--enable-source-maps`
cli option.

Also needed to return the init code combined in JS as well as separately in
coffeeCoverage.coffee and update the places where it is called.

CoffeeScript IntelliSense
----

https://marketplace.visualstudio.com/items?itemName=phil294.coffeesense

GitHub Actions
----

https://docs.github.com/en/actions/quickstart

### Environment Variables

Make sure to name the environment in the .yml file that matches the environment
set up when creating the secrets.

```yaml
  environment: deploy
```

https://bloggie.io/@_junrong/using-environment-variables-secrets-in-github-actions
https://zellwk.com/blog/debug-github-actions-secret/
