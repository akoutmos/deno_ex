// Tests writing a file
// Takes the name of a file and contents to write
// usage:
//  deno run --allow-write write_file.ts filename.txt hello

const file = Deno.args[0]
const content = Deno.args[1]
await Deno.writeTextFile(file, content)
console.log("File written " + file + " with " + content)