import * as fs from 'node:fs';
import {initializeABAP} from "../output/init.mjs";

const [clas, meth, out] = [
  process.argv[2] || "ZCL_PDF_DEMO",
  process.argv[3] || "run_base64",
  process.argv[4] || "preview.pdf",
];

await initializeABAP();

const result = await abap.Classes[clas][meth]();
fs.writeFileSync(out, Buffer.from(result.get(), "base64"));
console.log(`${clas}=>${meth} -> ${out} (${fs.statSync(out).size} bytes)`);
