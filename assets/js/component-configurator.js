import * as THREE from './three.module.js';
import { OrbitControls } from './OrbitControls.js';
import { GLTFLoader } from './loaders/GLTFLoader.js';
import { RoomEnvironment } from './RoomEnvironment.js';

const root=document.querySelector('.component-customizer'),canvas=document.querySelector('#component-canvas'),stage=document.querySelector('.three-stage');
if(root&&canvas){
  const config=JSON.parse(document.querySelector('#component-config-data').textContent),palette=JSON.parse(document.querySelector('#component-color-data').textContent),dimensionData=JSON.parse(document.querySelector('#overall-dimension-data')?.textContent||'{"rules":[],"ranges":{},"base_price":0}'),form=document.querySelector('#component-form'),status=document.querySelector('#three-status'),hidden=document.querySelector('#component-specs'),submit=document.querySelector('#add-configured-item'),modelUrl=root.dataset.modelUrl,productId=Number(root.dataset.productId);
  const mappedNodes={1:{
    frame:{mode:'named_group',nodes:['Upholstery | crisp boxed deck','Upholstery | straight high rear wall']},
    left_arm:{mode:'named_group',nodes:['Upholstery | equal-height tuxedo arm']},
    right_arm:{mode:'named_group',nodes:['Upholstery | equal-height tuxedo arm.001']},
    backrest:{mode:'named_group',nodes:[...numberedNodes('Upholstery | inset square back pad',2),...numberedNodes('Upholstery | inset square back pad | lower tailored welt',2),...numberedNodes('Upholstery | inset square back pad | upper tailored welt',2)]},
    seat_cushion:{mode:'named_group',nodes:[...numberedNodes('Upholstery | tight seat',2),...numberedNodes('Upholstery | tight seat | lower tailored welt',2),...numberedNodes('Upholstery | tight seat | upper tailored welt',2)]},
    sofa_leg:{mode:'named_group',nodes:['Steel | square sled end','Steel | square sled end.001']}
  },2:{
    table_top:{mode:'named_group',nodes:['Walnut top | 1220 x 660 x 30 mm']},
    table_leg:{mode:'named_group',nodes:numberedNodes('Splayed turned walnut leg',3)},
    table_brace:{mode:'named_group',nodes:[...numberedNodes('Lower shelf slat 01',0),...numberedNodes('Lower shelf slat 02',0),...numberedNodes('Lower shelf slat 03',0),...numberedNodes('Lower shelf slat 04',0),...numberedNodes('Lower shelf slat 05',0),...numberedNodes('Lower shelf support bearer',1)]},
    table_frame:{mode:'named_group',nodes:['Walnut end apron','Walnut end apron.001','Walnut side apron','Walnut side apron.001']},
    table_hardware:{mode:'named_group',nodes:[...numberedNodes('Leg plate screw | countersunk head',3),...numberedNodes('Leg plate screw | hex socket',3),...numberedNodes('Recessed felt glide',3),...numberedNodes('Satin brass foot ferrule',3),...numberedNodes('Shelf bearer bronze cap',3),...numberedNodes('Under-top steel fixing plate',3)]}
  },3:{
    bed_frame:{mode:'named_group',nodes:['Bed | centre support',...['Bed | centre support foot','Bed | end bearer','Bed | sprung oak slat','Bed | substantial side rail'].flatMap((name,index)=>numberedNodes(name,[1,1,12,1][index]))]},
    bed_ends:{mode:'named_group',nodes:[...numberedNodes('End | rounded oak crossrail',3),...numberedNodes('End | tapered spindle',33)]},
    bed_legs:{mode:'named_group',nodes:numberedNodes('Frame | tapered round post',3)},
    bed_hardware:{mode:'named_group',nodes:numberedNodes('Post | bronze foot cap',3)},
    bed_mattress:{mode:'named_group',nodes:['Mattress | upholstered ticking']},
    bed_pillows:{mode:'named_group',nodes:numberedNodes('Bedding | sewn pillow',1)},
    bed_quilt:{mode:'named_group',nodes:['Bedding | softly draped quilt']},
    bed_folded_return:{mode:'named_group',nodes:['Bedding | folded return']}
  },4:{
    dining_top:{mode:'named_group',nodes:numberedNodes('Sliding oak main top with straight mating edge',1)},
    dining_legs:{mode:'named_group',nodes:numberedNodes('Oak portal upright',3)},
    dining_brace:{mode:'named_group',nodes:[...numberedNodes('Portal lower tie',1),...numberedNodes('Portal top bearing',1)]},
    dining_hardware:{mode:'named_group',nodes:[...numberedNodes('Butterfly hinge leaf',3),'Butterfly-leaf center hinge',...numberedNodes('Butterfly-extension outer channel',1),...numberedNodes('Leaf deployment support',3),...numberedNodes('Leaf rotating support spindle',1),...numberedNodes('Sliding extension rail',3)]},
    dining_extension_leaf:{mode:'named_group',nodes:numberedNodes('Folding butterfly half-leaf',1)},
    dining_foot_glides:{mode:'named_group',nodes:numberedNodes('Portal floor glide',3)}
  },5:{
    desk_top:{mode:'named_group',nodes:['Solid walnut worktop | 1400 x 650 x 28 mm']},
    desk_frame:{mode:'named_group',nodes:['Steel end apron','Steel end apron.001','Steel long apron','Steel long apron.001','Top fixing plate','Top fixing plate.001','Top fixing plate.002','Top fixing plate.003']},
    desk_legs:{mode:'named_group',nodes:[...numberedNodes('Slender steel square leg',3),...numberedNodes('Bronze leg shoe',3),...numberedNodes('Inset elastomer foot',3)]},
    desk_drawer:{mode:'named_group',nodes:['Drawer bottom','Drawer left carcass side','Drawer rear panel','Drawer right carcass side','Concealed steel drawer slide','Concealed steel drawer slide.001']},
    desk_drawer_front:{mode:'named_group',nodes:['Walnut drawer front']},
    desk_drawer_handle:{mode:'named_group',nodes:['Bronze drawer pull | grip','Bronze drawer pull | standoff','Bronze drawer pull | standoff.001']},
    desk_hardware:{mode:'named_group',nodes:['Cable grommet | open lead slot','Cable grommet | split lid','Cable trough base','Cable trough fixing tab','Cable trough fixing tab.001','Cable trough rear flange','Flush cable grommet | charcoal rim',...numberedNodes('Desktop fixing | countersunk head',7),...numberedNodes('Desktop fixing | hex socket',7)]}
  }};
  function numberedNodes(base,lastSuffix){return [base,...Array.from({length:lastSuffix},(_,i)=>`${base}.${String(i+1).padStart(3,'0')}`)]}
  const initialFormState=[...root.querySelectorAll('input,select,textarea')].map(el=>({el,value:el.value,checked:el.checked}));
  const defs=new Map(config.map(c=>[String(c.component_id),c])),scene=new THREE.Scene();scene.background=new THREE.Color('#f3ece2');
  const camera=new THREE.PerspectiveCamera(38,1,.01,100);camera.position.set(3.5,2.7,4.5);
  let renderer,controls;const meshes=new Map(),templates=new Map(),templateInfo=new Map(),raycaster=new THREE.Raycaster(),pointer=new THREE.Vector2(),textureLoader=new THREE.TextureLoader(),textureCache=new Map(),textureLoads=new Map();let selectedId=null,autoRotate=false,ready=false,modelVisible=false,modelFitted=false,renderSequence=0,cameraDefault=null,targetDefault=null,latestFormValid=false;
  function applySupportedControls(){for(const card of root.querySelectorAll('.component-card')){const def=config.find(c=>String(c.component_id)===card.dataset.componentId);if(!def?.supported_controls)continue;const allowed=new Set(def.supported_controls);for(const el of card.querySelectorAll('[data-field]')){const field=el.dataset.field;if(field==='custom_color'||allowed.has(field))continue;const cell=el.closest('.col-6,.col-4,.col-12');if(cell)cell.hidden=true}if(!['position_x','position_y','position_z'].some(x=>allowed.has(x))){for(const label of card.querySelectorAll('.col-12 > .small.fw-semibold'))if(label.textContent.trim().startsWith('Position'))label.parentElement.hidden=true}}if([1,2,3,4,5].includes(productId))form.querySelector(':scope > details')?.setAttribute('hidden','hidden')}
  function setModelStatus(message,isError=false){status.textContent=message;status.classList.toggle('is-error',isError);stage.classList.toggle('model-error',isError)}
  applySupportedControls();
  scene.add(new THREE.HemisphereLight(0xffffff,0x8e7965,.72));const key=new THREE.DirectionalLight(0xffffff,1.75);key.position.set(3,6,4);scene.add(key);const fill=new THREE.DirectionalLight(0xffddb2,.42);fill.position.set(-4,2,-3);scene.add(fill);
  const ground=new THREE.Mesh(new THREE.PlaneGeometry(10,10),new THREE.MeshStandardMaterial({color:0xeae1d5,roughness:1}));ground.rotation.x=-Math.PI/2;ground.position.y=-.015;scene.add(ground);
  try{renderer=new THREE.WebGLRenderer({canvas,antialias:true,alpha:false});renderer.setPixelRatio(Math.min(devicePixelRatio||1,2));renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1;renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;controls=new OrbitControls(camera,renderer.domElement);controls.enableDamping=true;controls.target.set(0,1,0);controls.minDistance=1.4;controls.maxDistance=9;controls.maxPolarAngle=Math.PI*.48;submit.disabled=true;status.textContent='Loading the local GLB model and PBR materials…';const pmrem=new THREE.PMREMGenerator(renderer);scene.environment=pmrem.fromScene(new RoomEnvironment(),.04).texture;pmrem.dispose()}catch(e){status.textContent='3D preview is not supported by this browser or graphics device. The configurator is disabled to avoid claiming unshown changes.';submit.disabled=true;}
  const canvasTexture=(key)=>{const c=document.createElement('canvas');c.width=256;c.height=256;const ctx=c.getContext('2d');const palettes={oak:['#9a6335','#c9975e'],walnut:['#422c22','#76523b'],fabric:['#98785f','#d0b39b'],velvet:['#444960','#858ba3'],leather:['#422b25','#835d4c'],metal:['#73787b','#c8cacc'],matte:['#80603e','#b58c5e'],oil:['#684629','#a97845'],gloss:['#b48752','#e0bb83']};const colors=palettes[key]||['#a98568','#c9aa85'];ctx.fillStyle=colors[0];ctx.fillRect(0,0,256,256);if(['oak','walnut','oil'].includes(key)){for(let i=0;i<34;i++){ctx.strokeStyle=i%2?colors[1]:'#4b3225';ctx.globalAlpha=.15+Math.random()*.25;ctx.lineWidth=1+Math.random()*5;ctx.beginPath();const y=Math.random()*256;ctx.moveTo(0,y);ctx.bezierCurveTo(70,y-14,180,y+18,256,y+Math.random()*20-10);ctx.stroke()}}else if(['fabric','velvet','leather'].includes(key)){ctx.globalAlpha=.3;ctx.strokeStyle=colors[1];ctx.lineWidth=2;for(let i=0;i<256;i+=8){ctx.beginPath();ctx.moveTo(i,0);ctx.lineTo(i,256);ctx.moveTo(0,i);ctx.lineTo(256,i);ctx.stroke()}}else if(key==='metal'){const g=ctx.createLinearGradient(0,0,256,0);g.addColorStop(0,colors[0]);g.addColorStop(.45,colors[1]);g.addColorStop(1,colors[0]);ctx.globalAlpha=.85;ctx.fillStyle=g;ctx.fillRect(0,0,256,256)}ctx.globalAlpha=1;const t=new THREE.CanvasTexture(c);t.wrapS=t.wrapT=THREE.RepeatWrapping;t.repeat.set(2,2);return t};
  const formValue=(id,field)=>{const el=root.querySelector(`[data-component-id="${id}"][data-field="${field}"]`);return el?el.value:''};
  const finishRoughness=key=>key==='gloss'?.22:key==='satin'?.38:key==='oil'?.48:key==='matte'?.92:.66;
  function specFromForm(def){const id=String(def.component_id),optionIds={};for(const type of ['material','color','finish'])optionIds[type]=Number(formValue(id,`option_${type}`)||0);return {component_id:def.component_id,shape:formValue(id,'shape')||def.default_shape,quantity:Number(formValue(id,'quantity')??def.default_quantity),dimensions:{width_cm:Number(formValue(id,'width_cm')??def.default_width_cm),depth_cm:Number(formValue(id,'depth_cm')??def.default_depth_cm),height_cm:Number(formValue(id,'height_cm')??def.default_height_cm)},position:{x:Number(formValue(id,'position_x')??def.default_x_cm),y:Number(formValue(id,'position_y')??def.default_y_cm),z:Number(formValue(id,'position_z')??def.default_z_cm)},custom_color:formValue(id,'custom_color')||null,options:optionIds}}
  function getGlobalAppearance(){if([1,2,3,4,5].includes(productId))return {color:null,material:null,finish:null};const color=root.querySelector('input[name="options[Color]"]:checked'),material=root.querySelector('input[name="options[Material]"]:checked')||root.querySelector('input[name="options[Upholstery]"]:checked'),finish=root.querySelector('input[name="options[Finish]"]:checked');const materialName=material?.closest('label')?.innerText.trim().split('\n')[0].toLowerCase()||'';const finishName=finish?.closest('label')?.innerText.trim().split('\n')[0].toLowerCase()||'';return {color:color?.dataset.color||null,material:materialName.includes('leather')?'leather':materialName.includes('velvet')?'velvet':materialName.includes('fabric')||materialName.includes('weave')?'fabric':materialName.includes('walnut')?'walnut':'oak',finish:finishName.includes('gloss')?'gloss':finishName.includes('oil')?'oil':'matte'}}
  function optionFor(def,spec,type){const id=Number(spec.options?.[type]||0);return id?def.options.find(o=>o.option_type===type&&Number(o.component_option_id)===id)||null:null}
  function makeMaterial(def,spec){const matOption=optionFor(def,spec,'material'),colorOption=optionFor(def,spec,'color'),finishOption=optionFor(def,spec,'finish'),global=getGlobalAppearance(),color=spec.custom_color||colorOption?.color_hex||global.color||null,textureKey=matOption?.texture_key||def.default_texture_key||global.material,appearance=matOption||materialForKey(textureKey),finish=finishOption?.texture_key||global.finish,roughness=finishRoughness(finish),base=new THREE.MeshStandardMaterial({color:new THREE.Color(color||def.default_color_hex||'#A98568'),map:canvasTexture(textureKey),roughness,metalness:textureKey==='metal'?.75:.02}),material=appearance?surfaceMaterial(appearance,color,base):base;if(finishOption)material.roughness=roughness;return material}
  function roundedShape(w,h,r){const s=new THREE.Shape();s.moveTo(-w/2+r,-h/2);s.lineTo(w/2-r,-h/2);s.quadraticCurveTo(w/2,-h/2,w/2,-h/2+r);s.lineTo(w/2,h/2-r);s.quadraticCurveTo(w/2,h/2,w/2-r,h/2);s.lineTo(-w/2+r,h/2);s.quadraticCurveTo(-w/2,h/2,-w/2,h/2-r);s.lineTo(-w/2,-h/2+r);s.quadraticCurveTo(-w/2,-h/2,-w/2+r,-h/2);return s}
  function geometryFor(type,shape,w,d,h){let geom;if(shape==='square')return new THREE.BoxGeometry(w,h,d);if(type==='handle'&&shape==='knob')return new THREE.SphereGeometry(Math.max(.006,Math.min(w,d,h)/2),20,16);if(type==='handle'&&shape==='bar'){const radius=Math.max(.004,Math.min(d,h)/2);geom=new THREE.CylinderGeometry(radius,radius,w,18);geom.rotateZ(Math.PI/2);return geom}if(shape==='cylinder'||shape==='tapered'){geom=new THREE.CylinderGeometry(shape==='tapered'?.275:.5,.5,h,24);geom.scale(w,1,d);return geom}
    if(shape==='oval'&&type==='top'){geom=new THREE.CylinderGeometry(.5,.5,h,48,1,false);geom.scale(w,1,d);return geom}
    if(shape==='arched'){const s=new THREE.Shape();s.moveTo(-w/2,-h/2);s.lineTo(w/2,-h/2);s.lineTo(w/2,h/2*.45);s.absarc(0,h/2*.45,w/2,0,Math.PI,false);s.lineTo(-w/2,-h/2);geom=new THREE.ExtrudeGeometry(s,{depth:d,bevelEnabled:false});geom.translate(0,0,-d/2);return geom}
    if(shape==='rounded'){geom=new THREE.ExtrudeGeometry(roundedShape(w,h,Math.min(w,h)*.11),{depth:d,bevelEnabled:false});geom.translate(0,0,-d/2);return geom}
    if(shape==='angled'){const s=new THREE.Shape();s.moveTo(-w/2,-h/2);s.lineTo(w/2,-h/2);s.lineTo(w/2,h/2);s.lineTo(-w/2,h/2*.55);s.closePath();geom=new THREE.ExtrudeGeometry(s,{depth:d,bevelEnabled:false});geom.translate(0,0,-d/2);return geom}
    return new THREE.BoxGeometry(w,h,d)
  }
  function makeObject(def,spec,index){const w=spec.dimensions.width_cm/100,d=spec.dimensions.depth_cm/100,h=spec.dimensions.height_cm/100;let g=new THREE.Group(),shape=spec.shape,mat=makeMaterial(def,spec);const core=new THREE.Mesh(geometryFor(def.geometry_type,shape,w,d,h),mat);core.castShadow=true;core.receiveShadow=true;core.userData={componentId:String(def.component_id)};g.add(core);
    if(shape==='panelled'&&def.geometry_type==='door'){const trimMat=mat.clone();trimMat.color.offsetHSL(0,0,-.12);const panel=new THREE.Mesh(new THREE.BoxGeometry(w*.72,.012,d*.18),trimMat);panel.position.set(0,0,d*.56);panel.userData=core.userData;g.add(panel)}
    if(def.geometry_type==='drawer'){const pull=new THREE.Mesh(new THREE.CylinderGeometry(.008,.008,w*.22,12),new THREE.MeshStandardMaterial({color:'#997642',metalness:.75,roughness:.3}));pull.rotation.z=Math.PI/2;pull.position.set(0,h*.12,d*.53);pull.userData=core.userData;g.add(pull)}
    if(def.geometry_type==='handle'&&shape==='knob'){const knob=new THREE.Mesh(new THREE.SphereGeometry(Math.max(.012,Math.min(w,d,h)*.42),16,12),new THREE.MeshStandardMaterial({color:'#b7a178',metalness:.7,roughness:.28}));knob.position.z=d*.56;knob.userData=core.userData;g.add(knob)}
    return g
  }
  const materialForKey=(key)=>{for(const d of config)for(const o of d.options||[])if(o.option_type==='material'&&o.texture_key===key)return o;return null};
  function textureMap(url,color=false){if(!url)return null;const t=textureCache.get(url);if(!t)return null;t.wrapS=t.wrapT=THREE.RepeatWrapping;t.colorSpace=color?THREE.SRGBColorSpace:THREE.NoColorSpace;t.anisotropy=renderer.capabilities.getMaxAnisotropy();return t}
  function surfaceMaterial(opt,color,original,preserveTexture=false){const m=original.clone();if(opt){m.map=textureMap(opt.base_color_map,true);m.normalMap=textureMap(opt.normal_map);m.roughnessMap=textureMap(opt.roughness_map);m.metalnessMap=textureMap(opt.metallic_map);m.aoMap=textureMap(opt.ao_map);m.roughness=Number(opt.roughness??.65);m.metalness=Number(opt.metallic??0);m.normalScale.set(Number(opt.normal_scale??.45),Number(opt.normal_scale??.45));m.name=opt.option_name;}if(color){m.color.set(color);if(!preserveTexture)m.map=null}m.needsUpdate=true;return m}
  function modelObject(def,spec,index,hostSpec=null){const template=templates.get(def.component_key);if(!template||spec.shape!==def.default_shape)return makeObject(def,spec,index);const obj=template.clone(true),sx=spec.dimensions.width_cm/Number(def.default_width_cm),sy=spec.dimensions.height_cm/Number(def.default_height_cm),sz=spec.dimensions.depth_cm/Number(def.default_depth_cm),info=templateInfo.get(def.component_key);obj.userData={componentId:String(def.component_id)};const chosen=optionFor(def,spec,'material'),colorOption=optionFor(def,spec,'color'),finishOption=optionFor(def,spec,'finish'),global=getGlobalAppearance(),color=spec.custom_color||colorOption?.color_hex||global.color||null;let main=null,area=-1;obj.traverse(o=>{if(!o.isMesh)return;o.userData={...o.userData,componentId:String(def.component_id)};o.castShadow=true;o.receiveShadow=true;o.material=Array.isArray(o.material)?o.material.map(m=>m.clone()):o.material.clone();const n=o.geometry?.attributes?.position?.count||0;if(n>area){main=o;area=n}});if(info?.mode==='leg_group'){const hostWidth=Number(hostSpec?.dimensions?.width_cm||120),hostDepth=Number(hostSpec?.dimensions?.depth_cm||70),source=info.sourceDimensionsCm;obj.scale.set(1,1,1);for(const part of obj.children){part.scale.set(Number(def.default_width_cm)/source.width*sx,Number(def.default_height_cm)/source.height*sy,Number(def.default_depth_cm)/source.depth*sz);part.position.set(Number(part.userData.assetOffsetXRatio||0)*hostWidth/100,0,Number(part.userData.assetOffsetZRatio||0)*hostDepth/100)}}else if(info?.mode==='named_group'){obj.scale.set(1,1,1)}else{const source=info?.sourceDimensionsCm,baseX=source?Number(def.default_width_cm)/source.width:1,baseY=source?Number(def.default_height_cm)/source.height:1,baseZ=source?Number(def.default_depth_cm)/source.depth:1;obj.scale.set(baseX*sx,baseY*sy,baseZ*sz)}if(main){obj.traverse(o=>{if(!o.isMesh)return;const originalKey=(o.material.name||'').toLowerCase().replaceAll(' ','_'),original=materialForKey(originalKey),accent=/seam|piping|inlay|ferrule|pull|mount|collar|brace_joint/i.test(o.name||''),colorTarget=Boolean(color)&&!accent,isMappedAsset=Boolean(info),shouldApply=isMappedAsset?Boolean(chosen||color||finishOption):(o===main||colorTarget||(chosen&&original?.material_category===chosen.material_category));if(shouldApply){const oldMaterials=o.material,apply=(old)=>{const updated=surfaceMaterial(chosen,color,old,isMappedAsset);if(finishOption)updated.roughness=finishRoughness(finishOption.texture_key);old.dispose();return updated};o.material=Array.isArray(oldMaterials)?oldMaterials.map(apply):apply(oldMaterials)}})}return obj}
  function loadTexture(url,color=false){if(!url)return Promise.resolve(null);if(textureCache.has(url)){const t=textureCache.get(url);t.colorSpace=color?THREE.SRGBColorSpace:THREE.NoColorSpace;return Promise.resolve(t)}if(!textureLoads.has(url)){const pending=textureLoader.loadAsync('/FurniFlex/'+url).then(t=>{t.wrapS=t.wrapT=THREE.RepeatWrapping;t.colorSpace=color?THREE.SRGBColorSpace:THREE.NoColorSpace;t.anisotropy=renderer.capabilities.getMaxAnisotropy();textureCache.set(url,t);textureLoads.delete(url);return t}).catch(error=>{textureLoads.delete(url);throw error});textureLoads.set(url,pending)}return textureLoads.get(url)}
  async function preloadAppearanceTextures(specs){const pending=new Map();for(const def of config){const spec=specs[String(def.component_id)];if(!spec)continue;const chosen=optionFor(def,spec,'material'),material=chosen||materialForKey(def.default_texture_key);if(!material)continue;for(const field of ['base_color_map','normal_map','roughness_map','metallic_map','ao_map']){const url=material[field];if(!url)continue;
      // Non-metal materials do not use a metalness map. Some legacy fabric catalog
      // entries point at an empty placeholder file; requesting it rejects TextureLoader's
      // loadAsync promise and hides the entire model. Leave metalnessMap unset instead.
      if(field==='metallic_map'&&Number(material.metallic??0)<=0)continue;
      pending.set(url,loadTexture(url,field==='base_color_map'))
    }}await Promise.all(pending.values())}
  // Resize in assembly coordinates so coincident joints share the same displacement.
  // End bands translate intact, preserving perimeter profiles and foot/top thickness.
  // Resize each upright about its own axis, leaving its foot and mounting
  // centre in place. Work in the upright's local frame for splayed legs.
  function shapeShafts(object, scale) {
    if (scale.x === 1 && scale.z === 1) return;
    for (const wrapper of object.children) {
      const part=wrapper.children[0];
      if (!part) continue;
      const localBounds=new THREE.Box3().setFromObject(part,true);
      const center=localBounds.getCenter(new THREE.Vector3());
      part.worldToLocal(center);
      part.scale.set(scale.x,1,scale.z);
      part.position.x+=center.x*(1-scale.x);
      part.position.z+=center.z*(1-scale.z);
    }
  }
  function fitSupportMounts(group, definition, spec) {
    const ratio=spec.dimensions.height_cm/definition.default_height_cm;
    const shift=new THREE.Vector3(...['x','y','z'].map(axis=>
      (spec.position[axis]-definition['default_'+axis+'_cm'])/100));
    if(ratio===1 && shift.lengthSq()===0)return;
    const box=new THREE.Box3().setFromObject(group,true);
    const span=box.max.y-box.min.y;
    if(!span)return;
    // Preserve the original insertion depth at the mounting faces. The
    // middle section absorbs the height delta. A monotone mapping leaves
    // coincident points coincident, including points on other components.
    const band=Math.min(span*0.2,span*ratio*0.25);
    const low=box.min.y+band,high=box.max.y-band,delta=span*(ratio-1);
    const point=new THREE.Vector3();
    for(const assembly of meshes.values()){
      assembly.updateWorldMatrix(true,true);
      if(delta && (definition.component_key !== 'wardrobe_foot' || assembly === group))assembly.traverse(mesh=>{
        if(!mesh.isMesh)return;
        const bounds=new THREE.Box3().setFromObject(mesh,true);
        if(bounds.max.y<=low)return;
        if(!mesh.userData.resizedGeometry){
          mesh.geometry=mesh.geometry.clone();
          mesh.userData.resizedGeometry=true;
        }
        const inverse=mesh.matrixWorld.clone().invert();
        const positions=mesh.geometry.attributes.position;
        for(let i=0;i<positions.count;i++){
          point.fromBufferAttribute(positions,i).applyMatrix4(mesh.matrixWorld);
          point.y+=delta*THREE.MathUtils.clamp((point.y-low)/(high-low),0,1);
          point.applyMatrix4(inverse);
          positions.setXYZ(i,point.x,point.y,point.z);
        }
        positions.needsUpdate=true;
        if(bounds.min.y<high)mesh.geometry.computeVertexNormals();
        mesh.geometry.computeBoundingBox();
        mesh.geometry.computeBoundingSphere();
      });
      assembly.position.add(shift);
    }
  }
  function resizeAssembly() {
    const ratios = ['width', 'height', 'depth'].map(key => {
      const input = form.querySelector('.overall-dimension-input[name="' + key + '"]');
      return input ? Number(input.value) / Number(input.dataset.default) : 1;
    });
    if (ratios.every(ratio => ratio === 1)) return;
    const bounds = new THREE.Box3();
    for (const group of meshes.values()) bounds.expandByObject(group, true);
    if (bounds.isEmpty()) return;
    const point = new THREE.Vector3();
    for (const group of meshes.values()) group.traverse(mesh => {
      if (!mesh.isMesh) return;
      if (!mesh.userData.resizedGeometry) mesh.geometry = mesh.geometry.clone();
      mesh.userData.resizedGeometry = true;
      const inverse = mesh.matrixWorld.clone().invert();
      const positions = mesh.geometry.attributes.position;
      for (let i = 0; i < positions.count; i++) {
        point.fromBufferAttribute(positions, i).applyMatrix4(mesh.matrixWorld);
        for (let axis = 0; axis < 3; axis++) {
          const min = bounds.min.getComponent(axis);
          const span = bounds.max.getComponent(axis) - min;
          if (!span || ratios[axis] === 1) continue;
          const t = (point.getComponent(axis) - min) / span;
          const band = Math.min(0.15, ratios[axis] / 4);
          const weight = THREE.MathUtils.clamp((t - band) / (1 - 2 * band), 0, 1);
          point.setComponent(axis, point.getComponent(axis) +
            span * (ratios[axis] - 1) * (weight - (axis === 1 ? 0 : 0.5)));
        }
        point.applyMatrix4(inverse);
        positions.setXYZ(i, point.x, point.y, point.z);
      }
      positions.needsUpdate = true;
      mesh.geometry.computeVertexNormals();
      mesh.geometry.computeBoundingBox();
      mesh.geometry.computeBoundingSphere();
    });
  }
  function removeModel(){clearSelectionHighlight();for(const obj of [...meshes.values()]){scene.remove(obj);obj.traverse(o=>{if(o.userData.resizedGeometry)o.geometry.dispose();if(o.material){if(Array.isArray(o.material))o.material.forEach(m=>m.dispose());else o.material.dispose()}})}meshes.clear()}
  function overallDimensionState(){let cost=0,valid=true;const lines=[];for(const rule of dimensionData.rules||[]){const key=rule.dimension_name,input=form.querySelector(`[name="${key}"]`);if(!input)continue;const v=Number(input.value),min=Number(rule.min_cm),max=Number(rule.max_cm),step=Number(rule.step_cm),base=Number(rule.default_cm),off=(v-min)/step;let lineCost=0;if(!Number.isFinite(v)||v<min||v>max||Math.abs(off-Math.round(off))>.00001){input.setCustomValidity('Choose a value within the supported overall dimension range and step.');valid=false}else{input.setCustomValidity('');switch(rule.pricing_mode){case'per_cm':lineCost=Math.max(0,v-base)*Number(rule.price_amount);break;case'fixed':lineCost=Math.abs(v-base)>.00001?Number(rule.price_amount):0;break;case'percentage':lineCost=Math.abs(v-base)>.00001?Number(dimensionData.base_price)*Number(rule.price_amount)/100:0;break;case'material_usage':lineCost=Math.ceil(Math.max(0,v-base)/100)*Number(rule.price_amount);break;case'ranges':{const ranges=dimensionData.ranges?.[key]||[],rangeCost=value=>{const hits=ranges.filter((r,i)=>value>=Number(r.min_cm)&&(value<Number(r.max_cm)||(i===ranges.length-1&&value===Number(r.max_cm))));return hits.length===1?Number(hits[0].additional_cost):NaN},valueCost=rangeCost(v),defaultCost=rangeCost(base);if(!Number.isFinite(valueCost)||!Number.isFinite(defaultCost)){input.setCustomValidity('This value has no configured price range.');valid=false}else lineCost=Math.max(0,valueCost-defaultCost);break}}}cost+=lineCost;const label={width:'Overall Width',depth:'Overall Length / Depth',height:'Overall Height'}[key]||key;lines.push({label:`${label}: ${Number.isFinite(v)?v:base} cm`,cost:lineCost})}return {cost,valid,lines}}
  function updateSpecs(render=true){const canonical={};let total=0,valid=true;const lines=[];for(const def of config){const spec=specFromForm(def),id=String(def.component_id);canonical[id]=spec;const qty=spec.quantity,shapePrices=def.shape_prices||{};let cost=(Math.abs(spec.dimensions.width_cm-Number(def.default_width_cm))*Number(def.width_rate)+Math.abs(spec.dimensions.depth_cm-Number(def.default_depth_cm))*Number(def.depth_rate)+Math.abs(spec.dimensions.height_cm-Number(def.default_height_cm))*Number(def.height_rate)+Number(shapePrices[spec.shape]||0))*qty+Math.max(0,qty-Number(def.default_quantity))*Number(def.unit_price);for(const [type,oid] of Object.entries(spec.options)){if(!oid)continue;const opt=def.options.find(o=>Number(o.component_option_id)===oid);if(opt)cost+=Number(opt.additional_cost)*qty}total+=cost;lines.push({label:`${def.display_name} × ${qty}`,cost});for(const field of ['quantity','width_cm','depth_cm','height_cm','position_x','position_y','position_z']){const el=root.querySelector(`[data-component-id="${id}"][data-field="${field}"]`);if(el){const v=Number(el.value);if(!Number.isFinite(v)||v<Number(el.min)||v>Number(el.max)){el.setCustomValidity('Value outside the supported range.');valid=false}else el.setCustomValidity('')}}}
    for(const def of config){
      if(!def.anchor_component_key)continue;
      const hostDef=config.find(c=>c.component_key===def.anchor_component_key);if(!hostDef)continue;
      const part=canonical[String(def.component_id)],host=canonical[String(hostDef.component_id)];if(!part||!host)continue;
      const quantityInput=root.querySelector(`[data-component-id="${def.component_id}"][data-field="quantity"]`);
      if(host.quantity<1&&part.quantity>0){quantityInput?.setCustomValidity(`${def.display_name} needs at least one ${hostDef.display_name.toLowerCase()}.`);valid=false}
      else if(quantityInput?.validationMessage.includes('needs at least one '))quantityInput.setCustomValidity('');
      if(part.quantity<1)continue;
      const size=part.dimensions,pos=part.position,hostSize=host.dimensions,hostPos=host.position,axis=def.layout_axis,checks=[];
      if(axis==='x'||axis==='columns'){checks.push(['width_cm',size.width_cm*part.quantity+2*Math.abs(pos.x-Number(def.default_x_cm)),hostSize.width_cm,'position_x',size.width_cm*part.quantity]);checks.push(['depth_cm',size.depth_cm,hostSize.depth_cm,null,size.depth_cm])}
      else if(axis==='y'||axis==='shelves'){const offset=axis==='shelves'?pos.y-Number(def.default_y_cm):pos.y-hostPos.y;checks.push(['height_cm',size.height_cm*part.quantity+2*Math.abs(offset),hostSize.height_cm,'position_y',size.height_cm*part.quantity]);checks.push(['width_cm',size.width_cm,hostSize.width_cm,null,size.width_cm]);checks.push(['depth_cm',size.depth_cm,hostSize.depth_cm,null,size.depth_cm])}
      else if(axis==='z'||axis==='spread_z'){checks.push(['depth_cm',size.depth_cm*part.quantity+2*Math.abs(pos.z-Number(def.default_z_cm)),hostSize.depth_cm,'position_z',size.depth_cm*part.quantity]);checks.push(['width_cm',size.width_cm,hostSize.width_cm,null,size.width_cm])}
      else {const xOffset=axis==='corners'?pos.x:pos.x-hostPos.x,zOffset=axis==='corners'?pos.z:pos.z-hostPos.z;checks.push(['width_cm',size.width_cm+2*Math.abs(xOffset),hostSize.width_cm,axis==='corners'?'position_x':'width_cm',size.width_cm]);checks.push(['depth_cm',size.depth_cm+2*Math.abs(zOffset),hostSize.depth_cm,axis==='corners'?'position_z':'depth_cm',size.depth_cm])}
      for(const [dimensionField,used,available,positionField,dimensionOnly] of checks){const sizeInput=root.querySelector(`[data-component-id="${def.component_id}"][data-field="${dimensionField}"]`),positionInput=positionField?root.querySelector(`[data-component-id="${def.component_id}"][data-field="${positionField}"]`):null;if(used>available+.01){const target=positionInput&&dimensionOnly<=available+.01?positionInput:sizeInput;target?.setCustomValidity(`This ${def.display_name.toLowerCase()} does not fit within the ${hostDef.display_name.toLowerCase()}.`);valid=false}else for(const input of [sizeInput,positionInput])if(input?.validationMessage.startsWith('This '))input.setCustomValidity('')}
    }
    if(productId===2){const topDef=config.find(c=>c.component_key==='table_top'),legDef=config.find(c=>c.component_key==='table_leg'),top=topDef&&canonical[String(topDef.component_id)],legs=legDef&&canonical[String(legDef.component_id)],legWidthInput=legDef&&root.querySelector(`[data-component-id="${legDef.component_id}"][data-field="width_cm"]`),legDepthInput=legDef&&root.querySelector(`[data-component-id="${legDef.component_id}"][data-field="depth_cm"]`);if(top&&legs){const widthFits=.78*top.dimensions.width_cm+legs.dimensions.width_cm<=top.dimensions.width_cm+.01,depthFits=.6666667*top.dimensions.depth_cm+legs.dimensions.depth_cm<=top.dimensions.depth_cm+.01;if(!widthFits){legWidthInput?.setCustomValidity('The selected leg width extends beyond the tabletop.');valid=false}else if(legWidthInput?.validationMessage.includes('extends beyond the tabletop'))legWidthInput.setCustomValidity('');if(!depthFits){legDepthInput?.setCustomValidity('The selected leg depth extends beyond the tabletop.');valid=false}else if(legDepthInput?.validationMessage.includes('extends beyond the tabletop'))legDepthInput.setCustomValidity('')}}
    const overall=overallDimensionState();valid=valid&&overall.valid;latestFormValid=valid;hidden.value=JSON.stringify(canonical);submit.disabled=!ready||!valid||!modelVisible;document.dispatchEvent(new CustomEvent('component-price-change',{detail:{cost:total,lines,dimensionCost:overall.cost,dimensionLines:overall.lines}}));if(render&&ready)renderModel(canonical,valid);return canonical
  }
  async function renderModel(specs,valid=true){const sequence=++renderSequence;if(!valid){submit.disabled=true;return}let phase='material preparation';submit.disabled=true;try{await preloadAppearanceTextures(specs);if(sequence!==renderSequence)return;phase='initial configuration';buildModel(specs);phase='camera framing';phase='first render';renderer.render(scene,camera);const gl=renderer.getContext();if(gl.isContextLost())throw new Error('WebGL context was lost on the first furniture render.');if((renderer.info?.render?.calls||0)<1)throw new Error('The first furniture render produced no draw calls.');modelVisible=true;stage.classList.add('model-ready');stage.classList.remove('model-error');status.classList.remove('is-error');status.textContent=`${defs.get(selectedId)?.display_name||'Furniture'} ready`;submit.disabled=!latestFormValid}catch(error){if(sequence!==renderSequence)return;console.error('FurniFlex initialization failed during '+phase,error,{modelUrl,productId,selectedId,stack:error?.stack});modelVisible=false;stage.classList.remove('model-ready');stage.classList.add('model-error');status.textContent='Furniture preview failed during '+phase+'. The product image is shown. See browser console for details.';status.classList.add('is-error');submit.disabled=true}}
  function buildModel(specs){
    removeModel();
    // Assemble the support at its rest height first. Its mounting surfaces and
    // the meshes touching them must undergo exactly the same displacement.
    const support=config.find(d=>['sofa_leg','table_leg','bed_legs','dining_legs','desk_legs','wardrobe_foot'].includes(d.component_key));
    const requestedSupport=support && specs[String(support.component_id)];
    if(requestedSupport?.quantity){
      specs={...specs,[support.component_id]:{...requestedSupport,
        dimensions:{...requestedSupport.dimensions,height_cm:Number(support.default_height_cm)},
        position:{x:Number(support.default_x_cm),y:Number(support.default_y_cm),z:Number(support.default_z_cm)}
      }};
    }
    const positionsByComponent=new Map();for(const def of config){const spec=specs[String(def.component_id)],id=String(def.component_id),q=spec.quantity;if(q<1){positionsByComponent.set(id,[]);continue}const w=spec.dimensions.width_cm,d=spec.dimensions.depth_cm,h=spec.dimensions.height_cm,positions=[],anchorDef=def.anchor_component_key?config.find(c=>c.component_key===def.anchor_component_key):null,anchor=anchorDef?specs[String(anchorDef.component_id)]:null,parentPositions=anchorDef?positionsByComponent.get(String(anchorDef.component_id)):null;if(anchorDef&&(!anchor||anchor.quantity<1)){positionsByComponent.set(id,[]);continue}if(templateInfo.get(def.component_key)?.mode==='leg_group')positions.push(spec.position);else if(def.component_key==='wardrobe_shelf'&&anchor){const floor=anchor.position.y-anchor.dimensions.height_cm/2,low=floor+anchor.dimensions.height_cm*.51,high=floor+anchor.dimensions.height_cm*.96,shift=spec.position.y-Number(def.default_y_cm);for(let i=0;i<q;i++){const y=(q===1?(low+high)/2:low+(high-low)*i/(q-1))+shift;positions.push({...spec.position,y})}}else if(def.layout_axis==='x'&&parentPositions?.length>1){const baseCount=Math.floor(q/parentPositions.length),remainder=q%parentPositions.length;parentPositions.forEach((parent,index)=>{const count=baseCount+(index<remainder?1:0);for(let i=0;i<count;i++)positions.push({...spec.position,x:parent.x+spec.position.x-Number(def.default_x_cm)+(i-(count-1)/2)*(w+2)})})}else if(def.layout_axis==='corners'){const layouts={1:[[0,0]],2:[[-1,-1],[1,1]],3:[[-1,-1],[1,-1],[0,1]],4:[[-1,-1],[1,-1],[-1,1],[1,1]],5:[[-1,-1],[1,-1],[-1,1],[1,1],[0,0]],6:[[-1,-1],[1,-1],[-1,1],[1,1],[-1,0],[1,0]],7:[[-1,-1],[1,-1],[-1,1],[1,1],[-1,0],[1,0],[0,-1]],8:[[-1,-1],[1,-1],[-1,1],[1,1],[-1,0],[1,0],[0,-1],[0,1]]},corners=layouts[q]||layouts[8],hostW=anchor?.dimensions.width_cm||Number(def.default_width_cm),hostD=anchor?.dimensions.depth_cm||Number(def.default_depth_cm);for(let i=0;i<q;i++)positions.push({x:(anchor?.position.x||0)+spec.position.x+corners[i][0]*Math.max(0,(hostW-w)/2),y:spec.position.y,z:(anchor?.position.z||0)+spec.position.z+corners[i][1]*Math.max(0,(hostD-d)/2)})}else if(def.layout_axis==='x'||def.layout_axis==='y'||def.layout_axis==='z'||def.layout_axis==='shelves'||def.layout_axis==='columns'||def.layout_axis==='spread_z'){const axis=def.layout_axis==='shelves'?'y':def.layout_axis==='columns'?'x':def.layout_axis==='spread_z'?'z':def.layout_axis,span=axis==='x'?w:axis==='y'?h:d,hostSpan=anchor?.dimensions[axis==='x'?'width_cm':axis==='y'?'height_cm':'depth_cm'],spacing=['shelves','columns','spread_z'].includes(def.layout_axis)&&hostSpan?hostSpan/(q+1):span+2,base=anchor&&axis!=='y'?anchor.position[axis]+spec.position[axis]-Number(def[`default_${axis}_cm`]):spec.position[axis],center=def.layout_axis==='shelves'&&anchor?anchor.position.y+spec.position.y-Number(def.default_y_cm):base;for(let i=0;i<q;i++){const offset=(i-(q-1)/2)*spacing;positions.push({...spec.position,[axis]:center+offset})}}else positions.push(spec.position);
      positionsByComponent.set(id,positions);const group=new THREE.Group();group.userData={componentId:id};(templateInfo.get(def.component_key)?.mode==="named_group"?positions.slice(0,1):positions).forEach((pos,i)=>{const object=modelObject(def,spec,i,anchor);if(templateInfo.get(def.component_key)?.mode==='named_group'){
        const scale=new THREE.Vector3(w/def.default_width_cm,h/def.default_height_cm,d/def.default_depth_cm);
        const bounds=new THREE.Box3().setFromObject(object);
        const center=bounds.getCenter(new THREE.Vector3());
        // Floor-bearing assemblies retain their original contact elevation as height changes.
        // Explicit Y-position edits still apply after scaling.
        if (bounds.min.y <= 0.025 || ['table_top','dining_top','bed_pillows','bed_mattress'].includes(def.component_key)) {
          center.y=bounds.min.y;
        }
        if (['left_arm','right_arm'].includes(def.component_key)) {
          // Keep the arm seated on the deck and keep its inner mounting face fixed.
          center.y = bounds.min.y;
          center.x = def.component_key === 'left_arm' ? bounds.max.x : bounds.min.x;
        }
        if (def.component_key === 'sofa_leg') {
          // The two welded sled ends span the sofa. Resize each around its own
          // centre; the depth parameter changes the sled by the requested cm.
          for (const sled of object.children) {
            const box = new THREE.Box3().setFromObject(sled, true);
            const pivot = box.getCenter(new THREE.Vector3());
            const depth = box.max.z - box.min.z;
            const depthRatio = 1 + (d - def.default_depth_cm) / (100 * depth);
            sled.scale.x *= scale.x;
            sled.scale.z *= depthRatio;
            sled.position.x += pivot.x * (1 - scale.x);
            sled.position.z += pivot.z * (1 - depthRatio);
          }
          scale.x = scale.z = 1;
        }
        if (def.component_key === 'table_frame') center.y = bounds.max.y;
        if (def.component_key === 'desk_drawer_front') center.z = bounds.max.z;
        if (def.component_key==='desk_drawer_handle') center.z=bounds.min.z;
        if (['table_leg','bed_legs','dining_legs'].includes(def.component_key)) {
          shapeShafts(object,scale);
          scale.x=scale.z=1;
        }
        object.scale.copy(scale);
        object.position.set(
          center.x*(1-scale.x)+(spec.position.x-def.default_x_cm)/100,
          center.y*(1-scale.y)+(spec.position.y-def.default_y_cm)/100,
          center.z*(1-scale.z)+(spec.position.z-def.default_z_cm)/100
        );
      }else {
        const floorOffset = def.component_key === 'wardrobe_foot' ? (h-def.default_height_cm)/2 : 0;
        object.position.set(pos.x/100,(pos.y+floorOffset)/100,pos.z/100);
      }
      group.add(object)});meshes.set(id,group);scene.add(group)}
    // Apply parent travel in addition to each child's own editable offset.
    for (const [parentKey, children] of [
      ['desk_drawer', ['desk_drawer_front', 'desk_drawer_handle']],
      ['desk_drawer_front', ['desk_drawer_handle']]
    ]) {
      const parent = config.find(d => d.component_key === parentKey);
      if (!parent) continue;
      const position = specs[String(parent.component_id)].position;
      for (const key of children) {
        const child = config.find(d => d.component_key === key);
        const group = child && meshes.get(String(child.component_id));
        if (!group) continue;
        for (const axis of ['x', 'y', 'z']) {
          group.position[axis] += (position[axis] - parent['default_' + axis + '_cm']) / 100;
        }
      }
    }
    const componentGroup = key => {
      const def = config.find(part => part.component_key === key);
      return def && meshes.get(String(def.component_id));
    };
    const mattress = componentGroup('bed_mattress');
    const bedFrame = componentGroup('bed_frame');
    if (mattress && bedFrame) {
      const slats = new THREE.Box3();
      bedFrame.updateWorldMatrix(true,true);
      bedFrame.traverse(mesh => {
        if (mesh.isMesh && /sprung_oak_slat/i.test(mesh.name)) slats.expandByObject(mesh,true);
      });
      if (!slats.isEmpty()) {
        const def = config.find(part => part.component_key === 'bed_mattress');
        const spec = specs[String(def.component_id)];
        const bounds = new THREE.Box3().setFromObject(mattress,true);
        const offset = (spec.position.y - def.default_y_cm) / 100;
        const lift = slats.max.y - bounds.min.y + offset;
        mattress.position.y += lift;
        const thickness = bounds.max.y - bounds.min.y;
        const growth = thickness * (1 - def.default_height_cm / spec.dimensions.height_cm);
        for (const key of ['bed_pillows','bed_quilt','bed_folded_return']) {
          const bedding = componentGroup(key);
          if (bedding) bedding.position.y += lift + growth + offset;
        }
      }
    }
    const doors = componentGroup('wardrobe_door');
    const pulls = componentGroup('wardrobe_handle');
    if (doors?.children.length && pulls?.children.length) {
      const handle = config.find(d => d.component_key === 'wardrobe_handle');
      const offset = (specs[String(handle.component_id)].position.z - handle.default_z_cm) / 100;
      doors.updateWorldMatrix(true, true);
      for (const pull of pulls.children) {
        const bounds = new THREE.Box3().setFromObject(pull, true);
        const origin = bounds.getCenter(new THREE.Vector3());
        origin.z = new THREE.Box3().setFromObject(doors, true).max.z + 1;
        const mountingFace = new THREE.Raycaster(origin, new THREE.Vector3(0,0,-1))
          .intersectObject(doors, true)[0];
        if (mountingFace) pull.position.z += mountingFace.point.z - bounds.min.z + offset;
      }
    }
    const leaf = componentGroup('dining_extension_leaf');
    const slidingTop = componentGroup('dining_top');
    if (leaf && slidingTop) {
      const def = config.find(d => d.component_key === 'dining_extension_leaf');
      const ratio = specs[String(def.component_id)].dimensions.width_cm / def.default_width_cm;
      if (ratio !== 1) {
        const span = new THREE.Box3().setFromObject(leaf, true).getSize(new THREE.Vector3()).x;
        const travel = (span - span / ratio) / 2;
        for (const panel of slidingTop.children[0].children) {
          const center = new THREE.Box3().setFromObject(panel, true).getCenter(new THREE.Vector3());
          panel.position.x += Math.sign(center.x) * travel / slidingTop.children[0].scale.x;
        }
      }
    }
    if(requestedSupport?.quantity){
      const base=meshes.get(String(support.component_id));
      if(base && base.children.length) fitSupportMounts(base,support,requestedSupport);
    }
    if (support?.component_key === 'wardrobe_foot' && requestedSupport?.quantity) {
      const feet = meshes.get(String(support.component_id));
      const carcass = config.find(part => part.component_key === 'wardrobe_frame');
      const frame = carcass && meshes.get(String(carcass.component_id));
      if (feet && frame) {
        // Move the corner mounts inside the panel's rounded perimeter.
        const frameSize = new THREE.Box3().setFromObject(frame, true).getSize(new THREE.Vector3());
        for (const foot of feet.children) {
          for (const axis of ['x','z']) {
            const setback = Math.min(0.10, frameSize[axis] * 0.18);
            foot.position[axis] -= Math.sign(foot.position[axis]) * Math.min(Math.abs(foot.position[axis]), setback);
          }
        }
        const seatHeight = new THREE.Box3().setFromObject(feet, true).max.y;
        const underside = new THREE.Box3().setFromObject(frame, true).min.y;
        for (const assembly of meshes.values()) {
          if (assembly !== feet) assembly.position.y += seatHeight - underside - 0.001; // Seat each rim 1 mm into the panel.
        }
      }
    }
    resizeAssembly();
    root.querySelectorAll('.component-card').forEach(card=>card.classList.toggle('is-selected',card.dataset.componentId===selectedId));if(!modelFitted){fitModelIfNeeded();modelFitted=true}
  }
  function fitModelIfNeeded(){if(!ready)return;const box=new THREE.Box3();for(const obj of meshes.values())box.expandByObject(obj);if(box.isEmpty())return;const size=box.getSize(new THREE.Vector3()),center=box.getCenter(new THREE.Vector3());controls.target.copy(center);const max=Math.max(size.x,size.y,size.z);camera.position.copy(center).add(new THREE.Vector3(max*1.55,max*1.05,max*1.9));camera.near=Math.max(.01,max/100);camera.far=max*30;camera.updateProjectionMatrix();controls.update();if(!cameraDefault){cameraDefault=camera.position.clone();targetDefault=controls.target.clone()}}
  function resetCameraView(){if(!cameraDefault||!controls)return;controls.autoRotate=false;camera.position.copy(cameraDefault);controls.target.copy(targetDefault);camera.zoom=1;camera.updateProjectionMatrix();controls.update();autoRotate=false;const b=document.querySelector('#rotate-model');if(b)b.textContent='Auto rotate'}
  let selectionOutline=null,selectionOutlineTimer=0;
  function clearSelectionHighlight(){if(selectionOutlineTimer){clearTimeout(selectionOutlineTimer);selectionOutlineTimer=0}if(selectionOutline){scene.remove(selectionOutline);selectionOutline.geometry.dispose();selectionOutline.material.dispose();selectionOutline=null}}
  function highlightSelection(){clearSelectionHighlight();const group=meshes.get(selectedId);if(!group)return;group.updateWorldMatrix(true,true);const bounds=new THREE.Box3().setFromObject(group);if(bounds.isEmpty())return;selectionOutline=new THREE.Box3Helper(bounds,new THREE.Color('#d48b3d'));selectionOutline.material.depthTest=true;selectionOutline.material.transparent=true;selectionOutline.material.opacity=.9;selectionOutline.renderOrder=5;scene.add(selectionOutline);selectionOutlineTimer=setTimeout(clearSelectionHighlight,1600)}
  function select(id,fromMesh=false,showHighlight=true){selectedId=String(id);root.querySelectorAll('.component-card').forEach(card=>card.classList.toggle('is-selected',card.dataset.componentId===selectedId));if(showHighlight)highlightSelection();else clearSelectionHighlight();if(fromMesh)root.querySelector(`[data-component-id="${selectedId}"]`)?.scrollIntoView({behavior:'smooth',block:'nearest'});status.textContent=modelVisible?(productId===2?`Selected: ${defs.get(selectedId)?.display_name||'component'}. Change its supported material or color below.`:`Selected: ${defs.get(selectedId)?.display_name||'component'}. Edit its supported surface below.`):'Preparing furniture preview…'}
  root.addEventListener('click',e=>{const btn=e.target.closest('[data-select-component]');if(btn){select(btn.dataset.selectComponent);syncColorEditor()}const card=e.target.closest('.material-card');if(card){const owner=card.closest('.component-card');select(owner.dataset.componentId,false,false);syncColorEditor();const input=root.querySelector(`[data-component-id="${selectedId}"][data-field="option_material"]`);if(input){input.value=card.dataset.optionId;input.dispatchEvent(new Event('change',{bubbles:true}));owner.querySelectorAll('.material-card').forEach(x=>x.classList.toggle('selected',x===card))}}});
  root.addEventListener('input',e=>{if(e.target.matches('.overall-dimension-input'))updateSpecs();else if(e.target.matches('.component-field'))updateSpecs()});root.addEventListener('change',e=>{if(e.target.matches('.overall-dimension-input'))updateSpecs();else if(e.target.matches('.component-field,.option-input'))updateSpecs()});root.addEventListener('click',e=>{const resetDimensions=e.target.closest('#reset-dimensions');if(resetDimensions){root.querySelectorAll('.overall-dimension-input').forEach(input=>{input.value=input.dataset.default;input.setCustomValidity('')});updateSpecs();return}const stepButton=e.target.closest('[data-dimension-step]');if(!stepButton)return;const input=document.getElementById(stepButton.dataset.target);if(!input)return;const step=Number(input.step)||1,next=Math.max(Number(input.min),Math.min(Number(input.max),Number(input.value)+Number(stepButton.dataset.dimensionStep)*step));input.value=Number(next.toFixed(4));input.dispatchEvent(new Event('input',{bubbles:true}))});root.querySelectorAll('[data-select-component]').forEach(b=>b.addEventListener('focus',()=>select(b.dataset.selectComponent)));
  canvas.addEventListener('pointerup',e=>{const rect=canvas.getBoundingClientRect();pointer.x=((e.clientX-rect.left)/rect.width)*2-1;pointer.y=-((e.clientY-rect.top)/rect.height)*2+1;raycaster.setFromCamera(pointer,camera);const hits=raycaster.intersectObjects([...meshes.values()],true);if(hits.length){let obj=hits[0].object;while(obj&&!obj.userData.componentId)obj=obj.parent;if(obj?.userData.componentId)select(obj.userData.componentId,true)}});
  document.querySelector('#rotate-model')?.addEventListener('click',()=>{autoRotate=!autoRotate;controls.autoRotate=autoRotate;document.querySelector('#rotate-model').textContent=autoRotate?'Stop rotation':'Auto rotate'});document.querySelector('#reset-camera')?.addEventListener('click',resetCameraView);
  form.addEventListener('reset',()=>setTimeout(updateSpecs,0));
  const resetDialog=document.querySelector('#reset-confirm');document.querySelector('#reset-config')?.addEventListener('click',()=>{clearSelectionHighlight();resetDialog?.showModal()});document.querySelector('#cancel-reset')?.addEventListener('click',()=>resetDialog?.close());document.querySelector('#confirm-reset')?.addEventListener('click',()=>{clearSelectionHighlight();resetDialog?.close();form.reset();initialFormState.forEach(x=>{x.el.value=x.value;if(x.el.type==='radio'||x.el.type==='checkbox')x.el.checked=x.checked});setTimeout(()=>{root.querySelectorAll('input,select,textarea').forEach(el=>el.setCustomValidity(''));root.querySelectorAll('.material-card').forEach(el=>el.classList.remove('selected'));selectedId=String(config[0]?.component_id||'');select(selectedId,false,false);syncColorEditor();updateSpecs()},0)});
  function resize(){if(!renderer)return;const w=canvas.clientWidth,h=canvas.clientHeight;if(!w||!h)return;renderer.setSize(w,h,false);camera.aspect=w/h;camera.updateProjectionMatrix()};new ResizeObserver(resize).observe(canvas);resize();
  const colorPicker=document.querySelector('#custom-color-picker'),colorHex=document.querySelector('#custom-color-hex'),colorCategory=document.querySelector('#color-category'),swatches=document.querySelector('#palette-swatches');let recent=JSON.parse(localStorage.getItem('ffxRecentColors')||'[]'),favorites=JSON.parse(localStorage.getItem('ffxFavoriteColors')||'[]');
  function setColor(hex){if(!selectedId||!/^#[\da-f]{6}$/i.test(hex))return;colorHex.setCustomValidity('');colorHex.value=hex.toUpperCase();colorPicker.value=hex;const rgb=hex.match(/[\da-f]{2}/ig).map(x=>parseInt(x,16));document.querySelector('#color-rgb').textContent=`RGB ${rgb.join(', ')}`;const field=root.querySelector(`[data-component-id="${selectedId}"][data-field="custom_color"]`);field.value=hex.toUpperCase();recent=[hex.toUpperCase(),...recent.filter(x=>x!==hex.toUpperCase())].slice(0,8);localStorage.setItem('ffxRecentColors',JSON.stringify(recent));paintSwatches();updateSpecs()}
  function paintSwatches(){if(!swatches)return;const cat=colorCategory.value;swatches.replaceChildren();palette.filter(c=>cat==='all'||c.category===cat).forEach(c=>{const b=document.createElement('button');b.type='button';b.title=`${c.color_name} ${c.color_hex}`;b.className='palette-swatch';b.style.background=c.color_hex;b.addEventListener('click',()=>setColor(c.color_hex));swatches.append(b)});document.querySelector('#recent-colors').replaceChildren(...recent.map(c=>colorChip(c)));document.querySelector('#favorite-colors').replaceChildren(...favorites.map(c=>colorChip(c)))}
  function colorChip(hex){const b=document.createElement('button');b.type='button';b.className='palette-swatch mini';b.title=hex;b.style.background=hex;b.addEventListener('click',()=>setColor(hex));return b}
  function syncColorEditor(){document.querySelector('#color-target-label').textContent=`· ${defs.get(selectedId)?.display_name||''}`;const c=formValue(selectedId,'custom_color')||'#CABAA3';colorPicker.value=c;colorHex.value=c;const rgb=c.match(/[\da-f]{2}/ig)?.map(x=>parseInt(x,16))||[202,186,163];document.querySelector('#color-rgb').textContent=`RGB ${rgb.join(', ')}`}
  colorPicker.addEventListener('input',()=>setColor(colorPicker.value));colorHex.addEventListener('change',()=>{if(/^#[\da-f]{6}$/i.test(colorHex.value))setColor(colorHex.value);else colorHex.setCustomValidity('Enter a 6-digit HEX value such as #B88752')});colorHex.addEventListener('input',()=>{colorHex.setCustomValidity('');if(/^#[\da-f]{6}$/i.test(colorHex.value))setColor(colorHex.value)});colorHex.addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();if(/^#[\da-f]{6}$/i.test(colorHex.value))setColor(colorHex.value);colorHex.blur()}});colorCategory.addEventListener('change',paintSwatches);document.querySelector('#favorite-color').addEventListener('click',()=>{const c=colorHex.value.toUpperCase();if(!/^#[0-9a-f]{6}$/i.test(c)){colorHex.reportValidity();return}favorites=favorites.includes(c)?favorites.filter(x=>x!==c):[c,...favorites].slice(0,12);localStorage.setItem('ffxFavoriteColors',JSON.stringify(favorites));paintSwatches()});paintSwatches();
  root.querySelectorAll('.material-library').forEach(detail=>{const search=detail.querySelector('.material-search'),category=detail.querySelector('.material-category');const filter=()=>detail.querySelectorAll('.material-card').forEach(card=>card.hidden=!(card.dataset.name.includes(search.value.toLowerCase())&&(category.value==='all'||category.value===card.dataset.category)));search.addEventListener('input',filter);category.addEventListener('change',filter)});
if(renderer&&controls&&modelUrl){
  const loader=new GLTFLoader();
  loader.load('/FurniFlex/'+modelUrl,gltf=>{
    let phase='component mapping';
    const actualNodes=[],mappingFailures=[];
    try{
      const model=gltf.scene,mappings=mappedNodes[productId];
      model.traverse(o=>actualNodes.push({type:o.type,name:o.name||'<unnamed>',glb_source_name:o.userData?.name||null,isMesh:Boolean(o.isMesh)}));
      if(mappings){
        for(const def of config){
          const binding=mappings[def.component_key];
          if(!binding){mappingFailures.push({component_key:def.component_key,actual_node_name:null,reason:'No explicit mapping for this database component key'});continue}
          const group=new THREE.Group();
          for(const nodeSpec of binding.nodes){
            const marker=nodeSpec.lastIndexOf('#'),hasOccurrence=marker>=0,nodeName=hasOccurrence?nodeSpec.slice(0,marker):nodeSpec,occurrence=hasOccurrence?Number(nodeSpec.slice(marker+1)):null,matches=[];
            // GLTFLoader sanitizes Object3D.name (spaces/punctuation and duplicate suffixes).
            // It preserves the exact asset node name in userData.name; match that first.
            model.traverse(o=>{const sourceName=typeof o.userData?.name==='string'&&o.userData.name?o.userData.name:o.name;if(sourceName===nodeName)matches.push(o)});
            const source=hasOccurrence?matches[occurrence]:(matches.length===1?matches[0]:null);
            const sourceMeshes=[];source?.traverse(o=>{if(o.isMesh)sourceMeshes.push(o)});
            if(!source||!sourceMeshes.length){mappingFailures.push({component_key:def.component_key,configured_glb_node_name:nodeName,actual_node_name:matches.map(o=>({runtime_name:o.name,glb_source_name:o.userData?.name||null,type:o.type,isMesh:o.isMesh})),requested_occurrence:occurrence,matching_nodes:matches.length,reason:matches.length>1&&!hasOccurrence?'Repeated node name requires an explicit #occurrence index':'Exact source name was not found or contains no meshes'});continue}
            const part=source.clone(true),wrapper=new THREE.Group();
            if(binding.mode==='named_group'){wrapper.position.copy(source.position);wrapper.quaternion.copy(source.quaternion);wrapper.scale.copy(source.scale);part.position.set(0,0,0);part.quaternion.identity();part.scale.set(1,1,1)}
            else part.position.set(0,0,0);
            wrapper.userData={assetOffsetXRatio:binding.mode==='leg_group'?source.position.x/(binding.sourceTableDimensionsCm.width/100):0,assetOffsetZRatio:binding.mode==='leg_group'?source.position.z/(binding.sourceTableDimensionsCm.depth/100):0};
            wrapper.add(part);group.add(wrapper);
          }
          if(group.children.length!==binding.nodes.length)mappingFailures.push({component_key:def.component_key,actual_node_name:binding.nodes.map(x=>x.replace(/#\d+$/,'')),resolved_nodes:group.children.length,expected_nodes:binding.nodes.length,reason:'Not all configured nodes resolved'});
          else{templates.set(def.component_key,group);templateInfo.set(def.component_key,binding)}
        }
      }else{
        model.traverse(o=>{if(o.isMesh){o.castShadow=true;o.receiveShadow=true}const key=o.userData?.component_key||(/^FFX_component:(.+)$/.exec(o.name||'')?.[1]);if(key)templates.set(key,o)})
      }
      const missingKeys=config.filter(d=>!templates.has(d.component_key)).map(d=>d.component_key);
      if(mappingFailures.length||missingKeys.length){
        const first=mappingFailures[0]||{component_key:missingKeys[0],configured_glb_node_name:null,reason:'No template was built for the configured component'};
        const nodeLabel=Array.isArray(first.actual_node_name)?first.actual_node_name.map(x=>x.glb_source_name||x.runtime_name).join(', '):(first.configured_glb_node_name||'no mapped node');
        const error=new Error('Component mapping failed during initialization: '+first.component_key+' → '+nodeLabel+' ('+first.reason+')');
        setModelStatus('Component mapping failed: '+first.component_key+' → '+nodeLabel,true);
        console.error('FurniFlex component mapping failed',error,{modelUrl,productId,missingKeys,mappingFailures,actualNodes});
        submit.disabled=true;return;
      }
      phase='initial configuration';
      ready=true;selectedId=String(config[0].component_id);setModelStatus('Preparing furniture preview…');submit.disabled=true;select(selectedId,false,false);updateSpecs();
    }catch(error){
      console.error('FurniFlex initialization failed during '+phase,error,{modelUrl,productId,actualNodes});
      setModelStatus('Furniture preview failed during '+phase+'. See browser console for details.',true);submit.disabled=true;
    }
  },undefined,error=>{
    console.error('FurniFlex GLB load/parse failed',error,{modelUrl,productId,stack:error?.stack});
    setModelStatus('Furniture GLB failed to load. See browser console for details.',true);submit.disabled=true;
  });
}else{
  setModelStatus(modelUrl?'3D preview is unavailable in this browser.':'No local furniture model is configured.',true);submit.disabled=true
}
  let animationFrame=0,animationStopped=false;function failRuntime(error,phase='interactive rendering'){animationStopped=true;if(animationFrame)cancelAnimationFrame(animationFrame);modelVisible=false;stage.classList.remove('model-ready');stage.classList.add('model-error');status.textContent=`Furniture preview failed during ${phase}. The product image is shown.`;status.classList.add('is-error');submit.disabled=true;console.error('FurniFlex runtime render failed during '+phase,error,{modelUrl,productId,selectedId,stack:error?.stack})}function animate(){if(animationStopped)return;animationFrame=requestAnimationFrame(animate);if(!renderer||!modelVisible)return;try{controls.update();renderer.render(scene,camera);if(renderer.getContext().isContextLost())throw new Error('WebGL context was lost during interactive rendering.')}catch(error){failRuntime(error)}}canvas.addEventListener('webglcontextlost',event=>{event.preventDefault();failRuntime(new Error('WebGL context was lost.'),'WebGL context loss')});animate();
}
