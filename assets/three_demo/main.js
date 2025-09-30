import * as THREE from 'three';
import { OrbitControls } from './controls/OrbitControls.js';

const canvas = document.getElementById('app');

// ---------- Renderer: cheaper defaults on mobile ----------
const renderer = new THREE.WebGLRenderer({
  canvas,
  antialias: false,                 // MSAA is expensive on tiled mobile GPUs
  alpha: false,
  powerPreference: 'high-performance',
  preserveDrawingBuffer: false
});

// Clamp devicePixelRatio to keep fill-rate under control
function effectiveDPR() {
  const dpr = window.devicePixelRatio || 1;
  return Math.min(dpr, 1.25);       // 1.0–1.5 is a good range for phones
}
renderer.setPixelRatio(effectiveDPR());

// Set only the drawing buffer size (no layout thrash)
renderer.setSize(window.innerWidth, window.innerHeight, false);

// Modern color pipeline (cheap)
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.NoToneMapping;

// ---------- Scene ----------
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x20232a);

// ---------- Camera ----------
const camera = new THREE.PerspectiveCamera(
  60,
  window.innerWidth / window.innerHeight,
  0.1,
  100
);
camera.position.set(2, 1.5, 3);

// ---------- Lights ----------
const dir = new THREE.DirectionalLight(0xffffff, 1);
dir.position.set(1, 2, 3);
scene.add(dir, new THREE.AmbientLight(0xffffff, 0.25));

// Avoid shadows on mobile unless you really need them
renderer.shadowMap.enabled = false;
// dir.castShadow = false;

// ---------- Content ----------
const mesh = new THREE.Mesh(
  new THREE.BoxGeometry(1, 1, 1),
  new THREE.MeshStandardMaterial({ color: 0x00a2ff, metalness: 0.2, roughness: 0.6 })
);
scene.add(mesh);

// ---------- Controls ----------
const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;      // adds a small integrator but looks nicer
controls.dampingFactor = 0.08;

// ---------- Resize (debounced + DPR aware) ----------
let resizeT;
function handleResizeNow() {
  // Recompute DPR (user can change it in settings or when moving between screens)
  renderer.setPixelRatio(effectiveDPR());
  renderer.setSize(window.innerWidth, window.innerHeight, false);
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
}
function onResize() {
  clearTimeout(resizeT);
  resizeT = setTimeout(handleResizeNow, 100); // debounce to avoid burst work
}
addEventListener('resize', onResize, { passive: true });

// ---------- Visibility: pause when not visible ----------
let running = true;
function onVisibilityChange() {
  running = !document.hidden;
  if (running) requestAnimationFrame(tick);
}
document.addEventListener('visibilitychange', onVisibilityChange);

// ---------- (Optional) FPS cap to reduce battery/heat ----------
// Set to null for uncapped; e.g., 45 for a softer target.
const TARGET_FPS = null; // or 45
const frameInterval = TARGET_FPS ? 1000 / TARGET_FPS : 0;
let lastTime = performance.now();

// ---------- Context loss handling ----------
canvas.addEventListener('webglcontextlost', (e) => {
  e.preventDefault();
  running = false;
});
canvas.addEventListener('webglcontextrestored', () => {
  running = true;
  requestAnimationFrame(tick);
});

// ---------- Render loop ----------
function render() {
  controls.update();
  renderer.render(scene, camera);
}

function tick(now = performance.now()) {
  if (!running) return;

  if (!TARGET_FPS || (now - lastTime) >= frameInterval) {
    mesh.rotation.y += 0.01;
    render();
    lastTime = now;
  }
  requestAnimationFrame(tick);
}
requestAnimationFrame(tick);
