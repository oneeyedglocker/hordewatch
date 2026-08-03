#!/bin/bash
# Rebuild the Ping poster from poster-copy.txt.
# Usage: ./build-poster.sh
#
# Reads the copy sheet, fills the template, measures the real content height so
# the canvas never has a dead strip at the bottom, and renders at 2x.
set -e
cd "$(dirname "$0")"

python3 - <<'PY'
import re, html
copy = {}
for line in open('poster-copy.txt'):
    line = line.rstrip('\n')
    if not line.strip() or line.lstrip().startswith('#'):
        continue
    if '=' not in line:
        raise SystemExit("line has no '=': " + line)
    k, v = line.split('=', 1)
    copy[k.strip()] = v.strip()

s = open('poster-template.html').read()

# A feature the copy sheet leaves out is removed from the poster rather than
# treated as an error - dropping one is an edit, not a mistake.
for n in range(1, 7):
    if 'F%d_TITLE' % n not in copy:
        s, k = re.subn(r'\s*<div class="feat">(?:(?!</div></div>).)*?\{\{F%d_TITLE\}\}.*?</div></div>' % n,
                       '', s, count=1, flags=re.S)
        if k: print('dropped feature F%d' % n)

needed = set(re.findall(r'\{\{(\w+)\}\}', s))
missing = needed - set(copy)
extra   = set(copy) - needed
if missing: raise SystemExit("copy sheet is missing: " + ", ".join(sorted(missing)))
if extra:   raise SystemExit("copy sheet has keys the poster does not use: " + ", ".join(sorted(extra)))

for k, v in copy.items():
    # escape the text, then let a literal em dash through as-is
    s = s.replace('{{%s}}' % k, html.escape(v, quote=False))
open('poster-built.html', 'w').write(s)
print("filled %d strings" % len(copy))
PY

NODE_PATH=/opt/node22/lib/node_modules node -e "
const {chromium}=require('playwright');
(async()=>{
  const b=await chromium.launch();
  // measure first, at 1x
  let p=await b.newPage({viewport:{width:1320,height:1400},deviceScaleFactor:1});
  await p.goto('file://'+process.cwd()+'/poster-built.html');
  await p.waitForTimeout(900);
  const h=await p.evaluate(()=>{
    const P=document.querySelector('#B'), t=P.getBoundingClientRect().top;
    let m=0;
    P.querySelectorAll('.more .feat,.cols .sub,.cols img')
     .forEach(e=>m=Math.max(m,e.getBoundingClientRect().bottom-t));
    return Math.ceil(m);
  });
  await p.evaluate(h=>document.querySelector('#B').style.height=(h+52)+'px', h);
  await p.close();
  // render at 2x with the corrected height baked in
  p=await b.newPage({viewport:{width:1320,height:1400},deviceScaleFactor:2});
  await p.goto('file://'+process.cwd()+'/poster-built.html');
  await p.waitForTimeout(900);
  await p.evaluate(h=>document.querySelector('#B').style.height=(h+52)+'px', h);
  await p.locator('#B').screenshot({path:'ping-poster.png'});
  await b.close();
  console.log('rendered ping-poster.png at height '+(h+52)+'css');
})();
"
python3 -c "
from PIL import Image
im=Image.open('ping-poster.png')
print('%dx%d  %.2f:1' % (im.size[0], im.size[1], im.size[0]/im.size[1]))"
