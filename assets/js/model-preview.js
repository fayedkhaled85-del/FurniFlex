import * as THREE from './three.module.js';
import { GLTFLoader } from './loaders/GLTFLoader.js';
import { OrbitControls } from './OrbitControls.js';
import { RoomEnvironment } from './RoomEnvironment.js';

const loader = new GLTFLoader();
const arrangements = {
  1: { frame:[[0,.26,0]], left_arm:[[-.79,.67,0]], right_arm:[[.79,.67,0]], backrest:[[0,.71,-.29]], seat_cushion:[[-.44,.51,.07],[0,.51,.07],[.44,.51,.07]], sofa_leg:[[-.86,.08,-.34],[.86,.08,-.34],[-.86,.08,.34],[.86,.08,.34]] },
  2: { table_top:[[0,.45,0]], table_leg:[[-.56,.20,-.31],[.56,.20,-.31],[-.56,.20,.31],[.56,.20,.31]], table_brace:[[0,.24,0]] },
  8: { wardrobe_frame:[[0,1.1,0]], wardrobe_door:[[-.39,1.1,.32],[.39,1.1,.32]], wardrobe_drawer:[[0,.32,.32],[0,.60,.32],[0,.88,.32]], wardrobe_shelf:[[0,.44,0],[0,.78,0],[0,1.45,0],[0,1.78,0]], wardrobe_divider:[[0,1.1,0]], wardrobe_handle:[[-.18,1.1,.38],[.18,1.1,.38],[-.58,1.1,.38],[.58,1.1,.38]], wardrobe_foot:[[-.72,.06,-.25],[.72,.06,-.25],[-.72,.06,.25],[.72,.06,.25]] }
};

// Cards share one temporary WebGL context at a time; detail viewers remain interactive.
let cardQueue = Promise.resolve();
document.querySelectorAll('.product-card img:not(.preview-fallback), img.product-detail, img.preview-fallback').forEach(image => {
  image.addEventListener('error', () => replaceBrokenImage(image), {once:true});
});
document.querySelectorAll('.furniflex-3d-preview').forEach(host => {
  setPreviewState(host, 'loading');
  if (host.classList.contains('model-preview-card')) {
    cardQueue = cardQueue.then(() => renderPreview(host)).catch(error => showFailure(host, error));
  } else {
    renderPreview(host).catch(error => showFailure(host, error));
  }
});

