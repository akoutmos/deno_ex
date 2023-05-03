// tests for network capabilities
// usage
// deno run network.ts hostname port

const hostname = Deno.args[0]
const port = Number(Deno.args[1])

const listener = Deno.listen({hostname, port})
listener.close()
console.log("network connection worked")