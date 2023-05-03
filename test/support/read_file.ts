// Tests reading a file
// Takes the name of a file and contents to write
// usage:
//  deno run --allow-read read_file.ts filename.txt

const filename = Deno.args[0]
const text = await Deno.readTextFile(filename)
console.log(text)