async function renderPreview(host) {
  const canvas = host.querySelector('canvas');
  const url = host.dataset.modelUrl;
  if (!canvas || !url) throw new Error('Preview canvas or model URL is missing.');
  ensurePreviewFallback(host);

  const isCard = host.classList.contains('model-preview-card');
  let renderer = null;
  let pmrem = null;
  let environmentTarget = null;
  let scene = null;
  let controls = null;
  let resizeObserver = null;
  let animationFrame = 0;
  let stopped = false;
  try {
    renderer = new THREE.WebGLRenderer({ canvas, antialias:true, alpha:isCard, preserveDrawingBuffer:isCard });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, isCard ? 1 : 1.75));
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1;

    scene = new THREE.Scene();
    scene.background = isCard ? null : new THREE.Color('#f3ece2');
    const camera = new THREE.PerspectiveCamera(34, 1, .01, 100);
    scene.add(new THREE.HemisphereLight(0xffffff, 0x897967, 2.1));
    const key = new THREE.DirectionalLight(0xfff3e1, 3);
    key.position.set(3, 5, 4);
    key.castShadow = true;
    scene.add(key);
    const fill = new THREE.DirectionalLight(0xffffff, 1.5);
    fill.position.set(-4, 2, -3);
    scene.add(fill);
    const floor = new THREE.Mesh(new THREE.PlaneGeometry(12, 12), new THREE.MeshStandardMaterial({color:'#eae1d5', roughness:1}));
    floor.rotateX(-Math.PI / 2);
    scene.add(floor);
    pmrem = new THREE.PMREMGenerator(renderer);
    const room = new RoomEnvironment();
    environmentTarget = pmrem.fromScene(room, .04);
    scene.environment = environmentTarget.texture;
    safely(() => disposeObjectTree(room));

    if (!isCard) {
      controls = new OrbitControls(camera, canvas);
      controls.enableDamping = true;
      controls.target.set(0, .8, 0);
      controls.minDistance = 1.2;
      controls.maxDistance = 8;
      controls.maxPolarAngle = Math.PI * .48;
    }

    const fit = () => {
      const width = host.clientWidth;
      const height = host.clientHeight;
      if (!width || !height) return;
      renderer.setSize(width, height, false);
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
    };
    resizeObserver = new ResizeObserver(fit);
    resizeObserver.observe(host);
    fit();

    const gltf = await loader.loadAsync('/FurniFlex/' + url);
    const model = new THREE.Group();
    const source = gltf.scene;
    const productId = Number(host.dataset.productId);
    const layout = arrangements[productId] || {};
    if ([1, 2, 3, 4, 5].includes(productId)) {
      // These products use finished, locally stored GLBs whose source meshes
      // are already assembled in product coordinates. Preview that exact scene.
      const assembled = source.clone(true);
      assembled.traverse(object => {
        if (object.isMesh) {
          object.castShadow = true;
          object.receiveShadow = true;
        }
      });
      model.add(assembled);
    } else {
      for (const [key, positions] of Object.entries(layout)) {
        let template;
        source.traverse(node => {
          if (node.userData?.component_key === key || node.name === `FFX_component:${key}`) template = node;
        });
        if (!template) continue;
        for (const position of positions) {
          const part = template.clone(true);
          part.position.set(...position);
          part.traverse(object => {
            if (object.isMesh) {
              object.castShadow = true;
              object.receiveShadow = true;
            }
          });
          model.add(part);
        }
      }
    }

    const meshCount = countMeshes(model);
    if (!meshCount) throw new Error('The GLB has no mapped mesh components for this product.');
    const bounds = new THREE.Box3().setFromObject(model);
    const size = bounds.getSize(new THREE.Vector3());
    const center = bounds.getCenter(new THREE.Vector3());
    const max = Math.max(size.x, size.y, size.z);
    camera.position.copy(center).add(new THREE.Vector3(max * 1.65, max * 1.1, max * 2.05));
    camera.near = Math.max(.01, max / 100);
    camera.far = max * 30;
    camera.lookAt(center);
    camera.updateProjectionMatrix();
    if (controls) {
      controls.target.copy(center);
      controls.update();
    }
    scene.add(model);

    if (isCard) {
      renderer.render(scene, camera);
      const dataUrl = canvas.toDataURL('image/webp', .9);
      const thumbnail = await validateThumbnail(dataUrl);
      const productName = host.dataset.productName
        || host.closest('.product-card')?.querySelector('h5')?.textContent?.trim()
        || host.closest('.row')?.querySelector('h1')?.textContent?.trim()
        || `product ${productId}`;
      thumbnail.alt = `3D preview of ${productName}`;
      thumbnail.className = 'model-preview-generated';

      // Swap the still-visible fallback only after the rendered image decodes and passes validation.
      ensurePreviewFallback(host);
      host.append(thumbnail);
      // Resolve the thumbnail's pre-transition state before exposing it.
      thumbnail.getBoundingClientRect();
      canvas.remove();
      setPreviewState(host, 'loaded');
      host.querySelector('.model-loading')?.remove();
      cleanupRenderer({renderer, pmrem, environmentTarget, scene, controls, resizeObserver});
      return;
    }

    renderer.render(scene, camera);
    setPreviewState(host, 'loaded');
    host.querySelector('.model-loading')?.remove();
    const animate = () => {
      if (stopped) return;
      if (!host.isConnected) {
        stopped = true;
        cleanupRenderer({renderer, pmrem, environmentTarget, scene, controls, resizeObserver});
        return;
      }
      animationFrame = requestAnimationFrame(animate);
      try {
        controls?.update();
        renderer.render(scene, camera);
        if (renderer.getContext().isContextLost()) throw new Error('WebGL context was lost during model rendering.');
      } catch (error) {
        stopped = true;
        cancelAnimationFrame(animationFrame);
        cleanupRenderer({renderer, pmrem, environmentTarget, scene, controls, resizeObserver});
        showFailure(host, error);
      }
    };
    animate();
  } catch (error) {
    stopped = true;
    if (animationFrame) cancelAnimationFrame(animationFrame);
    cleanupRenderer({renderer, pmrem, environmentTarget, scene, controls, resizeObserver});
    throw error;
  }
}

async function validateThumbnail(dataUrl) {
  if (typeof dataUrl !== 'string' || !/^data:image\/(?:webp|png);base64,/.test(dataUrl) || dataUrl.length < 512) {
    throw new Error('Rendered thumbnail data is missing or incomplete.');
  }
  const image = new Image();
  image.src = dataUrl;
  if (typeof image.decode === 'function') await image.decode();
  else await new Promise((resolve, reject) => {
    image.onload = resolve;
    image.onerror = () => reject(new Error('Rendered thumbnail could not be decoded.'));
  });
  if (image.naturalWidth < 64 || image.naturalHeight < 64) throw new Error('Rendered thumbnail has invalid dimensions.');

  const probe = document.createElement('canvas');
  probe.width = 24;
  probe.height = 24;
  const context = probe.getContext('2d', {willReadFrequently:true});
  if (!context) throw new Error('Thumbnail validation canvas is unavailable.');
  context.drawImage(image, 0, 0, probe.width, probe.height);
  const pixels = context.getImageData(0, 0, probe.width, probe.height).data;
  let visiblePixels = 0;
  for (let i = 3; i < pixels.length; i += 4) if (pixels[i] > 12) visiblePixels++;
  if (visiblePixels < 8) throw new Error('Rendered thumbnail is blank.');
  return image;
}

