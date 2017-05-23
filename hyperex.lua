
--  hyperex.lua

local HYPEREX_VERSION = '0.1'

local log = hs.logger.new('hyperex', 'debug')

local KEY_DOWN = 1
local KEY_REPEAT = 2
local KEY_UP = 3

CHyper = {}

CHyper.version = function()
    return HYPEREX_VERSION
end

-- 比較の手間を省くためにあらかじめ数値にしておく
local function realKeyCode(v)
    if type(v) == 'string' then
        v = hs.keycodes.map[v]
    end
    if type(v) == 'number' then
        return v
    end
    return nil
end

-- 2つの引数から modifiers と key を取得する。返り値は modifiers, key
-- ({'mod','mod'}, key) (key, {'mod','mod'}) -> 順不同で OK
-- ('key', nil)  -> modifiers は {}
-- ('mod+mod+key') -> オリジナル
local function parseKey(a1, a2)
    local parseSingle = function(a)
        if type(a) == 'number' then return {}, a end
        if type(a) == 'string' then
            local k = realKeyCode(a)
            if k ~= nil then return {}, k end
            -- parse mod+mod+k style
            k = a:lower()
            local words = hs.fnutils.split(k, '+')
            local key = nil
            local mods = hs.fnutils.imap(words, function(v)
                if v == 'cmd' or v == 'command' or v == '⌘' then
                    return 'cmd' 
                elseif v == 'ctrl' or v == 'control' or v == '⌃' or v == 'ctl' then
                    return 'ctrl' 
                elseif v == 'alt' or v == 'option' or v == '⌥' or v == 'opt' then
                    return 'alt' 
                elseif v == 'shift' or v == '⇧' or v == 'shft' then
                    return 'shift' 
                end
                if v == '' then
                    if key == 'pad' then key = 'pad+' end
                else
                    key = v
                end
                return nil
            end)
            return mods, realKeyCode(key)
        end
    end

    if a2 == nil then return parseSingle(a1) end

    local m = nil
    local k = nil

    if type(a1) == 'table' then
        m = a1
        k = a2
    elseif type(a2) == 'table' then
        m = a2
        k = a1
    end
    if k ~= nil then
        k = realKeyCode(k)
        return m, k
    end

    return {}, nil
end

local function modifiersToFlags(modifiers)
    local flags = {}
    for i, v in pairs(modifiers) do
        flags[v] = true
    end
    return flags
end

local CModifier = {}
local CModifierImpl = {

    mod = function(self, modifiers)
        if type(modifiers) == 'string' then
            modifiers = {modifiers}
        end
        self._modFlags = modifiersToFlags(modifiers)
        return self
    end,

    withMessage = function(self, m, t)
        self.message = m
        if type(t) == 'number' then
            self.alertDuration = t
        end
        return self
    end,

    showMessage = function(self)
        if type(self.message) == 'string' then 
            hs.alert(self.message, self.alertDuration or 0)
        end
    end,

    to = function(self, keys)
        if type(keys) == 'string' then
            if keys == 'any' or keys == 'all' then
                self._anyTarget = true
                return self
            end
            keys = {keys}
        elseif type(keys) == 'number' then
            keys = {keys}
        end
        local keyNumbers = {}
        for i, v in pairs(keys) do
            local specials = nil
            if v == 'atoz' then
                specials = {'a','b','c','d','e','f','g','h','i','j','k','l','m',
                    'n','o','p','q','r','s','t','u','v','w','x','y','z'}
            elseif v == 'fkeys' then
                specials = {'f1','f2','f3','f4','f5','f6','f7','f8','f9','f10','f11','f12','f13','f14','f15'}
            else
                v = realKeyCode(v)
                if type(v) == 'number' then
                    table.insert(keyNumbers, v)
                end
            end
            if specials ~= nil then
                for i, v in pairs(specials) do
                    table.insert(keyNumbers, realKeyCode(v))
                end
            end
        end
        self._targetKeys = keyNumbers
        return self
    end,

    flagsForKey = function(self, key)
        if self._anyTarget then
            return self._modFlags
        end
        for i, v in pairs(self._targetKeys) do
            if key == v then
                return self._modFlags
            end
        end
        return nil
    end,

}

CModifier.new = function(hyperInstance)
    local _self = {
        _modFlags = {},
        _targetKeys = {},
        _anyTarget = false,
        message = nil,
        alertDuration = 0.4,
    }

    setmetatable(_self, {__index = CModifierImpl})
    return _self
