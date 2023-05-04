await Deno.stderr.write(new TextEncoder().encode("Bad Exit"))
Deno.exit(5)