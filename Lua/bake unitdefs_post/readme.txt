Funtionality to bake unitdefs_post into unitdef files

(1) Put unitdefs_post_save_to_customparams.lua in gamedata
(2) Put unitdefs_write.lua in widgets
(3) Add VFS.Include("gamedata/unitdefs_post_save_to_customparams.lua")
 to unitdefs_post, at the point where you want to bake
(4) Load Spring, then load the widget
(5) Look in the spring folder, unitdefs should all be written to file

Notes:
! Make sure your unit defs don't contain lua keywords as table keys (remove them with unitdefs_post if so)
! Make sure you don't bake in any modoptions that alter unitdefs
! It will round all numbers to 5dp and then remove trailing 0s after the decimal point, to avoid e.g. 0==0.000000234876
! It will convert all string keys to lower case
! It won't bake weapondefs_post (make the changes in unitdefs_post and bake that instead)