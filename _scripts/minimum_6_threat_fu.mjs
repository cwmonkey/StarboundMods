import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const file = process.argv[2];

const content = fs.readFileSync(file, 'utf8');
console.log(`*** Reading JSON patch: ${file}...`);
console.log(`*** __dirname: ${__dirname}...`);
const contentCleaned = content.replace(/^[\s]*\/\/[^\n\r]*$/mg, '');
const patches = JSON.parse(contentCleaned);
const outputFilePath = __dirname.split('\\').slice(0, -1).join('\\') + "/minimum_6_threat_fu/terrestrial_worlds.config.patch"
console.log(`*** outputFilePath: ${outputFilePath}...`);
let outputPatches = [];

patches.forEach((patch) => {
	if (patch.op === 'add' && patch.path.match(/^\/planetTypes\/[^/]+$/) && patch.value.threatRange[0] < 6) {
		const maxThreat = patch.value.threatRange[1] < 6 ? 6 : patch.value.threatRange[1];
		outputPatches.push({
			"op": "replace",
			"path": patch.path + "/threatRange",
			"value": [6, maxThreat]
		})
	}
});

const output = JSON.stringify(outputPatches, null, 2);

// Write to output file
fs.writeFileSync(outputFilePath, output, 'utf8');

console.log(`Processed ${file}.`);
