// Prints out a block of text matching number of chars
// and the number per line
// Usage:
//  deno run how_many_chars.ts 120 10
//  # prints 120 with 10 per line

const total: number = Number(Deno.args[0])
const width: number = Number(Deno.args[1])
const char = "a"

for (let i: number = 0; (total - (width * i)) > 0; i++) {
  let needed = total - (width * i)
  console.log("a".repeat(Math.min(needed, width)))
}