import { pathToFileURL } from 'url';
import { readFileSync } from 'fs';
import CoffeeScript from "coffeescript"
import "coffeescript/register.js"

const baseURL = pathToFileURL(process.cwd() + '/').href;
const extensionsRegex = /\.coffee$/;

export async function resolve(specifier, context, defaultResolve) {
  const { parentURL = baseURL } = context;

  if (extensionsRegex.test(specifier)) {
    return {
      url: new URL(specifier, parentURL).href
    };
  }

  // Let Node.js handle all other specifiers.
  return defaultResolve(specifier, context, defaultResolve);
}

export async function load(url, context, defaultLoad) {
  if (extensionsRegex.test(url)) {
    const source = readFileSync(url, "utf8")
    const nodes = CoffeeScript.compile(source, {
      ast: true,
      bare: true,
      header: false,
    })

    //@ts-ignore
    const isModule = nodes.program.body.some((node) =>
      node.importKind || node.exportKind
    )

    if (isModule) {
      return {
        format: "module",
        source: CoffeeScript.compile(source, {
          bare: true,
          header: false,
        })
      }
    } else {
      return { format: "commonjs" };
    }

  }

  // Let Node.js handle all other URLs.
  return defaultLoad(url, context, defaultLoad);
}
