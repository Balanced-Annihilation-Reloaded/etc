Widget part of BAs unit/weapon def _post baking functionality

To use:
(1) Set SaveDefsToCustomParams to true in alldefs_post.lua
(2) Put the widget part in your widgets dir
(3) Load the game, run the widget
(4) Defs, with their _Post functions from alldefs_post.lua applied should now be in Spring/baked_defs/

Notes:
! Make sure your unit defs don't contain lua keywords as table keys (remove them with unitdefs_post if so)
! Make sure you don't bake in any modoptions that alter unitdefs
! It will round ~all numbers to 5dp and then remove trailing 0s after the decimal point, to avoid e.g. 0==0.000000234876
! It will convert all string keys to lower case