end

local CBinder = {}
local CBinderImpl = {
    withMessage = function(self, m, t)
        self.message = m
        if type(t) == 'number' then
            self.alertDuration = t
        end
        return self
    end,

    showMessage = function(self)
        if type(self.message) == 'string' then 
            hs.alert(self.message, self.alertDuration or 0)
        end
    end,

    bind = function(self, fromKey, fromMod)
        self.fromMod, self.fromKey = parseKey(fromKey, fromMod)
        return self
    end,

    to = function(self, a1, a2)
        if type(a1) == 'function' then
            self.toFunc = a1
            self.toKey = nil
            return self
        end

        self.toFlags, self.toKey = parseKey(a1, a2)
        if self.toKey ~= nil then
            self.toFlags = modifiersToFlags(self.toFlags)
            self.toFunc = nil
        end
        return self
    end,

}

CBinder.new = function(hyperInstance)
    local _self = {
        fromKey = nil,
        fromMod = {},
        toKey = nil,
        toFlags = {},
        toFunc = nil,
        message = nil,
        alertDuration = 0.4,
    }

    setmetatable(_self, {__index = CBinderImpl})

    return _self
end



local CHyperImpl = {
    withMessage = function(self, m, t, z)
        if type(m) == 'string' and #m > 0 then
            self.message = m
        end
        if type(t) == 'number' then
            self.alertDuration = t
        elseif type(t) == 'string' and #t > 0 then
            self.leaveMessage = t
            if type(z) == 'number' then
                self.alertDuration = z
            end
        end
        return self
    end,

    setInitialFunc = function(self, func)
        if (type(func) == 'function') then
            self._initialHitFunc = func
        end
        return self
    end,

    setInitialKey = function(self, key, modifiers)
        modifiers, key = parseKey(key, modifiers)
        if key == self._triggerKey then
            return self
        end
        self._initialHitFunc = function()
            hs.eventtap.event.newKeyEvent(modifiers, key, true):post()
            hs.timer.usleep(600)
            hs.eventtap.event.newKeyEvent(modifiers, key, false):post()
        end
        return self
    end,

    setEmptyHitFunc = function(self, func)
        if type(func) == 'function' then
            self._emptyHitFunc = func
        end
        return self
    end,

    setEmptyHitKey = function(self, key, modifiers)
        modifiers, key = parseKey(key, modifiers)
        if key == self._triggerKey then
            return self
        end
        self._emptyHitFunc = function()
            hs.eventtap.event.newKeyEvent(modifiers, key, true):post()
            hs.timer.usleep(600)
            hs.eventtap.event.newKeyEvent(modifiers, key, false):post()
        end
        return self
    end,

    bind = function(self, fromKey, fromMod)
        local b = CBinder.new(self):bind(fromKey, fromMod)
        table.insert(self._binders, 1, b)
        return b
    end,

    mod = function(self, modifiers)
        local m = CModifier.new(self):mod(modifiers)
        table.insert(self._modifiers, 1, m)
        return m
    end,

    enter = function(self)
        if self._tap:isEnabled() then
            log.d('try to re-enter')
            return
        end
        if type(self.message) == 'string' then 
            hs.alert(self.message, self.alertDuration or 0)
        end
        self._tap:start()
        if self._initialHitFunc then
            self._initialHitFunc()
        end
        self._triggered = false
    end,

    exit = function(self)
        if not self._tap:isEnabled() then
            log.d('try to re-exit')
            return
        end
        if type(self.leaveMessage) == 'string' then 
            hs.alert(self.leaveMessage, self.alertDuration or 0)
        end
        self._tap:stop()
        -- stop した後に呼ばないとキーイベントが発生しない
        if (not self._triggered) and self._emptyHitFunc then
            self._emptyHitFunc()
        end
    end,

    handleTap = function(self, e, keyCode, type)

        -- ややこしいことになるので triggerKey と同じものは無視
        -- hotkey 最初の keyDown は来ないが、押下中の keyRepeat は来る
        if keyCode == self._triggerKey then
            -- triggerKey の keyUp は確実に逃がさないとモードを抜け出せない
            if type == KEY_UP then
                return false
            else
                return true
            end
        end

        -- binder
        for i, v in ipairs(self._binders) do
            if keyCode == v.fromKey then
                -- remap 型
                if v.toKey ~= nil then
                    e:setKeyCode(v.toKey)
                    e:setFlags(v.toFlags)
                    if type == KEY_DOWN then
                        self._triggered = true
                        v:showMessage()
                    end
                    return false
                -- func 型
                elseif v.toFunc ~= nil then
                    if type == KEY_DOWN then
                        self._triggered = true
                        v:showMessage()
                        v.toFunc()
                    end
                    return true
                end
            end
        end

        -- modifier
        for i, v in ipairs(self._modifiers) do
            local flag = v:flagsForKey(keyCode)
            if flag ~= nil then
                e:setFlags(flag)
                if type == KEY_DOWN then
                    self._triggered = true
                end
                return false
            end
        end

        return false
    end,

}

