import * as fs from 'node:fs';
import {initializeABAP} from "../output/init.mjs";

// node test/render.mjs CLASS METHOD out.pdf [file1 file2 ...]
// Extra files are passed to the method as iv_ttf / iv_ttf_bold xstring parameters,
// which is how a real system would hand over a font from SMW0 or a table.
const [clas, meth, out] = [
  process.argv[2] || "ZCL_PDF_DEMO",
  process.argv[3] || "run_base64",
  process.argv[4] || "preview.pdf",
];
const files = process.argv.slice(5);

await initializeABAP();

const params = {};
const names = ["iv_ttf", "iv_ttf_bold"];
files.forEach((path, i) => {
  const hex = fs.readFileSync(path).toString("hex").toUpperCase();
  params[names[i] || `iv_file${i}`] = new abap.types.XString().set(hex);
});

const result = await abap.Classes[clas][meth](Object.keys(params).length ? params : undefined);
fs.writeFileSync(out, Buffer.from(result.get(), "base64"));
console.log(`${clas}=>${meth} -> ${out} (${fs.statSync(out).size} bytes)`);
