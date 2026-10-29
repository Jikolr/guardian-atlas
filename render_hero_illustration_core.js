/* Native Spine 3.8 illustration export. Load after spine-webgl.js.
 * No atlas crops, mesh changes, background segmentation, or generated artwork.
 *
 * Unity's illustration atlases contain premultiplied RGB. Their additive fire
 * sprites may have opaque, black texels: RGB is emission, not an opaque plate.
 * For PNG export we keep the authored additive RGB and use max(R,G,B) as its
 * alpha. This preserves compositing over already drawn opaque artwork, and is
 * a portable source-over approximation on an arbitrary external background.
 * PNG cannot encode an additive blend operation independently of a background.
 */
(function (global) {
  'use strict';

  function decodeBytes(value) {
    if (value instanceof Uint8Array) return value;
    if (value instanceof ArrayBuffer) return new Uint8Array(value);
    if (Array.isArray(value)) return Uint8Array.from(value);
    if (typeof value === 'string') {
      return Uint8Array.from(atob(value.replace(/^data:[^,]*,/, '')), c => c.charCodeAt(0));
    }
    throw new TypeError('skeletonBytes must contain Spine binary bytes or base64.');
  }

  async function readImage(value) {
    if (value && typeof value !== 'string') return value;
    if (!value) throw new Error('Missing atlas page image.');
    return new Promise((resolve, reject) => {
      const image = new Image();
      image.onload = () => resolve(image);
      image.onerror = () => reject(new Error('Cannot decode atlas page.'));
      image.src = /^(data:|blob:|https?:|file:|\/)/.test(value)
        ? value : 'data:image/png;base64,' + value;
    });
  }

  function createHeroIllustrationRenderer(canvas, options = {}) {
    const spine = options.spine || global.spine;
    if (!spine || !spine.webgl) throw new Error('Spine 3.8 WebGL runtime is required.');
    const gl = canvas.getContext('webgl', {
      alpha: true, premultipliedAlpha: true, preserveDrawingBuffer: true,
      antialias: true, ...(options.contextAttributes || {})
    });
    if (!gl) throw new Error('WebGL is unavailable.');
    const scene = new spine.webgl.SceneRenderer(canvas, gl, true);
    const shader = new spine.webgl.Shader(scene.context, `
      attribute vec4 a_position;
      attribute vec4 a_color;
      attribute vec4 a_color2;
      attribute vec2 a_texCoords;
      uniform mat4 u_projTrans;
      varying vec4 v_light;
      varying vec4 v_dark;
      varying vec2 v_texCoords;
      void main() {
        v_light = a_color; v_dark = a_color2; v_texCoords = a_texCoords;
        gl_Position = u_projTrans * a_position;
      }`, `
      precision mediump float;
      varying vec4 v_light;
      varying vec4 v_dark;
      varying vec2 v_texCoords;
      uniform sampler2D u_texture;
      uniform float u_sourcePma;
      uniform float u_emission;
      void main() {
        vec4 tex = texture2D(u_texture, v_texCoords);
        // RGBA4444 quantization can leave RGB at alpha zero. Such values violate
        // premultiplication and cause browser-compositor ghost lines.
        tex.rgb = u_sourcePma > 0.5 ? min(tex.rgb, vec3(tex.a)) : tex.rgb * tex.a;
        vec3 rgb = (tex.a - tex.rgb) * v_dark.rgb + tex.rgb * v_light.rgb;
        float a = tex.a * v_light.a;
        if (u_emission > 0.5) a = max(max(rgb.r, rgb.g), rgb.b);
        else rgb = min(rgb, vec3(a));
        gl_FragColor = vec4(rgb, a);
      }`);
    scene.batcherShader.dispose();
    scene.batcherShader = shader;
    let currentSlot = null;
    let currentEmission = -1;
    const originalDraw = scene.batcher.draw.bind(scene.batcher);
    scene.batcher.draw = function (texture, vertices, indices) {
      const blend = currentSlot ? currentSlot.data.blendMode : spine.BlendMode.Normal;
      const emission = blend === spine.BlendMode.Additive || blend === spine.BlendMode.Screen ? 1 : 0;
      if (emission !== currentEmission) {
        this.flush();
        shader.setUniformf('u_emission', emission);
        currentEmission = emission;
      }
      return originalDraw(texture, vertices, indices);
    };
    const rigs = new Set();

    async function load(input) {
      const textures = new Map();
      for (const [name, value] of Object.entries(input.imagesByPage || {})) {
        const image = await readImage(value);
        // These PNGs already store premultiplied source RGB. Never ask the
        // browser to multiply that RGB a second time during texture upload.
        gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, false);
        gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, gl.NONE);
        const texture = new spine.webgl.GLTexture(gl, image, false);
        textures.set(name.replace(/\\/g, '/'), texture);
      }
      const atlas = new spine.TextureAtlas(input.atlasText, name => {
        const normalized = name.replace(/\\/g, '/');
        const texture = textures.get(normalized) || textures.get(normalized.split('/').pop());
        if (!texture) throw new Error('Missing atlas page: ' + name);
        return texture;
      });
      // The source Unity Texture2D import setting is authoritative here:
      // all 263 illustration textures in the 3.57.0 dump use bilinear mode 1,
      // even where stale .atlas text says Nearest. Do not enable mipmaps,
      // which can bleed neighboring packed parts at smaller output scales.
      for (const page of atlas.pages) {
        page.texture.setFilters(gl.LINEAR, gl.LINEAR);
      }
      const binary = new spine.SkeletonBinary(new spine.AtlasAttachmentLoader(atlas));
      binary.scale = input.scale === undefined ? 1 : input.scale;
      const data = binary.readSkeletonData(decodeBytes(input.skeletonBytes));
      const skeleton = new spine.Skeleton(data);
      for (const constraint of skeleton.ikConstraints) {
        const apply2 = constraint.apply2.bind(constraint);
        constraint.apply2 = function (parent, child, ...args) {
          const ancestor = parent.parent;
          // Some illustrations animate an entire alternate figure to scale
          // zero. The legacy JS IK solver then divides by its zero determinant
          // and poisons the bounds of the otherwise visible illustration.
          // A collapsed transform has no invertible IK space: retain that
          // authored collapsed pose, without changing any visible geometry.
          if (ancestor && ancestor.a * ancestor.d - ancestor.b * ancestor.c === 0) {
            child.updateWorldTransform();
            return;
          }
          return apply2(parent, child, ...args);
        };
      }
      for (const slot of skeleton.slots) {
        const getAttachment = slot.getAttachment.bind(slot);
        // SkeletonRenderer gets an attachment immediately before drawing it.
        // This keeps native clipping, mesh deformation and draw order intact,
        // while choosing export alpha per actual authored slot blend mode.
        slot.getAttachment = () => { currentSlot = slot; return getAttachment(); };
      }
      const rig = {
        data, skeleton, atlas, textures,
        sourcePremultipliedAlpha: input.sourcePremultipliedAlpha !== false,
        defaultSkin: input.skin || 'default',
        metadata: {
          version: data.version, name: data.name,
          skins: data.skins.map(skin => ({ name: skin.name, attachments: skin.getAttachments().map(a => ({ slotIndex: a.slotIndex, name: a.name, type: a.attachment.constructor.name })) })),
          animations: data.animations.map(animation => ({ name: animation.name, duration: animation.duration })),
          slots: data.slots.map(slot => ({ name: slot.name, blendMode: slot.blendMode, attachmentName: slot.attachmentName }))
        }
      };
      rigs.add(rig);
      return rig;
    }

    function render(input) {
      const rig = input.rig;
      if (!rigs.has(rig)) throw new Error('Load this rig with this renderer first.');
      const { data, skeleton } = rig;
      const mode = input.mode || 'combined';
      if (!['character', 'effects', 'combined'].includes(mode)) throw new Error('Unknown illustration mode: ' + mode);
      const skinName = input.skin || rig.defaultSkin;
      const skin = data.findSkin(skinName);
      if (skin) skeleton.setSkin(skin);
      else if (skinName !== 'default') throw new Error('Unknown skin: ' + skinName);
      skeleton.setToSetupPose();
      const animationName = input.animation === undefined
        ? (data.findAnimation('idle') ? 'idle' : data.animations[0] && data.animations[0].name)
        : input.animation;
      const animation = animationName ? data.findAnimation(animationName) : null;
      if (animationName && !animation) throw new Error('Unknown animation: ' + animationName);
      const time = input.time || 0;
      if (animation) animation.apply(skeleton, 0, time, true, [], 1, spine.MixBlend.setup, spine.MixDirection.mixIn);
      skeleton.updateWorldTransform();
      const extraEffects = new Set(input.effectSlots || []);
      const excluded = new Set(input.excludeSlots || []);
      const fxSlots = skeleton.slots.filter(slot =>
        slot.data.blendMode === spine.BlendMode.Additive || slot.data.blendMode === spine.BlendMode.Screen || extraEffects.has(slot.data.name));
      const fxSet = new Set(fxSlots);
      const omittedSlots = [];
      const includedSlots = [];
      for (const slot of skeleton.slots) {
        const attachment = slot.getAttachment();
        // Never remove a clipping attachment: retained meshes still need it.
        if (!attachment || attachment instanceof spine.ClippingAttachment) continue;
        const omit = excluded.has(slot.data.name) || (mode === 'character' && fxSet.has(slot)) || (mode === 'effects' && !fxSet.has(slot));
        if (omit) { omittedSlots.push(slot.data.name); slot.setAttachment(null); }
        else includedSlots.push(slot.data.name);
      }
      const offset = new spine.Vector2(), size = new spine.Vector2();
      skeleton.getBounds(offset, size, []);
      const empty = !Number.isFinite(size.x) || !Number.isFinite(size.y) || size.x <= 0 || size.y <= 0;
      const bounds = input.bounds || (empty ? { x: 0, y: 0, width: 1, height: 1 } : { x: offset.x, y: offset.y, width: size.x, height: size.y });
      const padding = input.padding === undefined ? 32 : input.padding;
      const scale = input.scale === undefined ? 1 : input.scale;
      if (!(scale > 0) || !(padding >= 0)) throw new Error('Scale must be positive and padding nonnegative.');
      const width = Math.max(1, Math.ceil((bounds.width + padding * 2) * scale));
      const height = Math.max(1, Math.ceil((bounds.height + padding * 2) * scale));
      const limit = gl.getParameter(gl.MAX_RENDERBUFFER_SIZE);
      if (width > limit || height > limit) throw new Error(`Illustration ${width}×${height} exceeds WebGL limit ${limit}; use an explicit lower output scale.`);
      canvas.width = width; canvas.height = height;
      scene.camera.position.set(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2, 0);
      scene.camera.setViewport(width / scale, height / scale);
      gl.viewport(0, 0, width, height);
      gl.clearColor(0, 0, 0, 0); gl.clear(gl.COLOR_BUFFER_BIT);
      currentEmission = -1;
      scene.begin();
      shader.setUniformf('u_sourcePma', rig.sourcePremultipliedAlpha ? 1 : 0);
      shader.setUniformf('u_emission', 0);
      if (!empty) scene.drawSkeleton(skeleton, true);
      scene.end();
      const result = {
        png: canvas.toDataURL('image/png'), width, height, bounds,
        animation: animationName || null, time, skin: skinName, mode, scale,
        empty, includedSlots, omittedSlots, effectSlots: fxSlots.map(slot => slot.data.name),
        alphaMethod: 'premultiplied-source-with-emission-derived-additive-alpha',
        warnings: []
      };
      if (fxSlots.length && mode !== 'character') result.warnings.push('PNG stores normal RGBA, so emissive effects use an alpha approximation for backgrounds outside this illustration.');
      if (input.diagnostics) {
        const pixels = new Uint8Array(width * height * 4);
        gl.readPixels(0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
        let invalidPremultipliedPixels = 0, visiblePixels = 0, opaqueBlackPixels = 0;
        for (let i = 0; i < pixels.length; i += 4) {
          const maximum = Math.max(pixels[i], pixels[i + 1], pixels[i + 2]);
          if (maximum > pixels[i + 3] + 1) invalidPremultipliedPixels++;
          if (pixels[i + 3]) visiblePixels++;
          if (pixels[i + 3] === 255 && maximum === 0) opaqueBlackPixels++;
        }
        result.diagnostics = { invalidPremultipliedPixels, visiblePixels, opaqueBlackPixels };
      }
      return result;
    }

    function disposeRig(rig) {
      if (!rigs.has(rig)) return;
      for (const texture of new Set(rig.textures.values())) texture.dispose();
      rigs.delete(rig);
    }
    function dispose() {
      for (const rig of [...rigs]) disposeRig(rig);
      scene.dispose();
    }
    return { load, render, disposeRig, dispose, canvas, gl };
  }

  global.createHeroIllustrationRenderer = createHeroIllustrationRenderer;
})(typeof window !== 'undefined' ? window : globalThis);
