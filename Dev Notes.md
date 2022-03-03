Notes
=====

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
