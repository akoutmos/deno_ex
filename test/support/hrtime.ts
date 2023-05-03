// Used to test high resolution time

import {hrtime} from "https://deno.land/std@0.177.0/node/process.ts"
let [something, time] = hrtime()
console.log(time)