CHyper.new = function(triggerKey)
    local _self = {
        message = nil,
        leaveMessage = nil,
        alertDuration = 0.4,

        _triggered = false,
        _binders = {},
        _modifiers = {},
        _emptyHitFunc = nil,
        _initialHitFunc = nil,

        _triggerKey = nil,
        _triggerMod = {}, -- unused now
        _trigger = nil,

        _tap = nil
    }

    setmetatable(_self, {__index = CHyperImpl})

    _self._triggerMod, _self._triggerKey = parseKey(triggerKey)
    if _self._triggerKey ~= nil then
        local hotkeyDown = function() _self:enter() end
        local hotkeyUp = function() _self:exit() end
        local handleTap = function(e)
            -- キーボードからの直接入力だけを扱う
            local stateID = e:getProperty(hs.eventtap.event.properties['eventSourceStateID'])
            if stateID ~= 1 then
                return false
            end
            local keyCode = e:getKeyCode()
            local type = KEY_UP
            if e:getType() == hs.eventtap.event.types.keyDown then
                if e:getProperty(hs.eventtap.event.properties['keyboardEventAutorepeat']) == 0 then
                    type = KEY_DOWN
                else
                    type = KEY_REPEAT
                end
            end
            _self:handleTap(e, keyCode, type)
        end
        _self._trigger = hs.hotkey.bind(_self._triggerMod, _self._triggerKey, 0, hotkeyDown, hotkeyUp, nil)
        _self._tap = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, handleTap)
    end

    return _self
end

-- stickey mode

local STICKEY_ONCE = 1
local STICKEY_TOGGLE = 2
local STICKEY_CHAIN = 3

local CHyperStickeyImpl = {
    enter = function(self)
        if self._tap:isEnabled() then
            self:exitStickey()
        else
            -- log.d("Stickey enter")
            self._stickeyModal:enter()
            CHyperImpl.enter(self)
        end
    end,

    exitStickey = function(self)
        -- log.d("Stickey exit")
        CHyperImpl.exit(self)
        self._stickeyModal:exit()
    end,

    exit = function(self)
        -- intercept
    end,

    chain = function(self)
        if self.chainTimer == nil then
            self.chainTimer = hs.timer.delayed.new(self.chainDelay, function() self:fireChainTimer() end)
        end
        self.chainTimer:start()
    end,

    fireChainTimer = function(self)
        self.chainTimer:stop()
        self:exitStickey()
    end,

    handleTap = function(self, e, keyCode, type)
        if keyCode == 0x35 or keyCode == self._triggerKey then
            return true
        end
        if self.stickeyMode == STICKEY_ONCE then
             self:exitStickey()
        elseif self.stickeyMode == STICKEY_CHAIN then
            self:chain()
        end
        return CHyperImpl.handleTap(self, e, keyCode, type)
    end,
}
setmetatable(CHyperStickeyImpl, {__index = CHyperImpl})

CHyperImpl.stickey = function(self, mode, op)
    if type(mode) == 'string' then
        local case = {once = STICKEY_ONCE, toggle = STICKEY_TOGGLE, chain = STICKEY_CHAIN}
        self.stickeyMode = case[mode:lower()]
    end

    if type(self.stickeyMode) == 'number' then
        if self._stickeyModal == nil then
            self._stickeyModal = hs.hotkey.modal.new()
            self._stickeyModal:bind({}, 0x35, 0, function() self:exitStickey() end, nil, nil)
        end
        if self.stickeyMode == STICKEY_CHAIN and type(op) == 'number' then
            self.chainDelay = op
        else
            self.chainDelay = 0.5
        end
        setmetatable(self, {__index = CHyperStickeyImpl})
    else
        setmetatable(self, {__index = CHyperImpl})
    end

    return self
end

return CHyper
