const fs = require('fs');
const html = fs.readFileSync('src-ui/index.html', 'utf8');

const regex = /<label[^>]*class="app-card[^"]*"[^>]*>/g;
let match;
let count = 0;
let withAppId = 0;
const missing = [];

while ((match = regex.exec(html)) !== null) {
    count++;
    const tag = match[0];
    if (tag.includes('data-app-id="')) {
        withAppId++;
    } else {
        missing.push(tag);
    }
}

console.log(`Total app cards found: ${count}`);
console.log(`Cards with data-app-id: ${withAppId}`);
if (missing.length > 0) {
    console.log('Cards missing data-app-id:');
    missing.forEach(m => console.log(m));
} else {
    console.log('ALL cards have data-app-id! 100% SUCCESS.');
}
