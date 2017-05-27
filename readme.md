
# hyperex

hyperex is [Hammerspoon](http://www.hammerspoon.org/) script which provides yet another modifier key. With simplicity, adaptability, diversity.

## Release Note

### 0.3
- Can be attached to modifier key now

### 0.2.1
 - [Setting priority was reversed](https://github.com/hetima/hammerspoon-hyperex/commit/3d9963d40d5dc51e7061eea8788d0b424d5fe5c9). Early settings takes precedence. You may need to repair init.lua.   
- added idiom `'num'` and `'pads'` for `mod():to()`

### 0.2
- added [Sticky mode](#sticky-mode)

## Install

Place `hyperex.lua` into `~/.hammerspoon/`

## Constructor

```lua
local hyperex = require('hyperex')
local hx = hyperex.new('f18') -- f18 becomes hyper-key
```

hyperex can attach behavior to modifier key. It can be set individual instance on the left and right.

```lua
local leftCmd = hyperex.new('cmd') -- define generic label as left
local rightCmd = hyperex.new('rightcmd')
```


## adding shortcut and function

This setting acts like hotkey during press hyper-key.

```lua
-- syntax
-- hyperex:bind(key):to(key, {mods, ...})
-- hyperex:bind(key):to(function)

-- hyper + a -> b
hx:bind('a'):to('b')
-- hyper + ] -> shift + 8
hx:bind(']'):to('8', {'shift'})
-- hyper + z -> trigger function
hx:bind('z'):to(function() hs.eventtap.keyStroke({}, 'h') end)

```

If attached to modifier key, source modifier is **not merged**.


## adding modifiers

This setting modify only modifier keys.

```lua
-- syntax
-- hyperex:mod({mods, ...}):to({key, otherKey, ...})

--  hyper + 3 or 4 -> cmd + shift + 3 or 4
hx:mod({'cmd', 'shift'}):to('3','4')

-- some special idiom
-- hyper + anyKey -> ctrl + shift + anyKey
hx:mod({'ctrl', 'shift'}):to('any')
-- hyper + a~z -> ctrl + shift + a~z
hx:mod({'ctrl', 'shift'}):to('atoz')
-- hyper + f1~f15 -> ctrl + shift + f1~f15
hx:mod({'ctrl', 'shift'}):to('fkeys')
-- hyper + 0~9 -> 0~9
hx:mod({}):to('num')
-- hyper + keypad(pad0~9, pad+, pad-, etc...) -> keypad
hx:mod({}):to('pads')
```

If attached to modifier key, source modifier is **merged**.

## InitialKey and EmptyHitKey
InitialKey is triggered immediately when hyper-key is pressed.  
EmptyHitKey is triggered when hyper-key is released if any setting was not triggered.

```lua
hx:setInitialKey(0x66) --eisu
hx:setEmptyHitKey(0x68) --kana

-- or function is also supported
hx:setInitialFunc(function ... end)
hx:setEmptyHitFunc(function ... end)
```

## message
Show message with `hs.alert()` when triggered. Default duration is 0.4 sec.
```lua
-- syntax
-- hyperex:withMessage(message[, leaveMessage][, duration])
-- setting:withMessage(message[, duration])

local hx = hyperex.new(0x50):withMessage("hello", "bye", 0.5)
hx:bind('a'):to('a', {}):withMessage("a was pressed", 0.1)
```

## Sticky mode

Sticky mode has three variants.

- `'once'` : It ends soon after any one stroke.
- `'toggle'` : Enabled until you press the hyper-key again.
- `'chain'` : Enabled while strokes continue at short intervals

Pressing the `esc` key ends mode immediately regardless of variant.

```lua
local hx = hyperex.new('f18')
hx:sticky('once')
hx:sticky('toggle')
hx:sticky('chain', 0.4) -- pass effective duration as secs
```

If attached to modifier key, sticky mode is disabled.

## Other

"Secure Keyboard Entry" option of Terminal.app avoids input monitoring. This option interferes with the operation of hyperex.


hyperex can be used multiple instances.

```lua
local hyperex = require('hyperex')
local hx = hyperex.new('f18')
local hx2 = hyperex.new('f19')
```

You can not set the same key as hyper-key

```lua
local hx = hyperex.new('f18')
hx:bind('f18'):to(...) -- disabled
hx:setInitialKey('f18') -- disabled
hx:setEmptyHitKey('f18') -- disabled
hx:bind('f1'):to('f18') -- enabled but confuse
```

Give priority to early settings. `bind` takes precedence over `mod` all the time.
```lua
local hx = hyperex.new('f18')
hx:mod({'ctrl', 'shift'}):to('f1','f2') -- only f2 is enabled 
hx:bind('f1'):to(...) -- enabled
hx:bind('f1'):to(...) -- disabled
hx:mod({'alt'}):to('f2','f3') -- only f3 is enabled
```

hyperex handles only real keyboard input.
```lua
-- this setting could be triggered. infinite loop does not occur.
hx:bind('x'):to(function() hs.eventtap.keyStroke({}, 'x') end)
```
Method chain

| class   | method | return |
|---------|--------|--------|
|CHyper   |.new()|CHyper|
|CHyper   |:setInitialKey()|self|
|CHyper   |:setEmptyHitKey()|self|
|CHyper   |:sticky()|self|
|CHyper   |:bind()|CBinder|
|CHyper   |:mod()|CModifier|
|CBinder  |:to()|self|
|CModifier|:to()|self|
|*        |:withMessage()|self|

## Example

Make left cmd to EISU and right cmd to KANA when type alone.
```lua
local hxLCmd = hyperex.new('cmd'):setEmptyHitKey(0x66)
local hxRCmd = hyperex.new('rightcmd'):setEmptyHitKey(0x68)
```

## License

WTFPL 2.0

## Author

hetima  
https://twitter.com/hetima
