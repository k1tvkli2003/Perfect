"""Isolated Stage 13 HTML design geometry checks; never tests Flutter runtime."""
import hashlib
import json
from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/design/07-task-row-stage13'
HTML = OUT / 'status-plates.html'
CHECK = r'''() => {
 const rect = e => {const r=e.getBoundingClientRect();return {x:r.x,y:r.y,right:r.right,bottom:r.bottom,width:r.width,height:r.height}};
 const rows=[...document.querySelectorAll('.row')];
 const controls=[...document.querySelectorAll('.status,.details')];
 const small=controls.filter(e=>{const r=rect(e);return r.width<47.5||r.height<47.5}).map(e=>e.getAttribute('aria-label'));
 const intersects=(a,b)=>Math.min(a.right,b.right)-Math.max(a.x,b.x)>1&&Math.min(a.bottom,b.bottom)-Math.max(a.y,b.y)>1;
 const overlaps=rows.filter(row=>{const a=rect(row.querySelector('.status')),b=rect(row.querySelector('.details')),c=rect(row.querySelector('.copy')),r=rect(row);return intersects(a,b)||intersects(a,c)||intersects(b,c)||c.x<r.x-1||c.right>r.right+1||c.bottom>r.bottom+1}).map(row=>row.querySelector('.title').textContent);
 const clipped=[...document.querySelectorAll('.row .title')].filter(e=>e.scrollWidth>e.clientWidth+1||e.scrollHeight>e.clientHeight+1).map(e=>e.textContent);
 return {plates:document.querySelectorAll('[data-plate]').length,rows:rows.length,controls:controls.length,
   overdue:!!document.querySelector('[data-fixture="overdue"]'),recurring:!!document.querySelector('[data-fixture="recurring"]'),rtl:!!document.querySelector('[data-fixture="rtl"]'),
   horizontalOverflow:document.documentElement.scrollWidth>innerWidth+1, small,overlaps,clipped};
}'''


def main():
    receipts=[]
    with sync_playwright() as p:
        browser=p.chromium.launch(channel='msedge',headless=True)
        try:
            page=browser.new_page()
            for width,height,scale in [(320,700,1),(390,844,1),(800,900,1),(1366,900,1),(390,844,2)]:
                page.set_viewport_size({'width':width,'height':height})
                page.goto(HTML.as_uri())
                page.evaluate('document.fonts.ready')
                if scale == 2:
                    page.evaluate('document.documentElement.dataset.textScale="200"')
                check=page.evaluate(CHECK)
                passed=check['plates']==9 and check['rows']==13 and check['controls']==38 and check['overdue'] and check['recurring'] and check['rtl'] and not any(check[k] for k in ('horizontalOverflow','small','overlaps','clipped'))
                id=f'{width}x{height}-scale{scale}'
                receipts.append({'id':id,'passed':passed,'geometry':check})
                print(id,'PASS' if passed else 'FAIL',json.dumps(check),flush=True)
                if scale==1 and width in (390,1366):
                    name='phone' if width==390 else 'desktop'
                    page.screenshot(path=str(OUT/f'status-plates-{name}.png'),full_page=True)
                if scale==2:
                    page.screenshot(path=str(OUT/'status-plates-390-text200.png'),full_page=True)
        finally:
            browser.close()
    receipt={'kind':'static-design-geometry-not-Flutter-runtime','preview_sha256':hashlib.sha256(HTML.read_bytes()).hexdigest(),'cases':receipts}
    (OUT/'browser-verification-v2.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('RESULT',sum(r['passed'] for r in receipts),'/',len(receipts),flush=True)
    return 0 if all(r['passed'] for r in receipts) else 1

if __name__=='__main__':
    raise SystemExit(main())
