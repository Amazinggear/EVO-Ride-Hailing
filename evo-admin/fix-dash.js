const fs = require('fs');
let content = fs.readFileSync('src/app/dashboard/page.tsx', 'utf8');
const lines = content.split('\n');
let chartLine = -1;
for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes('CHARTS & REPORTS')) { chartLine = i; break; }
}
const newEnd = [
'      {/* PLACEHOLDER — real charts when rides start */}',
'      <div className="bg-card rounded-3xl p-8 border border-white/5 shadow-lg text-center">',
'        <div className="text-5xl mb-4">📊</div>',
'        <h3 className="text-white font-bold text-lg mb-2">الرسوم البيانية والتقارير</h3>',
'        <p className="text-gray-400 text-sm">ستظهر المخططات فور بدء استقبال الرحلات.</p>',
'      </div>',
'    </div>',
'  );',
'}',
'',
];
lines.splice(chartLine, lines.length - chartLine, ...newEnd);
fs.writeFileSync('src/app/dashboard/page.tsx', lines.join('\n'));
console.log('Done. Lines: ' + lines.length);
