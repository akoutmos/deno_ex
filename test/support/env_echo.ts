// This is used to test access to environment variables.
// It prints the environment variable id and value to
// STDOUT.

const env_name = Deno.args[0]
const env_value = Deno.env.get(env_name)

console.log(env_name + " " + env_value)
