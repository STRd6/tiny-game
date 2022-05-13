import assertType from "assert"

declare global {
  // Test helpers
  var assert: typeof assertType;
}

import { util } from "./types";

type a = util.mapBehaviors
