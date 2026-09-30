const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require(process.env.SHARP_MODULE || '/Users/jaili/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const review = process.argv[2] || '/Users/jaili/.codex/visualizations/2026/09/30/01a0efce-95b9-7de2-a18c-c2741271cd54/review-v2';
const original = process.argv[3] || '/Users/jaili/.codex/generated_images/01a0efce-95b9-7de2-a18c-c2741271cd54/exec-b2389264-3414-4ec6-81b3-a662e727f096.png';
const glyphs = {
  ' ':['00000','00000','00000','00000','00000','00000','00000'],
  A:['01110','10001','10001','11111','10001','10001','10001'],B:['11110','10001','10001','11110','10001','10001','11110'],C:['01111','10000','10000','10000','10000','10000','01111'],D:['11110','10001','10001','10001','10001','10001','11110'],E:['11111','10000','10000','11110','10000','10000','11111'],F:['11111','10000','10000','11110','10000','10000','10000'],G:['01111','10000','10000','10111','10001','10001','01111'],H:['10001','10001','10001','11111','10001','10001','10001'],I:['11111','00100','00100','00100','00100','00100','11111'],J:['00111','00010','00010','00010','10010','10010','01100'],K:['10001','10010','10100','11000','10100','10010','10001'],L:['10000','10000','10000','10000','10000','10000','11111'],M:['10001','11011','10101','10101','10001','10001','10001'],N:['10001','11001','10101','10011','10001','10001','10001'],O:['01110','10001','10001','10001','10001','10001','01110'],P:['11110','10001','10001','11110','10000','10000','10000'],Q:['01110','10001','10001','10001','10101','10010','01101'],R:['11110','10001','10001','11110','10100','10010','10001'],S:['01111','10000','10000','01110','00001','00001','11110'],T:['11111','00100','00100','00100','00100','00100','00100'],U:['10001','10001','10001','10001','10001','10001','01110'],V:['10001','10001','10001','10001','10001','01010','00100'],W:['10001','10001','10001','10101','10101','10101','01010'],X:['10001','10001','01010','00100','01010','10001','10001'],Y:['10001','10001','01010','00100','00100','00100','00100'],Z:['11111','00001','00010','00100','01000','10000','11111'],
  '0':['01110','10001','10011','10101','11001','10001','01110'],'1':['00100','01100','00100','00100','00100','00100','01110'],'2':['01110','10001','00001','00010','00100','01000','11111'],'3':['11110','00001','00001','01110','00001','00001','11110'],'4':['00010','00110','01010','10010','11111','00010','00010'],'5':['11111','10000','10000','11110','00001','00001','11110'],'6':['01110','10000','10000','11110','10001','10001','01110'],'7':['11111','00001','00010','00100','01000','01000','01000'],'8':['01110','10001','10001','01110','10001','10001','01110'],'9':['01110','10001','10001','01111','00001','00001','01110'],
  '-':['00000','00000','00000','11111','00000','00000','00000'],':':['00000','00100','00100','00000','00100','00100','00000'],'.':['00000','00000','00000','00000','00000','00100','00100'],'!':['00100','00100','00100','00100','00100','00000','00100']
};
const roster=[];
function save(relative,bytes,source){
  const dest=path.join(root,relative);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.writeFileSync(dest,bytes);
  roster.push({path:relative,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),source});
}
async function pixels(relative,w,h,draw,source){
  const data=Buffer.alloc(w*h*4);
  const set=(x,y,c)=>{if(x>=0&&x<w&&y>=0&&y<h)data.set(c,(y*w+x)*4);};
  draw(set);save(relative,await sharp(data,{raw:{width:w,height:h,channels:4}}).png().toBuffer(),source);
}
(async()=>{
  const mapping={player:'player-ship',alien_blue:'green-enemy',alien_purple:'violet-enemy',alien_red:'red-enemy',alien_flagship:'boss'};
  for(const [target,source]of Object.entries(mapping)){
    const frames=[];
    for(let i=1;i<=3;i++){
      const bytes=fs.readFileSync(path.join(review,`${source}-${i}.png`));
      save(`assets/approved/frames/${source}-${i}.png`,bytes,`${source}-${i}.png`);
      frames.push({input:bytes,left:(i-1)*24,top:0});
    }
    save(`assets/sprites/${target}.png`,await sharp({create:{width:72,height:24,channels:4,background:'#00000000'}}).composite(frames).png().toBuffer(),'Unmodified approved frames, horizontal strip');
  }
  for(const filename of fs.readdirSync(path.join(review,'music'))){
    save('assets/music/'+filename,fs.readFileSync(path.join(review,'music',filename)),'Approved original chiptune review');
  }
  for(const filename of fs.readdirSync(review).filter(f=>f.endsWith('.webp')||f.endsWith('.json'))){
    save('assets/approved/reference/'+filename,fs.readFileSync(path.join(review,filename)),'Approved UI layout/reference');
  }
  await pixels('assets/ui/glyphs.png',96,48,set=>{
    for(const [letter,rows]of Object.entries(glyphs)){
      const index=letter.charCodeAt(0)-32;
      rows.forEach((row,y)=>[...row].forEach((bit,x)=>{if(bit==='1')set(index%16*6+x,Math.floor(index/16)*8+y,[255,255,255,255]);}));
    }
  },'Crisp 5x7 bitmap lettering matching approved UI');
  await pixels('assets/ui/logo.png',144,24,set=>{
    for(const [ox,oy,c]of [[2,2,[255,0,0,255]],[0,0,[255,255,0,255]]]){
      [...'GALAXIAN'].forEach((letter,k)=>glyphs[letter].forEach((row,y)=>[...row].forEach((bit,x)=>{
        if(bit==='1')for(let dy=0;dy<3;dy++)for(let dx=0;dx<3;dx++)set(k*18+x*3+dx+ox,y*3+dy+oy,c);
      })));
    }
  },'Approved yellow title lettering and red pixel shadow');
  await pixels('assets/sprites/flag.png',12,12,set=>{
    for(let y=1;y<11;y++)set(2,y,[255,255,255,255]);
    for(let y=1;y<=5;y++)for(let x=3;x<9-Math.abs(y-3)*2;x++)set(x,y,[255,0,0,255]);
  },'Approved wave flag');
  await pixels('assets/ui/cursor.png',7,9,set=>{
    for(let y=0;y<9;y++)for(let x=0;x<5-Math.abs(y-4);x++)set(x,y,[255,0,0,255]);
  },'Approved red menu cursor');
  for(const [name,color,height]of [['player_shot',[255,255,255,255],4],['enemy_shot',[255,255,0,255],3]]){
    await pixels(`assets/sprites/${name}.png`,8,8,set=>{for(let y=0;y<height;y++)set(3,2+y,color);},'Approved projectile');
  }
  const crops=[[1005,870,80,100],[1105,865,100,105],[1220,850,118,120],[1360,845,146,140]],effects=[];
  for(let i=0;i<4;i++){
    const [left,top,width,height]=crops[i];
    const raw=await sharp(original).extract({left,top,width,height}).resize(24,24,{kernel:'nearest'}).removeAlpha().raw().toBuffer();
    const rgba=Buffer.alloc(24*24*4);
    for(let p=0;p<576;p++){
      const c=[raw[p*3],raw[p*3+1],raw[p*3+2]];
      if(Math.max(...c)>110)rgba.set(c[1]>160?(c[2]>160?[255,255,255,255]:[255,255,0,255]):[255,30,0,255],p*4);
    }
    effects.push({input:await sharp(rgba,{raw:{width:24,height:24,channels:4}}).png().toBuffer(),left:i*24,top:0});
  }
  const explosion=await sharp({create:{width:120,height:24,channels:4,background:'#00000000'}}).composite(effects).png().toBuffer();
  for(const name of ['alien_explosion','player_explosion'])save(`assets/sprites/${name}.png`,explosion,'Approved four explosion stages, plus transparent end frame');
  fs.writeFileSync(path.join(root,'assets/approved/manifest.json'),JSON.stringify({approval:'User approved migration in this conversation',frameSize:24,roster},null,2)+'\n');
  console.log(`Imported ${roster.length} approved/derived files`);
})();
