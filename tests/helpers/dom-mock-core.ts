const GAME_WIDTH = 1280;
const GAME_HEIGHT = 720;

let installed = false;

const noop = (): void => {};

export function installMinimalDom(): void {
  if (installed) return;
  installed = true;

  const imageData = { data: new Uint8ClampedArray([0, 0, 0, 0]) };

  const ctx = {
    fillRect: noop,
    clearRect: noop,
    getImageData: () => imageData,
    putImageData: noop,
    createImageData: () => imageData,
    setTransform: noop,
    drawImage: noop,
    save: noop,
    restore: noop,
    beginPath: noop,
    moveTo: noop,
    lineTo: noop,
    closePath: noop,
    stroke: noop,
    translate: noop,
    scale: noop,
    rotate: noop,
    arc: noop,
    fill: noop,
    measureText: () => ({ width: 80 }),
    transform: noop,
    rect: noop,
    clip: noop,
    fillText: noop,
    strokeText: noop,
    canvas: { width: GAME_WIDTH, height: GAME_HEIGHT },
  };

  class MockElement {
    id = '';
    style: Record<string, string> = {};
    children: MockElement[] = [];
    parent: MockElement | null = null;
    tagName = 'DIV';
    ownerDocument = documentRef;

    appendChild(child: MockElement): MockElement {
      child.parent = this;
      child.ownerDocument = documentRef;
      this.children.push(child);
      return child;
    }

    remove(): void {
      if (this.parent) {
        this.parent.children = this.parent.children.filter((c) => c !== this);
      }
    }

    querySelectorAll(selector: string): MockElement[] {
      if (selector === 'canvas') {
        return this.children.filter((c) => c.tagName === 'CANVAS');
      }
      return [];
    }

    getElementsByTagName(tag: string): MockElement[] {
      const wanted = tag.toUpperCase();
      const out: MockElement[] = [];
      const walk = (el: MockElement) => {
        if (el.tagName === wanted) out.push(el);
        for (const child of el.children) walk(child);
      };
      walk(this);
      return out;
    }

    getContext(): typeof ctx {
      return ctx;
    }

    setAttribute(): void {}
    getAttribute(): string | null {
      return null;
    }

    addEventListener(): void {}
    removeEventListener(): void {}
  }

  let documentRef!: {
    body: MockElement;
    documentElement: MockElement;
    createElement: (tag: string) => MockElement;
    getElementById: (id: string) => MockElement | null;
    getElementsByTagName: (tag: string) => MockElement[];
    addEventListener: () => void;
    removeEventListener: () => void;
  };

  class MockCanvas extends MockElement {
    tagName = 'CANVAS';
    width = GAME_WIDTH;
    height = GAME_HEIGHT;
  }

  const body = new MockElement();
  const html = new MockElement();
  html.appendChild(body);

  documentRef = {
    body,
    documentElement: html,
    createElement: (tag: string) => {
      if (tag.toLowerCase() === 'canvas') return new MockCanvas();
      const el = new MockElement();
      el.tagName = tag.toUpperCase();
      return el;
    },
    getElementById: (id: string) => {
      const find = (el: MockElement): MockElement | null => {
        if (el.id === id) return el;
        for (const child of el.children) {
          const hit = find(child);
          if (hit) return hit;
        }
        return null;
      };
      return find(body);
    },
    getElementsByTagName: (tag: string) => html.getElementsByTagName(tag),
    addEventListener: noop,
    removeEventListener: noop,
  };

  const document = documentRef;
  body.ownerDocument = documentRef;
  html.ownerDocument = documentRef;

  const window = {
    document,
    innerWidth: GAME_WIDTH,
    innerHeight: GAME_HEIGHT,
    devicePixelRatio: 1,
    addEventListener: noop,
    removeEventListener: noop,
    requestAnimationFrame: (cb: FrameRequestCallback) => setTimeout(() => cb(Date.now()), 16),
    cancelAnimationFrame: (id: ReturnType<typeof setTimeout>) => clearTimeout(id),
    navigator: { userAgent: 'node.js' },
    location: { href: 'http://localhost/' },
    screen: { width: GAME_WIDTH, height: GAME_HEIGHT },
    getComputedStyle: () => ({ getPropertyValue: () => '' }),
  };

  const windowRef = window as unknown as Window & typeof globalThis;
  (globalThis as typeof globalThis & { window: typeof window }).window = windowRef;
  (globalThis as typeof globalThis & { self: typeof self }).self = windowRef;
  (globalThis as typeof globalThis & { document: typeof document }).document =
    document as unknown as Document;
  (globalThis as typeof globalThis & { HTMLElement: typeof HTMLElement }).HTMLElement =
    MockElement as unknown as typeof HTMLElement;
  (globalThis as typeof globalThis & { HTMLCanvasElement: typeof HTMLCanvasElement }).HTMLCanvasElement =
    MockCanvas as unknown as typeof HTMLCanvasElement;

  class MockImage {
    onload: (() => void) | null = null;
    onerror: (() => void) | null = null;
    src = '';
    width = 0;
    height = 0;
    addEventListener(): void {}
    removeEventListener(): void {}
  }

  (globalThis as typeof globalThis & { Image: typeof Image }).Image =
    MockImage as unknown as typeof Image;

  if (typeof globalThis.performance === 'undefined') {
    (globalThis as typeof globalThis & { performance: Performance }).performance = {
      now: () => Date.now(),
    } as Performance;
  }
}
