"""Serial local Chromium design checks; no model/API, no owner data."""
import hashlib
import json
from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/codex/2026-07-27-perfect-orbit-day-private-planner-rebuild/design/05-runtime-comparisons/stage12-today-stream/responsive-v2'
CHECK = r'''() => {
 const rect=e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,bottom:r.bottom,right:r.right}};
 const visible=e=>e.getClientRects().length && getComputedStyle(e).visibility!=='hidden';
 const controls=[...document.querySelectorAll('button,input,a')].filter(visible);
 const clip=[...document.querySelectorAll('h1,h2,h3,p,.copy,button,.capture')].filter(visible).filter(e=>e.scrollWidth>e.clientWidth+1).map(e=>e.className||e.tagName);
 const small=controls.filter(e=>{const r=rect(e);return r.width<47||r.height<47}).map(e=>e.getAttribute('aria-label')||e.textContent);
 const s=document.querySelector('.content-scroll'), sr=rect(s), footer=rect(document.querySelector('#footer'));
 const rows=[...document.querySelectorAll('[data-row-id]')];
 const last=rows.length?rect(rows.at(-1)):null;
 const capture=rect(document.querySelector('#capture'));
 const overlaps=rows.filter(e=>{const copy=rect(e.querySelector('.copy')),action=rect(e.querySelector('.details'));return copy.right>action.x+1 && copy.x<action.right-1}).map(e=>e.dataset.rowId);
 return {viewport:[innerWidth,innerHeight],horizontalOverflow:document.documentElement.scrollWidth>innerWidth+1,clip,small,overlaps,footer,capture,scroll:sr,last,lastReachable:!last||(last.bottom<=sr.bottom+1&&last.y>=sr.y-1),captureReachable:capture.y>=0&&capture.bottom<=innerHeight+1&&capture.right<=innerWidth+1,footerClear:sr.bottom<=footer.y+1,imagesLoaded:[...document.images].every(i=>i.complete&&i.naturalWidth>0)};
}'''

def main():
    manifest=json.loads((OUT/'matrix.json').read_text())
    receipts=[]
    with sync_playwright() as p:
        browser=p.chromium.launch(channel='msedge',headless=True)
        try:
            page=browser.new_page()
            for c in manifest['cases']:
                page.set_viewport_size({'width':c['width'],'height':c['height']})
                page.goto((OUT/c['file']).as_uri())
                page.evaluate('document.fonts.ready')
                page.screenshot(path=str(OUT/(c['id']+'-top.png')))
                page.locator('.content-scroll').evaluate('(e)=>e.scrollTop=e.scrollHeight')
                check=page.evaluate(CHECK)
                page.screenshot(path=str(OUT/(c['id']+'-end.png')))
                passed=not(check['horizontalOverflow'] or check['clip'] or check['small'] or check['overlaps']) and all(check[k] for k in ['lastReachable','captureReachable','footerClear','imagesLoaded'])
                receipts.append({'id':c['id'],'passed':passed,'geometry':check,'html_sha256':hashlib.sha256((OUT/c['file']).read_bytes()).hexdigest()})
                (OUT/'browser-verification.json').write_text(json.dumps({'kind':'mock-browser-geometry-not-visual-acceptance','cases':receipts},indent=2))
                print(c['id'], 'PASS' if passed else 'FAIL', '' if passed else json.dumps(check),flush=True)
        finally:
            browser.close()
    print('RESULT',sum(r['passed'] for r in receipts),'/',len(receipts),flush=True)
    return 0 if all(r['passed'] for r in receipts) else 1
if __name__=='__main__':
    raise SystemExit(main())
