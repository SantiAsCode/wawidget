const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const helper = {};
vm.createContext(helper);
vm.runInContext(fs.readFileSync(path.join(__dirname, '../contents/ui/ChatStyle.js'), 'utf8').replace(/^\.pragma library\s*/, ''), helper);

const styles = new Map();
const elements = [];
function element(id, width, parent, display = 'block') {
    const result = {id, parentElement: parent, children: [], attrs: {}, display,
        contains(other) { return other === this || this.children.some(child => child.contains(other)); },
        querySelector(selector) { return this.children.flatMap(child => [child, ...descendants(child)]).find(child => '#' + child.id === selector) || null; },
        getBoundingClientRect: () => ({width, height: 600}),
        setAttribute(key, value) { this.attrs[key] = value; },
        removeAttribute(key) { delete this.attrs[key]; }
    };
    if (parent) parent.children.push(result);
    elements.push(result);
    return result;
}
function descendants(element) { return element.children.flatMap(child => [child, ...descendants(child)]); }
const layout = element('layout', 1000, null, 'flex');
const column = element('outer-column', 400, layout);
const inner = element('inner-wrapper', 400, column);
const side = element('side', 400, inner);
const conversation = element('welcome', 600, layout);
const document = {
    documentElement: layout,
    getElementById: id => styles.get(id) || elements.find(element => element.id === id),
    querySelector: selector => elements.find(element => selector === '[data-wawidget-column="' + element.attrs['data-wawidget-column'] + '"]'),
    querySelectorAll: () => elements.filter(element => element.attrs['data-wawidget-column']),
    createElement: () => ({textContent: ''}),
    head: {appendChild: element => styles.set(element.id, element)}
};
const page = vm.createContext({document, window: {}, location: {origin: 'https://web.whatsapp.com'},
    getComputedStyle: element => ({display: element.display, flexDirection: 'row', position: 'relative'}),
    MutationObserver: class { observe() {} disconnect() {} }, requestAnimationFrame: callback => callback()
});
const apply = (narrow, compact, collapsed) => vm.runInContext(helper.script(narrow, compact, collapsed), page);
apply(true, false, false);
assert.match(styles.get('wawidget-style').textContent, /270px/);
assert.doesNotMatch(styles.get('wawidget-style').textContent, /zoom|display:none/);
assert.equal(column.attrs['data-wawidget-column'], 'chats', 'resize the actual outer flex column');
assert.equal(inner.attrs['data-wawidget-column'], undefined, 'do not resize only the inner wrapper');
assert.equal(conversation.attrs['data-wawidget-column'], 'conversation', 'conversation fills reclaimed space even without an open chat');
apply(false, true, false);
assert.match(styles.get('wawidget-style').textContent, /zoom:\.85/);
assert.doesNotMatch(styles.get('wawidget-style').textContent, /270px|display:none/);
apply(false, false, true);
assert.match(styles.get('wawidget-style').textContent, /body:has\(#main\)/);
assert.match(styles.get('wawidget-style').textContent, /display:none/);
apply(true, true, true);
assert.equal(styles.size, 1, 'updates reuse one stylesheet');
apply(false, false, false);
assert.equal(styles.get('wawidget-style').textContent, '', 'disabling everything restores the original presentation');
assert.equal(elements.some(element => element.attrs['data-wawidget-column']), false, 'rollback removes column markers');
page.location.origin = 'https://example.com';
apply(true, true, true);
assert.equal(styles.get('wawidget-style').textContent, '', 'styles never apply to other origins');
console.log('PASS: independent CSS options, rollback and origin restriction (not live WhatsApp selectors)');
