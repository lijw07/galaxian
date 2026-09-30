const fs=require('fs');
const path=require('path');
const root=path.resolve(__dirname,'..');
function save(file,text){const full=path.join(root,file);fs.mkdirSync(path.dirname(full),{recursive:true});fs.writeFileSync(full,text+'\n');}
function entity(file,name,script,texture,layer,mask,w,h,properties='',frames=3,disabled=true){
  save('scenes/entities/'+file+'.tscn',`[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/entities/${script}.gd" id="1"]
[ext_resource type="Script" path="res://scripts/entities/arcade_sprite.gd" id="2"]
[ext_resource type="Texture2D" path="res://assets/sprites/${texture}.png" id="3"]

[sub_resource type="RectangleShape2D" id="Hitbox"]
resource_local_to_scene = true
size = Vector2(${w}, ${h})

[node name="${name}" type="Area2D"]
texture_filter = 1
collision_layer = ${layer}
collision_mask = ${mask}
script = ExtResource("1")
${properties}

[node name="Visual" type="Sprite2D" parent="."]
texture = ExtResource("3")
hframes = ${frames}
script = ExtResource("2")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
${frames===1?'position = Vector2(-0.5, '+(file==='enemy_shot'?'-0.5':'0')+')':''}
shape = SubResource("Hitbox")
disabled = ${disabled}`);
}
entity('player','Player','player','player',1,10,10,8);
for(const [file,name,texture,kind]of [['green_enemy','GreenEnemy','alien_blue',0],['violet_enemy','VioletEnemy','alien_purple',1],['red_enemy','RedEnemy','alien_red',2],['boss','Boss','alien_flagship',3]])entity(file,name,'alien',texture,2,5,12,8,`kind = ${kind}`);
entity('player_shot','PlayerShot','projectile','player_shot',4,2,1,4,'velocity = Vector2(0, -280)',1,false);
entity('enemy_shot','EnemyShot','projectile','enemy_shot',8,1,1,3,'velocity = Vector2(0, 110)',1,false);
save('scenes/effects/explosion.tscn',`[gd_scene load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/entities/explosion.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/alien_explosion.png" id="2"]
[node name="Explosion" type="Node2D"]
script = ExtResource("1")
[node name="Visual" type="Sprite2D" parent="."]
texture = ExtResource("2")
hframes = 5`);
for(const [file,name,texture]of [['life_icon','LifeIcon','player'],['wave_flag','WaveFlag','flag']])save(`scenes/ui/${file}.tscn`,`[gd_scene load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://assets/sprites/${texture}.png" id="1"]
[node name="${name}" type="Sprite2D"]
texture = ExtResource("1")
hframes = ${file==='life_icon'?3:1}`);
for(const [file,name,script]of [['hud','Hud','ui/hud'],['starfield','Starfield','entities/starfield']])save(`scenes/${file==='hud'?'ui':'effects'}/${file}.tscn`,`[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/${script}.gd" id="1"]
[node name="${name}" type="Node2D"]
process_mode = 1
script = ExtResource("1")`);
const menus=[
  ['pause_menu','PauseMenu','PAUSED',['RESUME','RESTART','MAIN MENU'],['resume','restart','menu'],148,false],
  ['game_over','GameOverMenu','GAME OVER',['PLAY AGAIN','MAIN MENU'],['restart','menu'],166,true],
  ['high_scores','HighScores','HIGH SCORE',['BACK'],['menu'],177,true],
];
for(const [file,name,heading,options,actions,baseline,score]of menus)save(`scenes/ui/${file}.tscn`,`[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/ui/arcade_menu.gd" id="1"]
[node name="${name}" type="Node2D"]
process_mode = 3
visible = false
script = ExtResource("1")
heading = "${heading}"
heading_color = ${file==='game_over'?'Color(1, 0, 0, 1)':'Color(1, 1, 0, 1)'}
options = PackedStringArray(${options.map(JSON.stringify).join(', ')})
actions = PackedStringArray(${actions.map(JSON.stringify).join(', ')})
first_baseline = ${baseline}.0
dim_background = ${file==='pause_menu'}
show_score = ${score}`);
save('scenes/ui/title_screen.tscn',`[gd_scene load_steps=5 format=3]
[ext_resource type="Script" path="res://scripts/ui/title_screen.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/ui/logo.png" id="2"]
[ext_resource type="Texture2D" path="res://assets/sprites/alien_flagship.png" id="3"]
[ext_resource type="Script" path="res://scripts/entities/arcade_sprite.gd" id="4"]
[node name="TitleScreen" type="Node2D"]
process_mode = 3
script = ExtResource("1")
options = PackedStringArray("START GAME", "HIGH SCORES", "QUIT")
actions = PackedStringArray("start", "scores", "quit")
first_baseline = 154.0
[node name="Logo" type="Sprite2D" parent="."]
position = Vector2(112, 62)
texture = ExtResource("2")
[node name="BossIcon" type="Sprite2D" parent="."]
position = Vector2(112, 108)
scale = Vector2(2, 2)
texture = ExtResource("3")
hframes = 3
script = ExtResource("4")`);
save('scenes/game.tscn',`[gd_scene load_steps=5 format=3]
[ext_resource type="Script" path="res://scripts/game.gd" id="1"]
[ext_resource type="Script" path="res://scripts/entities/formation.gd" id="2"]
[ext_resource type="Script" path="res://scripts/entities/attack_director.gd" id="3"]
[ext_resource type="PackedScene" path="res://scenes/entities/player.tscn" id="4"]
[node name="Game" type="Node2D"]
process_mode = 1
script = ExtResource("1")
[node name="Formation" type="Node" parent="."]
script = ExtResource("2")
[node name="AttackDirector" type="Node" parent="."]
script = ExtResource("3")
[node name="Aliens" type="Node2D" parent="."]
[node name="Projectiles" type="Node2D" parent="."]
[node name="Player" parent="." instance=ExtResource("4")]
visible = false
[node name="Effects" type="Node2D" parent="."]`);
save('scenes/main.tscn',`[gd_scene load_steps=9 format=3]
[ext_resource type="Script" path="res://scripts/main.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/effects/starfield.tscn" id="2"]
[ext_resource type="PackedScene" path="res://scenes/game.tscn" id="3"]
[ext_resource type="PackedScene" path="res://scenes/ui/hud.tscn" id="4"]
[ext_resource type="PackedScene" path="res://scenes/ui/title_screen.tscn" id="5"]
[ext_resource type="PackedScene" path="res://scenes/ui/pause_menu.tscn" id="6"]
[ext_resource type="PackedScene" path="res://scenes/ui/game_over.tscn" id="7"]
[ext_resource type="PackedScene" path="res://scenes/ui/high_scores.tscn" id="8"]
[node name="Main" type="Node2D"]
process_mode = 3
script = ExtResource("1")
[node name="Starfield" parent="." instance=ExtResource("2")]
[node name="Game" parent="." node_paths=PackedStringArray("hud", "starfield") instance=ExtResource("3")]
hud = NodePath("../Hud")
starfield = NodePath("../Starfield")
[node name="Hud" parent="." instance=ExtResource("4")]
[node name="TitleScreen" parent="." instance=ExtResource("5")]
[node name="PauseMenu" parent="." instance=ExtResource("6")]
[node name="GameOverMenu" parent="." instance=ExtResource("7")]
[node name="HighScores" parent="." instance=ExtResource("8")]`);
console.log('Built 18 reusable scenes');