function countMeshes(root) {
  let count = 0;
  root.traverse(object => { if (object.isMesh) count++; });
  return count;
}

function setPreviewState(host, state) {
  host.classList.remove('preview-loading', 'preview-loaded', 'preview-failed', 'model-loaded', 'model-load-failed');
  host.classList.add(`preview-${state}`);
  host.dataset.previewState = state;
}

function showFailure(host, error) {
  const previewError=error instanceof Error?(error.stack||error.message):String(error||'Unknown preview error');
  host.dataset.previewError=previewError;
  console.error('FurniFlex 3D preview failed', {url:host.dataset.modelUrl,productId:host.dataset.productId,error,stack:previewError});
  setPreviewState(host, 'failed');
  ensurePreviewFallback(host).removeAttribute('hidden');
  host.querySelector('.model-preview-generated')?.remove();
  host.querySelector('canvas')?.setAttribute('hidden', '');
  const badge = host.querySelector('.model-loading');
  if (badge) badge.textContent = '3D preview unavailable · product image shown';
}

function ensurePreviewFallback(host) {
  let fallback = host.querySelector('.preview-fallback');
  if (!fallback) {
    fallback = document.createElement('img');
    fallback.className = 'preview-fallback';
    fallback.alt = host.dataset.productName || 'Furniture preview';
    fallback.loading = 'eager';
    fallback.decoding = 'async';
    fallback.src = sharedFallbackPath();
    fallback.addEventListener('error', () => replaceBrokenImage(fallback), {once:true});
    host.prepend(fallback);
  }
  return fallback;
}

function sharedFallbackPath() {
  return document.documentElement?.dataset?.productFallback || '';
}

function replaceBrokenImage(image) {
  if (!image.isConnected) return;
  const preview = image.classList.contains('preview-fallback');
  const host = image.closest('.model-preview');
  const name = image.alt || host?.dataset.productName || image.closest('.product-card')?.querySelector('h5')?.textContent?.trim() || 'This product';
  const fallbackPath = sharedFallbackPath();
  const isSharedFallback = image.dataset.universalFallback === 'true'
    || (fallbackPath && image.src === new URL(fallbackPath, document.baseURI).href);
  if (!isSharedFallback && fallbackPath) {
    const fallbackImage = document.createElement('img');
    fallbackImage.className = image.className;
    fallbackImage.alt = name;
    fallbackImage.loading = 'eager';
    fallbackImage.decoding = 'async';
    fallbackImage.dataset.universalFallback = 'true';
    fallbackImage.src = fallbackPath;
    fallbackImage.addEventListener('error', () => replaceBrokenImage(fallbackImage), {once:true});
    image.replaceWith(fallbackImage);
    return;
  }
  const placeholder = document.createElement('div');
  placeholder.setAttribute('role', 'img');
  placeholder.setAttribute('aria-label', `Product image unavailable for ${name}`);
  const label = document.createElement('strong');
  label.textContent = 'Furniture preview unavailable';
  const detail = document.createElement('span');
  detail.textContent = name;
  placeholder.append(label, detail);
  if (preview) {
    placeholder.className = 'preview-fallback preview-unavailable';
  } else {
    placeholder.className = `product-image-unavailable ${image.classList.contains('product-detail') ? 'product-detail rounded-4' : ''}`;
  }
  image.replaceWith(placeholder);
}

function cleanupRenderer({renderer, pmrem, environmentTarget, scene, controls, resizeObserver}) {
  safely(() => resizeObserver?.disconnect());
  safely(() => controls?.dispose());
  if (scene) {
    safely(() => { scene.environment = null; });
    safely(() => disposeObjectTree(scene));
  }
  safely(() => environmentTarget?.dispose());
  safely(() => pmrem?.dispose());
  if (renderer) {
    safely(() => renderer.renderLists?.dispose());
    safely(() => renderer.dispose());
    safely(() => renderer.forceContextLoss());
  }
}

function disposeObjectTree(root) {
  const geometries = new Set();
  const materials = new Set();
  const textures = new Set();
  root.traverse(object => {
    if (object.geometry) geometries.add(object.geometry);
    const list = Array.isArray(object.material) ? object.material : object.material ? [object.material] : [];
    for (const material of list) {
      materials.add(material);
      for (const value of Object.values(material)) if (value?.isTexture) textures.add(value);
    }
  });
  for (const texture of textures) safely(() => texture.dispose());
  for (const material of materials) safely(() => material.dispose());
  for (const geometry of geometries) safely(() => geometry.dispose());
  safely(() => root.clear?.());
}

function safely(action) {
  try { action(); }
  catch (error) { console.warn('FurniFlex preview cleanup step failed', error); }
}

export {cleanupRenderer, ensurePreviewFallback, replaceBrokenImage, setPreviewState, showFailure, validateThumbnail};
