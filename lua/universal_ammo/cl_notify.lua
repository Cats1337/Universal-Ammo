local NotifySounds = {
    [0] = "buttons/button16.wav", -- generic
    [1] = "buttons/button11.wav", -- error
    [2] = "buttons/button17.wav", -- undo
    [3] = "buttons/button3.wav",  -- hint
    [4] = "buttons/button6.wav"   -- cleanup
}

net.Receive("UA_Notify", function()
    local text = net.ReadString()
    local type = net.ReadUInt(3)
    local duration = net.ReadFloat()

    notification.AddLegacy(text, type, duration)

    local snd = NotifySounds[type]
    if snd then
        surface.PlaySound(snd)
    end
end)


-- NOTIFY_GENERIC	0
-- NOTIFY_ERROR	1
-- NOTIFY_UNDO	2
-- NOTIFY_HINT	3
-- NOTIFY_CLEANUP	4